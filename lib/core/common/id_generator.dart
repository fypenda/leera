import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

typedef IdGenerator = String Function();

/// Creates identifiers for new records: random (version 4) UUIDs, generated
/// on the device so records never need renumbering if they are synchronised.
final idGeneratorProvider = Provider<IdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});
