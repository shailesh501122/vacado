'use strict';

const { pool } = require('../src/db/pool');

async function run() {
  try {
    console.log('Updating categories table schema...');
    await pool.query(`ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_url TEXT`);
    await pool.query(`ALTER TABLE categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`);
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
