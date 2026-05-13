'use strict';

const { pool, withTx } = require('./pool');

const CATEGORIES = [
  { slug: 'fruits',      name: 'Fruits',      kind: 'apple',       position: 1 },
  { slug: 'vegetables',  name: 'Vegetables',  kind: 'tomato',      position: 2 },
  { slug: 'exotic',      name: 'Exotic',      kind: 'dragonfruit', position: 3 },
  { slug: 'juices',      name: 'Juices',      kind: 'juice',       position: 4 },
  { slug: 'dry-fruits',  name: 'Dry Fruits',  kind: 'almond',      position: 5 },
  { slug: 'organic',     name: 'Organic',     kind: 'spinach',     position: 6 },
  { slug: 'fresh-cuts',  name: 'Fresh Cuts',  kind: 'watermelon',  position: 7 },
  { slug: 'combos',      name: 'Combos',      kind: 'mango',       position: 8 },
  { slug: 'nabagenet',   name: 'Nabagenet',   kind: 'mango',       position: 9 },
];

const PRODUCTS = [
  { slug: 'alphonso-mango-1kg', name: 'Alphonso Mango, Ratnagiri', cat: 'fruits', kind: 'mango',
    origin: 'Ratnagiri, MH', weight: '1 kg', price: 45000, mrp: 59900, rating: 4.9, reviews: 2142,
    organic: true, bestseller: true, trending: true,
    nutrition: { kcal: '60', carbs: '14g', vitC: '46%', fiber: '7%' },
    packs: [
      { weight: '500 g', price: 24000, sub: '3–4 pcs' },
      { weight: '1 kg',  price: 45000, sub: '6–8 pcs', best: true },
      { weight: '2 kg',  price: 85900, sub: '12–16 pcs · save more' },
    ],
    desc: "The king of mangoes. GI-tagged Alphonso from Devgad's slow-ripening orchards. Saffron-yellow flesh, fiberless, with a honeyed cardamom finish." },

  { slug: 'royal-gala-apple', name: 'Royal Gala Apples', cat: 'fruits', kind: 'apple',
    origin: 'Himachal Pradesh', weight: '4 pcs', price: 12900, mrp: 15900, rating: 4.6, reviews: 815,
    trending: true,
    desc: 'Sweet, crisp Gala apples, hand-picked from Himachal orchards.' },

  { slug: 'robusta-banana', name: 'Robusta Banana', cat: 'fruits', kind: 'banana',
    origin: 'Tamil Nadu', weight: '6 pcs', price: 4900, mrp: 5900, rating: 4.4, reviews: 1310,
    bestseller: true,
    desc: 'Naturally ripened robusta bananas, perfect for breakfast.' },

  { slug: 'strawberry-mahabaleshwar', name: 'Strawberries, Mahabaleshwar', cat: 'fruits', kind: 'strawberry',
    origin: 'Mahabaleshwar, MH', weight: '250 g', price: 8900, mrp: 12000, rating: 4.7, reviews: 521,
    bestseller: true, trending: true,
    desc: 'Plump, juicy strawberries from the hills of Mahabaleshwar.' },

  { slug: 'pomegranate-bhagwa', name: 'Bhagwa Pomegranate', cat: 'fruits', kind: 'pomegranate',
    origin: 'Solapur, MH', weight: '500 g', price: 14900, mrp: 19900, rating: 4.8, reviews: 940,
    bestseller: true,
    desc: 'Iron-rich Bhagwa pomegranates, bursting with ruby arils.' },

  { slug: 'kiwi-green-imported', name: 'Green Kiwi, imported', cat: 'exotic', kind: 'kiwi',
    origin: 'New Zealand', weight: '4 pcs', price: 13900, rating: 4.6, reviews: 412,
    desc: 'Tangy and refreshing imported green kiwis.' },

  { slug: 'nagpur-orange', name: 'Nagpur Orange, sweet', cat: 'fruits', kind: 'orange',
    origin: 'Nagpur, MH', weight: '1 kg', price: 7900, rating: 4.5, reviews: 388,
    desc: 'Sweet, juicy Nagpur oranges packed with vitamin C.' },

  { slug: 'watermelon-seedless', name: 'Watermelon, seedless', cat: 'fresh-cuts', kind: 'watermelon',
    weight: '2 kg', price: 7900, mrp: 9900, rating: 4.5, reviews: 502,
    trending: true,
    desc: 'Refreshing seedless watermelon — cool & sweet.' },

  { slug: 'hass-avocado-ripe', name: 'Hass Avocado, ripe', cat: 'exotic', kind: 'avocado',
    origin: 'Karnataka', weight: '2 pcs', price: 19900, mrp: 24000, rating: 4.9, reviews: 711,
    organic: true, trending: true,
    desc: 'Creamy ready-to-eat Hass avocados.' },

  { slug: 'blueberry-imported', name: 'Blueberries, imported', cat: 'exotic', kind: 'blueberry',
    origin: 'Peru', weight: '125 g', price: 19900, rating: 4.6, reviews: 220,
    desc: 'Premium imported antioxidant-rich blueberries.' },

  { slug: 'dragon-fruit-pink', name: 'Pink Dragon Fruit', cat: 'exotic', kind: 'dragonfruit',
    weight: '1 pc', price: 14900, rating: 4.4, reviews: 156,
    desc: 'Visually stunning pink-flesh dragon fruit.' },

  { slug: 'cherries-us', name: 'Cherries, US imported', cat: 'exotic', kind: 'cherry',
    origin: 'Washington, US', weight: '250 g', price: 59900, mrp: 69900, rating: 4.7, reviews: 312,
    desc: 'Plump, premium US-imported cherries — a seasonal favourite.' },

  { slug: 'baby-spinach-organic', name: 'Baby spinach, organic', cat: 'vegetables', kind: 'spinach',
    weight: '250 g', price: 4900, rating: 4.6, reviews: 488,
    organic: true,
    desc: 'Tender baby spinach leaves, certified organic.' },

  { slug: 'tomato-hybrid', name: 'Hybrid Tomato', cat: 'vegetables', kind: 'tomato',
    weight: '1 kg', price: 5900, rating: 4.4, reviews: 233,
    desc: 'Farm-fresh hybrid tomatoes.' },

  { slug: 'carrot-ooty', name: 'Ooty Carrots', cat: 'vegetables', kind: 'carrot',
    origin: 'Ooty, TN', weight: '500 g', price: 4500, rating: 4.5, reviews: 188,
    desc: 'Sweet, vibrant Ooty carrots from the Nilgiris.' },

  { slug: 'cucumber-english', name: 'English Cucumber', cat: 'vegetables', kind: 'cucumber',
    weight: '2 pcs', price: 3900, rating: 4.4, reviews: 144,
    desc: 'Crisp, seedless English cucumbers.' },

  { slug: 'cold-pressed-orange-juice', name: 'Cold-pressed Orange Juice', cat: 'juices', kind: 'juice',
    weight: '500 ml', price: 14900, rating: 4.7, reviews: 312,
    desc: 'Fresh cold-pressed orange juice, no added sugar.' },

  { slug: 'almonds-premium', name: 'Premium Almonds', cat: 'dry-fruits', kind: 'almond',
    weight: '200 g', price: 21900, mrp: 26900, rating: 4.8, reviews: 624,
    desc: 'Hand-picked premium California almonds.' },

  { slug: 'lemon-fresh', name: 'Fresh Lemons', cat: 'fruits', kind: 'lemon',
    weight: '250 g', price: 2900, rating: 4.3, reviews: 192,
    desc: 'Juicy fresh lemons — zing for everything.' },

  { slug: 'banganapalli-mango', name: 'Mango, Banganapalli', cat: 'fruits', kind: 'mango',
    origin: 'Andhra Pradesh', weight: '1 kg', price: 28000, rating: 4.6, reviews: 412,
    desc: 'Sweet Banganapalli mangoes — a south Indian classic.' },
];

const COUPONS = [
  { code: 'VACADO50', title: '₹50 off above ₹299',           subtitle: 'For all users · expires today',         tone: 'green',  type: 'flat',    value: 5000,  minOrder: 29900 },
  { code: 'FIRST10',  title: '10% off your first 3 orders',  subtitle: 'Auto-applied · 2 of 3 used',            tone: 'orange', type: 'percent', value: 10,    minOrder: 0 },
  { code: 'WEEKEND',  title: 'Buy 2 get 1 free on fruit boxes', subtitle: 'Sat–Sun only · combos',              tone: 'green',  type: 'percent', value: 33,    minOrder: 0 },
  { code: 'HEALTHY',  title: 'Flat 15% off organic produce', subtitle: 'Min. order ₹199',                       tone: 'green',  type: 'percent', value: 15,    minOrder: 19900 },
  { code: 'UPI100',   title: 'Flat ₹100 cashback on UPI',    subtitle: 'Once per user · valid on Paytm/PhonePe', tone: 'orange', type: 'flat',    value: 10000, minOrder: 0 },
];

const BANNERS = [
  { title: 'Alphonso is here',  subtitle: 'Flat 30% OFF · ends in 2h 14m', tag: 'SEASONAL',     fruitKind: 'mango', gradient: 'orange', ctaLabel: 'Shop now', ctaTarget: 'alphonso-mango-1kg', position: 1 },
  { title: 'Flash deals live',  subtitle: 'Up to 60% off · 24 items live', tag: 'FLASH',        fruitKind: 'strawberry', gradient: 'amber', ctaLabel: 'Browse', ctaTarget: 'flash', position: 2 },
];

async function seed() {
  await withTx(async (client) => {
    console.log('→ clearing existing seed data');
    await client.query('TRUNCATE banners, coupons, order_events, order_items, orders, wishlist_items, cart_items, products, categories RESTART IDENTITY CASCADE');

    console.log('→ seeding categories');
    const catMap = {};
    for (const c of CATEGORIES) {
      const { rows } = await client.query(
        `INSERT INTO categories (slug, name, fruit_kind, position)
         VALUES ($1, $2, $3, $4) RETURNING id`,
        [c.slug, c.name, c.kind, c.position]
      );
      catMap[c.slug] = rows[0].id;
    }

    console.log('→ seeding products');
    for (const p of PRODUCTS) {
      await client.query(
        `INSERT INTO products
          (slug, name, description, category_id, fruit_kind, origin,
           weight_label, price_paise, mrp_paise, rating, review_count, eta_minutes,
           is_organic, is_trending, is_bestseller, stock,
           picked_at, nutrition, pack_options)
         VALUES
          ($1, $2, $3, $4, $5, $6,
           $7, $8, $9, $10, $11, $12,
           $13, $14, $15, $16,
           now() - interval '8 hours', $17::jsonb, $18::jsonb)`,
        [
          p.slug, p.name, p.desc, catMap[p.cat] || null, p.kind, p.origin || null,
          p.weight, p.price, p.mrp || null, p.rating, p.reviews, 10 + Math.floor(Math.random() * 4),
          !!p.organic, !!p.trending, !!p.bestseller, 100,
          JSON.stringify(p.nutrition || {}),
          JSON.stringify(p.packs || []),
        ]
      );
    }

    console.log('→ seeding coupons');
    for (const c of COUPONS) {
      await client.query(
        `INSERT INTO coupons (code, title, subtitle, tone, discount_type, discount_value, min_order_paise, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, now() + interval '30 days')`,
        [c.code, c.title, c.subtitle, c.tone, c.type, c.value, c.minOrder]
      );
    }

    console.log('→ seeding banners');
    for (const b of BANNERS) {
      await client.query(
        `INSERT INTO banners (title, subtitle, tag, fruit_kind, gradient, cta_label, cta_target, position)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [b.title, b.subtitle, b.tag, b.fruitKind, b.gradient, b.ctaLabel, b.ctaTarget, b.position]
      );
    }
  });
  console.log('Seed complete.');
}

seed()
  .then(() => pool.end())
  .catch((err) => {
    console.error('Seed failed:', err);
    pool.end();
    process.exit(1);
  });
