import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Clock = DateTime Function();

/// The single source of "now" for the app. Read the time through this
/// provider rather than calling DateTime.now() so tests can pin the date.
final clockProvider = Provider<Clock>((ref) => DateTime.now);
