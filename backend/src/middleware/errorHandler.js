'use strict';

const ApiError = require('../utils/ApiError');

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }
  if (err && err.name === 'ZodError') {
    return res.status(400).json({
      error: { code: 'validation_error', message: 'Invalid request', details: err.issues },
    });
  }
  console.error('Unhandled error:', err);
  return res.status(500).json({
    error: { code: 'internal_error', message: 'Something went wrong' },
  });
}

function notFoundHandler(req, res) {
  res.status(404).json({ error: { code: 'not_found', message: `No route for ${req.method} ${req.path}` } });
}

module.exports = { errorHandler, notFoundHandler };
