import 'package:shared_preferences/shared_preferences.dart';

/// Reads only the parent-set age band of the active child, so that Wasia can
/// choose age-appropriate words. It reads no name, progress or other family
/// data. The keys match FamilyService.
abstract final class ChildAgeBand {
  static const List<String> bands = <String>['5-8', '9-12', '13-17'];
  static const String fallback = '9-12';

  /// The id of the active child, or null. Used only to keep one child's
  /// conversation away from another's.
  static Future<String?> activeId() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      return p.getString('ar.family.active');
    } catch (_) {
      return null;
    }
  }

  static Future<String> active() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? id = p.getString('ar.family.active');
      if (id == null) return fallback;
      final String? v = p.getString('ar.family.age_band.$id');
      return (v != null && bands.contains(v)) ? v : fallback;
    } catch (_) {
      return fallback;
    }
  }
}
