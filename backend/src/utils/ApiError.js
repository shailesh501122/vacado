'use strict';

class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }

  static badRequest(message, details)    { return new ApiError(400, 'bad_request', message, details); }
  static unauthorized(message = 'unauthorized') { return new ApiError(401, 'unauthorized', message); }
  static forbidden(message = 'forbidden') { return new ApiError(403, 'forbidden', message); }
  static notFound(message = 'not_found') { return new ApiError(404, 'not_found', message); }
  static conflict(message, details)      { return new ApiError(409, 'conflict', message, details); }
  static internal(message = 'internal_error') { return new ApiError(500, 'internal_error', message); }
}

module.exports = ApiError;
