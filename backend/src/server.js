'use strict';

const app = require('./app');
const config = require('./config');
const { pool } = require('./db/pool');

const server = app.listen(config.port, () => {
  console.log(`Vacado API listening on http://localhost:${config.port}${config.apiPrefix}`);
});

function shutdown(signal) {
  console.log(`\n${signal} received — shutting down gracefully`);
  server.close(async () => {
    try { await pool.end(); } catch (_) { /* noop */ }
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGINT',  () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('unhandledRejection', (err) => {
  console.error('Unhandled rejection:', err);
});
