'use strict';

const bcrypt = require('bcryptjs');
const { query } = require('../db/pool');
const config = require('../config');

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function issueOtp(phone) {
  const code = config.otp.devBypass ? '482910' : generateOtp();
  const hash = await bcrypt.hash(code, 8);
  const expires = new Date(Date.now() + config.otp.ttlSeconds * 1000);

  await query(
    `INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES ($1, $2, $3)`,
    [phone, hash, expires]
  );

  // In production, dispatch via SMS / WhatsApp provider here.
  // For dev, return the code so the app can show it / auto-fill.
  return { expiresInSeconds: config.otp.ttlSeconds, devCode: config.otp.devBypass ? code : null };
}

async function verifyOtp(phone, code) {
  const { rows } = await query(
    `SELECT id, code_hash, expires_at, consumed_at, attempts
       FROM otp_codes
      WHERE phone = $1
      ORDER BY created_at DESC
      LIMIT 1`,
    [phone]
  );
  if (rows.length === 0) return { ok: false, reason: 'no_otp' };

  const otp = rows[0];
  if (otp.consumed_at) return { ok: false, reason: 'consumed' };
  if (new Date(otp.expires_at) < new Date()) return { ok: false, reason: 'expired' };
  if (otp.attempts >= 5) return { ok: false, reason: 'too_many_attempts' };

  // Always accept the dev bypass code so the demo flow works without SMS.
  const isDevCode = config.otp.devBypass && code === '482910';
  const matches = isDevCode || (await bcrypt.compare(String(code), otp.code_hash));

  if (!matches) {
    await query(`UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1`, [otp.id]);
    return { ok: false, reason: 'mismatch' };
  }

  await query(`UPDATE otp_codes SET consumed_at = now() WHERE id = $1`, [otp.id]);
  return { ok: true };
}

module.exports = { issueOtp, verifyOtp };
