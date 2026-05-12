'use strict';

const fs = require('fs');
const path = require('path');
const { pool } = require('./pool');

const MIGRATIONS_DIR = path.resolve(__dirname, '../../migrations');

async function ensureMigrationsTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
}

async function run() {
  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const client = await pool.connect();
  try {
    await ensureMigrationsTable(client);
    const { rows } = await client.query('SELECT filename FROM schema_migrations');
    const applied = new Set(rows.map((r) => r.filename));

    for (const file of files) {
      if (applied.has(file)) {
        console.log(`✓ skipping ${file} (already applied)`);
        continue;
      }
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
      console.log(`→ applying ${file}`);
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations(filename) VALUES ($1)', [file]);
        await client.query('COMMIT');
        console.log(`✓ applied ${file}`);
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      }
    }
    console.log('All migrations applied.');
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
