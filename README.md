# Vacado — Quick-commerce Fruit Delivery

Production-ready implementation of the Vacado design bundle.

- **Backend** — Node.js (Express) + PostgreSQL
- **Mobile** — Flutter (Android & iOS), all 15 screens from the design

```
.
├── backend/             # Node.js + Express + PostgreSQL API
├── mobile/              # Flutter app (Android + iOS, 15 screens)
└── docker-compose.yml   # Spins up Postgres + API in one go
```

---

## 1. Backend

### Stack

| Layer        | Choice                                  |
| ------------ | --------------------------------------- |
| Runtime      | Node.js 18+                             |
| Framework    | Express 4                               |
| DB           | PostgreSQL 16 with `pg` (no ORM)        |
| Validation   | Zod                                     |
| Auth         | Phone OTP → JWT (`Bearer`)              |
| Security     | Helmet, CORS, rate-limit, bcryptjs      |
| Money        | All amounts stored & exchanged in paise |

### Endpoints (`/api/v1`)

| Method  | Path                              | Auth | Purpose                                   |
| ------- | --------------------------------- | ---- | ----------------------------------------- |
| GET     | `/health`                         | —    | health-check                              |
| POST    | `/auth/request-otp`               | —    | issue OTP for a phone number              |
| POST    | `/auth/verify-otp`                | —    | verify OTP and exchange for a JWT         |
| GET     | `/auth/me`                        | ✓    | current user                              |
| GET     | `/catalog/home`                   | —    | banners + bestsellers + trending + AI pick|
| GET     | `/catalog/categories`             | —    | category list                             |
| GET     | `/catalog/products`               | —    | listing (filter, sort, paginate)          |
| GET     | `/catalog/products/:slug`         | —    | product details                           |
| GET     | `/catalog/search?q=`              | —    | search                                    |
| GET/POST/PATCH/DELETE | `/cart`             | ✓    | cart CRUD                                 |
| GET/POST/PUT/DELETE   | `/addresses`        | ✓    | address CRUD                              |
| POST    | `/addresses/:id/default`          | ✓    | set default address                       |
| GET/POST              | `/orders`           | ✓    | place / list                              |
| GET     | `/orders/:id`                     | ✓    | order details                             |
| GET     | `/orders/:id/track`               | ✓    | live tracking payload                     |
| GET     | `/wishlist`                       | ✓    | wishlist                                  |
| POST    | `/wishlist/toggle`                | ✓    | save / unsave                             |
| GET     | `/coupons`                        | —    | coupons                                   |
| POST    | `/coupons/preview`                | ✓    | preview coupon discount                   |

### Run locally

```bash
cd backend
cp .env.example .env
npm install
# start a postgres yourself, or use the root docker-compose: docker compose up -d db
npm run migrate
npm run seed
npm run dev          # http://localhost:4000/api/v1/health
```

### Dev OTP bypass

In dev (`OTP_DEV_BYPASS=true`) any request to `/auth/request-otp` returns
`devCode: "482910"`. Sending that code to `/auth/verify-otp` always succeeds, so
the mobile app can run end-to-end without an SMS provider.

Set `OTP_DEV_BYPASS=false` and wire your own SMS / WhatsApp provider in
`src/services/otpService.js` before going to production.

### Run with Docker

```bash
docker compose up --build
# API:   http://localhost:4000
# DB:    localhost:5432  (vacado / vacado)
```

The API container runs `migrate` and `seed` on boot.

### Schema

The schema lives in `backend/migrations/001_initial.sql`. Key tables: `users`,
`addresses`, `categories`, `products`, `cart_items`, `wishlist_items`, `coupons`,
`orders`, `order_items`, `order_events`, `banners`.

---

## 2. Flutter mobile app

All 15 screens from the design bundle are implemented as native Flutter routes
backed by the API. Screens live under `mobile/lib/screens/`:

| #  | Screen             | File                                                                  |
| -- | ------------------ | --------------------------------------------------------------------- |
| 01 | Splash             | `onboarding/splash_screen.dart`                                       |
| 02 | Onboarding         | `onboarding/onboarding_screen.dart`                                   |
| 03 | Login / OTP        | `onboarding/login_screen.dart`                                        |
| 04 | Home               | `browse/home_screen.dart`                                             |
| 05 | Search             | `browse/search_screen.dart`                                           |
| 06 | Categories         | `browse/categories_screen.dart`                                       |
| 07 | Listing            | `browse/listing_screen.dart`                                          |
| 08 | Offers & coupons   | `browse/offers_screen.dart`                                           |
| 09 | Product details    | `product/product_details_screen.dart`                                 |
| 10 | Wishlist           | `product/wishlist_screen.dart`                                        |
| 11 | Cart               | `commerce/cart_screen.dart`                                           |
| 12 | Checkout           | `commerce/checkout_screen.dart`                                       |
| 13 | Order tracking     | `commerce/tracking_screen.dart`                                       |
| 14 | Profile            | `account/profile_screen.dart`                                         |
| 15 | Delivery addresses | `account/address_screen.dart`                                         |

### Architecture

- `data/api_client.dart` — http client with JWT, error envelope, timeouts
- `data/repositories.dart` — one repository per resource
- `providers/` — `ChangeNotifier` providers (auth, catalog, cart, address)
- `widgets/` — shared primitives (`FruitTile`, `ProductCard`, `VBottomNav`, …)
- `theme/` — colour, type, and shadow tokens from the design (`tokens.css`)
- `screens/main_shell.dart` — bottom-nav scaffold

State management is `provider` because the screen graph is shallow and the
app uses optimistic cart updates. The persisted JWT lives in
`shared_preferences`.

### Run

```bash
cd mobile
flutter pub get

# Android emulator (uses 10.0.2.2 to reach host):
flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1

# iOS simulator (uses localhost):
flutter run --dart-define=API_BASE=http://localhost:4000/api/v1

# Physical device on the same wifi:
flutter run --dart-define=API_BASE=http://<host-ip>:4000/api/v1
```

### Production builds

```bash
# Android release
flutter build apk --release --dart-define=API_BASE=https://api.example.com/api/v1
flutter build appbundle --release --dart-define=API_BASE=https://api.example.com/api/v1

# iOS release
flutter build ipa --release --dart-define=API_BASE=https://api.example.com/api/v1
```

For production, also set `--dart-define=DEV_SHOW_OTP=false` so the dev bypass
code isn't shown in the OTP screen.

---

## 3. End-to-end demo

1. `docker compose up --build` — brings up Postgres + API on `:4000`, runs
   migrations and seeds 20 products + 5 coupons + 2 banners.
2. `cd mobile && flutter pub get && flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1`
3. Sign up with any phone number — the dev OTP `482910` is shown in the
   login screen.
4. Browse → add to cart → add an address → checkout → land on live tracking.

---

## 4. Design source

The design bundle from Claude Design lives nowhere in the repo by design — the
visual tokens were translated into `mobile/lib/theme/tokens.dart` and the
widget primitives were rebuilt natively, not lifted verbatim from the HTML
prototype.

## 5. Admin panel

The API also ships a single-page admin console at **`/admin`** — log in with
the seeded credentials (`Admin` / `Admin@123`) and you get a dashboard with
revenue, today's orders, status breakdown, and top products, plus full CRUD
for products and coupons, an orders board with status transitions, a
customer list, and a **Firebase phone-auth configuration** page.

The console is a self-contained React SPA (no build step — React 18 UMD +
Tailwind CDN + Babel-Standalone) served from `backend/public/admin/`. It
talks to a separate `/api/v1/admin/*` namespace gated by the
`adminRequired` middleware (bcrypt-hashed password → admin-scoped JWT).

Seed or rotate the admin password:

```bash
ADMIN_USERNAME=Admin ADMIN_PASSWORD='Admin@123' npm run seed:admin
```

## 6. Phone auth (Firebase) — SaaS config

The mobile app uses **Firebase Phone Auth** for OTP. Each Vacado instance
configures its own Firebase project from the admin panel — the public keys
ship to the app at runtime via `GET /api/v1/config/public`, and the
service-account JSON stays server-side and is used by the backend to verify
the Firebase ID token the app exchanges at `POST /api/v1/auth/firebase`.

### One-time setup

1. In the [Firebase console](https://console.firebase.google.com), create a
   project, then under **Authentication → Sign-in method**, enable **Phone**.
2. **Project settings → General → Your apps**: add an **Android** app with
   package `com.vacado.app` (or whichever package you ship with) and your
   debug + release SHA-1/SHA-256 fingerprints. Add an iOS app with your
   bundle ID. Copy the **web** API key, App ID, Project ID, and Messaging
   sender ID — you will paste these into the admin panel.
3. **Project settings → Service accounts → Generate new private key** — save
   the JSON.
4. Open `http://<your-host>/admin` → **Firebase** tab → paste the public keys,
   paste the service-account JSON, flip **Enabled** on, **Save**.
5. The mobile app picks up the new config on its next launch (or on hot-restart
   in dev). Firebase Phone Auth requires app verification — on Android the
   SDK uses Play Integrity / SMS auto-retrieval, on iOS it uses a silent push.
6. To rotate the operator: paste a fresh service-account JSON and save — the
   backend re-initialises the Firebase Admin SDK on the next call.

### Endpoints introduced

| Method | Path                                   | Auth   | Purpose                                          |
| ------ | -------------------------------------- | ------ | ------------------------------------------------ |
| GET    | `/api/v1/config/public`                | —      | Firebase web keys + feature flags for mobile app |
| GET    | `/api/v1/admin/settings/firebase`      | admin  | Read current config (service account redacted)   |
| PUT    | `/api/v1/admin/settings/firebase`      | admin  | Upsert config + service account JSON             |
| POST   | `/api/v1/auth/firebase`                | —      | Trade a Firebase ID token for our JWT            |

## 7. What's next

- Plug in a real payment gateway for the `payment_method` flow.
- Replace the faux delivery map with Mapbox / Google Maps + a websocket
  channel for live rider position.
- Encrypt the Firebase service-account JSON at rest (e.g. AWS KMS / OCI Vault
  envelope encryption) — today it's plain JSONB in `app_settings`.
