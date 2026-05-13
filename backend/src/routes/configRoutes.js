'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const { getPublicConfig } = require('../services/firebaseService');

// Public mobile-app bootstrap config. No secrets here.
router.get('/public', asyncHandler(async (_req, res) => {
  const firebase = await getPublicConfig();
  res.json({
    firebase,
    features: {
      otpDevBypass: process.env.OTP_DEV_BYPASS === 'true',
    },
  });
}));

module.exports = router;
