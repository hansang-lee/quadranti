import 'package:hive_ce/hive_ce.dart';

/// Small per-device settings.
abstract class Prefs {
  /// Whether [userId] has seen the guide (GuideScreen).
  Future<bool> guideSeen(String userId);
  Future<void> markGuideSeen(String userId);
}

class HivePrefs implements Prefs {
  Future<Box> _open() => Hive.openBox('prefs');

  @override
  Future<bool> guideSeen(String userId) async => (await _open()).get('guideSeen_$userId') == true;

  @override
  Future<void> markGuideSeen(String userId) async => (await _open()).put('guideSeen_$userId', true);
}

class MemoryPrefs implements Prefs {
  final Set<String> _seen = {};

  @override
  Future<bool> guideSeen(String userId) async => _seen.contains(userId);

  @override
  Future<void> markGuideSeen(String userId) async => _seen.add(userId);
}
