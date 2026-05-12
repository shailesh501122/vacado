'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/cartController');

router.use(authRequired);

router.get   ('/',     asyncHandler(ctrl.getCart));
router.post  ('/items', validate(ctrl.schemas.addSchema),    asyncHandler(ctrl.addItem));
router.patch ('/items', validate(ctrl.schemas.updateSchema), asyncHandler(ctrl.setQuantity));
router.delete('/',     asyncHandler(ctrl.clearCart));

module.exports = router;
