import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Provider exposing the local Isar database instance.
/// Must be overridden in the ProviderScope in main.dart.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar has not been initialized. Override it in the ProviderScope.');
});
