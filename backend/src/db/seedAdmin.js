'use strict';

const bcrypt = require('bcryptjs');
const { pool, query } = require('./pool');

async function run() {
  const username = process.env.ADMIN_USERNAME || 'Admin';
  const password = process.env.ADMIN_PASSWORD || 'Admin@123';
  const name     = process.env.ADMIN_NAME     || 'Vacado Admin';
  const email    = process.env.ADMIN_EMAIL    || null;

  const hash = await bcrypt.hash(password, 10);

  await query(
    `INSERT INTO admins (username, password_hash, name, email, role)
     VALUES ($1, $2, $3, $4, 'superadmin')
     ON CONFLICT (username) DO UPDATE
       SET password_hash = EXCLUDED.password_hash,
           name = EXCLUDED.name,
           email = EXCLUDED.email,
           updated_at = now()`,
    [username, hash, name, email]
  );

  console.log(`Admin upserted: ${username}`);
}

run()
  .then(() => pool.end())
  .catch((err) => {
    console.error('seedAdmin failed:', err);
    pool.end();
    process.exit(1);
  });
