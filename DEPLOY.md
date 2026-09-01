# SnapBee — Production Launch Checklist

Covers the four buildable Flutter-web apps. All point at the **same** Supabase project:
`zhdhkvoxkdmsuiyehgsw` (`https://zhdhkvoxkdmsuiyehgsw.supabase.co`).

| App | Actor | `.env` required | Behaviour if `.env` missing |
|---|---|---|---|
| `snapbee_customer_app` | Customers | **No** — URL + publishable key are in `lib/main.dart` | n/a |
| `snapbee_vendor` | Vendors | **Yes** (bundled asset) | Silently falls back to in-memory **mock** repositories |
| `snapbee_delivery` | Delivery partners | **Yes** (bundled asset) | **Hard crash on startup** (blank page) — `dotenv.env['SUPABASE_URL']!` |
| `snapbee_admin` | Platform admins | **Yes** (bundled asset) | Boots with empty credentials → all Supabase calls fail |

Last full audit: **2026-08-31** (see `[[project_snapbee_prod_readiness_audit_2026_08_31]]` in the
Claude memory store). Sections below reflect live inspection of the production project on that date.

---

## 0. Per-app status (2026-08-31)

All four: `flutter analyze` 0 issues · `flutter test` 645 pass (65 / 73 / 173 / 334), 0 fail / 0 skip ·
`flutter build web` ✅. All on GitHub (private, `dhanushkumarzarad-creator`), `master` in sync.

### `snapbee_customer_app` — code-ready; ships as a COD-only shopping app
- Navigator-based routing; auth gate via `StreamBuilder` on Supabase auth state — no lockout/loop.
- Real end-to-end: signup/login, home/catalog, cart, checkout (`place_customer_order`), orders list,
  cancel (`cancel_customer_order`), wishlist, order history, Services sector.
- No `.env` — URL + publishable key inlined in `lib/main.dart` (correct).
- Intentional gaps (need product sign-off, not code): COD only; no Google login; no forgot-password;
  Profile menu stubs — wallet top-up, Coupons, Rewards, Referrals, in-app Support, saved-address
  management, Settings, Help, About.

### `snapbee_vendor` — code-ready; blocked only by deploy-time `.env` + real vendor data
- `go_router` (mobile bottom-nav shell / web sidebar) with auth-redirect gate — every route maps to
  a real screen.
- 13 repositories wired to Supabase at the composition root when `.env` is present; falls back to
  in-memory mocks if `.env` is missing (no crash, but not production).
- Real: onboarding + self-registration → admin approval, orders (accept/reject/advance), catalog,
  inventory, earnings, club/commission, delivery assignment, documents, notifications, support,
  business profile/location.
- Dead code: unused `PlaceholderScreen` class (harmless).

### `snapbee_delivery` — code-ready, highest test coverage; two operational gaps
- `go_router` with auth redirect; service-provider sub-module has its own auth.
- 11 repositories hard-overridden to Supabase at the composition root. Hard-crashes on startup
  (blank page) if `.env` is missing — `dotenv.env['SUPABASE_URL']!`.
- Real: login (freelance + salaried), tasks/job details, claim/receive, status advance,
  proof-of-delivery, COD collection + settlement, live location upload, earnings, support.
- Automated dispatch is inert: `select_best_candidate` INNER-JOINs `vehicles` +
  `delivery_partner_locations`, both empty in prod. Manual assignment (`assign_delivery_manually`,
  from vendor/admin) works now and does not touch those tables; auto-dispatch activates as real
  partners onboard (vehicle assigned → go Online → GPS pings).
- Dead code: unused `PlaceholderScreen` class.

### `snapbee_admin` — code-ready; the mature reference app; blocked only by deploy-time `.env`
- `go_router` sidebar shell, permission-gated. Leftover `[DIAG]` diagnostics block removed from
  `main.dart` (`0150cca`).
- All modules load real Supabase data; per-repo mock fallback only fires on a genuinely-missing
  table (`42P01`), every other error rethrows — effectively dead code (all tables exist).
- Boots with empty credentials if `.env` is missing → all Supabase calls fail.
- Intentional: global cross-module search bar disabled; in-app notification bell auto-disables
  unless `admin_notifications` is confirmed live.

### Backend — Supabase `zhdhkvoxkdmsuiyehgsw`
- RLS enabled on every core/sensitive table with real (non-`true`) policies; no `PUBLIC` grants;
  `anon` SELECT limited to 6 catalog tables.
- `TRUNCATE` / `REFERENCES` / `TRIGGER` revoked from `anon` + `authenticated` on all public tables
  (`supabase/revoke_truncate_from_client_roles.sql`, `d6c48ba`) — verified 0 remain, DML + service_role
  untouched.
- Settings tables + delivery config/pricing/capacity rules seeded; all 15 AI-hardening migrations
  applied + verified (2026-08-28).
- Not production-ready: data is test/demo only (1 usable vendor `Local Store`; `sss` / `vfvf` /
  Demo A/B junk; 4 of 5 vendors have no branch; `vehicles` = 0; `delivery_partner_locations` = 0).
  Auth dashboard config (URLs / SMTP / backups) not verified. `supabase_admin`-owned default
  privileges + `MAINTAIN` residuals remain (see §2).

---

## 1. MUST DO BEFORE LAUNCH

### 1.1 — Provision `.env` in the deploy build for every dotenv app
`.env` is gitignored and bundled as a Flutter asset. A fresh clone has none — `delivery` hard-crashes
without it, `vendor` falls back to mock repos, `admin` boots with empty credentials, and each of the
four Services provider apps boots with an empty Supabase URL/key (Supabase never initializes; every
screen shows its error state).

**Seven apps read `.env`** (`snapbee_customer_app` does NOT — its values are inlined in `lib/main.dart`,
which is correct and needs no action):

| App | `.env` path (sibling of `pubspec.yaml`) | `.env.example` committed |
|---|---|---|
| `snapbee_admin` | `snapbee_admin/.env` | yes |
| `snapbee_vendor` | `snapbee_vendor/.env` | yes |
| `snapbee_delivery` | `snapbee_delivery/.env` | yes |
| `snapbee_services_admin` | `snapbee_services_admin/.env` | yes |
| `snapbee_services_vendor` | `snapbee_services_vendor/.env` | yes |
| `snapbee_services_technician` | `snapbee_services_technician/.env` | yes |
| `snapbee_services_inspector` | `snapbee_services_inspector/.env` | yes |

**Steps** — in the CI/deploy job, *before* `flutter build web`, write each `.env` above containing
exactly:

```dotenv
SUPABASE_URL=https://zhdhkvoxkdmsuiyehgsw.supabase.co
SUPABASE_ANON_KEY=sb_publishable_6CT-UQ0hog6b4Y9oOEljSw_LMH3V3D5
APP_ENV=production
```

(Every app's `.env.example` is exactly this shape with `APP_ENV=development` — `cp .env.example .env`
then flip `APP_ENV`.) Then build. **Verify:** `build/web/assets/.env` in each output shows
`APP_ENV=production`. **Never** put a `service_role`/secret key in `.env` — it ships to every browser.
The `SUPABASE_ANON_KEY` above is the *publishable* key; RLS is the security boundary.

- [ ] `snapbee_admin/.env`
- [ ] `snapbee_vendor/.env`
- [ ] `snapbee_delivery/.env`
- [ ] `snapbee_services_admin/.env`
- [ ] `snapbee_services_vendor/.env`
- [ ] `snapbee_services_technician/.env`
- [ ] `snapbee_services_inspector/.env`

### 1.2 — Configure Supabase Auth URL settings for the deployed domains
Not verified in the audit. Auth email links / session redirects break if the deployed origins aren't
registered.

**Steps** — Dashboard → project `zhdhkvoxkdmsuiyehgsw`:
1. **Authentication → URL Configuration → Site URL** = deployed customer-app URL.
2. **Redirect URLs** — add the deployed URL of **all eight apps**, each with `/**`:
   customer app, admin, vendor, delivery, Services admin, Services vendor,
   Services technician, Services inspector. (Every app authenticates against the
   same project; any app whose origin is not listed will fail its auth callback.)
3. **Authentication → CORS / allowed origins** — add each deployed origin.
4. **Authentication → Providers → Email** — confirm "Confirm email" matches the intended flow.

- [ ] Site URL set
- [ ] Redirect URLs added for all 8 apps
- [ ] Allowed origins added for all 8 apps
- [ ] Email-confirmation setting confirmed

### 1.3 — Replace the default auth email sender (custom SMTP)
Not verified. Supabase's built-in SMTP is rate-limited to a few messages/hour and will block real
signup/reset traffic.

**Steps** — Dashboard → **Authentication → Emails / SMTP Settings** → enter a real provider
(SendGrid / SES / Postmark): host, port, username, password, sender address. Send a test.

- [ ] Custom SMTP configured and test email received

### 1.4 — Load real vendor + branch data
Prod has **1** usable vendor (`Local Store`, has a primary branch). `SnapBee Demo Vendor A`/`B`,
`sss`, `vfvf` have **zero** branches. `place_customer_order` resolves exactly one branch — a vendor
with no `is_primary` branch (with coordinates) cannot receive any order.

**Steps** — Admin panel, for every launch vendor:
1. **Vendors** → confirm the vendor exists, status = Active (approve if pending).
2. Open vendor → **Branches** → **Add Branch**: name, address, city, district, pincode,
   **latitude**, **longitude** (non-null), opening/closing time, status = **Active**.
3. Mark exactly **one** branch **Set as primary**.
4. Verify each launch vendor ends with `branches ≥ 1`, `primary = 1`.

- [ ] Every launch vendor has an active primary branch with coordinates

### 1.5 — Remove test / junk data from production
Prod holds only demo/test rows: 5 vendors incl. `sss` / `vfvf`, 2 demo delivery partners
(`salaried.demo`, `freelance.demo`), 2 demo orders, 1 test customer.

**Steps** — Admin panel (do this **after** 1.4):
1. **Vendors** → delete `sss`, delete `vfvf`.
2. Decide on `SnapBee Demo Vendor A`/`B` and the two `*.demo@snapbee.app` delivery partners —
   keep intentionally for staff testing, or delete them and their demo orders.
3. **Orders** → delete `Demo Customer — Pool Order` and `Demo Customer — Salaried Assigned` if the
   demo vendors/partners were removed.

- [ ] Junk vendors `sss` / `vfvf` deleted
- [ ] Demo vendors / partners / orders resolved (kept-for-testing or deleted)

### 1.6 — Live RLS verification with real signed-in accounts
Read-only inspection confirmed RLS is enabled everywhere with real (non-`true`) conditions, but
**cannot** confirm each policy is semantically correct (cross-tenant isolation).

**Steps** — on the deployed apps, two real accounts per role:
1. **Customers:** Customer A places an order. Sign in as Customer B → B must see none of A's orders.
   Confirm in DevTools → Network (or `curl` with B's token) that the `orders` request returns only
   B's rows.
2. **Vendors:** A and B each with a branch + product. A sees only its own branch's orders; editing
   B's product via the app must fail.
3. **Delivery partner:** sees only their assigned + eligible pool tasks.
4. **Admin:** sign in with a **view-only** role → write actions must be rejected.

Record pass/fail per check. Any failure is a launch blocker.

- [ ] Customer ↔ customer isolation verified
- [ ] Vendor ↔ vendor isolation verified
- [ ] Delivery-partner task scoping verified
- [ ] Admin limited-role write-block verified

### 1.7 — Sign off on the intentional launch-scope limits
Deliberate, but need a recorded product decision:
- Checkout is **COD only** (prepaid disabled).
- No Google login, no forgot-password (customer app).
- Customer Profile items are non-functional stubs: wallet top-up, Coupons, Rewards, Referrals,
  in-app Support, saved-address management, Settings, Help, About.
- Admin global search bar is disabled.
- Admin in-app notification bell stays disabled unless `admin_notifications` is live
  (verify: SQL editor → `select to_regclass('public.admin_notifications');` → non-null = fine).

- [ ] Product/stakeholder sign-off on the above

### 1.8 — Backups / PITR
Not verified. **Steps** — Dashboard → **Settings → Database → Backups**: confirm daily backups on;
enable PITR if the plan supports it.

- [ ] Backups confirmed / PITR enabled

### 1.9 — Final build gate (run against the exact deploy commit)
Per app: `flutter pub get && flutter analyze && flutter test && flutter build web` — all clean.
Green as of 2026-08-31 (645 tests: 65 / 73 / 173 / 334).

- [ ] All four apps: analyze 0, tests pass, web build succeeds

---

## 2. SAFE TO DO AFTER LAUNCH

- **Delivery auto-dispatch** — `vehicles` and `delivery_partner_locations` are empty, so
  `run_dispatch_tick` matches nobody. Resolves organically as real partners onboard (register →
  vehicle assigned → go Online → GPS pings). **Manual assignment works today**
  (`assign_delivery_manually`, from vendor/admin) and covers the gap. No pre-seeding needed.
- **`MAINTAIN` privilege** still held by `anon`/`authenticated` on `postgres`-owned tables
  (VACUUM/ANALYZE/LOCK — low risk): `revoke maintain on all tables in schema public from anon, authenticated;`
- **`supabase_admin` default-privileges residual** — a future *dashboard/extension-created* table
  would re-grant TRUNCATE/REFERENCES/TRIGGER to client roles. Re-run
  `revoke truncate, references, trigger on all tables in schema public from anon, authenticated;`
  after adding any such table.
- **Crash/error reporting** — wire Sentry/Crashlytics into all four apps.
- **`go_router` `errorBuilder`** for `delivery` + `admin` (branded 404).
- **Dead code** — remove the unused `PlaceholderScreen` class in `vendor` and `delivery`.
- **SECURITY DEFINER RPC exposure review** (defense in depth).
- **Dependency updates** — 32–42 packages per app have newer versions behind constraints.
- **Feature backlog** — prepaid payments, social login, forgot-password, customer
  wallet/coupons/rewards/referrals/support, admin global search, admin notifications, richer catalog.

---

## 3. ALREADY VERIFIED (2026-08-31 audit — no action needed)

**Build & code**
- `flutter analyze`: 0 issues, all four apps.
- `flutter test`: 645 pass (customer 65, vendor 73, delivery 173, admin 334), 0 fail / 0 skip.
- `flutter build web`: succeeds for all four (Wasm dry-run clean).
- Auth gates + routing sound; every route resolves to a real screen; no redirect lockout/loop.
- No secrets in any `lib/`; no raw `print()`; no `http://` / `localhost`.
- All Supabase RPC wiring is real (`place_customer_order`, `create_service_booking`,
  `assign_delivery_manually`, `complete_delivery`, COD / inventory / location RPCs).
- Removed the leftover `[DIAG]` block from `snapbee_admin/lib/main.dart` (`0150cca`).
- All four apps on GitHub (private, `dhanushkumarzarad-creator`), `master` in sync.

**Config**
- All three dotenv apps' `.env` (and `customer_app`'s hardcoded values) already point at production
  `zhdhkvoxkdmsuiyehgsw` with the publishable key. Only `APP_ENV` label differs — it is read nowhere
  that affects behaviour (`snapbee_admin`'s `EnvConfig.isProduction` is defined but unused; `vendor`
  and `delivery` never read `APP_ENV`).

**Database — seeding**
- `app_settings`, `notification_settings`, `security_settings`, `system_info` — 1 row each
  (self-seeded by `schema.sql`). `admin_profile_settings` is a **view**, not a table.
- `delivery_config` (1), `vehicle_capacity_rules` (2), `delivery_pricing_rules` (3) — seeded; the
  delivery quote engine is functional.
- All 15 AI-hardening / event-routing migrations applied + verified on prod (2026-08-28).

**Database — RLS & grants (live inspection)**
- RLS enabled on every core/sensitive table with real policies (orders 10, customers 7, vendors 7,
  products 8, vehicles 5, delivery_partners 7, delivery_assignments 7, vendor_branches 6,
  commission_rates 5, cod_collections 6, vendor_bank_details 5, payouts 4, admin_profiles 3,
  settings tables 2 each).
- No unconditional `USING (true)` DELETE/UPDATE/SELECT policy on any of 14 sensitive tables.
- No `PUBLIC` table grants. `anon` SELECT limited to 6 catalog tables; no anon read on
  orders/customers/vendors/finance.
- `settings_authenticated_grants.sql` applied — `authenticated` has UPDATE on `app_settings` +
  `admin_profiles`; `notification_settings` / `security_settings` correctly SELECT-only.
- **`TRUNCATE` / `REFERENCES` / `TRIGGER` revoked from `anon` + `authenticated` on all public
  tables** (`supabase/revoke_truncate_from_client_roles.sql`, commit `d6c48ba`, applied + verified):
  0 such grants remain; all SELECT/INSERT/UPDATE/DELETE grants unchanged; `service_role` untouched;
  future `postgres`-owned tables no longer auto-grant them.

---

## Appendix A — `.env` file reference

`vendor`, `delivery`, `admin` load `.env` via `flutter_dotenv` and declare it as a `pubspec.yaml`
asset, so `flutter build web` bakes it into the bundle. `.env.example` exists for `delivery` and
`admin` only (not `vendor`).

| Key | Value |
|---|---|
| `SUPABASE_URL` | `https://zhdhkvoxkdmsuiyehgsw.supabase.co` |
| `SUPABASE_ANON_KEY` | `sb_publishable_6CT-UQ0hog6b4Y9oOEljSw_LMH3V3D5` (publishable — safe to ship) |
| `APP_ENV` | `production` for deploys; keep committed `.env.example` at `development` |

Staging project (do **not** use for production): `ycvtiizukzaindrpcpie`, key
`sb_publishable_ZjL2SDjtn-aw_CullEf_hw_-TKC3N-G` — see `snapbee_admin/.env.staging`.

## Appendix B — Build commands

Per app:

```bash
flutter pub get
flutter analyze          # must report: No issues found!
flutter test             # must report: All tests passed
flutter build web        # output: build/web/
```
