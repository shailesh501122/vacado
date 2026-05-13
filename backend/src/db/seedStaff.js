'use strict';

const bcrypt = require('bcryptjs');
const { pool, query, withTx } = require('./pool');

/**
 * Idempotent staff seeding. Creates / refreshes:
 *   Admin / Admin@123      (superadmin)
 *   vendor / vendor        (vendor)  — Vacado Bangalore store
 *   boy / boy              (rider)   — Delivery rider
 */

const STAFF = [
  {
    username: 'Admin',
    password: 'Admin@123',
    name: 'Vacado Admin',
    role: 'superadmin',
  },
  {
    username: 'vendor',
    password: 'vendor',
    name: 'Vacado Vendor',
    role: 'vendor',
    vendor: { storeName: 'Vacado Indiranagar Store', storePhone: '+91 98000 11111', storeCity: 'Bangalore' },
  },
  {
    username: 'boy',
    password: 'boy',
    name: 'Delivery Boy',
    role: 'rider',
    rider: { displayName: 'Rahul', phone: '+91 99888 77665', vehicle: 'KA 03 ZJ', rating: 4.9 },
  },
];

async function run() {
  await withTx(async (client) => {
    for (const s of STAFF) {
      const hash = await bcrypt.hash(s.password, 10);
      const up = await client.query(
        `INSERT INTO admins (username, password_hash, name, role)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (username) DO UPDATE
           SET password_hash = EXCLUDED.password_hash,
               name = EXCLUDED.name,
               role = EXCLUDED.role,
               updated_at = now()
         RETURNING id`,
        [s.username, hash, s.name, s.role]
      );
      const adminId = up.rows[0].id;

      if (s.vendor) {
        await client.query(
          `INSERT INTO vendors (admin_id, store_name, store_phone, store_city)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (admin_id) DO UPDATE
             SET store_name = EXCLUDED.store_name,
                 store_phone = EXCLUDED.store_phone,
                 store_city = EXCLUDED.store_city`,
          [adminId, s.vendor.storeName, s.vendor.storePhone, s.vendor.storeCity]
        );

        // Assign all currently-orphaned products to this default vendor so
        // there's something to see in the vendor dashboard immediately.
        await client.query(
          `UPDATE products
              SET vendor_id = (SELECT id FROM vendors WHERE admin_id = $1)
            WHERE vendor_id IS NULL`,
          [adminId]
        );
      }

      if (s.rider) {
        await client.query(
          `INSERT INTO riders (admin_id, display_name, phone, vehicle, rating)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (admin_id) DO UPDATE
             SET display_name = EXCLUDED.display_name,
                 phone = EXCLUDED.phone,
                 vehicle = EXCLUDED.vehicle,
                 rating = EXCLUDED.rating`,
          [adminId, s.rider.displayName, s.rider.phone, s.rider.vehicle, s.rider.rating]
        );
      }

      console.log(`✓ ${s.role.padEnd(11)} → ${s.username}`);
    }
  });
}

run()
  .then(() => pool.end())
  .catch((err) => {
    console.error('seedStaff failed:', err);
    pool.end();
    process.exit(1);
  });
