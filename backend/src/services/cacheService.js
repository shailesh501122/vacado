'use strict';

const Redis = require('ioredis');

let client = null;
let warned = false;

function getClient() {
  if (client) return client;
  const url = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
  client = new Redis(url, {
    lazyConnect: true,
    enableReadyCheck: true,
    maxRetriesPerRequest: 1,
    retryStrategy: (times) => Math.min(times * 200, 2000),
  });
  client.on('error', (err) => {
    if (!warned) {
      console.warn('redis: unavailable —', err.message, '— falling back to no-cache');
      warned = true;
    }
  });
  // Best-effort connect; if it fails the helpers below short-circuit.
  client.connect().catch(() => {});
  return client;
}

async function cacheGet(key) {
  try {
    const c = getClient();
    if (c.status !== 'ready') return null;
    const raw = await c.get(key);
    return raw ? JSON.parse(raw) : null;
  } catch (_) { return null; }
}

async function cacheSet(key, value, ttlSeconds = 30) {
  try {
    const c = getClient();
    if (c.status !== 'ready') return;
    await c.set(key, JSON.stringify(value), 'EX', ttlSeconds);
  } catch (_) { /* noop */ }
}

async function cacheDel(key) {
  try {
    const c = getClient();
    if (c.status !== 'ready') return;
    await c.del(key);
  } catch (_) { /* noop */ }
}

async function cacheDelByPrefix(prefix) {
  try {
    const c = getClient();
    if (c.status !== 'ready') return;
    const keys = await c.keys(`${prefix}*`);
    if (keys.length) await c.del(keys);
  } catch (_) { /* noop */ }
}

/** Memoise an async resolver under a key for up to ttlSeconds. */
async function cached(key, ttlSeconds, resolver) {
  const hit = await cacheGet(key);
  if (hit != null) return hit;
  const fresh = await resolver();
  await cacheSet(key, fresh, ttlSeconds);
  return fresh;
}

module.exports = { cacheGet, cacheSet, cacheDel, cacheDelByPrefix, cached };
