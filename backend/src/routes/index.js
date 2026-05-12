'use strict';

const express = require('express');
const router = express.Router();

const auth = require('./authRoutes');
const catalog = require('./catalogRoutes');
const cart = require('./cartRoutes');
const wishlist = require('./wishlistRoutes');
const orders = require('./orderRoutes');
const addresses = require('./addressRoutes');
const coupons = require('./couponRoutes');
const admin = require('./adminRoutes');

router.get('/health', (_req, res) => res.json({ ok: true, ts: Date.now() }));

router.use('/auth',      auth);
router.use('/catalog',   catalog);
router.use('/cart',      cart);
router.use('/wishlist',  wishlist);
router.use('/orders',    orders);
router.use('/addresses', addresses);
router.use('/coupons',   coupons);
router.use('/admin',     admin);

module.exports = router;
