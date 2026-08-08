# Logistics WMS Mobile — API Configuration

## Base URL

All requests use `ApiConfig.baseUrl` (must include `/api`).

| Environment | URL | How to run |
|-------------|-----|------------|
| **Development** (localhost / web) | `http://localhost:5001/api` | `--dart-define=API_ENV=development` |
| **Android emulator** | `http://10.0.2.2:5001/api` | `--dart-define=API_ENV=emulator` |
| **Physical device** | Your LAN IP | `--dart-define=API_BASE_URL=http://192.168.x.x:5001/api` |

Backend default port: **5001** (`Logistics/server/server.js`).

```bash
flutter pub get
flutter run --dart-define=API_ENV=emulator
flutter run --dart-define=API_ENV=development
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:5001/api
```

## Authentication

| Method | Path | Notes |
|--------|------|--------|
| POST | `/api/auth/login` | `{ "email", "password" }` → `{ "token", "user" }` |
| GET | `/api/profile/me` | Bearer token — session restore & profile |

JWT is stored in **flutter_secure_storage**. Splash restores the session when a token exists. **401** responses clear the session and return to login (no server refresh endpoint on this backend).

## Module endpoints

| Feature | Backend path | Mobile usage |
|---------|--------------|--------------|
| Dashboard | `GET /dashboard/stats`, `GET /dashboard/widgets` | Staff aggregate + Admin/Supervisor KPIs |
| Tasks | `GET /tasks`, `GET /tasks/:id`, `PATCH /tasks/:id/status` | My Tasks |
| Inventory | `GET /inventory`, `GET /inventory/tracking` | Tracking preferred; `/inventory` fallback |
| Products | `GET /products` | Catalog (repository wired) |
| Orders | `GET /orders`, `GET /orders/:id`, `PUT /orders/:id/status` | My Orders |
| Profile | `GET /profile/me` | Account screen |
| Movements | `GET /inventory/movements` | Stock Operations |
| Notifications | `GET /notifications` | Notifications screen |

## Dio interceptors (order)

1. **Auth** — `Authorization: Bearer <token>`
2. **Logging** — debug / `API_LOGGING=true`
3. **Response** — metadata on success
4. **Error** — maps 400, 401, 403, 404, 5xx, timeouts → `ApiException`
5. **Unauthorized** — clears session on 401 (except login)

## Architecture

`RemoteDataSource` → `Repository` → `UseCase` → `Cubit/Bloc`

## Role routing

| Role | Home |
|------|------|
| Admin | `/admin` |
| Supervisor | `/supervisor` |
| Staff | `/staff/dashboard` |
