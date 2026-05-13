'use strict';

const { query } = require('../db/pool');

const cache = new Map();
const TTL_MS = 30_000;

async function getSetting(key) {
  const cached = cache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.value;

  const { rows } = await query('SELECT value FROM app_settings WHERE key = $1 LIMIT 1', [key]);
  const value = rows[0]?.value ?? null;
  cache.set(key, { value, expiresAt: Date.now() + TTL_MS });
  return value;
}

async function setSetting(key, value, adminId, isSecret = false) {
  await query(
    `INSERT INTO app_settings (key, value, is_secret, updated_by_admin_id)
     VALUES ($1, $2::jsonb, $3, $4)
     ON CONFLICT (key) DO UPDATE
       SET value = EXCLUDED.value,
           is_secret = EXCLUDED.is_secret,
           updated_by_admin_id = EXCLUDED.updated_by_admin_id,
           updated_at = now()`,
    [key, JSON.stringify(value), isSecret, adminId || null]
  );
  cache.delete(key);
}

function invalidate(key) { cache.delete(key); }

module.exports = { getSetting, setSetting, invalidate };
