'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const { mapProduct } = require('./catalogController');

const toggleSchema = z.object({ productId: z.string().uuid() });

async function listWishlist(req, res) {
  const { rows } = await query(
    `SELECT products.*, wishlist_items.created_at AS saved_at
       FROM wishlist_items
       JOIN products ON products.id = wishlist_items.product_id
      WHERE wishlist_items.user_id = $1
      ORDER BY wishlist_items.created_at DESC`,
    [req.user.id]
  );
  const items = rows.map((r) => ({
    product: mapProduct(r),
    savedAt: r.saved_at,
    note: r.is_bestseller ? 'Restocked today' : (r.mrp_paise && r.mrp_paise > r.price_paise ? 'Lower price · save more' : ''),
  }));
  res.json({ items });
}

async function toggleWishlist(req, res) {
  const { productId } = req.body;
  const existing = await query(
    `SELECT id FROM wishlist_items WHERE user_id = $1 AND product_id = $2`,
    [req.user.id, productId]
  );
  if (existing.rows[0]) {
    await query('DELETE FROM wishlist_items WHERE id = $1', [existing.rows[0].id]);
    return res.json({ saved: false });
  }
  await query(
    `INSERT INTO wishlist_items (user_id, product_id) VALUES ($1, $2)`,
    [req.user.id, productId]
  );
  res.json({ saved: true });
}

module.exports = { schemas: { toggleSchema }, listWishlist, toggleWishlist };
