# ritmio_client

Flutter client for Ritmio API with:
- auth (`/register`, `/login`, `/logout`)
- dashboard summary (weekly/monthly)
- CRUD for transactions, tasks, and categories

## Setup

1. Start backend API (`ritmio_backend`) on `http://127.0.0.1:8000`.
2. Base URL is configured in `lib/core/config/app_config.dart`:
   - `AppConfig.apiBaseUrl = 'http://127.0.0.1:8000/api'`
3. Install dependencies:
   - `flutter pub get`
4. Run app:
   - `flutter run`

## Quality checks

- `flutter analyze`
- `flutter test`
