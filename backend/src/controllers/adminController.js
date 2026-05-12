'use strict';

const bcrypt = require('bcryptjs');
const { z } = require('zod');
const { query } = require('../db/pool');
const { signAdmin } = require('../middleware/adminAuth');
const ApiError = require('../utils/ApiError');

// ─── Auth ──────────────────────────────────────────────────
const loginSchema = z.object({
  username: z.string().min(2).max(80),
  password: z.string().min(4).max(120),
});

async function login(req, res) {
  const { username, password } = req.body;
  const { rows } = await query(
    `SELECT id, username, password_hash, name, role, is_active
       FROM admins
      WHERE lower(username) = lower($1) LIMIT 1`,
    [username]
  );
  const admin = rows[0];
  if (!admin || !admin.is_active) throw ApiError.unauthorized('Invalid credentials');
  const ok = await bcrypt.compare(password, admin.password_hash);
  if (!ok) throw ApiError.unauthorized('Invalid credentials');

  await query('UPDATE admins SET last_login_at = now() WHERE id = $1', [admin.id]);

  const token = signAdmin({ sub: admin.id, username: admin.username, role: admin.role });
  res.json({
    ok: true, token,
    admin: { id: admin.id, username: admin.username, name: admin.name, role: admin.role },
  });
}

async function me(req, res) {
  const { rows } = await query(
    `SELECT id, username, name, email, role, last_login_at FROM admins WHERE id = $1`,
    [req.admin.id]
  );
  if (!rows[0]) throw ApiError.notFound('admin_not_found');
  res.json({ admin: rows[0] });
}

// ─── Stats / Dashboard ─────────────────────────────────────
async function stats(_req, res) {
  const [{ rows: o }, { rows: r }, { rows: u }, { rows: p }, { rows: today }] = await Promise.all([
    query(`SELECT count(*)::int AS total FROM orders`),
    query(`SELECT COALESCE(SUM(total_paise), 0)::bigint AS revenue FROM orders WHERE status <> 'cancelled'`),
    query(`SELECT count(*)::int AS total FROM users`),
    query(`SELECT count(*)::int AS total FROM products WHERE stock > 0`),
    query(`SELECT count(*)::int AS orders, COALESCE(SUM(total_paise),0)::bigint AS revenue
             FROM orders WHERE placed_at >= now() - interval '24 hours' AND status <> 'cancelled'`),
  ]);

  const { rows: byStatus } = await query(
    `SELECT status, count(*)::int AS n FROM orders GROUP BY status`
  );
  const { rows: topProducts } = await query(
    `SELECT products.id, products.name, products.fruit_kind, count(order_items.*)::int AS sold,
            COALESCE(SUM(order_items.line_total_paise), 0)::bigint AS revenue
       FROM products
       LEFT JOIN order_items ON order_items.product_id = products.id
       GROUP BY products.id
       ORDER BY sold DESC, revenue DESC
       LIMIT 6`
  );
  const { rows: recentOrders } = await query(
    `SELECT id, order_number, status, total_paise, placed_at FROM orders ORDER BY placed_at DESC LIMIT 8`
  );

  res.json({
    totals: {
      orders: o[0].total,
      revenuePaise: Number(r[0].revenue),
      customers: u[0].total,
      products: p[0].total,
    },
    today: { orders: today[0].orders, revenuePaise: Number(today[0].revenue) },
    byStatus,
    topProducts: topProducts.map((t) => ({
      id: t.id, name: t.name, fruitKind: t.fruit_kind, sold: t.sold, revenuePaise: Number(t.revenue),
    })),
    recentOrders: recentOrders.map((o) => ({
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, placedAt: o.placed_at,
    })),
  });
}

// ─── Orders ────────────────────────────────────────────────
async function listOrders(req, res) {
  const status = req.query.status;
  const params = [];
  let where = '';
  if (status) { params.push(status); where = `WHERE status = $${params.length}`; }
  params.push(50);
  const { rows } = await query(
    `SELECT orders.*, users.phone AS user_phone, users.name AS user_name
       FROM orders LEFT JOIN users ON users.id = orders.user_id
      ${where}
      ORDER BY placed_at DESC LIMIT $${params.length}`,
    params
  );
  res.json({
    orders: rows.map((o) => ({
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, paymentMethod: o.payment_method, paymentStatus: o.payment_status,
      placedAt: o.placed_at, deliveredAt: o.delivered_at,
      customer: { phone: o.user_phone, name: o.user_name },
      rider: o.rider_name ? { name: o.rider_name, phone: o.rider_phone } : null,
    })),
  });
}

async function getOrder(req, res) {
  const { id } = req.params;
  const orderRes = await query(
    `SELECT orders.*, users.phone AS user_phone, users.name AS user_name
       FROM orders LEFT JOIN users ON users.id = orders.user_id
      WHERE orders.id = $1`,
    [id]
  );
  if (!orderRes.rows[0]) throw ApiError.notFound('order_not_found');
  const items = await query(`SELECT * FROM order_items WHERE order_id = $1`, [id]);
  const events = await query(`SELECT * FROM order_events WHERE order_id = $1 ORDER BY occurred_at ASC`, [id]);
  const o = orderRes.rows[0];
  res.json({
    order: {
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, subtotalPaise: o.subtotal_paise, discountPaise: o.discount_paise,
      paymentMethod: o.payment_method, paymentStatus: o.payment_status,
      placedAt: o.placed_at, deliveredAt: o.delivered_at,
      customer: { phone: o.user_phone, name: o.user_name },
      rider: o.rider_name ? { name: o.rider_name, phone: o.rider_phone, rating: o.rider_rating, vehicle: o.rider_vehicle } : null,
      items: items.rows.map((i) => ({
        productName: i.product_name, fruitKind: i.fruit_kind, weightLabel: i.weight_label,
        unitPricePaise: i.unit_price_paise, quantity: i.quantity, lineTotalPaise: i.line_total_paise,
      })),
      events: events.rows.map((e) => ({ kind: e.kind, title: e.title, subtitle: e.subtitle, occurredAt: e.occurred_at })),
    },
  });
}

const statusSchema = z.object({
  status: z.enum(['placed', 'packed', 'out_for_delivery', 'delivered', 'cancelled']),
});

async function updateOrderStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;
  const r = await query(
    `UPDATE orders
        SET status = $1,
            delivered_at = CASE WHEN $1 = 'delivered' THEN now() ELSE delivered_at END,
            updated_at = now()
      WHERE id = $2
      RETURNING id`,
    [status, id]
  );
  if (!r.rowCount) throw ApiError.notFound('order_not_found');
  await query(
    `INSERT INTO order_events (order_id, kind, title, subtitle) VALUES ($1, $2, $3, $4)`,
    [id, status, `Status → ${status}`, `Set by admin ${req.admin.username}`]
  );
  res.json({ ok: true });
}

// ─── Products ──────────────────────────────────────────────
async function listProducts(_req, res) {
  const { rows } = await query(
    `SELECT products.*, categories.name AS category_name
       FROM products LEFT JOIN categories ON categories.id = products.category_id
      ORDER BY products.created_at DESC`
  );
  res.json({
    products: rows.map((p) => ({
      id: p.id, slug: p.slug, name: p.name, categoryName: p.category_name,
      fruitKind: p.fruit_kind, weightLabel: p.weight_label,
      pricePaise: p.price_paise, mrpPaise: p.mrp_paise, stock: p.stock,
      rating: Number(p.rating), reviewCount: p.review_count, etaMinutes: p.eta_minutes,
      isOrganic: p.is_organic, isTrending: p.is_trending, isBestseller: p.is_bestseller,
      updatedAt: p.updated_at,
    })),
  });
}

const productUpsertSchema = z.object({
  slug: z.string().min(2).max(120),
  name: z.string().min(2).max(160),
  description: z.string().optional(),
  categoryId: z.string().uuid().optional().nullable(),
  fruitKind: z.string().default('apple'),
  origin: z.string().optional().nullable(),
  weightLabel: z.string().default('500 g'),
  pricePaise: z.number().int().min(0),
  mrpPaise: z.number().int().min(0).optional().nullable(),
  stock: z.number().int().min(0).default(100),
  etaMinutes: z.number().int().min(0).default(10),
  isOrganic: z.boolean().default(false),
  isTrending: z.boolean().default(false),
  isBestseller: z.boolean().default(false),
});

async function createProduct(req, res) {
  const p = req.body;
  const { rows } = await query(
    `INSERT INTO products
      (slug, name, description, category_id, fruit_kind, origin, weight_label,
       price_paise, mrp_paise, stock, eta_minutes, is_organic, is_trending, is_bestseller)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
     RETURNING id`,
    [p.slug, p.name, p.description || null, p.categoryId || null, p.fruitKind, p.origin || null,
     p.weightLabel, p.pricePaise, p.mrpPaise || null, p.stock, p.etaMinutes,
     p.isOrganic, p.isTrending, p.isBestseller]
  );
  res.status(201).json({ id: rows[0].id });
}

async function updateProduct(req, res) {
  const { id } = req.params;
  const p = req.body;
  const r = await query(
    `UPDATE products
        SET slug = $1, name = $2, description = $3, category_id = $4, fruit_kind = $5, origin = $6,
            weight_label = $7, price_paise = $8, mrp_paise = $9, stock = $10, eta_minutes = $11,
            is_organic = $12, is_trending = $13, is_bestseller = $14, updated_at = now()
      WHERE id = $15`,
    [p.slug, p.name, p.description || null, p.categoryId || null, p.fruitKind, p.origin || null,
     p.weightLabel, p.pricePaise, p.mrpPaise || null, p.stock, p.etaMinutes,
     p.isOrganic, p.isTrending, p.isBestseller, id]
  );
  if (!r.rowCount) throw ApiError.notFound('product_not_found');
  res.json({ ok: true });
}

async function deleteProduct(req, res) {
  const { id } = req.params;
  const r = await query(`DELETE FROM products WHERE id = $1`, [id]);
  if (!r.rowCount) throw ApiError.notFound('product_not_found');
  res.json({ ok: true });
}

// ─── Customers ─────────────────────────────────────────────
async function listCustomers(_req, res) {
  const { rows } = await query(
    `SELECT users.id, users.phone, users.name, users.created_at,
            COUNT(orders.id)::int AS order_count,
            COALESCE(SUM(orders.total_paise), 0)::bigint AS total_spent_paise
       FROM users LEFT JOIN orders ON orders.user_id = users.id
      GROUP BY users.id
      ORDER BY users.created_at DESC
      LIMIT 100`
  );
  res.json({
    customers: rows.map((c) => ({
      id: c.id, phone: c.phone, name: c.name, createdAt: c.created_at,
      orderCount: c.order_count, totalSpentPaise: Number(c.total_spent_paise),
    })),
  });
}

// ─── Coupons ───────────────────────────────────────────────
const couponUpsertSchema = z.object({
  code: z.string().min(2).max(40),
  title: z.string().min(2).max(160),
  subtitle: z.string().optional(),
  tone: z.enum(['green','orange']).default('green'),
  discountType: z.enum(['flat','percent']),
  discountValue: z.number().int().min(0),
  minOrderPaise: z.number().int().min(0).default(0),
  isActive: z.boolean().default(true),
});

async function listCoupons(_req, res) {
  const { rows } = await query(`SELECT * FROM coupons ORDER BY created_at DESC`);
  res.json({ coupons: rows });
}

async function createCoupon(req, res) {
  const c = req.body;
  const { rows } = await query(
    `INSERT INTO coupons (code, title, subtitle, tone, discount_type, discount_value, min_order_paise, is_active)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
    [c.code.toUpperCase(), c.title, c.subtitle || null, c.tone, c.discountType, c.discountValue, c.minOrderPaise, c.isActive]
  );
  res.status(201).json({ id: rows[0].id });
}

async function deleteCoupon(req, res) {
  const { id } = req.params;
  const r = await query(`DELETE FROM coupons WHERE id = $1`, [id]);
  if (!r.rowCount) throw ApiError.notFound('coupon_not_found');
  res.json({ ok: true });
}

// ─── Categories ────────────────────────────────────────────
async function listCategoriesAdmin(_req, res) {
  const { rows } = await query(
    `SELECT id, slug, name, fruit_kind, position, is_active FROM categories ORDER BY position ASC`
  );
  res.json({ categories: rows });
}

module.exports = {
  schemas: { loginSchema, productUpsertSchema, statusSchema, couponUpsertSchema },
  login, me, stats,
  listOrders, getOrder, updateOrderStatus,
  listProducts, createProduct, updateProduct, deleteProduct,
  listCustomers,
  listCoupons, createCoupon, deleteCoupon,
  listCategoriesAdmin,
};
