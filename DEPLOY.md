# SnapBee — Production Deploy Checklist

Covers the four buildable Flutter-web apps:

| App | Actor | `.env` required | Behaviour if `.env` missing |
|---|---|---|---|
| `snapbee_customer_app` | Customers | **No** — URL + publishable key are in `lib/main.dart` | n/a |
| `snapbee_vendor` | Vendors | **Yes** (bundled asset) | Silently falls back to in-memory **mock** repositories |
| `snapbee_delivery` | Delivery partners | **Yes** (bundled asset) | **Hard crash on startup** (blank page) — `dotenv.env['SUPABASE_URL']!` |
| `snapbee_admin` | Platform admins | **Yes** (bundled asset) | Boots with empty credentials → all Supabase calls fail |

All apps point at the **same** Supabase project: `zhdhkvoxkdmsuiyehgsw` (`https://zhdhkvoxkdmsuiyehgsw.supabase.co`).

---

## 1. `.env` setup

`vendor`, `delivery`, and `admin` each load `.env` via `flutter_dotenv` and declare it as an asset in `pubspec.yaml`, so **`flutter build web` bakes `.env` into the deployed bundle**. It is `.gitignore`d, so a fresh `git clone` has no `.env` — CI/deploy must create it before building.

### Steps (per app: `snapbee_vendor`, `snapbee_delivery`, `snapbee_admin`)

1. `cp .env.example .env` (vendor has no example — create `.env` with the three keys below).
2. Fill in:

   ```dotenv
   SUPABASE_URL=https://zhdhkvoxkdmsuiyehgsw.supabase.co
   SUPABASE_ANON_KEY=<publishable / anon key for the prod project>
   APP_ENV=production
   ```

3. **`APP_ENV=production`** — every checked-in example currently says `development`.
4. Confirm `.env` exists on disk immediately before `flutter build web`.

### Hard rules

- **Never** put `SUPABASE_SERVICE_ROLE_KEY` (or any secret) in `.env` — it is a client asset and ships to every browser. Only the publishable/anon key belongs there; RLS is the security boundary.
- `snapbee_customer_app` has its URL + publishable key hardcoded in `lib/main.dart` — update there if the project ever changes; it does not read `.env`.

---

## 2. Build

Per app:

```bash
flutter pub get
flutter analyze          # must report: No issues found!
flutter test             # must report: All tests passed
flutter build web        # output: build/web/
```

Last verified green (all four): analyze 0 issues; tests 65 / 73 / 173 / 334 pass; web builds succeed.

---

## 3. Database seeding (Supabase, prod project)

The apps build and run without this data, but core flows are dead until it exists.

- [ ] **`vehicles`** — must have ≥1 row. Delivery dispatch matching is an inner join on `vehicles`; with 0 rows **no delivery is ever assigned**.
- [ ] **`vendor_branches`** — ≥1 row per active vendor, exactly one with `is_primary = true`. Customer checkout (`place_customer_order`) resolves a single branch; vendors with no branch cannot receive orders.
- [ ] **Admin settings tables** — seed one row in each; an *empty* table makes the Admin app silently show mock settings:
  - [ ] `app_settings`
  - [ ] `admin_profile_settings`
  - [ ] `notification_settings`
  - [ ] `security_settings`
  - [ ] `system_info`
- [ ] **`admin_notifications`** — confirm the table/RPC is live, or the Admin notification bell stays disabled ("coming soon").
- [ ] At least one real record per actor to smoke-test: a customer account, an approved vendor + product, a delivery partner (freelance and salaried), an admin account with a role granting the permissions under test.

---

## 4. Backend verification (cannot be checked from client code)

- [ ] All migrations in `supabase/*.sql` (each app) applied to the **prod** project — verify against prod, not staging.
- [ ] RLS smoke test per role: sign in as each actor and confirm they can do exactly what they should and nothing more (customer can't read other customers' orders, vendor only sees own branch, etc.).
- [ ] RPCs callable by the intended role only: `place_customer_order`, `cancel_customer_order`, `create_service_booking`, `assign_delivery_manually`, `complete_delivery`, `record_cod_collection`, inventory/location RPCs.
- [ ] `SECURITY DEFINER` functions are not grantable to arbitrary `authenticated` users.

---

## 5. Per-app end-to-end smoke test (real accounts, prod)

- [ ] **customer_app** — sign up / sign in → browse → add to cart → checkout (COD) → order appears in Orders → cancel.
- [ ] **vendor** — sign in → see the order → accept → advance status → confirm customer + delivery see the update.
- [ ] **delivery** — sign in (freelance *and* salaried) → claim/receive task → advance to delivered → COD collection recorded.
- [ ] **admin** — sign in → each module loads real data (not mock) → vendor approve/reject → a CRUD write in one module round-trips.

---

## 6. Known-incomplete (intentional — not blockers)

- customer_app Profile: wallet top-up, Coupons, Rewards, Referrals, in-app Support, saved-address management, Settings/Help/About are `_comingSoon()` stubs. Forgot-password and Google login too. Checkout is **COD-only** (prepaid disabled).
- admin: global cross-module search bar is deliberately disabled.
- `PlaceholderScreen` widget class is defined-but-unused in vendor and delivery (dead code).

## 7. Recommended before launch (non-blocking)

- [ ] Wire a crash/error reporting sink — uncaught errors currently have no destination in any app.
- [ ] Add a `go_router` `errorBuilder` to `delivery` and `admin` so an unknown deep link shows a branded page instead of go_router's default.
