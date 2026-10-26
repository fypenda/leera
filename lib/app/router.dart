import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../core/settings/settings.dart';
import '../features/english/english_routes.dart';
import '../features/english/presentation/english_feedback_page.dart';
import '../features/english/presentation/english_page.dart';
import '../features/english/presentation/english_restitution_page.dart';
import '../features/english/presentation/english_topic_page.dart';
import '../features/english/presentation/explore_page.dart';
import '../features/english/presentation/explore_theme_page.dart';
import '../features/english/presentation/journal_page.dart';
import '../features/english/presentation/progress_page.dart';
import '../features/english/presentation/review_page.dart';
import 'account/account_page.dart';
import 'account/sign_in_page.dart';
import 'main_shell.dart';
import 'plus/plus_page.dart';
import 'welcome/welcome_page.dart';

const _startingPath = '/starting';
const _signInPath = '/sign-in';
const _welcomePath = '/welcome';

/// The app's routes: signing in, the tabs (Today, Explore, Journal,
/// Progress), the three
/// steps of a session, the account and Leera Plus.
///
/// Signed out, every address leads to signing in; signed in, the welcome
/// comes first until it has been gone through once on this device, then
/// signing in leads home. Until the session has been read from the Keychain, the app
/// waits on a blank page the colour of the launch screen.
///
/// The session pages and the account are siblings of the tabs rather than
/// nested under them: they are full screen, without the tab bar, and the
/// account opened from a session goes back there.
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

  // Null until known whether the welcome was gone through on this device.
  final welcomed = ValueNotifier<bool?>(null);
  ref.listen<AsyncValue<bool>>(welcomeDoneProvider, (previous, next) {
    if (next.hasValue) {
      welcomed.value = next.value;
    } else if (next.hasError) {
      // Settings that cannot be read must not lock the app on the welcome.
      welcomed.value = true;
    }
  }, fireImmediately: true);

  final router = GoRouter(
    initialLocation: _startingPath,
    refreshListenable: Listenable.merge([signedIn, welcomed]),
    redirect: (context, state) {
      final known = signedIn.value;
      if (known == null) return null;
      final location = state.matchedLocation;
      if (!known) return location == _signInPath ? null : _signInPath;
      // Signed in: the welcome comes first, once.
      final welcome = welcomed.value;
      if (welcome == null) {
        return location == _signInPath ? _startingPath : null;
      }
      if (!welcome) return location == _welcomePath ? null : _welcomePath;
      if (location == _signInPath ||
          location == _startingPath ||
          location == _welcomePath) {
        return '/';
      }
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
        path: _welcomePath,
        builder: (context, state) => const WelcomePage(),
      ),
      // The tabs: Today, Explore, Journal and Progress.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: englishRouteName,
                builder: (context, state) => const EnglishPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: exploreRouteName,
                builder: (context, state) => const ExplorePage(),
                routes: [
                  GoRoute(
                    path: ':$exploreThemeParameter',
                    name: exploreThemeRouteName,
                    builder: (context, state) => ExploreThemePage(
                      theme: state.pathParameters[exploreThemeParameter]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                name: journalRouteName,
                builder: (context, state) => const JournalPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: progressRouteName,
                builder: (context, state) => const ProgressPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        name: accountRouteName,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/review',
        name: reviewRouteName,
        builder: (context, state) => const ReviewPage(),
      ),
      GoRoute(
        path: '/plus',
        name: plusRouteName,
        builder: (context, state) => const PlusPage(),
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
    welcomed.dispose();
  });
  return router;
});

String _sessionIdIn(GoRouterState state) =>
    state.pathParameters[englishSessionParameter]!;
