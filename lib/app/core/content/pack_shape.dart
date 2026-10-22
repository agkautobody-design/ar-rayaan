/// Item-level shape check for remotely served content packs.
///
/// Pure Dart (no Flutter, no I/O) so it is unit-tested directly.
///
/// The bundled copy of a pack is the contract the app was built against.
/// For every list of objects in it (at the top level, or one or two levels
/// down inside those objects) this works out which keys EVERY shipped item
/// carries and what kind of value each key holds. A remote pack is only
/// usable when every item in the corresponding list is an object that still
/// carries those keys with the same kinds of value. That is what the
/// screens' casts (`j['title'] as String`) rely on, so a drifted remote
/// pack is refused here instead of blanking a screen on an older client.
class PackShape {
  const PackShape._();

  /// Deepest nesting of lists-of-objects that is compared.
  static const int maxDepth = 4;

  /// Returns null when [candidate] may be used in place of [shipped],
  /// otherwise a short reason.
  static String? problem(dynamic shipped, dynamic candidate) {
    if (shipped is List<dynamic>) {
      if (candidate is! List<dynamic>) return 'top-level shape changed';
      return _lists(<dynamic>[shipped], <dynamic>[candidate], r'$', 0);
    }
    if (shipped is Map<String, dynamic>) {
      if (candidate is! Map<String, dynamic>) return 'top-level shape changed';
      return _maps(<Map<String, dynamic>>[shipped],
          <Map<String, dynamic>>[candidate], r'$', 0);
    }
    return null;
  }

  /// Compares the lists-of-objects found under the same-named keys of the
  /// given map samples.
  static String? _maps(
    List<Map<String, dynamic>> shipped,
    List<Map<String, dynamic>> candidate,
    String path,
    int depth,
  ) {
    final Set<String> keys = <String>{
      for (final Map<String, dynamic> m in shipped) ...m.keys,
    };
    for (final String k in keys) {
      final List<dynamic> was = <dynamic>[
        for (final Map<String, dynamic> m in shipped)
          if (m[k] is List<dynamic>) m[k],
      ];
      if (was.isEmpty) continue;
      final List<dynamic> now = <dynamic>[
        for (final Map<String, dynamic> m in candidate)
          if (m[k] is List<dynamic>) m[k],
      ];
      // A section the app ships may not vanish from the pack at top level.
      if (depth == 0 && now.isEmpty) return 'missing section $k';
      final String? p = _lists(was, now, '$path.$k', depth + 1);
      if (p != null) return p;
    }
    return null;
  }

  static String? _lists(
    List<dynamic> shippedLists,
    List<dynamic> candidateLists,
    String path,
    int depth,
  ) {
    final List<Map<String, dynamic>> was = <Map<String, dynamic>>[];
    var mixed = false;
    for (final dynamic l in shippedLists) {
      for (final dynamic e in l as List<dynamic>) {
        if (e is Map<String, dynamic>) {
          was.add(e);
        } else {
          mixed = true;
        }
      }
    }
    // Only lists made of objects carry a per-item contract.
    if (was.isEmpty || mixed) return null;

    final List<Map<String, dynamic>> now = <Map<String, dynamic>>[];
    for (final dynamic l in candidateLists) {
      for (final dynamic e in l as List<dynamic>) {
        if (e is! Map<String, dynamic>) return '$path: item is not an object';
        now.add(e);
      }
    }

    // Keys every shipped item has, and the kinds of value each holds.
    Set<String> must = was.first.keys.toSet();
    for (final Map<String, dynamic> m in was) {
      must = must.intersection(m.keys.toSet());
    }
    for (final String k in must) {
      final Set<String> kinds = <String>{for (final m in was) _kind(m[k])};
      for (var i = 0; i < now.length; i++) {
        final Map<String, dynamic> item = now[i];
        if (!item.containsKey(k)) return '$path[$i]: missing "$k"';
        if (!kinds.contains(_kind(item[k]))) {
          return '$path[$i]: "$k" changed type';
        }
      }
    }

    if (depth < maxDepth) {
      return _maps(was, now, path, depth + 1);
    }
    return null;
  }

  static String _kind(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return 'string';
    if (v is num) return 'number';
    if (v is bool) return 'bool';
    if (v is List<dynamic>) return 'list';
    if (v is Map<String, dynamic>) return 'map';
    return 'other';
  }
}
