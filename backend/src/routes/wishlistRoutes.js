'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const { authRequired } = require('../middleware/auth');
const ctrl = require('../controllers/wishlistController');

router.use(authRequired);

router.get ('/',       asyncHandler(ctrl.listWishlist));
router.post('/toggle', validate(ctrl.schemas.toggleSchema), asyncHandler(ctrl.toggleWishlist));

module.exports = router;
