'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const { cached, cacheDelByPrefix } = require('../services/cacheService');
const ApiError = require('../utils/ApiError');

function mapProduct(row) {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    description: row.description,
    categoryId: row.category_id,
    fruitKind: row.fruit_kind,
    origin: row.origin,
    weightLabel: row.weight_label,
    pricePaise: row.price_paise,
    mrpPaise: row.mrp_paise,
    discountPercent: row.mrp_paise && row.mrp_paise > row.price_paise
      ? Math.round((1 - row.price_paise / row.mrp_paise) * 100)
      : 0,
    rating: Number(row.rating),
    reviewCount: row.review_count,
    etaMinutes: row.eta_minutes,
    isOrganic: row.is_organic,
    isTrending: row.is_trending,
    isBestseller: row.is_bestseller,
    stock: row.stock,
    pickedAt: row.picked_at,
    nutrition: row.nutrition,
    packOptions: row.pack_options,
    imageUrl: row.image_url || null,
  };
}

async function listCategories(_req, res) {
  const { rows } = await query(
    `SELECT id, slug, name, fruit_kind, position
       FROM categories
      WHERE is_active = true
      ORDER BY position ASC`
  );
  res.json({
    categories: rows.map((r) => ({ id: r.id, slug: r.slug, name: r.name, fruitKind: r.fruit_kind, position: r.position })),
  });
}

const listProductsSchema = z.object({
  category: z.string().optional(),
  q: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(40),
  offset: z.coerce.number().int().min(0).default(0),
  sort: z.enum(['popular', 'price_asc', 'price_desc', 'rating']).default('popular'),
});

async function listProducts(req, res) {
  const { category, q, limit, offset, sort } = req.query;

  const where = ['products.stock > 0'];
  const params = [];
  if (category) {
    params.push(category);
    where.push(`categories.slug = $${params.length}`);
  }
  if (q && q.trim()) {
    params.push(`%${q.trim()}%`);
    where.push(`(products.name ILIKE $${params.length} OR products.description ILIKE $${params.length})`);
  }

  let order = 'products.review_count DESC, products.rating DESC';
  if (sort === 'price_asc')  order = 'products.price_paise ASC';
  if (sort === 'price_desc') order = 'products.price_paise DESC';
  if (sort === 'rating')     order = 'products.rating DESC, products.review_count DESC';

  params.push(limit, offset);

  const sql = `
    SELECT products.*
      FROM products
      LEFT JOIN categories ON categories.id = products.category_id
     ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
     ORDER BY ${order}
     LIMIT $${params.length - 1} OFFSET $${params.length}
  `;

  const { rows } = await query(sql, params);
  res.json({ products: rows.map(mapProduct) });
}

async function getProduct(req, res) {
  const { slug } = req.params;
  const { rows } = await query(`SELECT * FROM products WHERE slug = $1 LIMIT 1`, [slug]);
  if (!rows[0]) throw ApiError.notFound('product_not_found');
  res.json({ product: mapProduct(rows[0]) });
}

async function homeFeed(_req, res) {
  // Cache the heavy join+random pass for 30s. Cache key is global because
  // the public home feed is identical for every anonymous client.
  const payload = await cached('home:feed:v2', 30, async () => {
    const banners = await query(
      `SELECT id, title, subtitle, tag, fruit_kind, gradient, cta_label, cta_target
         FROM banners WHERE is_active = true ORDER BY position ASC`
    );
    const bestsellers = await query(
      `SELECT * FROM products WHERE is_bestseller = true ORDER BY review_count DESC LIMIT 8`
    );
    const trending = await query(
      `SELECT * FROM products WHERE is_trending = true ORDER BY rating DESC LIMIT 8`
    );
    const recommended = await query(
      `SELECT * FROM products ORDER BY random() LIMIT 8`
    );
    return {
      banners: banners.rows.map((b) => ({
        id: b.id, title: b.title, subtitle: b.subtitle, tag: b.tag,
        fruitKind: b.fruit_kind, gradient: b.gradient, ctaLabel: b.cta_label, ctaTarget: b.cta_target,
      })),
      bestsellers: bestsellers.rows.map(mapProduct),
      trending: trending.rows.map(mapProduct),
      recommended: recommended.rows.map(mapProduct),
    };
  });

  res.json({
    banners: payload.banners,
    bestsellers: payload.bestsellers,
    trending: payload.trending,
    recommended: payload.recommended,
    aiPick: {
      title: 'Boost your morning iron',
      subtitle: 'Based on your last 12 orders + iron-rich profile',
      items: ['pomegranate', 'spinach', 'strawberry', 'almond'],
      extraCount: 6,
    },
  });
}

/** Called from admin product mutations to bust the home-feed cache. */
function invalidateCatalogCache() {
  cacheDelByPrefix('home:feed');
}

module.exports.invalidateCatalogCache = invalidateCatalogCache;

const searchSchema = z.object({ q: z.string().min(1).max(80) });

async function search(req, res) {
  const { q } = req.query;
  const { rows } = await query(
    `SELECT * FROM products
      WHERE name ILIKE $1 OR description ILIKE $1
      ORDER BY review_count DESC LIMIT 20`,
    [`%${q}%`]
  );
  const trending = ['Watermelon', 'Dragon fruit', 'Sweet lime', 'Organic apples', 'Cherries, US', 'Coconut water', 'Berries box'];
  res.json({
    products: rows.map(mapProduct),
    trending,
  });
}

module.exports = {
  schemas: { listProductsSchema, searchSchema },
  listCategories,
  listProducts,
  getProduct,
  homeFeed,
  search,
  mapProduct,
};
