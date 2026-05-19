'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const config = require('../config');
const { getPublicConfig } = require('../services/firebaseService');

// Public mobile-app bootstrap config. No secrets here.
router.get('/public', asyncHandler(async (_req, res) => {
  const firebase = await getPublicConfig();
  res.json({
    firebase,
    features: {
      otpDevBypass: config.otp.devBypass,
    },
  });
}));

module.exports = router;
