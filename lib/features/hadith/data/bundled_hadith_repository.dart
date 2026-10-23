import 'dart:convert';

import '../../../app/core/content_loader.dart';
import '../application/hadith_repository.dart';
import '../domain/hadith_models.dart';

/// Serves the bundled Forty Hadith of Imam an-Nawawi. Parsed once.
class BundledHadithRepository implements HadithRepository {
  List<Hadith>? _cache;

  @override
  Future<List<Hadith>> collection() async {
    final List<Hadith>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await ContentLoader.loadString(
      'assets/hadith/nawawi40.json',
    );
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    final List<Hadith> hadiths = <Hadith>[
      for (final Map<String, dynamic> h in data.cast<Map<String, dynamic>>())
        Hadith(
          number: h['n'] as int,
          arabic: h['ar'] as String,
          english: h['en'] as String,
          source: h['src'] as String?,
          grade: HadithGrade.fromJson(h),
        ),
    ];
    _cache = hadiths;
    return hadiths;
  }
}
