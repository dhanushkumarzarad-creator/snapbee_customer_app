# SnapBee Services Sector — Architecture

This document is the map for finding (and correctly placing) any piece of the
Home Services sector across the monorepo. It exists so a future
developer/agent never has to guess where a Services feature belongs or
re-derive the app/database boundaries from scratch.

**Deploying?** See [`DEPLOY.md`](DEPLOY.md) — per-app `.env` setup,
`APP_ENV=production`, build steps, and the database-seeding / RLS-verification
checklist. It is written against the four Daily Essentials apps
(`snapbee_customer_app`, `snapbee_vendor`, `snapbee_delivery`,
`snapbee_admin`); the Services apps share the same Supabase project and the
same `flutter_dotenv` `.env`-as-bundled-asset pattern, so the same steps
apply per app.

## App boundaries

Services is a separate business vertical from Daily Essentials. It has its
own five apps under `02_Flutter_Apps/`, each independently `flutter create`d
(own `pubspec.yaml`, own `.env`, own tests) — none of them import from or
write into `snapbee_admin`, `snapbee_vendor`, `snapbee_delivery`, or
`snapbee_customer_app`'s Daily Essentials code:

| App | Role | Actor table it authenticates against |
|---|---|---|
| `snapbee_customer_app` (existing) | Common customer app — Services is one sector tab among several (`lib/features/services/`) | `customers` |
| `snapbee_services_vendor` | Business/Service-Center provider app | `service_vendors` |
| `snapbee_services_technician` | Independent Technician app | `service_technicians` |
| `snapbee_services_inspector` | Inspector app (a genuinely separate app, not folded into Technician — see note below) | `service_inspectors` |
| `snapbee_services_admin` | Services sector administration — separate from `snapbee_admin` (Daily Essentials admin), on purpose | `admin_profiles` (shared platform RBAC) |

**Why five separate apps and not tabs bolted onto existing apps:** the
Daily Essentials Vendor app (`snapbee_vendor`) and Daily Essentials Admin
Panel (`snapbee_admin`) are a different business vertical with a different
data model (orders, not bookings; vendors selling products, not businesses
dispatching technicians). Mixing the two would violate the actor model
(`service_vendors`/`service_technicians`/`service_inspectors` are distinct
identities from `vendors`/`delivery_partners`) and make it impossible to
answer "where does Services code live" with a single, confident folder path.

An earlier pass of this build did add Services screens directly into
`snapbee_admin` — that was reverted. `snapbee_admin`'s own git history no
longer references `services` anywhere (`AppRoutes`, `ModuleNames`,
`nav_items`, `app_sidebar` are all back to Daily-Essentials-only).

**Inspector note:** Inspector could plausibly have been a role/mode inside
the Technician app rather than a sixth Flutter project. It was built as its
own app because the user's spec explicitly listed it as a peer of the Vendor
and Technician apps in the target folder layout — followed literally rather
than re-litigated.

## Folder structure inside each app

Every Services app uses a layered-by-feature structure:

```
lib/
  app/            — app.dart (root widget), router/, shell/
  core/
    auth/         — auth_providers.dart (isSupabaseReadyProvider, signIn/signUp/signOut)
    theme/        — app_colors.dart
    providers/    — repository_providers.dart (wires every feature repo)
    permissions/  — (snapbee_services_admin only) PermissionAction enum
  features/
    <feature>/
      domain/
        entities/
        repositories/     — abstract interface
      data/
        repositories/     — Supabase-backed implementation
      presentation/
        providers/        — Riverpod StateNotifier + state class
        screens/
        widgets/
  main.dart
```

`snapbee_services_admin`'s `features/` are the sector's admin surfaces —
today: `dashboard`, `categories`, `catalog`, `vendors`, `technicians`,
`inspectors`, `bookings`. **Not yet built** (each gets its own
`features/<name>/` folder when it is, following the exact same
domain/data/presentation shape — not stubbed in advance): `pricing`,
`quotations`, `warranties`, `policies`, `trust`, `ai`, `complaints`,
`disputes`, `settlements`, `reports`.

`snapbee_customer_app`'s Services sector lives entirely under
`lib/features/services/` (that app's own convention is flat —
`data/ models/ <feature>/` siblings, no domain/data/presentation layering —
matching how `lib/screens/cart/` already shapes itself: `cart_screen.dart` +
`models/` + `widgets/` as siblings, not nested layers). Built folders today:
`data/` (2 repositories — catalog vs. the authenticated booking lifecycle),
`models/`, `home/`, `categories/` (list + detail + inline verified-provider
listing), `booking/` (form + extra-work response sheet), `tracking/`
(the full lifecycle hub — timeline, OTP display, quotation/extra-work
action cards, payment summary, warranty, review, complaint/dispute entry
points), `service_records/` (My Bookings, tabbed upcoming/active/completed/
cancelled), `quotation/`, `warranty/`, `complaints/`, `disputes/`,
`reviews/`, `payments/`. The sector tab (`ServiceTabsWidget`) is wired —
tapping "Services" navigates to `ServicesHomeScreen` for real.

**Not yet built** (no fake/placeholder screens created for these — they
simply don't exist yet): `offers/` as its own folder (offers are shown
inline on Home instead), `inspection/`/`work_order/` as their own folders
(the inspection flow is transparent to this app — `create_service_booking`
opens the inspection record server-side; work-order state is read via the
same booking-status timeline, not a separate screen), `recurring/`, `amc/`,
`chat/`. Payment here is intentionally read-only (advance/remaining amounts,
paid flags) — a customer never self-reports "I paid the advance"; that
confirmation is a technician action (`record_service_payment`, called from
`snapbee_services_technician`), so building a "pay now" button in this app
would have been fake functionality.

## Database boundaries

Every Services table lives in `supabase/services_module_v2.sql` (owned by
`snapbee_admin`'s `supabase/` directory — that's this monorepo's existing
convention for where migration files live, regardless of which app
consumes the schema). Every table/function name is `service_*` or
`services_*`-prefixed, distinct from Daily Essentials' `vendors` /
`delivery_partners` / `orders` / `customers` (the last one, `customers`, is
the one deliberately shared identity — a Services booking is still made by
the same customer account that places a Daily Essentials order).

- 43 tables, all registered in `table_module_map` with `module = 'services'`.
- RLS admin policies generated by looping `table_module_map where module =
  'services'` (same generator every other module in this codebase uses).
- Per-actor self-access RLS layered on top (customer-self, vendor-self,
  technician-self, inspector-self) — additive, never narrows admin access.
- RBAC: a single `'services'` module row in `permissions`/`role_permissions`
  — `snapbee_services_admin` checks only this one module's actions (unlike
  `snapbee_admin`, which resolves every Daily Essentials module too).
- **Migrations, repositories, models, RLS policies, and tests all stay
  inside this one file / this one app's `supabase/` directory** — no
  Services DDL exists in any other app's repo.
- No AI logic lives in SQL beyond deterministic rule checks (the 1.5×
  reference-price part flag, the repeated-warranty-claim flag) and the
  logging tables (`service_ai_decisions`, `service_ai_escalations`) the
  future AI layer will read from and write to.

## AI layer (planned, not yet built)

When built, every AI concern gets its own dedicated module — never
scattered into booking/quotation/warranty screens directly:

```
services/
  ai/
    ai_service.dart          — the single entry point every feature calls
    ai_decision_engine.dart  — rules-first dispatcher: deterministic check -> AI only if genuinely ambiguous -> admin escalation if high-risk
    ai_risk_engine.dart      — trust/fraud/risk scoring
    ai_moderation.dart       — chat/media moderation
    ai_quotation.dart        — quotation/price validation
    ai_matching.dart         — provider matching assistance
    ai_warranty.dart         — warranty-abuse detection
    ai_escalation.dart       — writes to service_ai_escalations, notifies Admin
```

Every AI call logs a `service_ai_decisions` row (confidence + risk score);
anything above the configured risk threshold writes a
`service_ai_escalations` row instead of resolving silently. No screen calls
an LLM directly — everything routes through `ai_service.dart`.

## Policy engine (schema built, application layer not yet built)

`service_policies` (in `services_module_v2.sql`) is the single source of
truth for cancellation fees, no-show handling, reschedule fees, emergency
surcharges, visit charges, extra-work approval routing, commission,
platform fee, and tax — as `jsonb` rules, Admin-editable, with real seeded
defaults (not hardcoded UI logic). RPCs already read it
(`get_service_policy_rules`); no screen should ever hardcode a cancellation
percentage or an approval threshold — read it from this table via that
helper (or its future Dart-layer equivalent,
`service_policy_engine.dart`, once one app needs to read rules outside SQL).

## Shared vs. sector-specific code

Genuinely shared across sectors and legitimately reused, not duplicated:
- The Supabase project itself (one backend, `.env` in every app points at
  the same URL/anon key — matches every existing SnapBee app's own
  precedent).
- `customers` (the identity), `admin_profiles`/`get_my_permissions()`/
  `get_my_role_name()` (the platform RBAC primitive every admin-side app,
  Daily Essentials or Services, already authenticates through).
- The `has_permission(module, action)` Postgres function and the
  `table_module_map`-driven RLS generator pattern.

Everything else — actor tables, booking lifecycle, RPCs, Dart entities,
repositories, screens — is Services-owned and namespaced. Nothing here was
copy-pasted from Daily Essentials' equivalent (vendors/delivery_partners/
orders); each concept was designed fresh against the Services domain model.

## Integration points

- **Customer App ↔ Services backend**: wired — real signup/booking/tracking/
  quotation-approval/warranty-claim/complaint/dispute/review flows, all
  through the same RPCs the provider-side apps use. Two schema gaps found
  and fixed while wiring this (services_module_v2.sql SECTION 22, still
  pre-application): `service_vendors`/`service_pricing` had no
  customer-browse RLS at all (needed for "Verified Providers" on the
  service detail screen), and complaints/disputes had a table + admin-only
  RLS but no customer write path — added `raise_service_complaint`/
  `raise_service_dispute` RPCs rather than a raw RLS insert policy, matching
  every other customer write in this file. Also added the `service-media`
  private storage bucket (per-uploader-folder RLS) for emergency-booking
  problem photos.
- **Vendor/Technician/Inspector apps ↔ Services Admin**: all four write to
  the same tables Admin reads/approves (pricing, quotations, warranties) —
  no direct app-to-app calls, everything flows through Postgres + RLS.
- **AI layer ↔ everything**: planned to be called from RPCs and/or a Dart
  service layer, logging into `service_ai_decisions`/
  `service_ai_escalations`, never bypassing the deterministic rules already
  enforced by RLS and the policy engine.

## Naming conventions

Repositories/engines are named for exactly what they own:
`categories_repository` / `catalog_repository` / `vendors_repository` /
`technicians_repository` / `inspectors_repository` / `bookings_repository`
today; `service_quotation_repository` / `service_warranty_repository` /
`service_policy_engine` / `service_ai_engine` / `service_trust_engine` when
those features are built. No `helper.dart` / `manager.dart` / `utils.dart` —
if something is generic enough to need one of those names, it almost
certainly belongs as a named method on the specific repository/engine that
owns the concern instead.
