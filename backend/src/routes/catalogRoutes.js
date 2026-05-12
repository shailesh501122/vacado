'use strict';

const router = require('express').Router();
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validate');
const ctrl = require('../controllers/catalogController');

router.get('/home',       asyncHandler(ctrl.homeFeed));
router.get('/categories', asyncHandler(ctrl.listCategories));
router.get('/products',   validate(ctrl.schemas.listProductsSchema, 'query'), asyncHandler(ctrl.listProducts));
router.get('/products/:slug', asyncHandler(ctrl.getProduct));
router.get('/search',     validate(ctrl.schemas.searchSchema, 'query'), asyncHandler(ctrl.search));

module.exports = router;
