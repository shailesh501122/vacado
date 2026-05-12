-- Admins (separate principal from end-users so we don't mix auth flows)

CREATE TABLE IF NOT EXISTS admins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name          TEXT NOT NULL,
  email         TEXT,
  role          TEXT NOT NULL DEFAULT 'admin', -- admin | superadmin
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admins_username_idx ON admins(username);
