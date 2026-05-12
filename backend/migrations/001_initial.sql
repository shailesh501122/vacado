-- Vacado initial schema

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ─── Users ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone           TEXT UNIQUE NOT NULL,
  name            TEXT,
  email           TEXT,
  avatar_initial  TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS users_phone_idx ON users(phone);

-- ─── OTP verifications ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS otp_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       TEXT NOT NULL,
  code_hash   TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  attempts    INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS otp_phone_idx ON otp_codes(phone, created_at DESC);

-- ─── Addresses ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS addresses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tag          TEXT NOT NULL,
  icon         TEXT NOT NULL DEFAULT 'home',
  line1        TEXT NOT NULL,
  line2        TEXT,
  city         TEXT NOT NULL,
  pincode      TEXT NOT NULL,
  phone        TEXT,
  latitude     DOUBLE PRECISION,
  longitude    DOUBLE PRECISION,
  is_default   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS addresses_user_idx ON addresses(user_id);

-- ─── Categories ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug       TEXT UNIQUE NOT NULL,
  name       TEXT NOT NULL,
  parent_id  UUID REFERENCES categories(id) ON DELETE SET NULL,
  fruit_kind TEXT NOT NULL DEFAULT 'apple',
  position   INT NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS categories_parent_idx ON categories(parent_id);

-- ─── Products ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  description     TEXT,
  category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
  fruit_kind      TEXT NOT NULL DEFAULT 'apple',
  origin          TEXT,
  weight_label    TEXT NOT NULL DEFAULT '500 g',
  price_paise     INT NOT NULL,
  mrp_paise       INT,
  rating          NUMERIC(2,1) NOT NULL DEFAULT 4.5,
  review_count    INT NOT NULL DEFAULT 0,
  eta_minutes     INT NOT NULL DEFAULT 10,
  is_organic      BOOLEAN NOT NULL DEFAULT FALSE,
  is_trending     BOOLEAN NOT NULL DEFAULT FALSE,
  is_bestseller   BOOLEAN NOT NULL DEFAULT FALSE,
  stock           INT NOT NULL DEFAULT 100,
  picked_at       TIMESTAMPTZ,
  nutrition       JSONB NOT NULL DEFAULT '{}'::jsonb,
  pack_options    JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS products_category_idx ON products(category_id);
CREATE INDEX IF NOT EXISTS products_search_idx ON products USING gin (to_tsvector('simple', name || ' ' || COALESCE(description, '')));

-- ─── Cart ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cart_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity    INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);

-- ─── Wishlist ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wishlist_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);

-- ─── Coupons ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS coupons (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL,
  subtitle        TEXT,
  tone            TEXT NOT NULL DEFAULT 'green',
  discount_type   TEXT NOT NULL CHECK (discount_type IN ('flat','percent')),
  discount_value  INT NOT NULL,
  min_order_paise INT NOT NULL DEFAULT 0,
  max_discount_paise INT,
  starts_at       TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Orders ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  address_id          UUID REFERENCES addresses(id) ON DELETE SET NULL,
  order_number        TEXT UNIQUE NOT NULL,
  status              TEXT NOT NULL DEFAULT 'placed',
    -- placed | packed | out_for_delivery | delivered | cancelled
  subtotal_paise      INT NOT NULL DEFAULT 0,
  discount_paise      INT NOT NULL DEFAULT 0,
  delivery_fee_paise  INT NOT NULL DEFAULT 0,
  handling_paise      INT NOT NULL DEFAULT 0,
  total_paise         INT NOT NULL DEFAULT 0,
  coupon_code         TEXT,
  payment_method      TEXT NOT NULL DEFAULT 'upi',
  payment_status      TEXT NOT NULL DEFAULT 'pending',
  delivery_slot       TEXT NOT NULL DEFAULT 'standard',
  delivery_instruction TEXT,
  eta_minutes         INT NOT NULL DEFAULT 12,
  rider_name          TEXT,
  rider_phone         TEXT,
  rider_rating        NUMERIC(2,1),
  rider_vehicle       TEXT,
  placed_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  delivered_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_user_idx ON orders(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS order_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id      UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name    TEXT NOT NULL,
  fruit_kind      TEXT NOT NULL,
  weight_label    TEXT NOT NULL,
  unit_price_paise INT NOT NULL,
  quantity        INT NOT NULL,
  line_total_paise INT NOT NULL
);

CREATE INDEX IF NOT EXISTS order_items_order_idx ON order_items(order_id);

CREATE TABLE IF NOT EXISTS order_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL,
  title       TEXT NOT NULL,
  subtitle    TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS order_events_order_idx ON order_events(order_id, occurred_at);

-- ─── Search history ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS search_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  query       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS search_history_user_idx ON search_history(user_id, created_at DESC);

-- ─── Banners ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS banners (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  subtitle    TEXT,
  tag         TEXT,
  fruit_kind  TEXT NOT NULL DEFAULT 'mango',
  gradient    TEXT,
  cta_label   TEXT,
  cta_target  TEXT,
  position    INT NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
