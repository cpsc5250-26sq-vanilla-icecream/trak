import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/router/app_router.dart';

const _fakeUser = AuthUser(
  userId: 'test-uid',
  username: 'testuser',
  signInDetails: CognitoSignInDetailsHostedUi(),
);

const _signedIn = AsyncData<AuthUser?>(_fakeUser);
const _signedOut = AsyncData<AuthUser?>(null);
const _authLoading = AsyncLoading<AuthUser?>();

const _needsUsername = AsyncData<bool>(true);
const _hasUsername = AsyncData<bool>(false);
const _usernameLoading = AsyncLoading<bool>();

void main() {
  group('computeRedirect', () {
    group('auth loading', () {
      test('never redirects while auth is loading', () {
        expect(
          computeRedirect(
            authState: _authLoading,
            needsUsername: _hasUsername,
            currentLocation: AppRoute.home,
          ),
          isNull,
        );
      });
    });

    group('not signed in', () {
      test('redirects any protected route to /login', () {
        for (final loc in [
          AppRoute.home,
          AppRoute.powerups,
          AppRoute.profile,
        ]) {
          expect(
            computeRedirect(
              authState: _signedOut,
              needsUsername: _hasUsername,
              currentLocation: loc,
            ),
            AppRoute.login,
            reason: '$loc should redirect to login',
          );
        }
      });

      test('does not redirect when already on /login', () {
        expect(
          computeRedirect(
            authState: _signedOut,
            needsUsername: _hasUsername,
            currentLocation: AppRoute.login,
          ),
          isNull,
        );
      });
    });

    group('signed in, needs username', () {
      test('redirects any route to /username', () {
        for (final loc in [AppRoute.home, AppRoute.powerups, AppRoute.login]) {
          expect(
            computeRedirect(
              authState: _signedIn,
              needsUsername: _needsUsername,
              currentLocation: loc,
            ),
            AppRoute.username,
            reason: '$loc should redirect to username',
          );
        }
      });

      test('does not redirect when already on /username', () {
        expect(
          computeRedirect(
            authState: _signedIn,
            needsUsername: _needsUsername,
            currentLocation: AppRoute.username,
          ),
          isNull,
        );
      });

      test('does not redirect while username check is loading', () {
        expect(
          computeRedirect(
            authState: _signedIn,
            needsUsername: _usernameLoading,
            currentLocation: AppRoute.home,
          ),
          isNull,
        );
      });
    });

    group('signed in, has username', () {
      test('redirects /login to /home', () {
        expect(
          computeRedirect(
            authState: _signedIn,
            needsUsername: _hasUsername,
            currentLocation: AppRoute.login,
          ),
          AppRoute.home,
        );
      });

      test('redirects /username to /home', () {
        expect(
          computeRedirect(
            authState: _signedIn,
            needsUsername: _hasUsername,
            currentLocation: AppRoute.username,
          ),
          AppRoute.home,
        );
      });

      test('does not redirect when on a normal app route', () {
        for (final loc in [
          AppRoute.home,
          AppRoute.powerups,
          AppRoute.profile,
        ]) {
          expect(
            computeRedirect(
              authState: _signedIn,
              needsUsername: _hasUsername,
              currentLocation: loc,
            ),
            isNull,
            reason: '$loc should not redirect',
          );
        }
      });
    });
  });
}
