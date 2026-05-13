-- Product image storage + extended role system + vendor/rider linkage

-- ─── Product image column ──────────────────────────────────
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS vendor_id UUID;

-- ─── Admins / staff with richer roles ──────────────────────
-- role ∈ ('superadmin','admin','vendor','rider')
-- Existing rows already use 'admin' / 'superadmin', so no DDL fixup needed.
CREATE INDEX IF NOT EXISTS admins_role_idx ON admins(role);

-- Rider-specific profile (vehicle, rating, online)
CREATE TABLE IF NOT EXISTS riders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID NOT NULL UNIQUE REFERENCES admins(id) ON DELETE CASCADE,
  display_name    TEXT NOT NULL,
  phone           TEXT,
  vehicle         TEXT,
  rating          NUMERIC(2,1) NOT NULL DEFAULT 4.9,
  delivered_count INT NOT NULL DEFAULT 0,
  is_online       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Vendor-specific profile (store name, location)
CREATE TABLE IF NOT EXISTS vendors (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     UUID NOT NULL UNIQUE REFERENCES admins(id) ON DELETE CASCADE,
  store_name   TEXT NOT NULL,
  store_phone  TEXT,
  store_city   TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Link products to a vendor (after the column existed)
ALTER TABLE products
  ADD CONSTRAINT products_vendor_fk
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE SET NULL
  NOT VALID;

CREATE INDEX IF NOT EXISTS products_vendor_idx ON products(vendor_id);

-- Assign orders to a rider
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS rider_admin_id UUID REFERENCES admins(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS orders_rider_admin_idx ON orders(rider_admin_id);
