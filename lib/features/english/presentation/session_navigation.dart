import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/common/widgets/load_failure.dart';
import '../application/english_sessions.dart';
import '../application/english_themes.dart';
import '../domain/practice_session.dart';
import '../domain/practice_topic.dart';
import '../english_routes.dart';

/// The route of the step a session is at.
String routeNameOf(PracticeSession session) => switch (session.status) {
  PracticeSessionStatus.researching => englishTopicRouteName,
  PracticeSessionStatus.presenting => englishRestitutionRouteName,
  PracticeSessionStatus.completed => englishFeedbackRouteName,
};

/// Opens [session] at the step it is at.
void openSession(BuildContext context, PracticeSession session) =>
    context.goNamed(
      routeNameOf(session),
      pathParameters: {englishSessionParameter: session.id},
    );

/// Continues the session in progress, or starts a new one on a topic drawn
/// at random, from the themes chosen if any. Says so if the new session
/// could not be saved.
Future<void> startOrContinueSession(BuildContext context, WidgetRef ref) async {
  final inProgress = ref.read(sessionInProgressProvider).value;
  if (inProgress != null) {
    openSession(context, inProgress);
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    final session = await ref
        .read(practiceSessionActionsProvider)
        .start(themes: ref.read(dailyThemesProvider));
    if (context.mounted) openSession(context, session);
  } on Object {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('The session could not be started.')),
      );
  }
}

/// Builds a session page from the stored session with [sessionId], with
/// what to show while it loads, if it fails, or if there is no such
/// session.
class SessionLoader extends ConsumerWidget {
  const SessionLoader({
    super.key,
    required this.sessionId,
    required this.builder,
  });

  final String sessionId;
  final Widget Function(BuildContext context, PracticeSession session) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(practiceSessionsProvider);

    Widget frame(Widget child) => Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );

    return sessions.when(
      data: (sessions) {
        final session = sessions
            .where((session) => session.id == sessionId)
            .firstOrNull;
        if (session == null) {
          return frame(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This session no longer exists.',
                  key: const ValueKey('session-not-found'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.goNamed(englishRouteName),
                  child: const Text('Back to English'),
                ),
              ],
            ),
          );
        }
        return builder(context, session);
      },
      loading: () => frame(const SizedBox.shrink()),
      error: (error, stackTrace) => frame(
        LoadFailure(
          message: 'The session could not be loaded.',
          onRetry: () => ref.invalidate(practiceSessionsProvider),
        ),
      ),
    );
  }
}

/// Starts a session on [topic], chosen in Explore. Says so if it could not
/// be saved. The caller makes sure no session is in progress.
Future<void> startSessionOn(
  BuildContext context,
  WidgetRef ref,
  PracticeTopic topic,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final session = await ref
        .read(practiceSessionActionsProvider)
        .startOn(topic);
    if (context.mounted) openSession(context, session);
  } on Object {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('The session could not be started.')),
      );
  }
}
