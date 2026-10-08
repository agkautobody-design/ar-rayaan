import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/noor_entry.dart';

/// Serves the bundled daily-NOOR collection (30 entries) and maps each
/// calendar day to one entry. Fully offline.
class BundledNoorRepository {
  List<NoorEntry>? _cache;

  Future<List<NoorEntry>> entries() async {
    final List<NoorEntry>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await rootBundle.loadString('assets/noor/noor.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final List<NoorEntry> parsed = <NoorEntry>[
      for (final Map<String, dynamic> e
          in (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
        NoorEntry.fromJson(e),
    ];
    _cache = parsed;
    return parsed;
  }

  /// The entry for a calendar day: day-of-year mapped onto the collection,
  /// so the NOOR rotates monthly and everyone sees the same light each day.
  Future<NoorEntry> entryFor(DateTime date) async {
    final List<NoorEntry> all = await entries();
    final int dayOfYear = date
        .difference(DateTime(date.year, 1, 1))
        .inDays; // 0-based
    return all[dayOfYear % all.length];
  }
}
