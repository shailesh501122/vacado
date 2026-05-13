'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { adminRequired } = require('../middleware/adminAuth');
const ctrl = require('../controllers/adminController');

// public (login)
router.post('/login', validate(ctrl.schemas.loginSchema), asyncHandler(ctrl.login));

// authenticated
router.use(adminRequired);

router.get('/me',                     asyncHandler(ctrl.me));
router.get('/stats',                  asyncHandler(ctrl.stats));

router.get   ('/orders',              asyncHandler(ctrl.listOrders));
router.get   ('/orders/:id',          asyncHandler(ctrl.getOrder));
router.patch ('/orders/:id/status',   validate(ctrl.schemas.statusSchema), asyncHandler(ctrl.updateOrderStatus));

router.get   ('/products',            asyncHandler(ctrl.listProducts));
router.post  ('/products',            validate(ctrl.schemas.productUpsertSchema), asyncHandler(ctrl.createProduct));
router.put   ('/products/:id',        validate(ctrl.schemas.productUpsertSchema), asyncHandler(ctrl.updateProduct));
router.delete('/products/:id',        asyncHandler(ctrl.deleteProduct));

router.get   ('/customers',           asyncHandler(ctrl.listCustomers));

router.get   ('/coupons',             asyncHandler(ctrl.listCoupons));
router.post  ('/coupons',             validate(ctrl.schemas.couponUpsertSchema), asyncHandler(ctrl.createCoupon));
router.delete('/coupons/:id',         asyncHandler(ctrl.deleteCoupon));

router.get   ('/categories',          asyncHandler(ctrl.listCategoriesAdmin));

router.get   ('/settings/firebase',   asyncHandler(ctrl.getFirebaseSettings));
router.put   ('/settings/firebase',   validate(ctrl.schemas.firebaseSettingsSchema), asyncHandler(ctrl.updateFirebaseSettings));

module.exports = router;
