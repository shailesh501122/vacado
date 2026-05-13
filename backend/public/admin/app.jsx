// Vacado Admin · single-file React SPA
const { useState, useEffect, useCallback, useMemo, createContext, useContext } = React;

// ─── API client ───────────────────────────────────────────
const API = '/api/v1';
const TOKEN_KEY = 'vacado_admin_token';

async function api(path, { method = 'GET', body, token } = {}) {
  const headers = { 'Accept': 'application/json' };
  if (body) headers['Content-Type'] = 'application/json';
  const t = token || localStorage.getItem(TOKEN_KEY);
  if (t) headers.Authorization = `Bearer ${t}`;

  const res = await fetch(API + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const ct = res.headers.get('content-type') || '';
  const data = ct.includes('application/json') ? await res.json() : await res.text();
  if (!res.ok) {
    const msg = (data && data.error && data.error.message) || `HTTP ${res.status}`;
    const err = new Error(msg); err.status = res.status; err.code = data?.error?.code; throw err;
  }
  return data;
}

// ─── Helpers ──────────────────────────────────────────────
const rupees = (paise) => `₹${(paise / 100).toLocaleString('en-IN', { maximumFractionDigits: 0 })}`;
const fmtDate = (s) => new Date(s).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
const cls = (...c) => c.filter(Boolean).join(' ');

const FRUIT = {
  apple:{t:'#FFE4E1',b:'#E63946'}, banana:{t:'#FFF6D6',b:'#F4C430'}, strawberry:{t:'#FFE0E6',b:'#E11D48'},
  orange:{t:'#FFE8CC',b:'#FB7B24'}, kiwi:{t:'#E4F3D9',b:'#7CB518'}, blueberry:{t:'#DCE3F5',b:'#3B5BDB'},
  watermelon:{t:'#FFD9DD',b:'#EF4444'}, mango:{t:'#FFEED0',b:'#F59E0B'},
  pomegranate:{t:'#FCDCDF',b:'#B91C1C'}, avocado:{t:'#E4EED1',b:'#4D7C0F'},
  juice:{t:'#FFEFCB',b:'#F97316'}, almond:{t:'#F1E4D2',b:'#C2956B'},
  spinach:{t:'#D8EAD0',b:'#15803D'}, tomato:{t:'#FFE0E0',b:'#DC2626'},
  carrot:{t:'#FFE0CC',b:'#EA580C'}, cucumber:{t:'#DAEFD6',b:'#65A30D'},
  cherry:{t:'#FCD9DC',b:'#BE123C'}, lemon:{t:'#FFF8C7',b:'#EAB308'},
  dragonfruit:{t:'#FFD9EC',b:'#EC4899'}, papaya:{t:'#FFE0CC',b:'#F97316'},
};

function FruitTile({ kind = 'apple', size = 40 }) {
  const p = FRUIT[kind] || FRUIT.apple;
  return (
    <div className="ft" style={{ width: size, height: size, background: p.t }}>
      <div className="blob" style={{ background: p.b }} />
    </div>
  );
}

const STATUS_TONES = {
  placed:           { bg: 'bg-amber-50',  fg: 'text-amber-800', label: 'Placed' },
  packed:           { bg: 'bg-sky-50',    fg: 'text-sky-800',   label: 'Packed' },
  out_for_delivery: { bg: 'bg-violet-50', fg: 'text-violet-800',label: 'Out' },
  delivered:        { bg: 'bg-brand-50',  fg: 'text-brand-700', label: 'Delivered' },
  cancelled:        { bg: 'bg-rose-50',   fg: 'text-rose-700',  label: 'Cancelled' },
};

function StatusPill({ status }) {
  const t = STATUS_TONES[status] || { bg: 'bg-line-2', fg: 'text-ink-2', label: status };
  return <span className={cls('inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wide', t.bg, t.fg)}>{t.label}</span>;
}

// ─── Auth context ────────────────────────────────────────
const AuthCtx = createContext(null);

function useAuth() { return useContext(AuthCtx); }

function AuthProvider({ children }) {
  const [admin, setAdmin] = useState(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    const t = localStorage.getItem(TOKEN_KEY);
    if (!t) { setLoaded(true); return; }
    api('/admin/me').then((d) => setAdmin(d.admin)).catch(() => localStorage.removeItem(TOKEN_KEY)).finally(() => setLoaded(true));
  }, []);

  const login = useCallback(async (username, password) => {
    const r = await api('/admin/login', { method: 'POST', body: { username, password } });
    localStorage.setItem(TOKEN_KEY, r.token);
    setAdmin(r.admin);
    return r.admin;
  }, []);

  const logout = useCallback(() => { localStorage.removeItem(TOKEN_KEY); setAdmin(null); }, []);

  return <AuthCtx.Provider value={{ admin, login, logout, loaded }}>{children}</AuthCtx.Provider>;
}

// ─── Login screen ────────────────────────────────────────
function Login() {
  const { login } = useAuth();
  const [u, setU] = useState('Admin');
  const [p, setP] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState(null);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true); setErr(null);
    try { await login(u, p); } catch (e) { setErr(e.message); } finally { setBusy(false); }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-gradient-to-br from-brand-50 via-white to-brand-50">
      <div className="w-full max-w-md">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-12 h-12 rounded-xl bg-brand grid place-items-center text-white shadow-lg shadow-brand/30">
            <svg viewBox="0 0 40 40" width="26" height="26" fill="none"><path d="M20 4c-7 0-13 4-13 13 0 8 6 12 12 18 1 1 2 1 3 0 6-6 11-10 11-18 0-9-6-13-13-13z" fill="#fff"/><circle cx="20" cy="16" r="3.5" fill="#22C55E"/></svg>
          </div>
          <div>
            <div className="serif text-3xl leading-none">vacado</div>
            <div className="text-xs font-bold tracking-widest text-brand-700 uppercase">admin console</div>
          </div>
        </div>

        <form onSubmit={submit} className="bg-white border border-line-2 rounded-2xl p-6 shadow-xl shadow-ink/5 space-y-4">
          <div>
            <label className="text-[11px] font-bold uppercase tracking-wide text-ink-3">Username</label>
            <input value={u} onChange={(e) => setU(e.target.value)} required
              className="mt-1 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm font-semibold focus:outline-none focus:border-brand"
              autoComplete="username" />
          </div>
          <div>
            <label className="text-[11px] font-bold uppercase tracking-wide text-ink-3">Password</label>
            <input value={p} onChange={(e) => setP(e.target.value)} required type="password"
              className="mt-1 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm font-semibold focus:outline-none focus:border-brand"
              autoComplete="current-password" />
          </div>
          {err && <div className="text-xs text-rose-700 bg-rose-50 border border-rose-100 rounded-lg px-3 py-2">{err}</div>}
          <button disabled={busy} className="w-full bg-brand text-white font-bold py-3 rounded-xl shadow-md shadow-brand/40 disabled:opacity-60">
            {busy ? 'Signing in…' : 'Sign in'}
          </button>
          <div className="text-[11px] text-ink-3 text-center">
            Default: <code className="text-ink font-semibold">Admin</code> · <code className="text-ink font-semibold">Admin@123</code>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Shell ───────────────────────────────────────────────
const NAV = [
  { k: 'dashboard', label: 'Dashboard', icon: 'M4 13h6V4H4v9zm0 7h6v-5H4v5zm10 0h6V11h-6v9zm0-16v5h6V4h-6z' },
  { k: 'orders',    label: 'Orders',    icon: 'M3 7l4-3h10l4 3v3H3V7zm0 5h18v9H3v-9zm6 0v6h6v-6' },
  { k: 'products',  label: 'Products',  icon: 'M3 3h18v6H3V3zm0 8h8v10H3V11zm10 0h8v10h-8V11z' },
  { k: 'customers', label: 'Customers', icon: 'M12 12a4 4 0 100-8 4 4 0 000 8zm-8 9a8 8 0 0116 0H4z' },
  { k: 'coupons',   label: 'Coupons',   icon: 'M3 8a2 2 0 012-2h14a2 2 0 012 2v2a2 2 0 000 4v2a2 2 0 01-2 2H5a2 2 0 01-2-2v-2a2 2 0 000-4V8zm6-2v12' },
  { k: 'firebase',  label: 'Firebase',  icon: 'M5 18L8 3l4 6 3-3 4 12-7 3z' },
  { k: 'settings',  label: 'Settings',  icon: 'M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 010-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3h0a1.7 1.7 0 001-1.5V3a2 2 0 014 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8v0a1.7 1.7 0 001.5 1H21a2 2 0 010 4h-.1a1.7 1.7 0 00-1.5 1z' },
];

function Shell() {
  const { admin, logout } = useAuth();
  const [page, setPage] = useState('dashboard');

  const Page = useMemo(() => ({
    dashboard: Dashboard, orders: Orders, products: Products,
    customers: Customers, coupons: Coupons, firebase: FirebaseSettings, settings: Settings,
  })[page] || Dashboard, [page]);

  return (
    <div className="min-h-screen flex">
      {/* Sidebar */}
      <aside className="w-60 shrink-0 bg-white border-r border-line-2 flex flex-col">
        <div className="px-5 py-5 flex items-center gap-3 border-b border-line-2">
          <div className="w-9 h-9 rounded-lg bg-brand grid place-items-center text-white">
            <svg viewBox="0 0 40 40" width="20" height="20" fill="none"><path d="M20 4c-7 0-13 4-13 13 0 8 6 12 12 18 1 1 2 1 3 0 6-6 11-10 11-18 0-9-6-13-13-13z" fill="#fff"/></svg>
          </div>
          <div>
            <div className="serif text-xl leading-none">vacado</div>
            <div className="text-[10px] tracking-widest font-bold text-ink-3 uppercase">admin</div>
          </div>
        </div>
        <nav className="flex-1 p-3 space-y-1">
          {NAV.map((n) => {
            const active = n.k === page;
            return (
              <button key={n.k} onClick={() => setPage(n.k)}
                className={cls('w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-bold transition',
                  active ? 'bg-brand-25 text-brand-700' : 'text-ink-2 hover:bg-line-2')}>
                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2"
                     strokeLinecap="round" strokeLinejoin="round"><path d={n.icon} /></svg>
                {n.label}
              </button>
            );
          })}
        </nav>
        <div className="p-4 border-t border-line-2">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-brand-50 text-brand-700 font-black grid place-items-center">{(admin?.name || admin?.username || 'A').slice(0,1).toUpperCase()}</div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-bold truncate">{admin?.name || admin?.username}</div>
              <div className="text-[10px] uppercase tracking-wide text-ink-3">{admin?.role}</div>
            </div>
            <button onClick={logout} className="text-[11px] font-bold text-rose-700 hover:underline">Sign out</button>
          </div>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 min-w-0 overflow-y-auto">
        <div className="px-8 py-7"><Page /></div>
      </main>
    </div>
  );
}

// ─── Dashboard ───────────────────────────────────────────
function Dashboard() {
  const [data, setData] = useState(null);
  const [err, setErr] = useState(null);

  useEffect(() => { api('/admin/stats').then(setData).catch((e) => setErr(e.message)); }, []);

  if (err) return <ErrorBox msg={err} />;
  if (!data) return <Loader />;

  return (
    <div className="space-y-6">
      <header className="flex items-end justify-between">
        <div>
          <div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">overview</div>
          <h1 className="serif text-4xl">Dashboard</h1>
        </div>
        <div className="text-sm text-ink-3">Live · {fmtDate(new Date().toISOString())}</div>
      </header>

      <div className="grid grid-cols-4 gap-4">
        <Stat label="Total revenue"    value={rupees(data.totals.revenuePaise)} accent="brand"  sub={`${data.totals.orders} orders`} />
        <Stat label="Today"            value={rupees(data.today.revenuePaise)}  accent="accent" sub={`${data.today.orders} today`} />
        <Stat label="Customers"        value={data.totals.customers}            accent="brand"  />
        <Stat label="Active products"  value={data.totals.products}             accent="accent" />
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Card className="col-span-2">
          <CardHeader title="Recent orders" subtitle="Last 8" />
          <table className="w-full text-sm">
            <thead className="text-[10px] uppercase tracking-wide text-ink-3">
              <tr className="border-b border-line-2"><th className="text-left py-2">Order</th><th className="text-left">Status</th><th className="text-right">Total</th><th className="text-right">Placed</th></tr>
            </thead>
            <tbody>
              {data.recentOrders.map((o) => (
                <tr key={o.id} className="border-b border-line-2 last:border-0">
                  <td className="py-3 font-bold">{o.orderNumber}</td>
                  <td><StatusPill status={o.status} /></td>
                  <td className="text-right font-bold">{rupees(o.totalPaise)}</td>
                  <td className="text-right text-ink-3">{fmtDate(o.placedAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
        <Card>
          <CardHeader title="By status" />
          <div className="space-y-3 mt-2">
            {data.byStatus.map((s) => (
              <div key={s.status} className="flex items-center justify-between">
                <StatusPill status={s.status} />
                <div className="font-bold tabular-nums">{s.n}</div>
              </div>
            ))}
            {data.byStatus.length === 0 && <div className="text-ink-3 text-sm">No orders yet.</div>}
          </div>
        </Card>
      </div>

      <Card>
        <CardHeader title="Top products" subtitle="By units sold" />
        <div className="grid grid-cols-6 gap-4 mt-3">
          {data.topProducts.map((p) => (
            <div key={p.id} className="space-y-2">
              <FruitTile kind={p.fruitKind} size={60} />
              <div className="text-xs font-bold leading-tight">{p.name}</div>
              <div className="text-[11px] text-ink-3">{p.sold} sold · {rupees(p.revenuePaise)}</div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function Stat({ label, value, sub, accent = 'brand' }) {
  const ring = accent === 'accent' ? 'from-accent/15 to-accent/0' : 'from-brand/15 to-brand/0';
  return (
    <div className="rounded-2xl border border-line-2 bg-white p-5 relative overflow-hidden">
      <div className={cls('absolute -top-12 -right-12 w-40 h-40 rounded-full bg-gradient-to-br', ring)} />
      <div className="text-[11px] uppercase tracking-widest font-bold text-ink-3">{label}</div>
      <div className="serif text-4xl mt-1">{value}</div>
      {sub && <div className="text-xs text-ink-3 mt-1">{sub}</div>}
    </div>
  );
}

// ─── Orders ─────────────────────────────────────────────
function Orders() {
  const [list, setList] = useState(null);
  const [filter, setFilter] = useState('');
  const [open, setOpen] = useState(null);

  const refresh = () => api(`/admin/orders${filter ? `?status=${filter}` : ''}`).then((d) => setList(d.orders));
  useEffect(() => { setList(null); refresh(); }, [filter]);

  return (
    <div className="space-y-6">
      <header className="flex items-end justify-between">
        <div>
          <div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">commerce</div>
          <h1 className="serif text-4xl">Orders</h1>
        </div>
        <div className="flex items-center gap-2">
          {['', 'placed', 'packed', 'out_for_delivery', 'delivered', 'cancelled'].map((s) => (
            <button key={s || 'all'} onClick={() => setFilter(s)}
              className={cls('px-3 py-1.5 rounded-full border text-xs font-bold',
                filter === s ? 'bg-ink text-white border-ink' : 'bg-white border-line text-ink-2 hover:border-ink-2')}>
              {s ? STATUS_TONES[s].label : 'All'}
            </button>
          ))}
        </div>
      </header>

      {!list ? <Loader /> : list.length === 0 ? (
        <Empty label="No orders" />
      ) : (
        <Card noPad>
          <table className="w-full text-sm">
            <thead className="text-[10px] uppercase tracking-wide text-ink-3 bg-line-2">
              <tr><th className="text-left px-4 py-3">Order</th><th className="text-left">Customer</th><th className="text-left">Status</th><th className="text-left">Payment</th><th className="text-right">Total</th><th className="text-right pr-4">Placed</th></tr>
            </thead>
            <tbody>
              {list.map((o) => (
                <tr key={o.id} onClick={() => setOpen(o.id)} className="border-b border-line-2 last:border-0 cursor-pointer hover:bg-line-2/50">
                  <td className="px-4 py-3 font-bold">{o.orderNumber}</td>
                  <td><div className="text-sm font-semibold">{o.customer.name || '—'}</div><div className="text-[11px] text-ink-3">{o.customer.phone}</div></td>
                  <td><StatusPill status={o.status} /></td>
                  <td className="text-xs"><div className="font-bold uppercase">{o.paymentMethod}</div><div className="text-ink-3">{o.paymentStatus}</div></td>
                  <td className="text-right font-bold">{rupees(o.totalPaise)}</td>
                  <td className="text-right pr-4 text-ink-3">{fmtDate(o.placedAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {open && <OrderModal id={open} onClose={() => setOpen(null)} onChanged={refresh} />}
    </div>
  );
}

function OrderModal({ id, onClose, onChanged }) {
  const [order, setOrder] = useState(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => { api(`/admin/orders/${id}`).then((d) => setOrder(d.order)); }, [id]);

  const setStatus = async (status) => {
    setBusy(true);
    try { await api(`/admin/orders/${id}/status`, { method: 'PATCH', body: { status } }); await onChanged(); onClose(); }
    catch (e) { alert(e.message); } finally { setBusy(false); }
  };

  return (
    <div className="fixed inset-0 bg-ink/40 backdrop-blur-sm z-40 grid place-items-center p-6" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()} className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-auto shadow-2xl">
        {!order ? <div className="p-10"><Loader /></div> : (
          <div>
            <div className="px-6 py-5 border-b border-line-2 flex items-start justify-between">
              <div>
                <div className="text-[11px] uppercase tracking-widest text-brand-700 font-bold">order</div>
                <div className="serif text-3xl">{order.orderNumber}</div>
                <div className="text-xs text-ink-3 mt-1">{fmtDate(order.placedAt)}</div>
              </div>
              <button onClick={onClose} className="w-9 h-9 rounded-lg hover:bg-line-2 grid place-items-center">×</button>
            </div>
            <div className="p-6 space-y-5">
              <div className="grid grid-cols-2 gap-4">
                <Card><CardHeader title="Customer" /><div className="font-bold">{order.customer.name || '—'}</div><div className="text-sm text-ink-3">{order.customer.phone}</div></Card>
                <Card><CardHeader title="Rider" />
                  {order.rider ? <><div className="font-bold">{order.rider.name}</div><div className="text-sm text-ink-3">{order.rider.phone} · {order.rider.vehicle}</div></>
                               : <div className="text-sm text-ink-3">Not yet assigned</div>}
                </Card>
              </div>
              <Card noPad>
                <table className="w-full text-sm">
                  <thead className="text-[10px] uppercase tracking-wide text-ink-3"><tr className="border-b border-line-2"><th className="text-left px-4 py-3">Item</th><th className="text-right">Qty</th><th className="text-right pr-4">Total</th></tr></thead>
                  <tbody>
                    {order.items.map((it, i) => (
                      <tr key={i} className="border-b border-line-2 last:border-0">
                        <td className="px-4 py-3 flex items-center gap-3"><FruitTile kind={it.fruitKind} size={36} /><div><div className="font-semibold">{it.productName}</div><div className="text-[11px] text-ink-3">{it.weightLabel}</div></div></td>
                        <td className="text-right">×{it.quantity}</td>
                        <td className="text-right pr-4 font-bold">{rupees(it.lineTotalPaise)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr><td className="px-4 py-2 text-ink-3" colSpan={2}>Subtotal</td><td className="text-right pr-4 font-semibold">{rupees(order.subtotalPaise)}</td></tr>
                    {order.discountPaise > 0 && <tr><td className="px-4 py-2 text-ink-3" colSpan={2}>Discount</td><td className="text-right pr-4 text-brand-700 font-semibold">−{rupees(order.discountPaise)}</td></tr>}
                    <tr className="border-t border-line-2"><td className="px-4 py-3 font-bold" colSpan={2}>Total</td><td className="text-right pr-4 font-black text-lg">{rupees(order.totalPaise)}</td></tr>
                  </tfoot>
                </table>
              </Card>
              <Card><CardHeader title="Timeline" />
                <ol className="space-y-3 mt-3">
                  {order.events.map((e, i) => (
                    <li key={i} className="flex items-start gap-3">
                      <div className="w-2 h-2 rounded-full bg-brand mt-2" />
                      <div><div className="font-bold text-sm">{e.title}</div><div className="text-[11px] text-ink-3">{e.subtitle} · {fmtDate(e.occurredAt)}</div></div>
                    </li>
                  ))}
                </ol>
              </Card>
              <div>
                <div className="text-[11px] font-bold uppercase tracking-wide text-ink-3 mb-2">Move to</div>
                <div className="flex flex-wrap gap-2">
                  {Object.keys(STATUS_TONES).map((s) => (
                    <button key={s} disabled={busy || s === order.status} onClick={() => setStatus(s)}
                      className={cls('px-3 py-1.5 rounded-lg text-xs font-bold border', s === order.status ? 'bg-line-2 border-line text-ink-3 cursor-not-allowed' : 'border-line hover:bg-line-2 text-ink')}>
                      {STATUS_TONES[s].label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Products ───────────────────────────────────────────
function Products() {
  const [list, setList] = useState(null);
  const [q, setQ] = useState('');
  const [edit, setEdit] = useState(null); // { id?, ...fields }

  const load = () => api('/admin/products').then((d) => setList(d.products));
  useEffect(() => { load(); }, []);

  const filtered = useMemo(() => {
    if (!list) return null;
    if (!q) return list;
    return list.filter((p) => p.name.toLowerCase().includes(q.toLowerCase()) || p.slug.includes(q.toLowerCase()));
  }, [list, q]);

  const del = async (id) => {
    if (!confirm('Delete this product?')) return;
    await api(`/admin/products/${id}`, { method: 'DELETE' }); load();
  };

  return (
    <div className="space-y-6">
      <header className="flex items-end justify-between">
        <div>
          <div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">catalog</div>
          <h1 className="serif text-4xl">Products</h1>
        </div>
        <div className="flex items-center gap-2">
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search products…"
            className="px-3 py-2 rounded-lg border border-line bg-white text-sm w-64 focus:outline-none focus:border-brand" />
          <button onClick={() => setEdit({})} className="bg-brand text-white px-4 py-2 rounded-lg text-sm font-bold shadow-sm shadow-brand/40">+ New product</button>
        </div>
      </header>

      {!filtered ? <Loader /> : filtered.length === 0 ? <Empty label="No products" /> : (
        <Card noPad>
          <table className="w-full text-sm">
            <thead className="text-[10px] uppercase tracking-wide text-ink-3 bg-line-2">
              <tr><th className="text-left px-4 py-3">Product</th><th className="text-left">Category</th><th className="text-right">Price</th><th className="text-right">Stock</th><th className="text-right">Rating</th><th className="text-right pr-4">Actions</th></tr>
            </thead>
            <tbody>
              {filtered.map((p) => (
                <tr key={p.id} className="border-b border-line-2 last:border-0">
                  <td className="px-4 py-3 flex items-center gap-3">
                    <FruitTile kind={p.fruitKind} size={40} />
                    <div>
                      <div className="font-bold">{p.name}</div>
                      <div className="text-[11px] text-ink-3">{p.slug} · {p.weightLabel}</div>
                    </div>
                  </td>
                  <td className="text-ink-2">{p.categoryName || '—'}</td>
                  <td className="text-right font-bold">{rupees(p.pricePaise)}{p.mrpPaise > p.pricePaise && <div className="text-[10px] text-ink-3 line-through">{rupees(p.mrpPaise)}</div>}</td>
                  <td className={cls('text-right font-bold', p.stock < 10 ? 'text-rose-700' : 'text-ink')}>{p.stock}</td>
                  <td className="text-right">{p.rating.toFixed(1)} <span className="text-[10px] text-ink-3">({p.reviewCount})</span></td>
                  <td className="text-right pr-4">
                    <button onClick={() => setEdit(p)} className="text-xs font-bold text-brand-700 hover:underline mr-3">Edit</button>
                    <button onClick={() => del(p.id)} className="text-xs font-bold text-rose-700 hover:underline">Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {edit && <ProductForm initial={edit} onClose={() => setEdit(null)} onSaved={() => { setEdit(null); load(); }} />}
    </div>
  );
}

function ProductForm({ initial, onClose, onSaved }) {
  const [cats, setCats] = useState([]);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState(null);
  const isEdit = !!initial.id;

  const [f, setF] = useState({
    slug: initial.slug || '',
    name: initial.name || '',
    description: initial.description || '',
    categoryId: initial.categoryId || initial.category_id || null,
    fruitKind: initial.fruitKind || 'apple',
    origin: initial.origin || '',
    weightLabel: initial.weightLabel || '500 g',
    pricePaise: initial.pricePaise || 0,
    mrpPaise: initial.mrpPaise || 0,
    stock: initial.stock ?? 100,
    etaMinutes: initial.etaMinutes ?? 10,
    isOrganic: !!initial.isOrganic,
    isTrending: !!initial.isTrending,
    isBestseller: !!initial.isBestseller,
  });

  useEffect(() => { api('/admin/categories').then((d) => setCats(d.categories)); }, []);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true); setErr(null);
    try {
      const body = { ...f, mrpPaise: f.mrpPaise || null, categoryId: f.categoryId || null };
      if (isEdit) await api(`/admin/products/${initial.id}`, { method: 'PUT', body });
      else        await api('/admin/products', { method: 'POST', body });
      onSaved();
    } catch (e) { setErr(e.message); } finally { setBusy(false); }
  };

  const set = (k, v) => setF((s) => ({ ...s, [k]: v }));

  return (
    <div className="fixed inset-0 bg-ink/40 backdrop-blur-sm z-40 grid place-items-center p-6" onClick={onClose}>
      <form onClick={(e) => e.stopPropagation()} onSubmit={submit} className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-auto shadow-2xl">
        <div className="px-6 py-5 border-b border-line-2 flex items-center justify-between">
          <h2 className="serif text-2xl">{isEdit ? 'Edit product' : 'New product'}</h2>
          <button type="button" onClick={onClose} className="w-9 h-9 rounded-lg hover:bg-line-2 grid place-items-center">×</button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Field label="Slug" value={f.slug} onChange={(v) => set('slug', v)} required />
            <Field label="Name" value={f.name} onChange={(v) => set('name', v)} required />
          </div>
          <Field label="Description" value={f.description} onChange={(v) => set('description', v)} multiline />
          <div className="grid grid-cols-3 gap-4">
            <Select label="Category" value={f.categoryId || ''} onChange={(v) => set('categoryId', v || null)}
              options={[{ value: '', label: '—' }, ...cats.map((c) => ({ value: c.id, label: c.name }))]} />
            <Select label="Fruit kind" value={f.fruitKind} onChange={(v) => set('fruitKind', v)}
              options={Object.keys(FRUIT).map((k) => ({ value: k, label: k }))} />
            <Field label="Origin" value={f.origin} onChange={(v) => set('origin', v)} />
          </div>
          <div className="grid grid-cols-4 gap-4">
            <Field label="Weight label" value={f.weightLabel} onChange={(v) => set('weightLabel', v)} />
            <Field label="Price (paise)" type="number" value={f.pricePaise} onChange={(v) => set('pricePaise', Number(v))} required />
            <Field label="MRP (paise)" type="number" value={f.mrpPaise} onChange={(v) => set('mrpPaise', Number(v))} />
            <Field label="Stock" type="number" value={f.stock} onChange={(v) => set('stock', Number(v))} />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Field label="ETA (min)" type="number" value={f.etaMinutes} onChange={(v) => set('etaMinutes', Number(v))} />
            <Checkbox label="Organic" value={f.isOrganic} onChange={(v) => set('isOrganic', v)} />
            <Checkbox label="Trending" value={f.isTrending} onChange={(v) => set('isTrending', v)} />
          </div>
          <Checkbox label="Bestseller" value={f.isBestseller} onChange={(v) => set('isBestseller', v)} />
          {err && <div className="text-xs text-rose-700 bg-rose-50 border border-rose-100 rounded-lg px-3 py-2">{err}</div>}
        </div>
        <div className="px-6 py-4 border-t border-line-2 flex items-center justify-end gap-3">
          <button type="button" onClick={onClose} className="px-4 py-2 rounded-lg border border-line text-sm font-bold">Cancel</button>
          <button disabled={busy} className="bg-brand text-white px-4 py-2 rounded-lg text-sm font-bold shadow-sm shadow-brand/40 disabled:opacity-60">
            {busy ? 'Saving…' : (isEdit ? 'Save changes' : 'Create product')}
          </button>
        </div>
      </form>
    </div>
  );
}

// ─── Customers ──────────────────────────────────────────
function Customers() {
  const [list, setList] = useState(null);
  useEffect(() => { api('/admin/customers').then((d) => setList(d.customers)); }, []);
  return (
    <div className="space-y-6">
      <header><div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">people</div><h1 className="serif text-4xl">Customers</h1></header>
      {!list ? <Loader /> : list.length === 0 ? <Empty label="No customers" /> : (
        <Card noPad>
          <table className="w-full text-sm">
            <thead className="text-[10px] uppercase tracking-wide text-ink-3 bg-line-2">
              <tr><th className="text-left px-4 py-3">Customer</th><th className="text-left">Phone</th><th className="text-right">Orders</th><th className="text-right">Spent</th><th className="text-right pr-4">Joined</th></tr>
            </thead>
            <tbody>
              {list.map((c) => (
                <tr key={c.id} className="border-b border-line-2 last:border-0">
                  <td className="px-4 py-3 font-bold">{c.name || '—'}</td>
                  <td className="text-ink-2">{c.phone}</td>
                  <td className="text-right font-bold">{c.orderCount}</td>
                  <td className="text-right font-bold">{rupees(c.totalSpentPaise)}</td>
                  <td className="text-right pr-4 text-ink-3">{fmtDate(c.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}

// ─── Coupons ────────────────────────────────────────────
function Coupons() {
  const [list, setList] = useState(null);
  const [creating, setCreating] = useState(false);

  const load = () => api('/admin/coupons').then((d) => setList(d.coupons));
  useEffect(() => { load(); }, []);

  const del = async (id) => { if (!confirm('Delete coupon?')) return; await api(`/admin/coupons/${id}`, { method: 'DELETE' }); load(); };

  return (
    <div className="space-y-6">
      <header className="flex items-end justify-between">
        <div><div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">promotions</div><h1 className="serif text-4xl">Coupons</h1></div>
        <button onClick={() => setCreating(true)} className="bg-brand text-white px-4 py-2 rounded-lg text-sm font-bold shadow-sm shadow-brand/40">+ New coupon</button>
      </header>
      {!list ? <Loader /> : (
        <div className="grid grid-cols-2 gap-4">
          {list.map((c) => (
            <div key={c.id} className="rounded-2xl border border-line-2 bg-white overflow-hidden flex">
              <div className={cls('w-16 grid place-items-center', c.tone === 'orange' ? 'bg-gradient-to-br from-orange-100 to-orange-200' : 'bg-gradient-to-br from-brand-50 to-emerald-200')}>
                <div className={cls('font-black tracking-wider', c.tone === 'orange' ? 'text-orange-700' : 'text-brand-700')} style={{ writingMode: 'vertical-rl', transform: 'rotate(180deg)' }}>{c.code}</div>
              </div>
              <div className="flex-1 p-4">
                <div className="font-bold text-ink">{c.title}</div>
                <div className="text-xs text-ink-3 mt-1">{c.subtitle}</div>
                <div className="text-[11px] mt-3 text-ink-3">{c.discount_type === 'flat' ? `Flat ₹${c.discount_value/100}` : `${c.discount_value}% off`} · min ₹{c.min_order_paise/100}</div>
                <div className="flex justify-end mt-3"><button onClick={() => del(c.id)} className="text-xs font-bold text-rose-700 hover:underline">Delete</button></div>
              </div>
            </div>
          ))}
        </div>
      )}
      {creating && <CouponForm onClose={() => setCreating(false)} onSaved={() => { setCreating(false); load(); }} />}
    </div>
  );
}

function CouponForm({ onClose, onSaved }) {
  const [f, setF] = useState({ code: '', title: '', subtitle: '', tone: 'green', discountType: 'flat', discountValue: 0, minOrderPaise: 0, isActive: true });
  const [busy, setBusy] = useState(false); const [err, setErr] = useState(null);
  const set = (k, v) => setF((s) => ({ ...s, [k]: v }));
  const submit = async (e) => { e.preventDefault(); setBusy(true); setErr(null); try { await api('/admin/coupons', { method: 'POST', body: f }); onSaved(); } catch (e) { setErr(e.message); } finally { setBusy(false); } };
  return (
    <div className="fixed inset-0 bg-ink/40 backdrop-blur-sm z-40 grid place-items-center p-6" onClick={onClose}>
      <form onClick={(e) => e.stopPropagation()} onSubmit={submit} className="bg-white rounded-2xl w-full max-w-lg shadow-2xl">
        <div className="px-6 py-5 border-b border-line-2 flex items-center justify-between"><h2 className="serif text-2xl">New coupon</h2><button type="button" onClick={onClose}>×</button></div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Field label="Code" value={f.code} onChange={(v) => set('code', v.toUpperCase())} required />
            <Select label="Tone" value={f.tone} onChange={(v) => set('tone', v)} options={[{value:'green',label:'Green'},{value:'orange',label:'Orange'}]} />
          </div>
          <Field label="Title" value={f.title} onChange={(v) => set('title', v)} required />
          <Field label="Subtitle" value={f.subtitle} onChange={(v) => set('subtitle', v)} />
          <div className="grid grid-cols-3 gap-4">
            <Select label="Type" value={f.discountType} onChange={(v) => set('discountType', v)} options={[{value:'flat',label:'Flat ₹'},{value:'percent',label:'Percent %'}]} />
            <Field label={f.discountType === 'flat' ? 'Value (paise)' : 'Value (%)'} type="number" value={f.discountValue} onChange={(v) => set('discountValue', Number(v))} />
            <Field label="Min order (paise)" type="number" value={f.minOrderPaise} onChange={(v) => set('minOrderPaise', Number(v))} />
          </div>
          {err && <div className="text-xs text-rose-700 bg-rose-50 border border-rose-100 rounded-lg px-3 py-2">{err}</div>}
        </div>
        <div className="px-6 py-4 border-t border-line-2 flex justify-end gap-3">
          <button type="button" onClick={onClose} className="px-4 py-2 rounded-lg border border-line text-sm font-bold">Cancel</button>
          <button disabled={busy} className="bg-brand text-white px-4 py-2 rounded-lg text-sm font-bold disabled:opacity-60">{busy ? 'Saving…' : 'Create'}</button>
        </div>
      </form>
    </div>
  );
}

// ─── Settings ──────────────────────────────────────────
function Settings() {
  const { admin } = useAuth();
  return (
    <div className="space-y-6">
      <header><div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">account</div><h1 className="serif text-4xl">Settings</h1></header>
      <Card>
        <CardHeader title="Admin account" />
        <div className="grid grid-cols-2 gap-4 mt-3 text-sm">
          <KV label="Username" value={admin?.username} />
          <KV label="Name" value={admin?.name} />
          <KV label="Role" value={admin?.role} />
          <KV label="Admin ID" value={admin?.id} mono />
        </div>
      </Card>
      <Card>
        <CardHeader title="System" />
        <ul className="text-sm space-y-1.5 mt-3">
          <li className="text-ink-3">API base: <code className="text-ink font-bold">{location.origin}/api/v1</code></li>
          <li className="text-ink-3">Admin URL: <code className="text-ink font-bold">{location.origin}/admin</code></li>
          <li className="text-ink-3">Build: <code className="text-ink font-bold">single-file SPA · React 18 (UMD) · Tailwind CDN</code></li>
        </ul>
      </Card>
    </div>
  );
}

// ─── Firebase config ──────────────────────────────────
function FirebaseSettings() {
  const [cfg, setCfg] = useState(null);
  const [err, setErr] = useState(null);
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(null);
  const [serviceAccount, setServiceAccount] = useState(''); // raw textarea contents

  const load = () => api('/admin/settings/firebase').then((d) => setCfg(d.settings)).catch((e) => setErr(e.message));
  useEffect(() => { load(); }, []);

  const set = (k, v) => setCfg((s) => ({ ...s, [k]: v }));

  const save = async (e) => {
    e.preventDefault();
    setBusy(true); setErr(null); setSaved(null);
    try {
      const body = {
        enabled: !!cfg.enabled,
        apiKey: cfg.apiKey || '',
        appId: cfg.appId || '',
        projectId: cfg.projectId || '',
        messagingSenderId: cfg.messagingSenderId || '',
        iosAppId: cfg.iosAppId || '',
        iosBundleId: cfg.iosBundleId || '',
        androidPackageName: cfg.androidPackageName || 'com.vacado.app',
      };
      if (serviceAccount.trim().length > 0) body.serviceAccountJson = serviceAccount;
      const r = await api('/admin/settings/firebase', { method: 'PUT', body });
      setCfg(r.settings);
      setServiceAccount('');
      setSaved(new Date().toLocaleTimeString());
    } catch (e) { setErr(e.message); } finally { setBusy(false); }
  };

  if (!cfg) return <Loader />;

  return (
    <div className="space-y-6">
      <header>
        <div className="text-[11px] font-bold uppercase tracking-widest text-brand-700">auth</div>
        <h1 className="serif text-4xl">Firebase phone auth</h1>
        <p className="text-sm text-ink-3 mt-2 max-w-2xl">
          Per-instance Firebase configuration. The mobile app fetches the public
          keys at runtime and uses Firebase to send and verify SMS OTPs. The
          backend uses the service account to verify the resulting ID tokens.
          {' '}<a href="https://console.firebase.google.com" target="_blank" className="text-brand-700 font-bold">Firebase console ↗</a>
        </p>
      </header>

      <form onSubmit={save} className="space-y-4">
        <Card>
          <div className="flex items-center justify-between">
            <CardHeader title="Enabled" subtitle="Turn this on once the keys below are filled in" />
            <label className="inline-flex items-center gap-2 cursor-pointer">
              <input type="checkbox" checked={!!cfg.enabled} onChange={(e) => set('enabled', e.target.checked)} className="w-5 h-5 accent-[#22C55E]" />
              <span className="text-sm font-bold">{cfg.enabled ? 'On' : 'Off'}</span>
            </label>
          </div>
        </Card>

        <Card>
          <CardHeader title="Public web config" subtitle="Project settings → General → Your apps → Web/Android app" />
          <div className="grid grid-cols-2 gap-4 mt-3">
            <Field label="Web API key (apiKey)" value={cfg.apiKey} onChange={(v) => set('apiKey', v)} />
            <Field label="App ID (appId)" value={cfg.appId} onChange={(v) => set('appId', v)} />
            <Field label="Project ID" value={cfg.projectId} onChange={(v) => set('projectId', v)} />
            <Field label="Messaging sender ID" value={cfg.messagingSenderId} onChange={(v) => set('messagingSenderId', v)} />
            <Field label="Android package" value={cfg.androidPackageName} onChange={(v) => set('androidPackageName', v)} />
            <Field label="iOS bundle ID" value={cfg.iosBundleId} onChange={(v) => set('iosBundleId', v)} />
            <Field label="iOS app ID" value={cfg.iosAppId} onChange={(v) => set('iosAppId', v)} />
          </div>
        </Card>

        <Card>
          <CardHeader title="Service account (private)" subtitle="Project settings → Service accounts → Generate new private key" />
          <div className="mt-3">
            {cfg.hasServiceAccount && serviceAccount.length === 0 && (
              <div className="text-xs bg-brand-25 border border-brand-50 text-brand-700 rounded-lg px-3 py-2 mb-3 inline-block font-bold">
                ✓ Service account already stored
              </div>
            )}
            <textarea
              value={serviceAccount}
              onChange={(e) => setServiceAccount(e.target.value)}
              rows={10}
              placeholder={cfg.hasServiceAccount ? 'Paste a new JSON to replace the stored one (or leave blank to keep it)' : 'Paste the full Firebase service-account JSON here…'}
              className="w-full font-mono text-xs rounded-lg border border-line bg-white px-3 py-2 focus:outline-none focus:border-brand"
            />
            <p className="text-[11px] text-ink-3 mt-2">Stored server-side and never returned to the browser. The backend reuses the stored copy if you leave this blank.</p>
          </div>
        </Card>

        {err   && <div className="text-xs text-rose-700 bg-rose-50 border border-rose-100 rounded-lg px-3 py-2">{err}</div>}
        {saved && <div className="text-xs text-brand-700 bg-brand-50 border border-brand-50 rounded-lg px-3 py-2">Saved at {saved}</div>}

        <div className="flex items-center justify-end gap-3">
          <button type="button" onClick={load} className="px-4 py-2 rounded-lg border border-line text-sm font-bold">Reload</button>
          <button disabled={busy} className="bg-brand text-white px-5 py-2.5 rounded-lg text-sm font-bold shadow-sm shadow-brand/40 disabled:opacity-60">
            {busy ? 'Saving…' : 'Save changes'}
          </button>
        </div>
      </form>

      <Card>
        <CardHeader title="Quickstart" />
        <ol className="list-decimal pl-5 text-sm space-y-2 mt-3 text-ink-2">
          <li>Create a Firebase project, enable <b>Phone</b> sign-in under Authentication → Sign-in method.</li>
          <li>Add an Android app with package <code className="font-mono text-xs">{cfg.androidPackageName || 'com.vacado.app'}</code> and your SHA-1 / SHA-256. Add an iOS app with the bundle ID above.</li>
          <li>Copy the <b>web</b> Firebase config (apiKey, appId, projectId, messagingSenderId) into the fields above.</li>
          <li>Generate a service-account JSON and paste it below.</li>
          <li>Flip <b>Enabled</b> on, save, and the mobile app starts using Firebase phone auth instantly.</li>
        </ol>
      </Card>
    </div>
  );
}

// ─── Generic UI ────────────────────────────────────────
function Card({ children, className = '', noPad = false }) {
  return <div className={cls('bg-white rounded-2xl border border-line-2', noPad ? '' : 'p-5', className)}>{children}</div>;
}
function CardHeader({ title, subtitle }) {
  return <div><div className="flex items-end justify-between"><h3 className="font-bold text-ink">{title}</h3>{subtitle && <div className="text-xs text-ink-3">{subtitle}</div>}</div></div>;
}
function Field({ label, value, onChange, type = 'text', required, multiline }) {
  return (
    <label className="block">
      <span className="text-[10px] font-bold uppercase tracking-wide text-ink-3">{label}</span>
      {multiline
        ? <textarea value={value} onChange={(e) => onChange(e.target.value)} rows={3} className="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-sm focus:outline-none focus:border-brand" />
        : <input value={value} onChange={(e) => onChange(e.target.value)} type={type} required={required} className="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-sm focus:outline-none focus:border-brand" />}
    </label>
  );
}
function Select({ label, value, onChange, options }) {
  return (
    <label className="block">
      <span className="text-[10px] font-bold uppercase tracking-wide text-ink-3">{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)} className="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-sm focus:outline-none focus:border-brand">
        {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </label>
  );
}
function Checkbox({ label, value, onChange }) {
  return (
    <label className="flex items-center gap-2 select-none cursor-pointer">
      <input type="checkbox" checked={value} onChange={(e) => onChange(e.target.checked)} className="w-4 h-4 accent-[#22C55E]" />
      <span className="text-sm font-semibold text-ink-2">{label}</span>
    </label>
  );
}
function KV({ label, value, mono }) {
  return <div><div className="text-[10px] font-bold uppercase tracking-wide text-ink-3">{label}</div><div className={cls('font-semibold', mono && 'font-mono text-xs break-all')}>{value || '—'}</div></div>;
}
function Loader() { return <div className="text-ink-3 text-sm py-8 text-center">Loading…</div>; }
function Empty({ label }) { return <div className="bg-white border border-line-2 rounded-2xl p-12 text-center text-ink-3 text-sm">{label}</div>; }
function ErrorBox({ msg }) { return <div className="bg-rose-50 border border-rose-100 text-rose-700 rounded-2xl p-4 text-sm">{msg}</div>; }

// ─── Root ──────────────────────────────────────────────
function Root() {
  const { admin, loaded } = useAuth();
  if (!loaded) return <Loader />;
  return admin ? <Shell /> : <Login />;
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <AuthProvider><Root /></AuthProvider>
);
