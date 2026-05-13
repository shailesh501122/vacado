'use strict';

const { query } = require('../db/pool');
const ApiError = require('../utils/ApiError');

async function profile(req, res) {
  const { rows } = await query(
    `SELECT riders.*, admins.username, admins.name AS account_name
       FROM riders JOIN admins ON admins.id = riders.admin_id
      WHERE riders.admin_id = $1`,
    [req.admin.id]
  );
  if (!rows[0]) throw ApiError.notFound('rider_profile_not_found');
  const r = rows[0];
  res.json({
    rider: {
      id: r.id, displayName: r.display_name, phone: r.phone, vehicle: r.vehicle,
      rating: Number(r.rating), deliveredCount: r.delivered_count, isOnline: r.is_online,
      username: r.username, accountName: r.account_name,
    },
  });
}

async function setOnline(req, res) {
  const online = !!req.body.online;
  await query('UPDATE riders SET is_online = $1 WHERE admin_id = $2', [online, req.admin.id]);
  res.json({ ok: true, online });
}

async function stats(req, res) {
  const { rows } = await query(
    `SELECT
        (SELECT count(*)::int FROM orders WHERE rider_admin_id = $1 AND status = 'out_for_delivery') AS active,
        (SELECT count(*)::int FROM orders WHERE rider_admin_id = $1 AND status = 'delivered') AS delivered,
        (SELECT count(*)::int FROM orders WHERE rider_admin_id = $1 AND status = 'delivered'
                                            AND delivered_at >= now() - interval '24 hours') AS deliveredToday,
        COALESCE((SELECT rating FROM riders WHERE admin_id = $1), 4.9) AS rating`,
    [req.admin.id]
  );
  res.json(rows[0]);
}

/** Orders assigned to this rider OR unassigned out_for_delivery orders they can claim. */
async function listOrders(req, res) {
  const { rows } = await query(
    `SELECT orders.id, orders.order_number, orders.status, orders.total_paise,
            orders.placed_at, orders.delivered_at, orders.payment_method,
            orders.delivery_instruction, orders.eta_minutes,
            orders.rider_admin_id,
            users.name AS user_name, users.phone AS user_phone,
            addresses.line1, addresses.line2, addresses.city, addresses.pincode
       FROM orders
       LEFT JOIN users     ON users.id     = orders.user_id
       LEFT JOIN addresses ON addresses.id = orders.address_id
      WHERE orders.rider_admin_id = $1
         OR (orders.rider_admin_id IS NULL AND orders.status IN ('packed','out_for_delivery'))
      ORDER BY
        CASE WHEN orders.rider_admin_id = $1 AND orders.status = 'out_for_delivery' THEN 0
             WHEN orders.rider_admin_id = $1 THEN 1
             ELSE 2 END,
        orders.placed_at DESC
      LIMIT 50`,
    [req.admin.id]
  );
  res.json({
    orders: rows.map((o) => ({
      id: o.id, orderNumber: o.order_number, status: o.status,
      totalPaise: o.total_paise, paymentMethod: o.payment_method,
      placedAt: o.placed_at, deliveredAt: o.delivered_at,
      etaMinutes: o.eta_minutes, deliveryInstruction: o.delivery_instruction,
      isMine: o.rider_admin_id === req.admin.id,
      customer: { name: o.user_name, phone: o.user_phone },
      address: o.line1
        ? { line1: o.line1, line2: o.line2, city: o.city, pincode: o.pincode }
        : null,
    })),
  });
}

async function claimOrder(req, res) {
  const { id } = req.params;
  const result = await query(
    `UPDATE orders
        SET rider_admin_id = $1,
            rider_name     = (SELECT display_name FROM riders WHERE admin_id = $1),
            rider_phone    = (SELECT phone        FROM riders WHERE admin_id = $1),
            rider_vehicle  = (SELECT vehicle      FROM riders WHERE admin_id = $1),
            rider_rating   = (SELECT rating       FROM riders WHERE admin_id = $1),
            status         = CASE WHEN status = 'packed' THEN 'out_for_delivery' ELSE status END,
            updated_at     = now()
      WHERE id = $2 AND (rider_admin_id IS NULL OR rider_admin_id = $1)
      RETURNING id`,
    [req.admin.id, id]
  );
  if (!result.rowCount) throw ApiError.conflict('already_claimed_or_missing');

  await query(
    `INSERT INTO order_events (order_id, kind, title, subtitle)
     VALUES ($1, 'rider_assigned', 'Rider on the way',
             (SELECT 'Rider ' || display_name FROM riders WHERE admin_id = $2))`,
    [id, req.admin.id]
  );
  res.json({ ok: true });
}

async function markDelivered(req, res) {
  const { id } = req.params;
  const r = await query(
    `UPDATE orders
        SET status = 'delivered', delivered_at = now(), updated_at = now()
      WHERE id = $1 AND rider_admin_id = $2
      RETURNING id`,
    [id, req.admin.id]
  );
  if (!r.rowCount) throw ApiError.notFound('not_your_order');
  await query(
    `INSERT INTO order_events (order_id, kind, title, subtitle)
     VALUES ($1, 'delivered', 'Delivered', 'Marked by rider')`,
    [id]
  );
  await query(
    'UPDATE riders SET delivered_count = delivered_count + 1 WHERE admin_id = $1',
    [req.admin.id]
  );
  res.json({ ok: true });
}

module.exports = { profile, setOnline, stats, listOrders, claimOrder, markDelivered };
