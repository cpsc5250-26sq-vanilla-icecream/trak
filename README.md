# Trak

A Flutter social fitness app. Walk steps, earn points, compete with friends on a live leaderboard, and use powerups and attacks to shake up the rankings.

**Trello:** https://trello.com/b/F94zZbge/trak

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter + Dart |
| State management | Riverpod |
| Auth | AWS Cognito (Google sign-in via Amplify) |
| API | AWS API Gateway + Lambda (Node.js) |
| Database | DynamoDB |
| Step source | Native health API (device pedometer) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.x)
- Android Studio or Xcode for a device/emulator

### Run the app

```bash
flutter pub get
flutter run
```

The app currently runs against a mock backend (`MockAppRepository`). Real AWS integration is in progress as part of Sprint 1.

### Run tests

```bash
flutter test --coverage
```

Coverage requirements are enforced in CI and change each sprint (currently **30%** for Sprint 1). If you can get to **60%** on code you touch, that's ideal — we'll need to hit that threshold eventually anyway.

### Format and lint

```bash
dart format .
flutter analyze
```

Both are required to pass before merging.

---

## Architecture

The app uses a repository pattern to decouple the UI from the data source:

```
Native health API  ──┐
AWS backend        ──┼──▶  AppRepository  ──▶  Riverpod providers  ──▶  Widgets
SQLite local cache ──┘
```

`AppRepository` is an abstract interface. `MockAppRepository` is used during development. The real `AwsAppRepository` (backed by Cognito + API Gateway) is being built in Sprint 1.

Providers:

| Provider | Type | Description |
|---|---|---|
| `stepCountProvider` | `StreamProvider<int>` | Live step count from device |
| `leaderboardProvider` | `StreamProvider<List<LeaderboardEntry>>` | Friends ranked by total points |
| `inventoryProvider` | `StreamProvider<List<InventoryItem>>` | Powerups and attacks available to the user |
| `currentUserProvider` | `FutureProvider<UserProfile>` | Authenticated user's profile |

---

## Backend

The AWS backend is already deployed. See [`trak-sam/README.md`](trak-sam/README.md) for the full API reference, auth setup, and how to get a test token.

---

## Sprint Plan

| Sprint | Status | Goals |
|---|---|---|
| Sprint 1 | In progress | Step count from device, AWS setup (Cognito/API Gateway/DynamoDB), local cache, profile/sign-in, add friends by username |
| Sprint 2 | Not started | Steps → points, leaderboard screen, SNS, QR friend add, push notification POC |
| Sprint 3 | Not started | UI settings (colors/fonts/backgrounds), powerups & attacks, full push notifications, historical leaderboards |

---

## Contributing

### Branching

- Branch off `dev` for all work — never push directly to `dev` or `main`
- Name branches `feature/xyz`, `fix/xyz`, or `chore/xyz`
- Open a PR into `dev`; every PR needs **1 approval** before merging
- `dev` → `main` happens once at the end of each sprint

### Commit messages

Prefix every commit message with `feat:`, `fix:`, or `chore:`.

### Workflow

```bash
# 1. Start from latest dev
git checkout dev
git pull origin dev --rebase

# 2. Create a branch
git checkout -b feature/xyz

# 3. Do your work, then format and lint before committing
dart format .
flutter analyze
git add [files you changed]
git commit -m "feat: describe your change"

# 4. Push and open a PR into dev
git push origin feature/xyz
```

---

## CI

GitHub Actions runs on every PR to `main` and `dev`:

1. `dart format` check
2. `flutter analyze`
3. `flutter test --coverage` with minimum coverage gate (30% for Sprint 1)
4. `flutter build apk --debug`
