'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const { adminRequired, requireRole } = require('../middleware/adminAuth');
const ctrl = require('../controllers/riderController');

router.use(adminRequired, requireRole('rider'));

router.get  ('/me',                       asyncHandler(ctrl.profile));
router.get  ('/stats',                    asyncHandler(ctrl.stats));
router.post ('/online',                   asyncHandler(ctrl.setOnline));
router.get  ('/orders',                   asyncHandler(ctrl.listOrders));
router.post ('/orders/:id/claim',         asyncHandler(ctrl.claimOrder));
router.post ('/orders/:id/delivered',     asyncHandler(ctrl.markDelivered));

module.exports = router;
