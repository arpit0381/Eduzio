import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Provider exposing the local Isar database instance (nullable on web/unsupported platforms).
final isarProvider = Provider<Isar?>((ref) => null);
