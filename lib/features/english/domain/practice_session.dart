import 'restitution_format.dart';

/// How long the research of a session is meant to last. The timer shows it;
/// nothing is stopped when it runs out.
const researchTime = Duration(minutes: 20);

/// Where a session stands. Stored by name: do not rename a value without
/// migrating the stored data.
enum PracticeSessionStatus {
  /// The topic is drawn; the person is researching it, without AI.
  researching,

  /// The research is over; the person is presenting the topic.
  presenting,

  /// The presentation was sent for feedback.
  completed,
}

/// One English practice session: a topic drawn at random, researched, then
/// presented in a format drawn at random too.
///
/// A session that exists is valid: the constructor rejects inconsistent
/// state with an [ArgumentError], and the changes below refuse what the
/// session's status does not allow with a [StateError].
class PracticeSession {
  PracticeSession({
    required this.id,
    required this.topicId,
    required this.format,
    required this.status,
    this.notes = '',
    this.presentation,
    this.rerolled = false,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'Must not be empty.');
    if (topicId.trim().isEmpty) {
      throw ArgumentError.value(topicId, 'topicId', 'Must not be blank.');
    }
    if (presentation != null && presentation!.trim().isEmpty) {
      throw ArgumentError.value(
        presentation,
        'presentation',
        'Must be null rather than blank.',
      );
    }
    if (!startedAt.isUtc || !updatedAt.isUtc || completedAt?.isUtc == false) {
      throw ArgumentError('Session timestamps must be UTC instants.');
    }
    if ((status == PracticeSessionStatus.completed) != (completedAt != null)) {
      throw ArgumentError(
        'completedAt must be set when, and only when, the session is '
        'completed.',
      );
    }
  }

  final String id;

  /// The id of its topic in the bundled catalog.
  final String topicId;
  final RestitutionFormat format;
  final PracticeSessionStatus status;

  /// What the person wrote down while researching.
  final String notes;

  /// The written presentation; null for a spoken one, whose audio is not
  /// kept.
  final String? presentation;

  /// Whether the other topic it allows has already been drawn.
  final bool rerolled;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == PracticeSessionStatus.completed;

  /// Another topic can still be drawn: only once, and only while
  /// researching.
  bool get canReroll =>
      !rerolled && status == PracticeSessionStatus.researching;

  /// This session with [notes] instead of its own. Notes can be changed
  /// until the session is completed.
  PracticeSession withNotes(String notes, DateTime at) {
    if (isCompleted) throw StateError('A completed session is closed.');
    if (notes == this.notes) return this;
    return _copy(notes: notes, updatedAt: at);
  }

  /// This session on another topic and format, drawn once while
  /// researching. The research starts again, and so do the notes.
  PracticeSession rerolledTo(
    String topicId,
    RestitutionFormat format,
    DateTime at,
  ) {
    if (!canReroll) {
      throw StateError('Another topic can be drawn once, while researching.');
    }
    return _copy(
      topicId: topicId,
      format: format,
      notes: '',
      rerolled: true,
      startedAt: at,
      updatedAt: at,
    );
  }

  /// The research is over: the session moves on to the presentation.
  /// Returns this session unchanged if it is already there.
  PracticeSession startPresenting(DateTime at) => switch (status) {
    PracticeSessionStatus.researching => _copy(
      status: PracticeSessionStatus.presenting,
      updatedAt: at,
    ),
    PracticeSessionStatus.presenting => this,
    PracticeSessionStatus.completed => throw StateError(
      'A completed session is closed.',
    ),
  };

  /// The presentation is sent: the session is completed at [at], keeping
  /// [presentation] if it was written. A blank one counts as none.
  PracticeSession completedWith(String? presentation, DateTime at) {
    if (isCompleted) throw StateError('The session is already completed.');
    final written = presentation?.trim();
    return _copy(
      status: PracticeSessionStatus.completed,
      presentation: written == null || written.isEmpty ? null : presentation,
      updatedAt: at,
      completedAt: at,
    );
  }

  PracticeSession _copy({
    String? topicId,
    RestitutionFormat? format,
    PracticeSessionStatus? status,
    String? notes,
    String? presentation,
    bool? rerolled,
    DateTime? startedAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) => PracticeSession(
    id: id,
    topicId: topicId ?? this.topicId,
    format: format ?? this.format,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    presentation: presentation ?? this.presentation,
    rerolled: rerolled ?? this.rerolled,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt,
    completedAt: completedAt ?? this.completedAt,
  );
}
