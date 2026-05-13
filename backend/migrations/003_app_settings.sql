-- Per-instance settings (SaaS-style). One row per key.
-- Values are JSONB so we can store complex configs (Firebase, Razorpay, etc).
-- Set updated_by_admin_id to remember who changed what.

CREATE TABLE IF NOT EXISTS app_settings (
  key                  TEXT PRIMARY KEY,
  value                JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_secret            BOOLEAN NOT NULL DEFAULT FALSE,
  updated_by_admin_id  UUID REFERENCES admins(id) ON DELETE SET NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed with a disabled Firebase config so the app starts gracefully.
INSERT INTO app_settings (key, value, is_secret) VALUES (
  'auth.firebase',
  '{
    "enabled": false,
    "apiKey": "",
    "appId": "",
    "projectId": "",
    "messagingSenderId": "",
    "iosAppId": "",
    "iosBundleId": "",
    "androidPackageName": "com.vacado.app",
    "serviceAccountJson": null
  }'::jsonb,
  true
) ON CONFLICT (key) DO NOTHING;
