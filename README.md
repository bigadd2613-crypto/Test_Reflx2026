# flutter_login_app1

## Online database setup

The app keeps its UI unchanged and uses Supabase for shared players, scores,
and country visit reports. Run `supabase_schema.sql` in the Supabase SQL Editor,
then add these repository secrets under **Settings > Secrets and variables >
Actions**:

- `SUPABASE_URL`: the Supabase project URL
- `SUPABASE_ANON_KEY`: the public anon key from the Supabase API settings

After pushing to `main`, the GitHub Actions workflow builds the Flutter web app
with those values and publishes it to GitHub Pages.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
