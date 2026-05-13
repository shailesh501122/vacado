'use strict';

const { z } = require('zod');
const { query } = require('../db/pool');
const { issueOtp, verifyOtp } = require('../services/otpService');
const { verifyIdToken } = require('../services/firebaseService');
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

// ─── Firebase Phone Auth exchange ─────────────────────────────
// Mobile app does the phone+OTP flow with Firebase directly (so SMS billing
// stays on the operator's Firebase project), then sends us the Firebase ID
// token. We verify it server-side and mint our own JWT.
const firebaseLoginSchema = z.object({
  idToken: z.string().min(20),
  name: z.string().min(1).max(80).optional(),
});

async function firebaseLogin(req, res) {
  const { idToken, name } = req.body;

  let decoded;
  try {
    decoded = await verifyIdToken(idToken);
  } catch (err) {
    if (err.code === 'firebase_not_configured') {
      throw ApiError.badRequest('firebase_not_configured', { message: 'Admin has not configured Firebase yet' });
    }
    throw ApiError.unauthorized('Firebase token rejected');
  }

  const phone = decoded.phone_number;
  if (!phone) throw ApiError.unauthorized('No phone number on Firebase token');

  let { rows } = await query(
    `SELECT id, phone, name, email, avatar_initial FROM users WHERE phone = $1`,
    [phone]
  );
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
  } else if (name && !user.name) {
    await query('UPDATE users SET name = $1 WHERE id = $2', [name, user.id]);
    user.name = name;
  }

  const token = sign({ sub: user.id, phone: user.phone });
  res.json({ ok: true, token, user });
}

module.exports = {
  schemas: { requestOtpSchema, verifyOtpSchema, firebaseLoginSchema },
  requestOtp,
  verifyOtpAndLogin,
  firebaseLogin,
  me,
};
