'use strict';

const { pool } = require('../src/db/pool');

async function run() {
  try {
    console.log('Adding image_url column to categories...');
    await pool.query(`ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_url TEXT`);
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
