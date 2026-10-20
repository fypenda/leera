import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leera/app/account/account_page.dart';
import 'package:leera/app/account/sign_in_page.dart';
import 'package:leera/core/ai/backend_client.dart';
import 'package:leera/core/auth/apple_sign_in.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/features/english/presentation/english_page.dart';

import '../support/fake_ai.dart';
import '../support/pump_app.dart';

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settle(tester);
}

final _signInButton = find.byKey(const ValueKey('sign-in-apple'));

void main() {
  for (final (name, size) in [
    ('a phone', iPhonePortrait),
    ('an iPad', iPadLandscape),
  ]) {
    appTest('signed out, the app opens on Sign in with Apple, on $name', (
      tester,
    ) async {
      final sessions = InMemorySessionStore();
      final apple = FakeAppleSignIn();
      final backend = FakeBackendClient();
      await pumpEnglishApp(
        tester,
        size,
        sessions: sessions,
        appleSignIn: apple,
        backend: backend,
      );
      expect(find.byType(SignInPage), findsOneWidget);

      await _tap(tester, _signInButton);

      // Apple was given the hash of the nonce the backend received.
      final signIn = backend.signIns.single;
      expect(signIn.identityToken, 'apple-identity-token');
      expect(apple.hashedNonces.single, hashNonce(signIn.nonce));
      expect(sessions.session?.accessToken, testSession().accessToken);
      expect(find.byType(EnglishPage), findsOneWidget);
    });
  }

  appTest('closing Apple\'s sheet leaves the person where they were', (
    tester,
  ) async {
    final backend = FakeBackendClient();
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      sessions: InMemorySessionStore(),
      appleSignIn: FakeAppleSignIn(token: null),
      backend: backend,
    );

    await _tap(tester, _signInButton);

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-error')), findsNothing);
    expect(backend.signIns, isEmpty);
  });

  appTest('debug builds can sign in without Apple', (tester) async {
    final sessions = InMemorySessionStore();
    final apple = FakeAppleSignIn();
    final backend = FakeBackendClient();
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      sessions: sessions,
      appleSignIn: apple,
      backend: backend,
    );

    await _tap(tester, find.byKey(const ValueKey('sign-in-dev')));

    expect(backend.devSignIns, ['dev']);
    expect(apple.hashedNonces, isEmpty);
    expect(sessions.session, isNotNull);
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('a sign-in the backend refuses says so', (tester) async {
    final sessions = InMemorySessionStore();
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      sessions: sessions,
      backend: FakeBackendClient(
        signInFailure: BackendFailure.invalidIdentity,
      ),
    );

    await _tap(tester, _signInButton);

    expect(find.byType(SignInPage), findsOneWidget);
    expect(
      find.text(describeBackendFailure(BackendFailure.invalidIdentity)),
      findsOneWidget,
    );
    expect(sessions.session, isNull);
  });

  appTest('the account shows the plan and what is left', (tester) async {
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      backend: FakeBackendClient(
        quota: testQuota(plan: Plan.plus, used: 1, limit: 3),
      ),
    );

    await _tap(tester, find.byKey(const ValueKey('open-account')));

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Leera Plus ✨'), findsOneWidget);
    expect(find.text('2 corrections left today'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('account-leave')));
    expect(find.byType(EnglishPage), findsOneWidget);
  });

  appTest('signing out leads back to signing in', (tester) async {
    final sessions = InMemorySessionStore(testSession());
    await pumpEnglishApp(tester, iPhonePortrait, sessions: sessions);

    await _tap(tester, find.byKey(const ValueKey('open-account')));
    await _tap(tester, find.byKey(const ValueKey('sign-out')));

    expect(sessions.session, isNull);
    expect(find.byType(SignInPage), findsOneWidget);
  });

  appTest('deleting the account asks first, then signs out', (tester) async {
    final sessions = InMemorySessionStore(testSession());
    final backend = FakeBackendClient();
    await pumpEnglishApp(
      tester,
      iPhonePortrait,
      sessions: sessions,
      backend: backend,
    );
    await _tap(tester, find.byKey(const ValueKey('open-account')));

    // Cancelled: nothing happens.
    await _tap(tester, find.byKey(const ValueKey('delete-account')));
    await _tap(tester, find.text('Cancel'));
    expect(backend.deletions, 0);
    expect(find.byType(AccountPage), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('delete-account')));
    await _tap(tester, find.byKey(const ValueKey('confirm-delete-account')));

    expect(backend.deletions, 1);
    expect(sessions.session, isNull);
    expect(find.byType(SignInPage), findsOneWidget);
  });
}
