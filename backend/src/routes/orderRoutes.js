'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/orderController');

router.use(authRequired);

router.post('/',         validate(ctrl.schemas.placeOrderSchema), asyncHandler(ctrl.placeOrder));
router.get ('/',         asyncHandler(ctrl.listOrders));
router.get ('/:id',      asyncHandler(ctrl.getOrderById));
router.get ('/:id/track', asyncHandler(ctrl.getTracking));

module.exports = router;
