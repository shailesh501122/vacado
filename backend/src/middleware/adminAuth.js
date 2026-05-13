'use strict';

const jwt = require('jsonwebtoken');
const config = require('../config');
const ApiError = require('../utils/ApiError');

const ROLES = ['superadmin', 'admin', 'vendor', 'rider'];

function signAdmin(payload) {
  return jwt.sign({ ...payload, kind: 'admin' }, config.jwt.secret, { expiresIn: '12h' });
}

function adminRequired(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(ApiError.unauthorized('Missing bearer token'));
  try {
    const payload = jwt.verify(token, config.jwt.secret);
    if (payload.kind !== 'admin') return next(ApiError.forbidden('Admin token required'));
    req.admin = { id: payload.sub, username: payload.username, role: payload.role };
    return next();
  } catch (err) {
    return next(ApiError.unauthorized('Invalid or expired admin token'));
  }
}

/** Only allow the listed roles past this middleware. */
function requireRole(...allowed) {
  const allow = new Set(allowed);
  return (req, _res, next) => {
    if (!req.admin) return next(ApiError.unauthorized('not authenticated'));
    // superadmin implicitly passes every gate.
    if (req.admin.role === 'superadmin' || allow.has(req.admin.role)) return next();
    return next(ApiError.forbidden(`role_required: ${[...allow].join('|')}`));
  };
}

module.exports = { ROLES, signAdmin, adminRequired, requireRole };
