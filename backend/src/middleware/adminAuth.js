'use strict';

const jwt = require('jsonwebtoken');
const config = require('../config');
const ApiError = require('../utils/ApiError');

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

module.exports = { signAdmin, adminRequired };
