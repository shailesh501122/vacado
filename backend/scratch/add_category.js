'use strict';

const { pool } = require('../src/db/pool');

async function run() {
  try {
    console.log('Inserting NABAGENET category...');
    await pool.query(
      `INSERT INTO categories (slug, name, fruit_kind, position, is_active)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, fruit_kind = EXCLUDED.fruit_kind, position = EXCLUDED.position`,
      ['nabagenet', 'Nabagenet', 'mango', 9, true]
    );
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
