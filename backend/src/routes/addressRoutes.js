'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/addressController');

router.use(authRequired);

router.get   ('/',          asyncHandler(ctrl.listAddresses));
router.post  ('/',          validate(ctrl.schemas.addressSchema), asyncHandler(ctrl.createAddress));
router.put   ('/:id',       validate(ctrl.schemas.addressSchema), asyncHandler(ctrl.updateAddress));
router.post  ('/:id/default', asyncHandler(ctrl.setDefault));
router.delete('/:id',       asyncHandler(ctrl.deleteAddress));

module.exports = router;
