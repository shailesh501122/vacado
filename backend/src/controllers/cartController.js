'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const { mapProduct } = require('./catalogController');
const ApiError = require('../utils/ApiError');

const DELIVERY_FEE_PAISE = 0; // free for design
const HANDLING_PAISE = 400;

async function loadCart(userId) {
  const { rows } = await query(
    `SELECT cart_items.id, cart_items.quantity, products.*
       FROM cart_items
       JOIN products ON products.id = cart_items.product_id
      WHERE cart_items.user_id = $1
      ORDER BY cart_items.created_at ASC`,
    [userId]
  );
  return rows.map((r) => ({
    cartItemId: r.id,
    quantity: r.quantity,
    product: mapProduct(r),
    lineTotalPaise: r.quantity * r.price_paise,
    lineMrpPaise:   r.quantity * (r.mrp_paise || r.price_paise),
  }));
}

async function applyCouponIfAny(userId, items, subtotal) {
  // Auto-apply VACADO50 if eligible. Keeps cart screen UX as designed.
  const { rows } = await query(
    `SELECT * FROM coupons WHERE code = $1 AND is_active = true LIMIT 1`,
    ['VACADO50']
  );
  const c = rows[0];
  if (!c) return { discount: 0, code: null };
  if (subtotal < c.min_order_paise) return { discount: 0, code: null };
  let discount = 0;
  if (c.discount_type === 'flat')    discount = c.discount_value;
  if (c.discount_type === 'percent') discount = Math.floor((subtotal * c.discount_value) / 100);
  return { discount, code: c.code };
}

function summarise(items, discount = 0) {
  const subtotal = items.reduce((s, i) => s + i.lineTotalPaise, 0);
  const mrpTotal = items.reduce((s, i) => s + i.lineMrpPaise, 0);
  const handling = items.length > 0 ? HANDLING_PAISE : 0;
  const delivery = DELIVERY_FEE_PAISE;
  const total    = Math.max(0, subtotal + handling + delivery - discount);
  return {
    itemCount: items.reduce((s, i) => s + i.quantity, 0),
    subtotalPaise: subtotal,
    mrpTotalPaise: mrpTotal,
    handlingPaise: handling,
    deliveryFeePaise: delivery,
    discountPaise: discount,
    totalPaise: total,
    youSavePaise: Math.max(0, (mrpTotal - subtotal) + discount),
  };
}

async function getCart(req, res) {
  const items = await loadCart(req.user.id);
  const subtotal = items.reduce((s, i) => s + i.lineTotalPaise, 0);
  const { discount, code } = await applyCouponIfAny(req.user.id, items, subtotal);
  res.json({ items, couponCode: code, summary: summarise(items, discount) });
}

const addSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().min(1).max(99).default(1),
});

async function addItem(req, res) {
  const { productId, quantity } = req.body;
  const { rows: pRows } = await query('SELECT id, stock FROM products WHERE id = $1', [productId]);
  if (!pRows[0]) throw ApiError.notFound('product_not_found');
  if (pRows[0].stock < quantity) throw ApiError.conflict('insufficient_stock');

  await query(
    `INSERT INTO cart_items (user_id, product_id, quantity)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, product_id) DO UPDATE
       SET quantity = cart_items.quantity + EXCLUDED.quantity,
           updated_at = now()`,
    [req.user.id, productId, quantity]
  );

  const items = await loadCart(req.user.id);
  const subtotal = items.reduce((s, i) => s + i.lineTotalPaise, 0);
  const { discount, code } = await applyCouponIfAny(req.user.id, items, subtotal);
  res.json({ items, couponCode: code, summary: summarise(items, discount) });
}

const updateSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().min(0).max(99),
});

async function setQuantity(req, res) {
  const { productId, quantity } = req.body;
  if (quantity === 0) {
    await query('DELETE FROM cart_items WHERE user_id = $1 AND product_id = $2', [req.user.id, productId]);
  } else {
    await query(
      `INSERT INTO cart_items (user_id, product_id, quantity)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, product_id) DO UPDATE
         SET quantity = EXCLUDED.quantity, updated_at = now()`,
      [req.user.id, productId, quantity]
    );
  }
  const items = await loadCart(req.user.id);
  const subtotal = items.reduce((s, i) => s + i.lineTotalPaise, 0);
  const { discount, code } = await applyCouponIfAny(req.user.id, items, subtotal);
  res.json({ items, couponCode: code, summary: summarise(items, discount) });
}

async function clearCart(req, res) {
  await query('DELETE FROM cart_items WHERE user_id = $1', [req.user.id]);
  res.json({ items: [], summary: summarise([], 0) });
}

module.exports = {
  schemas: { addSchema, updateSchema },
  getCart,
  addItem,
  setQuantity,
  clearCart,
  loadCart,
  summarise,
  applyCouponIfAny,
};
