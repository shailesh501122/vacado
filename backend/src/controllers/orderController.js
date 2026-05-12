'use strict';

const { z } = require('zod');
const { query, withTx } = require('../db/pool');
const ApiError = require('../utils/ApiError');
const { applyCouponIfAny, summarise } = require('./cartController');

function orderNumber() {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `VC-${ts}-${rand}`;
}

const placeOrderSchema = z.object({
  addressId: z.string().uuid(),
  paymentMethod: z.enum(['upi', 'card', 'cod']).default('upi'),
  deliverySlot: z.enum(['standard', 'evening', 'tomorrow']).default('standard'),
  deliveryInstruction: z.string().max(160).optional(),
  couponCode: z.string().max(40).optional(),
});

const RIDERS = [
  { name: 'Rahul',   phone: '+91 99888 77665', rating: 4.9, vehicle: 'MH 12 RP' },
  { name: 'Aman',    phone: '+91 90909 12121', rating: 4.8, vehicle: 'KA 03 ZJ' },
  { name: 'Sneha',   phone: '+91 98765 54321', rating: 4.95, vehicle: 'KA 05 AB' },
];

function pickRider() {
  return RIDERS[Math.floor(Math.random() * RIDERS.length)];
}

function mapOrder(o, items = [], events = []) {
  return {
    id: o.id,
    orderNumber: o.order_number,
    status: o.status,
    addressId: o.address_id,
    paymentMethod: o.payment_method,
    paymentStatus: o.payment_status,
    deliverySlot: o.delivery_slot,
    deliveryInstruction: o.delivery_instruction,
    etaMinutes: o.eta_minutes,
    placedAt: o.placed_at,
    deliveredAt: o.delivered_at,
    subtotalPaise: o.subtotal_paise,
    discountPaise: o.discount_paise,
    deliveryFeePaise: o.delivery_fee_paise,
    handlingPaise: o.handling_paise,
    totalPaise: o.total_paise,
    couponCode: o.coupon_code,
    rider: o.rider_name ? {
      name: o.rider_name, phone: o.rider_phone, rating: o.rider_rating, vehicle: o.rider_vehicle,
    } : null,
    items: items.map((i) => ({
      productId: i.product_id,
      name: i.product_name,
      fruitKind: i.fruit_kind,
      weightLabel: i.weight_label,
      unitPricePaise: i.unit_price_paise,
      quantity: i.quantity,
      lineTotalPaise: i.line_total_paise,
    })),
    events: events.map((e) => ({
      id: e.id, kind: e.kind, title: e.title, subtitle: e.subtitle, occurredAt: e.occurred_at,
    })),
  };
}

async function placeOrder(req, res) {
  const { addressId, paymentMethod, deliverySlot, deliveryInstruction, couponCode } = req.body;

  const order = await withTx(async (client) => {
    // Validate address belongs to user
    const addr = await client.query(
      `SELECT id FROM addresses WHERE id = $1 AND user_id = $2`,
      [addressId, req.user.id]
    );
    if (!addr.rows[0]) throw ApiError.notFound('address_not_found');

    // Load cart
    const cart = await client.query(
      `SELECT cart_items.quantity, products.id AS product_id, products.name, products.fruit_kind,
              products.weight_label, products.price_paise, products.mrp_paise, products.stock
         FROM cart_items
         JOIN products ON products.id = cart_items.product_id
        WHERE cart_items.user_id = $1`,
      [req.user.id]
    );
    if (cart.rows.length === 0) throw ApiError.badRequest('cart_empty');

    // Build totals
    const items = cart.rows.map((r) => ({
      productId: r.product_id,
      name: r.name,
      fruitKind: r.fruit_kind,
      weightLabel: r.weight_label,
      quantity: r.quantity,
      unitPricePaise: r.price_paise,
      lineTotalPaise: r.quantity * r.price_paise,
      lineMrpPaise: r.quantity * (r.mrp_paise || r.price_paise),
    }));

    const subtotal = items.reduce((s, i) => s + i.lineTotalPaise, 0);

    // Resolve coupon
    let discount = 0;
    let appliedCode = null;
    if (couponCode) {
      const r = await client.query(
        `SELECT * FROM coupons WHERE code = $1 AND is_active = true LIMIT 1`,
        [couponCode.toUpperCase()]
      );
      if (r.rows[0]) {
        const c = r.rows[0];
        if (subtotal >= c.min_order_paise) {
          appliedCode = c.code;
          if (c.discount_type === 'flat')    discount = c.discount_value;
          if (c.discount_type === 'percent') discount = Math.floor((subtotal * c.discount_value) / 100);
          if (c.max_discount_paise) discount = Math.min(discount, c.max_discount_paise);
        }
      }
    } else {
      const auto = await applyCouponIfAny(req.user.id, items, subtotal);
      discount = auto.discount;
      appliedCode = auto.code;
    }

    const summary = summarise(items.map((i) => ({ quantity: i.quantity, lineTotalPaise: i.lineTotalPaise, lineMrpPaise: i.lineMrpPaise })), discount);

    const rider = pickRider();
    const num = orderNumber();
    const eta = 12;

    const insertOrder = await client.query(
      `INSERT INTO orders (
         user_id, address_id, order_number, status,
         subtotal_paise, discount_paise, delivery_fee_paise, handling_paise, total_paise,
         coupon_code, payment_method, payment_status, delivery_slot, delivery_instruction,
         eta_minutes, rider_name, rider_phone, rider_rating, rider_vehicle
       ) VALUES (
         $1,$2,$3,'placed',
         $4,$5,$6,$7,$8,
         $9,$10,$11,$12,$13,
         $14,$15,$16,$17,$18
       ) RETURNING *`,
      [
        req.user.id, addressId, num,
        summary.subtotalPaise, summary.discountPaise, summary.deliveryFeePaise, summary.handlingPaise, summary.totalPaise,
        appliedCode, paymentMethod, paymentMethod === 'cod' ? 'pending' : 'paid', deliverySlot, deliveryInstruction || null,
        eta, rider.name, rider.phone, rider.rating, rider.vehicle,
      ]
    );
    const created = insertOrder.rows[0];

    // Items
    for (const i of items) {
      await client.query(
        `INSERT INTO order_items
           (order_id, product_id, product_name, fruit_kind, weight_label, unit_price_paise, quantity, line_total_paise)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [created.id, i.productId, i.name, i.fruitKind, i.weightLabel, i.unitPricePaise, i.quantity, i.lineTotalPaise]
      );
      await client.query('UPDATE products SET stock = GREATEST(stock - $1, 0) WHERE id = $2', [i.quantity, i.productId]);
    }

    // Lifecycle events
    const events = [
      { kind: 'placed',  title: 'Order confirmed',     sub: `paid via ${paymentMethod.toUpperCase()}` },
      { kind: 'packed',  title: 'Packed at warehouse', sub: `${items.length} items + ice pack` },
      { kind: 'ofd',     title: 'Out for delivery',    sub: `rider ${rider.name} · ${rider.vehicle}` },
    ];
    for (const e of events) {
      await client.query(
        `INSERT INTO order_events (order_id, kind, title, subtitle) VALUES ($1,$2,$3,$4)`,
        [created.id, e.kind, e.title, e.sub]
      );
    }

    // Clear cart
    await client.query('DELETE FROM cart_items WHERE user_id = $1', [req.user.id]);

    return created.id;
  });

  return getOrderById(req, res, order);
}

async function getOrderById(req, res, id) {
  const orderId = id || req.params.id;
  const orderRes = await query(
    `SELECT * FROM orders WHERE id = $1 AND user_id = $2`,
    [orderId, req.user.id]
  );
  if (!orderRes.rows[0]) throw ApiError.notFound('order_not_found');
  const items = await query(`SELECT * FROM order_items WHERE order_id = $1`, [orderId]);
  const events = await query(`SELECT * FROM order_events WHERE order_id = $1 ORDER BY occurred_at ASC`, [orderId]);
  res.json({ order: mapOrder(orderRes.rows[0], items.rows, events.rows) });
}

async function listOrders(req, res) {
  const { rows } = await query(
    `SELECT * FROM orders WHERE user_id = $1 ORDER BY placed_at DESC LIMIT 50`,
    [req.user.id]
  );
  // Light list (no items)
  const orders = await Promise.all(rows.map(async (o) => {
    const items = await query(
      `SELECT fruit_kind FROM order_items WHERE order_id = $1 ORDER BY id ASC LIMIT 6`,
      [o.id]
    );
    return {
      ...mapOrder(o),
      thumbs: items.rows.map((i) => i.fruit_kind),
    };
  }));
  res.json({ orders });
}

async function getTracking(req, res) {
  const orderRes = await query(
    `SELECT * FROM orders WHERE id = $1 AND user_id = $2`,
    [req.params.id, req.user.id]
  );
  if (!orderRes.rows[0]) throw ApiError.notFound('order_not_found');
  const o = orderRes.rows[0];

  const events = await query(`SELECT * FROM order_events WHERE order_id = $1 ORDER BY occurred_at ASC`, [o.id]);

  const elapsedSec = Math.floor((Date.now() - new Date(o.placed_at).getTime()) / 1000);
  const remaining = Math.max(0, o.eta_minutes * 60 - elapsedSec);

  res.json({
    orderNumber: o.order_number,
    status: o.status,
    etaSecondsRemaining: remaining,
    rider: o.rider_name ? { name: o.rider_name, phone: o.rider_phone, rating: o.rider_rating, vehicle: o.rider_vehicle } : null,
    events: events.rows.map((e) => ({
      kind: e.kind, title: e.title, subtitle: e.subtitle, occurredAt: e.occurred_at,
    })),
  });
}

module.exports = {
  schemas: { placeOrderSchema },
  placeOrder,
  listOrders,
  getOrderById,
  getTracking,
};
