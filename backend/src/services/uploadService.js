'use strict';

const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');

const UPLOAD_ROOT = path.resolve(__dirname, '../../uploads');
const PRODUCT_DIR = path.join(UPLOAD_ROOT, 'products');

for (const d of [UPLOAD_ROOT, PRODUCT_DIR]) {
  fs.mkdirSync(d, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, PRODUCT_DIR),
  filename: (_req, file, cb) => {
    const ext = (path.extname(file.originalname || '') || '.jpg').toLowerCase();
    const id = crypto.randomBytes(12).toString('hex');
    cb(null, `${Date.now()}-${id}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 6 * 1024 * 1024 }, // 6 MB
  fileFilter: (_req, file, cb) => {
    const ok = /^image\/(jpe?g|png|webp|gif)$/i.test(file.mimetype);
    if (!ok) return cb(new Error('only_image_files'));
    cb(null, true);
  },
});

function publicUrlFor(req, filename) {
  // The mobile app receives an absolute URL so it can fetch the image from
  // wherever it's running. We prefer X-Forwarded-* headers so it stays valid
  // behind reverse proxies, falling back to the host header.
  const proto = (req.headers['x-forwarded-proto'] || req.protocol || 'http').toString().split(',')[0].trim();
  const host  = (req.headers['x-forwarded-host'] || req.headers.host || '').toString().split(',')[0].trim();
  return `${proto}://${host}/uploads/products/${filename}`;
}

module.exports = { upload, publicUrlFor, UPLOAD_ROOT, PRODUCT_DIR };
