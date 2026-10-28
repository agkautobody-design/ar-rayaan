/// Loads the Academy v3 lessons, the verified-phrase registry and the Qur'an
/// text they are resolved against.
///
/// Files are discovered from the asset manifest, so a new course (or author)
/// adds `assets/academy/lessons_v3/<course>.json` or
/// `assets/academy/phrases/<author>.json` without touching any list here.
/// Every failure falls back to "no v3 lessons": the manifest lessons keep
/// working exactly as before.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../domain/v3/lesson_v3_model.dart';
import '../domain/v3/lessons_v3.dart';
import '../domain/v3/phrase_registry.dart';
import '../domain/v3/quran_verses.dart';
import '../../quran/application/quran_translit.dart' show kQuranTranslitAsset;

const String kLessonsV3Dir = 'assets/academy/lessons_v3/';
const String kPhrasesDir = 'assets/academy/phrases/';
const String kTransliterationAsset = 'assets/quran/transliteration.json';

Future<List<String>> _jsonAssetsIn(String dir) async {
  final AssetManifest manifest =
      await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> keys = manifest
      .listAssets()
      .where((String k) => k.startsWith(dir) && k.endsWith('.json'))
      .toList()
    ..sort();
  return keys;
}

/// The parsed lesson files (small). A file that does not parse is skipped, so
/// one bad course file cannot take the others down.
final lessonFilesV3Provider = FutureProvider<List<LessonsFile>>((Ref ref) async {
  try {
    final List<LessonsFile> out = <LessonsFile>[];
    for (final String key in await _jsonAssetsIn(kLessonsV3Dir)) {
      try {
        final String raw = await ContentLoader.loadString(key);
        out.add(parseLessonsFile(jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Academy v3: skipped $key ($e)');
      }
    }
    return out;
  } catch (_) {
    return const <LessonsFile>[];
  }
});

/// True when a v3 lesson replaces the manifest lesson [lessonId]. Cheap: it
/// needs only the small lesson files, not the Qur'an text.
final hasLessonV3Provider =
    FutureProvider.family<bool, String>((Ref ref, String lessonId) async {
  final List<LessonsFile> files = await ref.watch(lessonFilesV3Provider.future);
  return files.any(
    (LessonsFile f) => f.lessons.any((LessonV3 l) => l.id == lessonId),
  );
});

/// Every v3 lesson, merged and ready to resolve phrases and ayat.
final lessonsV3Provider = FutureProvider<LessonsV3>((Ref ref) async {
  final List<LessonsFile> files = await ref.watch(lessonFilesV3Provider.future);
  final List<String> phraseTexts = <String>[];
  for (final String key in await _jsonAssetsIn(kPhrasesDir)) {
    phraseTexts.add(await ContentLoader.loadString(key));
  }
  final QuranVerses quran = QuranVerses.parse(
    await ContentLoader.loadString(kQuranAsset),
    transliterationJson: await ContentLoader.loadString(kTransliterationAsset),
    fallbackTransliterationJson: await _optionalString(kQuranTranslitAsset),
  );
  return LessonsV3.build(files, PhraseRegistry.parseAll(phraseTexts), quran);
});

Future<String?> _optionalString(String key) async {
  try {
    return await ContentLoader.loadString(key);
  } catch (_) {
    return null;
  }
}
