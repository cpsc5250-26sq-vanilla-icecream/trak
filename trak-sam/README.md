# Trak API — Frontend Developer Guide

The backend is already deployed. You do not need to touch AWS or run any infrastructure commands. This guide covers how to get a token for testing and how to call the API.

---

## Config Values

| Key | Value |
|---|---|
| `API_BASE_URL` | `https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod` |
| `USER_POOL_ID` | `us-east-1_LFSu0wZmV` |
| `CLIENT_ID` | `54k55f1soa74c6if86mvnq5nsi` |
| `OAUTH_DOMAIN` | `https://us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com` |
| `REGION` | `us-east-1` |

---

## Getting a Test Token

Choose one of the two methods below.

---

### Option 1 — Postman (recommended)

All API requests require a JWT in the `Authorization` header. To get one:

1. Open Postman → new request → **Authorization** tab
2. Set type to `OAuth 2.0` → click **Get New Access Token**
3. Fill in:

| Field | Value |
|---|---|
| Grant Type | Authorization Code |
| Callback URL | `https://oauth.pstmn.io/v1/callback` |
| Auth URL | `https://us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com/oauth2/authorize` |
| Access Token URL | `https://us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com/oauth2/token` |
| Client ID | `54k55f1soa74c6if86mvnq5nsi` |
| Client Secret | *(leave blank)* |
| Scope | `openid email profile` |
| Client Authentication | Send client credentials in body |

4. Click **Request Token** → sign in with Google
5. Copy the **`id_token`** from the response (not `access_token`)
6. Click **Use Token** — Postman attaches it automatically

Tokens expire after **1 hour**. Repeat these steps to get a new one.

---

### Option 2 — Browser + curl (no install required)

**Step 1 — Open the sign-in page**

Paste this URL into your browser:
```
https://us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com/oauth2/authorize?client_id=54k55f1soa74c6if86mvnq5nsi&response_type=code&scope=openid+email+profile&redirect_uri=http://localhost
```

Sign in with Google. The browser will fail to load `localhost` — that's expected.

**Step 2 — Copy the code from the URL bar**

The URL bar will look like:
```
http://localhost/?code=abcd1234-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Copy everything after `code=`. You have **60 seconds** before it expires.

**Step 3 — Exchange the code for tokens**

Run this curl command immediately, replacing `<code>` with what you copied:

```bash
curl -X POST https://us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&client_id=54k55f1soa74c6if86mvnq5nsi&code=<code>&redirect_uri=http://localhost"
```

Response:
```json
{
  "id_token": "eyJ...",
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

Copy the **`id_token`** value — that's your JWT for API requests.

**Step 4 — Make an API request**

```bash
curl -X POST https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod/users \
  -H "Authorization: Bearer <id_token>" \
  -H "Content-Type: application/json" \
  -d '{"username": "johndoe", "displayName": "John Doe"}'
```

Tokens expire after **1 hour**. Repeat from Step 1 to get a new one.

---

## Making Requests

Attach the token to every request:

```
Authorization: Bearer <id_token>
Content-Type: application/json
```

---

## Endpoints

Base URL: `https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod`

### Users

#### Create / update profile
```
POST /users
```
Call this on first login and whenever the user updates their profile.

Request body:
```json
{
  "username": "johndoe",
  "displayName": "John Doe",
  "avatarUrl": "https://...",
  "colorScheme": "default",
  "font": "default"
}
```

Response:
```json
{
  "userId": "sub-from-cognito",
  "username": "johndoe",
  "displayName": "John Doe",
  "points": 0,
  "createdAt": "2026-04-18T00:00:00.000Z",
  "updatedAt": "2026-04-18T00:00:00.000Z"
}
```

---

#### Get own profile
```
GET /users/me
```

Returns the full profile of the authenticated user including points.

---

#### Get another user's profile
```
GET /users/{userId}
```

Returns public fields only: `userId`, `username`, `displayName`, `avatarUrl`, `colorScheme`, `font`, `points`.

---

### Steps

#### Submit today's step count
```
POST /steps
```

Call this whenever you sync steps from the device. Submitting multiple times in a day is safe — it updates the record and recalculates points correctly.

Request body:
```json
{
  "stepCount": 10000
}
```

Response:
```json
{
  "userId": "sub-from-cognito",
  "date": "2026-04-18",
  "stepCount": 10000,
  "points": 100
}
```

Points are calculated at **100 steps = 1 point**.

---

#### Get step history
```
GET /steps
GET /steps?limit=14
```

Returns the last 7 days by default (max 30). Sorted newest first.

Response:
```json
[
  { "userId": "...", "date": "2026-04-18", "stepCount": 10000 },
  { "userId": "...", "date": "2026-04-17", "stepCount": 8500 }
]
```

---

### Friends

#### Add a friend by username
```
POST /friends
```

Request body:
```json
{
  "username": "someuser"
}
```

Response:
```json
{
  "friendId": "sub-from-cognito",
  "username": "someuser",
  "displayName": "Some User"
}
```

Errors:
- `404` — username not found
- `400` — cannot add yourself

---

#### Remove a friend
```
DELETE /friends/{friendId}
```

`friendId` is the Cognito `userId` (sub) of the friend, returned when you added them.

---

#### List friends
```
GET /friends
```

Response:
```json
[
  { "userId": "...", "friendId": "...", "createdAt": "..." }
]
```

---

### Leaderboard

#### Get leaderboard
```
GET /leaderboard
```

Returns the authenticated user + all their friends ranked by points.

Response:
```json
[
  { "rank": 1, "userId": "...", "username": "johndoe", "displayName": "John Doe", "points": 250 },
  { "rank": 2, "userId": "...", "username": "someuser", "displayName": "Some User", "points": 180 }
]
```

---

## Amplify Setup

Install the Amplify Flutter packages in `pubspec.yaml`:

```yaml
dependencies:
  amplify_flutter: ^2.0.0
  amplify_auth_cognito: ^2.0.0
```

Configure Amplify once at app startup (before `runApp`):

```dart
await Amplify.addPlugin(AmplifyAuthCognito());
await Amplify.configure(AmplifyConfig(
  auth: AuthConfig.cognito(
    userPoolConfig: CognitoUserPoolConfig(
      poolId: 'us-east-1_LFSu0wZmV',
      appClientId: '54k55f1soa74c6if86mvnq5nsi',
      region: 'us-east-1',
    ),
    hostedUiConfig: CognitoOAuthConfig(
      appClientId: '54k55f1soa74c6if86mvnq5nsi',
      scopes: ['openid', 'email', 'profile'],
      signInRedirectUri: 'myapp://callback',
      signOutRedirectUri: 'myapp://callback',
      webDomain: 'us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com',
    ),
  ),
));
```

### Signing in with Google

```dart
await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
```

### Getting the JWT for API calls

After sign-in, fetch the `id_token` and attach it to every request:

```dart
final session = await Amplify.Auth.fetchAuthSession(
  options: CognitoSessionOptions(getAWSCredentials: false),
) as CognitoAuthSession;

final idToken = session.userPoolTokens?.idToken.raw;

final response = await http.post(
  Uri.parse('https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod/users'),
  headers: {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({ 'username': 'johndoe', 'displayName': 'John Doe' }),
);
```

Tokens expire after 1 hour. Call `fetchAuthSession` before every request — Amplify automatically refreshes the token if it's expired.

### Signing out

```dart
await Amplify.Auth.signOut();
```

---

## App Flows

### 1. First Login / Every Login
```
User taps "Sign in with Google"
→ Amplify.Auth.signInWithWebUI()   handles Google OAuth + Cognito
→ fetchAuthSession()               get id_token
→ POST /users                      create or refresh profile in DB
→ GET  /users/me                   load profile into app state
→ POST /steps                      sync today's steps from device
→ GET  /leaderboard                populate leaderboard on home screen
```

### 2. Daily Use (app opens or foregrounds)
```
→ fetchAuthSession()   refresh token if needed
→ POST /steps          sync latest step count from device pedometer
→ GET  /leaderboard    refresh rankings
```

### 3. Profile Update
```
User changes display name / avatar / color scheme
→ POST /users          send updated fields (upsert — safe to call anytime)
→ GET  /users/me       confirm updated profile
```

### 4. Adding a Friend
```
User searches by username or scans QR code
→ POST /friends        { "username": "..." }  →  get back friendId
→ GET  /leaderboard    refresh — new friend now appears in rankings
```

### 5. Removing a Friend
```
User taps remove on a friend
→ DELETE /friends/{friendId}
→ GET  /leaderboard    refresh — friend disappears from rankings
```

### 6. Viewing a Friend's Profile
```
User taps a friend on the leaderboard
→ GET /users/{userId}  returns their public profile
```

### 7. Step History (stats screen)
```
→ GET /steps           last 7 days by default
→ GET /steps?limit=30  for a monthly view
```
