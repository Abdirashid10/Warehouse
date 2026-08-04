# Logistics WMS — Mobile

Flutter client for the Logistics WMS Node.js + MongoDB backend. Authenticates against the live API and loads operational data for Staff (and role-specific home screens for Admin/Supervisor).

## Prerequisites

- Flutter SDK 3.9+
- Logistics WMS backend running (default port **5001**)

## Run

```bash  
flutter pub get

# Android emulator (default)
flutter run --dart-define=API_ENV=emulator

# Local development
flutter run --dart-define=API_ENV=development

# Physical device
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:5001/api
```

Sign in with credentials from your WMS backend.

## Architecture

```
lib/
├── core/           # ApiConfig, Dio, secure session, DI
├── features/       # auth, dashboard, tasks, inventory, stock_operations, orders, profile
├── routes/         # GoRouter + role redirects
└── widgets/        # Shared UI + WMS badges
```

## Stack

- Flutter · Material 3 · go_router · flutter_bloc
- Dio · flutter_secure_storage

See [CONFIG.md](CONFIG.md) for endpoints and environment variables.
