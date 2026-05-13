'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const { adminRequired, requireRole } = require('../middleware/adminAuth');
const ctrl = require('../controllers/vendorController');

router.use(adminRequired, requireRole('vendor'));

router.get('/me',     asyncHandler(ctrl.profile));
router.get('/stats',  asyncHandler(ctrl.stats));
router.get('/orders', asyncHandler(ctrl.listOrders));

module.exports = router;
