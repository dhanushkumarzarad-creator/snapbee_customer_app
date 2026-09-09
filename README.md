# snapbee_customer_app

The SnapBee customer-facing Flutter app (web + mobile).

## Deployment (web)

Every push to `master` runs `.github/workflows/deploy-web.yml`:
`flutter analyze` + `flutter test` -> `flutter build web --release` ->
publish to **GitHub Pages**.

Live: <https://dhanushkumarzarad-creator.github.io/snapbee_customer_app/>

No secrets are configured -- the Supabase URL and *publishable* (anon) key
are public by design; the workflow writes `.env` from those values with
`APP_ENV=production` before building. Deploy manually via Actions ->
"Deploy customer app (web)" -> Run workflow.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
