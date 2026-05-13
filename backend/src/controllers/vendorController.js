'use strict';

const { query } = require('../db/pool');
const ApiError = require('../utils/ApiError');

async function _vendorIdFor(req) {
  const { rows } = await query('SELECT id FROM vendors WHERE admin_id = $1 LIMIT 1', [req.admin.id]);
  if (!rows[0]) throw ApiError.forbidden('no_vendor_profile');
  return rows[0].id;
}

async function profile(req, res) {
  const { rows } = await query(
    `SELECT vendors.*, admins.username, admins.name AS contact_name, admins.email
       FROM vendors JOIN admins ON admins.id = vendors.admin_id
      WHERE vendors.admin_id = $1`,
    [req.admin.id]
  );
  if (!rows[0]) throw ApiError.notFound('vendor_profile_not_found');
  const v = rows[0];
  res.json({
    vendor: {
      id: v.id, storeName: v.store_name, storePhone: v.store_phone, storeCity: v.store_city,
      isActive: v.is_active, username: v.username, contactName: v.contact_name, email: v.email,
    },
  });
}

async function stats(req, res) {
  const vendorId = await _vendorIdFor(req);
  const [{ rows: p }, { rows: lowStock }, { rows: revenue }, { rows: orders }] = await Promise.all([
    query('SELECT count(*)::int AS n FROM products WHERE vendor_id = $1', [vendorId]),
    query('SELECT count(*)::int AS n FROM products WHERE vendor_id = $1 AND stock < 10', [vendorId]),
    query(
      `SELECT COALESCE(SUM(order_items.line_total_paise), 0)::bigint AS total
         FROM order_items
         JOIN products ON products.id = order_items.product_id
        WHERE products.vendor_id = $1`,
      [vendorId]
    ),
    query(
      `SELECT count(DISTINCT orders.id)::int AS n
         FROM orders
         JOIN order_items ON order_items.order_id = orders.id
         JOIN products    ON products.id = order_items.product_id
        WHERE products.vendor_id = $1`,
      [vendorId]
    ),
  ]);

  const recentOrders = await query(
    `SELECT DISTINCT orders.id, orders.order_number, orders.status, orders.total_paise, orders.placed_at,
            users.name AS user_name, users.phone AS user_phone
       FROM orders
       JOIN order_items ON order_items.order_id = orders.id
       JOIN products    ON products.id = order_items.product_id
       LEFT JOIN users  ON users.id = orders.user_id
      WHERE products.vendor_id = $1
      ORDER BY orders.placed_at DESC
      LIMIT 8`,
    [vendorId]
  );

  res.json({
    products: p[0].n,
    lowStock: lowStock[0].n,
    orders: orders[0].n,
    revenuePaise: Number(revenue[0].total),
    recentOrders: recentOrders.rows.map((o) => ({
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, placedAt: o.placed_at,
      customer: { name: o.user_name, phone: o.user_phone },
    })),
  });
}

async function listOrders(req, res) {
  const vendorId = await _vendorIdFor(req);
  const { rows } = await query(
    `SELECT DISTINCT orders.id, orders.order_number, orders.status, orders.total_paise,
            orders.placed_at, orders.payment_status,
            users.name AS user_name, users.phone AS user_phone
       FROM orders
       JOIN order_items ON order_items.order_id = orders.id
       JOIN products    ON products.id = order_items.product_id
       LEFT JOIN users  ON users.id = orders.user_id
      WHERE products.vendor_id = $1
      ORDER BY orders.placed_at DESC
      LIMIT 100`,
    [vendorId]
  );
  res.json({
    orders: rows.map((o) => ({
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, paymentStatus: o.payment_status, placedAt: o.placed_at,
      customer: { name: o.user_name, phone: o.user_phone },
    })),
  });
}

module.exports = { profile, stats, listOrders };
