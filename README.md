# my_app

A new Flutter project.

## Supabase setup

This app reads Supabase config from compile-time defines.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Standard practice in this repo:

- Copy `.env.example` → `.env` and fill values (this file is git-ignored).
- Run using `--dart-define-from-file=.env`.

The easiest way in this repo (reuses `admin-panel/.env.local`) is:

`tool/bootstrap_env.sh` then `tool/run_live_android.sh <device-id>`

To enable/disable the Supabase-backed feed: use `--dart-define=SUPABASE_FEED=true|false` (defaults to `true`).

Schema reference: `docs/supabase_schema.sql`

## OAuth (Google/Facebook) on mobile

This app uses Supabase OAuth via `signInWithOAuth(...)` and receives the callback
through a deep link:

- `io.supabase.flutter://login-callback`

Add this URL to Supabase Dashboard → Authentication → URL Configuration →
Additional Redirect URLs.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
