import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ai/ai_settings.dart';
import '../features/english/english_routes.dart';
import '../features/english/presentation/english_feedback_page.dart';
import '../features/english/presentation/english_page.dart';
import '../features/english/presentation/english_restitution_page.dart';
import '../features/english/presentation/english_topic_page.dart';
import 'settings/ai_settings_page.dart';

/// The app's routes: the English home, the three steps of a session, and
/// the AI settings.
///
/// The session pages and the settings are siblings of the home rather than
/// nested under it, so that a settings page opened from a session goes back
/// there.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: englishRouteName,
        builder: (context, state) => const EnglishPage(),
      ),
      GoRoute(
        path: '/settings/ai',
        name: aiSettingsRouteName,
        builder: (context, state) => const AiSettingsPage(),
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
  ref.onDispose(router.dispose);
  return router;
});

String _sessionIdIn(GoRouterState state) =>
    state.pathParameters[englishSessionParameter]!;
