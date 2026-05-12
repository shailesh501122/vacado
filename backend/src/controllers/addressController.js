'use strict';

const { z } = require('zod');
const { query, withTx } = require('../db/pool');
const ApiError = require('../utils/ApiError');

const addressSchema = z.object({
  tag: z.string().min(1).max(40),
  icon: z.enum(['home', 'work', 'heart', 'pin']).default('home'),
  line1: z.string().min(3).max(160),
  line2: z.string().max(160).optional(),
  city: z.string().min(2).max(80),
  pincode: z.string().min(3).max(12),
  phone: z.string().min(8).max(20).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  isDefault: z.boolean().optional(),
});

function mapAddress(a) {
  return {
    id: a.id,
    tag: a.tag,
    icon: a.icon,
    line1: a.line1,
    line2: a.line2,
    city: a.city,
    pincode: a.pincode,
    phone: a.phone,
    latitude: a.latitude,
    longitude: a.longitude,
    isDefault: a.is_default,
  };
}

async function listAddresses(req, res) {
  const { rows } = await query(
    `SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC`,
    [req.user.id]
  );
  res.json({ addresses: rows.map(mapAddress) });
}

async function createAddress(req, res) {
  const a = req.body;
  const result = await withTx(async (client) => {
    if (a.isDefault) {
      await client.query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    }
    const { rows } = await client.query(
      `INSERT INTO addresses (user_id, tag, icon, line1, line2, city, pincode, phone, latitude, longitude, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        req.user.id, a.tag, a.icon, a.line1, a.line2 || null, a.city, a.pincode,
        a.phone || null, a.latitude || null, a.longitude || null, !!a.isDefault,
      ]
    );
    return rows[0];
  });
  res.status(201).json({ address: mapAddress(result) });
}

async function updateAddress(req, res) {
  const { id } = req.params;
  const a = req.body;
  const updated = await withTx(async (client) => {
    if (a.isDefault) {
      await client.query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    }
    const { rows } = await client.query(
      `UPDATE addresses
          SET tag = $1, icon = $2, line1 = $3, line2 = $4, city = $5, pincode = $6,
              phone = $7, latitude = $8, longitude = $9, is_default = $10,
              updated_at = now()
        WHERE id = $11 AND user_id = $12
        RETURNING *`,
      [
        a.tag, a.icon, a.line1, a.line2 || null, a.city, a.pincode,
        a.phone || null, a.latitude || null, a.longitude || null, !!a.isDefault,
        id, req.user.id,
      ]
    );
    return rows[0];
  });
  if (!updated) throw ApiError.notFound('address_not_found');
  res.json({ address: mapAddress(updated) });
}

async function setDefault(req, res) {
  const { id } = req.params;
  await withTx(async (client) => {
    await client.query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    const r = await client.query(
      `UPDATE addresses SET is_default = true, updated_at = now()
        WHERE id = $1 AND user_id = $2 RETURNING id`,
      [id, req.user.id]
    );
    if (!r.rowCount) throw ApiError.notFound('address_not_found');
  });
  res.json({ ok: true });
}

async function deleteAddress(req, res) {
  const { id } = req.params;
  const { rowCount } = await query(
    'DELETE FROM addresses WHERE id = $1 AND user_id = $2',
    [id, req.user.id]
  );
  if (!rowCount) throw ApiError.notFound('address_not_found');
  res.json({ ok: true });
}

module.exports = {
  schemas: { addressSchema },
  listAddresses,
  createAddress,
  updateAddress,
  setDefault,
  deleteAddress,
};
