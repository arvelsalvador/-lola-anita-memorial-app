# nita

Flutter memorial app for Lola Anita.

## Connect Supabase

Credentials are never stored in code — they are read at build time.

- **Live site (GitHub Pages):** repo **Settings → Secrets and variables → Actions** → add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. The workflow in `.github/workflows/deploy.yml` bakes them into the web build and now fails the deploy if either secret is missing.
- **VS Code:** copy `env.example.json` to `env.json`, fill in the two values, then pick the **"nita (Windows + Supabase)"** launch config. `env.json` is git-ignored.
- **Terminal:**
  ```
  flutter run --dart-define=SUPABASE_URL=https://REF.supabase.co \
              --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
  ```

Use the **publishable** key (`sb_publishable_...`) from Settings → API Keys. Never put the `service_role` / secret key in this repo. Without these values the app runs local-only (data stays on the device/browser).

## Keep the free Supabase project awake

Free Supabase projects **pause after about 7 days without API activity**. While paused, the site loads but condolences, candles and the admin page fail.

`.github/workflows/keep-alive.yml` calls a read-only function every **Monday and Thursday**. Nothing to configure — it uses the same two secrets as the deploy.

- Run it by hand: **Actions → Keep Supabase awake → Run workflow**.
- GitHub disables scheduled workflows after **60 days with no repository activity**; it sends an email first. Open **Actions** and click **Enable workflow** to resume.
- If the check fails, the project is paused or a key changed. Restore the project in Supabase, then re-run the workflow.

## Backups

Three layers, cheapest first:

1. **Supabase daily backups** — Dashboard → Database → Backups. Free plan keeps a short rolling window; restore from there for data loss.
2. **Data export** — open the admin page → **Export** buttons copy visitors and private candle messages as CSV to the clipboard. Save one occasionally somewhere safe.
3. **Schema snapshot** — the table/function/policy definitions live only in the dashboard. Run `supabase/schema_snapshot.sql` in the SQL Editor and save the resulting JSON as `supabase/schema_snapshot.json` (no personal data is included). Repeat after any schema change.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
