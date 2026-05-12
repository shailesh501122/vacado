'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/couponController');

router.get ('/', asyncHandler(ctrl.listCoupons));
router.post('/preview', authRequired, validate(ctrl.schemas.applySchema), asyncHandler(ctrl.previewCoupon));

module.exports = router;
