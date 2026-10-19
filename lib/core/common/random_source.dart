import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The source of randomness for anything drawn by chance, such as a practice
/// topic. Read it through this provider so tests can supply a seeded one.
final randomProvider = Provider<Random>((ref) => Random());
