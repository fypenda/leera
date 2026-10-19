import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../features/english/english_routes.dart';
import '../features/english/presentation/english_feedback_page.dart';
import '../features/english/presentation/english_page.dart';
import '../features/english/presentation/english_restitution_page.dart';
import '../features/english/presentation/english_topic_page.dart';
import 'account/account_page.dart';
import 'account/sign_in_page.dart';

const _startingPath = '/starting';
const _signInPath = '/sign-in';

/// The app's routes: signing in, the home page, the three steps of a
/// session, and the account.
///
/// Signed out, every address leads to signing in; signed in, signing in
/// leads home. Until the session has been read from the Keychain, the app
/// waits on a blank page the colour of the launch screen.
///
/// The session pages and the account are siblings of the home rather than
/// nested under it, so that the account opened from a session goes back
/// there.
final routerProvider = Provider<GoRouter>((ref) {
  // Null until the session is known.
  final signedIn = ValueNotifier<bool?>(null);
  ref.listen<AsyncValue<Session?>>(sessionProvider, (previous, next) {
    if (next.hasValue) {
      signedIn.value = next.value != null;
    } else if (next.hasError) {
      // A Keychain that cannot be read is as good as no session.
      signedIn.value = false;
    }
  }, fireImmediately: true);

  final router = GoRouter(
    initialLocation: _startingPath,
    refreshListenable: signedIn,
    redirect: (context, state) {
      final known = signedIn.value;
      if (known == null) return null;
      final location = state.matchedLocation;
      if (!known) return location == _signInPath ? null : _signInPath;
      if (location == _signInPath || location == _startingPath) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: _startingPath,
        builder: (context, state) => const Scaffold(body: SizedBox.expand()),
      ),
      GoRoute(
        path: _signInPath,
        name: signInRouteName,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/',
        name: englishRouteName,
        builder: (context, state) => const EnglishPage(),
      ),
      GoRoute(
        path: '/account',
        name: accountRouteName,
        builder: (context, state) => const AccountPage(),
      ),
      // Each page finds its session itself, and says so if there is none.
      GoRoute(
        path: '/session/:$englishSessionParameter',
        name: englishTopicRouteName,
        builder: (context, state) =>
            EnglishTopicPage(sessionId: _sessionIdIn(state)),
        routes: [
          GoRoute(
            path: 'restitution',
            name: englishRestitutionRouteName,
            builder: (context, state) =>
                EnglishRestitutionPage(sessionId: _sessionIdIn(state)),
          ),
          GoRoute(
            path: 'feedback',
            name: englishFeedbackRouteName,
            builder: (context, state) =>
                EnglishFeedbackPage(sessionId: _sessionIdIn(state)),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    signedIn.dispose();
  });
  return router;
});

String _sessionIdIn(GoRouterState state) =>
    state.pathParameters[englishSessionParameter]!;
