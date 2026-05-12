'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/authController');

router.post('/request-otp', validate(ctrl.schemas.requestOtpSchema), asyncHandler(ctrl.requestOtp));
router.post('/verify-otp',  validate(ctrl.schemas.verifyOtpSchema),  asyncHandler(ctrl.verifyOtpAndLogin));
router.get ('/me',          authRequired, asyncHandler(ctrl.me));

module.exports = router;
