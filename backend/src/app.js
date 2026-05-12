'use strict';

const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const config = require('./config');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);

// Helmet with CSP relaxed so the admin SPA can pull react + tailwind from a CDN.
app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));
app.use(cors({ origin: config.cors.origin, credentials: false }));
app.use(compression());
app.use(express.json({ limit: '256kb' }));
app.use(express.urlencoded({ extended: false }));

if (!config.isProd) app.use(morgan('dev'));

const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(config.apiPrefix, limiter);

app.use(config.apiPrefix, routes);

// Static admin SPA — single-page React app served from /admin
const adminPath = path.resolve(__dirname, '../public/admin');
app.use('/admin', express.static(adminPath, { extensions: ['html'] }));
app.get(/^\/admin(\/.*)?$/, (_req, res) => res.sendFile(path.join(adminPath, 'index.html')));

// Root info
app.get('/', (_req, res) => {
  res.json({
    name: 'Vacado API',
    version: '1.0.0',
    apiPrefix: config.apiPrefix,
    admin: '/admin',
    docs: `${config.apiPrefix}/health`,
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
