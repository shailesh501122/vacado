'use strict';

require('dotenv').config();

const env = process.env;

function parseBool(v, fallback = false) {
  if (v == null) return fallback;
  return String(v).toLowerCase() === 'true' || v === '1';
}

const config = {
  env: env.NODE_ENV || 'development',
  port: parseInt(env.PORT || '4000', 10),
  apiPrefix: env.API_PREFIX || '/api/v1',
  database: {
    url: env.DATABASE_URL || 'postgres://vacado:vacado@127.0.0.1:5432/vacado',
    ssl: parseBool(env.PGSSL, false),
  },
  jwt: {
    secret: env.JWT_SECRET || 'dev-only-secret-change-me',
    expiresIn: env.JWT_EXPIRES_IN || '30d',
  },
  otp: {
    ttlSeconds: parseInt(env.OTP_TTL_SECONDS || '300', 10),
    devBypass: parseBool(env.OTP_DEV_BYPASS, true),
  },
  cors: {
    origin: env.CORS_ORIGIN || '*',
  },
  rateLimit: {
    windowMs: parseInt(env.RATE_LIMIT_WINDOW_MS || '60000', 10),
    max: parseInt(env.RATE_LIMIT_MAX || '120', 10),
  },
};

config.isProd = config.env === 'production';

module.exports = config;
