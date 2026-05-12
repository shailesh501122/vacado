'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const { issueOtp, verifyOtp } = require('../services/otpService');
const { sign } = require('../middleware/auth');
const ApiError = require('../utils/ApiError');

const phoneSchema = z.string().min(8).max(20);

const requestOtpSchema = z.object({
  phone: phoneSchema,
});

const verifyOtpSchema = z.object({
  phone: phoneSchema,
  code: z.string().regex(/^\d{4,8}$/),
  name: z.string().min(1).max(80).optional(),
});

async function requestOtp(req, res) {
  const { phone } = req.body;
  const { expiresInSeconds, devCode } = await issueOtp(phone);
  res.json({
    ok: true,
    message: `OTP sent to ${phone} via WhatsApp & SMS`,
    expiresInSeconds,
    devCode,
  });
}

async function verifyOtpAndLogin(req, res) {
  const { phone, code, name } = req.body;
  const result = await verifyOtp(phone, code);
  if (!result.ok) {
    throw ApiError.unauthorized(`OTP invalid: ${result.reason}`);
  }

  let { rows } = await query('SELECT id, phone, name, email, avatar_initial FROM users WHERE phone = $1', [phone]);
  let user = rows[0];

  if (!user) {
    const initial = (name || 'V').trim().charAt(0).toUpperCase();
    const inserted = await query(
      `INSERT INTO users (phone, name, avatar_initial)
       VALUES ($1, $2, $3)
       RETURNING id, phone, name, email, avatar_initial`,
      [phone, name || null, initial]
    );
    user = inserted.rows[0];
  }

  const token = sign({ sub: user.id, phone: user.phone });
  res.json({ ok: true, token, user });
}

async function me(req, res) {
  const { rows } = await query(
    `SELECT id, phone, name, email, avatar_initial, created_at FROM users WHERE id = $1`,
    [req.user.id]
  );
  if (!rows[0]) throw ApiError.notFound('user_not_found');
  res.json({ user: rows[0] });
}

module.exports = {
  schemas: { requestOtpSchema, verifyOtpSchema },
  requestOtp,
  verifyOtpAndLogin,
  me,
};
