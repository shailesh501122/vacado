'use strict';

const jwt = require('jsonwebtoken');
const config = require('../config');
const ApiError = require('../utils/ApiError');

function sign(payload) {
  return jwt.sign(payload, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
}

function verify(token) {
  return jwt.verify(token, config.jwt.secret);
}

function authRequired(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(ApiError.unauthorized('Missing bearer token'));
  try {
    const payload = verify(token);
    req.user = { id: payload.sub, phone: payload.phone };
    return next();
  } catch (err) {
    return next(ApiError.unauthorized('Invalid or expired token'));
  }
}

module.exports = { sign, verify, authRequired };
