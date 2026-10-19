import 'package:drift/drift.dart';

import '../converters.dart';

/// English practice sessions: a topic drawn at random, researched, then
/// presented. The constraints mirror the rules of the `PracticeSession`
/// domain class.
///
/// `topic_id` is the stable id of a topic in the app's bundled catalog; the
/// catalog itself is not stored. `format` and `status` hold the names of the
/// `RestitutionFormat` and `PracticeSessionStatus` enum values. Renaming a
/// value means migrating the stored data.
///
/// `presentation` holds a written presentation; it stays null for a spoken
/// one, since no audio is stored. `completed_at` is set exactly when the
/// session is completed.
@DataClassName('PracticeSessionRow')
class PracticeSessions extends Table {
  TextColumn get id => text()();
  TextColumn get topicId => text()();
  TextColumn get format => text()();
  TextColumn get status => text()();
  TextColumn get notes => text()();
  TextColumn get presentation => text().nullable()();
  BoolColumn get rerolled => boolean()();
  IntColumn get startedAt => integer().map(const UtcInstantConverter())();
  IntColumn get updatedAt => integer().map(const UtcInstantConverter())();
  IntColumn get completedAt =>
      integer().map(const UtcInstantConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (length(trim(topic_id)) > 0)",
    "CHECK (format IN ('voiceNote', 'explainToAChild', 'tedIntro', 'debate', "
        "'shortEssay', 'keyFacts', 'expertEmail'))",
    "CHECK (status IN ('researching', 'presenting', 'completed'))",
    "CHECK ((status = 'completed') = (completed_at IS NOT NULL))",
  ];
}
