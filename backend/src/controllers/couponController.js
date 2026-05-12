'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const ApiError = require('../utils/ApiError');

function mapCoupon(c) {
  return {
    id: c.id,
    code: c.code,
    title: c.title,
    subtitle: c.subtitle,
    tone: c.tone,
    discountType: c.discount_type,
    discountValue: c.discount_value,
    minOrderPaise: c.min_order_paise,
    maxDiscountPaise: c.max_discount_paise,
    expiresAt: c.expires_at,
  };
}

async function listCoupons(_req, res) {
  const { rows } = await query(
    `SELECT * FROM coupons WHERE is_active = true ORDER BY created_at DESC`
  );
  res.json({ coupons: rows.map(mapCoupon) });
}

const applySchema = z.object({
  code: z.string().min(2).max(40),
  subtotalPaise: z.number().int().min(0),
});

async function previewCoupon(req, res) {
  const { code, subtotalPaise } = req.body;
  const { rows } = await query(
    `SELECT * FROM coupons WHERE code = $1 AND is_active = true LIMIT 1`,
    [code.toUpperCase()]
  );
  if (!rows[0]) throw ApiError.notFound('coupon_not_found');
  const c = rows[0];
  if (subtotalPaise < c.min_order_paise) {
    throw ApiError.badRequest('min_order_not_met', { minOrderPaise: c.min_order_paise });
  }
  let discount = 0;
  if (c.discount_type === 'flat')    discount = c.discount_value;
  if (c.discount_type === 'percent') discount = Math.floor((subtotalPaise * c.discount_value) / 100);
  if (c.max_discount_paise) discount = Math.min(discount, c.max_discount_paise);

  res.json({ coupon: mapCoupon(c), discountPaise: discount });
}

module.exports = { schemas: { applySchema }, listCoupons, previewCoupon };
