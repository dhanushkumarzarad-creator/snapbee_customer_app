# SnapBee Travel & Entertainment Sectors — Architecture

Companion to [`SERVICES_ARCHITECTURE.md`](SERVICES_ARCHITECTURE.md). Travel and
Entertainment are two more independent SnapBee business verticals, built the
same way Services was: own apps, own tables, own RPCs, own settlement/
cancellation logic. Nothing here is copy-pasted business logic from Daily
Essentials, Services, or Delivery — only genuinely shared infrastructure
(Supabase project, auth, payment gateway plumbing, storage, the
`has_permission`/`table_module_map` RLS primitive, `notify_customer`) is
reused.

## Phase 0 audit findings (2026-09-01)

- Monorepo has 12 app directories under `02_Flutter_Apps/`. `snapbee_travel`
  and `snapbee_entertainment` already exist as directories but are **empty**
  (0 files, not even `flutter create`d) — confirmed by direct listing, not
  assumed from memory.
- Established multi-app-per-vertical precedent: Services shipped as 5 apps
  (`snapbee_customer_app` sector tab + `snapbee_services_vendor` +
  `snapbee_services_technician` + `snapbee_services_inspector` +
  `snapbee_services_admin`), each independently `flutter create`d, none
  importing another vertical's code.
- Single shared Postgres/Supabase project (`zhdhkvoxkdmsuiyehgsw`). Every
  vertical's DDL lives in one file inside `snapbee_admin/supabase/` —
  established convention regardless of which app consumes the schema
  (`services_module_v2.sql` is 2493 lines, owned there, consumed by 5 apps).
- `table_module_map` + `has_permission(module, action)` + the RLS-generator
  `do $$ ... $$` block in `schema.sql` is the authorization primitive every
  module (including `services`) plugs into. New modules just need rows
  inserted into `table_module_map` with `module = 'travel'` /
  `module = 'entertainment'` — the generator picks them up automatically.
- Actor-table pattern (reused for every provider-side identity):
  `auth_user_id uuid unique references auth.users(id)` +
  `current_<actor>_id()` SECURITY DEFINER helper, e.g.
  `current_service_vendor_id()`. Travel/Entertainment provider actors follow
  the identical shape.
- Booking-ID convention: `id text primary key default ('PREFIX-' ||
  lpad(nextval('some_seq')::text, N, '0'))` — used for `ORD-####` and
  `SVC-####`. Travel/Entertainment reuse this exact mechanism for
  `TRV-######`, `HTL-######`, `MOV-######`, `EVT-######`, `AMP-######`.
- `notify_customer(customer_id, type, title, message, action_route,
  image_url)` is the one write path into `customer_notifications` — reused
  as-is; its `type` check constraint is widened (not replaced) to admit
  `'travel'` and `'entertainment'`.
- Customer App Home currently lists sectors as tabs
  (`ServiceTabsWidget`/equivalent); Daily Essentials (`Food`/`Grocery`) and
  `Services` are wired. Travel and Entertainment are added as two more
  sibling tabs — new folders, not modifications to the existing tab
  widgets' Food/Grocery/Services branches.
- pg_cron is already active in this project (`services_scheduled_jobs.sql`,
  `delivery_dispatch_cron.sql`) — reused for the movie seat-lock expiry
  sweep and for settlement generation, exactly like Delivery's dispatch tick
  and Services' settlement generator.

## App boundaries

| App | Role | Actor table |
|---|---|---|
| `snapbee_customer_app` (existing) | Travel + Entertainment are two more sector tabs (`lib/features/travel/`, `lib/features/entertainment/`) | `customers` (shared identity) |
| `snapbee_travel` | Travel Provider app — rental vendor + driver (freelance or vendor-managed) + hotel-owner surface | `travel_vendors`, `travel_drivers` |
| `snapbee_travel_admin` | Travel sector administration | `admin_profiles` (shared platform RBAC) |
| `snapbee_entertainment` | Entertainment Provider app — theatre manager / event organizer / amusement-park operator | `entertainment_providers` |
| `snapbee_entertainment_admin` | Entertainment sector administration | `admin_profiles` |

`snapbee_travel` and `snapbee_entertainment` (the two pre-existing empty
directories) are claimed as the **provider** apps, not customer-facing —
consistent with how `snapbee_vendor` (not a new customer app) was the
Daily-Essentials provider app. `snapbee_travel_admin` and
`snapbee_entertainment_admin` are new apps, mirroring why
`snapbee_services_admin` is separate from `snapbee_admin`: different data
model (bookings/inventory/settlement rules), different module scope in
`role_permissions`, and "where does this code live" must stay a
one-folder answer.

## Database boundaries

Two files in `snapbee_admin/supabase/`, each self-contained:

- **`travel_module.sql`** — `travel_*` (vehicle types, vendors, drivers,
  vehicles, pricing rules, bookings, extra-charge audit, cancellation
  policies, payments, refunds, commission rules, settlements, quality
  flags, AI analysis log) + `hotel_*` (hotels, rooms, per-date inventory,
  bookings). Module tag in `table_module_map`: `'travel'`.
- **`entertainment_module.sql`** — `entertainment_*` (providers, quality
  flags, cancellation policies, payments, refunds, commission, settlements,
  AI analysis log) + `movie_*` (theatres, screens, seat layout, movies,
  shows, per-show seat status with the 5-minute lock, bookings) +
  `event_*` (events, ticket types, bookings) + `amusement_*` (parks, ticket
  types, bookings). Module tag: `'entertainment'`.

Neither file touches `orders`, `order_items`, `vendors`, `products`,
`service_*`, or `delivery_*` tables. The only cross-references are to
shared identity/infrastructure: `auth.users`, `customers`,
`customer_notifications`/`notify_customer`, `admin_profiles`,
`table_module_map`, `has_permission`.

## Extension points (deliberately not built now)

- Travel: `travel_transport_providers` is designed as a `mode` enum column
  (`'vehicle_rental'` today) on a `travel_bookings.mode` — bus/train/flight
  can be added as new `mode` values + new pricing/seat tables later without
  touching the rental/hotel tables.
- Entertainment provider abstraction: every movie/hotel booking carries a
  `source` column (`'SNAPBEE' | 'EXTERNAL_PROVIDER'`) plus a
  `provider_ref jsonb` free-form column for whatever a future real external
  API needs to store — no external API is wired now (none exists to wire;
  fabricating one would violate "do not fabricate provider availability").

## What "AI" means here (same posture as Services)

Deterministic SQL rule-evaluators, not an LLM call, logging to
`travel_ai_analyses` / `entertainment_ai_analyses` — recommendation/
analysis only, `SECURITY DEFINER` with `authenticated` execute revoked
(only reachable from admin-owned RPCs), never touching settlement/payment
tables directly. Same shape as `services_ai_agent_architecture.sql`, scaled
down to what Travel/Entertainment actually need at launch (no 8-agent/
24-worker hierarchy — that was sized for Services' much larger booking
lifecycle).
