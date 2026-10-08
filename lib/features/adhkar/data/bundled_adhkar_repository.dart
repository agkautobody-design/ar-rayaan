import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../application/adhkar_repository.dart';
import '../domain/adhkar_models.dart';

/// Serves the bundled Hisn al-Muslim adhkar sets. Parsed once.
class BundledAdhkarRepository implements AdhkarRepository {
  List<AdhkarSet>? _cache;

  @override
  Future<List<AdhkarSet>> sets() async {
    final List<AdhkarSet>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await rootBundle.loadString('assets/adhkar/adhkar.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final List<AdhkarSet> sets = <AdhkarSet>[
      for (final Map<String, dynamic> s
          in (data['sets'] as List<dynamic>).cast<Map<String, dynamic>>())
        AdhkarSet(
          id: s['id'] as String,
          titleEn: s['titleEn'] as String,
          titleAr: s['titleAr'] as String,
          items: <Dhikr>[
            for (final Map<String, dynamic> i
                in (s['items'] as List<dynamic>).cast<Map<String, dynamic>>())
              Dhikr(
                number: i['n'] as int,
                arabic: i['ar'] as String,
                count: i['count'] as int,
                translation: i['en'] as String?,
              ),
          ],
        ),
    ];
    _cache = sets;
    return sets;
  }
}
