import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/hadi/data/local_knowledge.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';

/// The real corpus and the real bundled Qur'an, read from disk, so tests
/// need no asset bundle.
HadiCorpus loadRealCorpus() {
  final Map<String, dynamic> corpus = json.decode(
    File('assets/noor/hadi_corpus.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<dynamic> quran = json.decode(
    File('assets/quran/quran.json').readAsStringSync(),
  ) as List<dynamic>;
  return HadiCorpus.fromJson(corpus: corpus, quran: quran);
}

Map<String, dynamic> readCorpusJson() => json.decode(
      File('assets/noor/hadi_corpus.json').readAsStringSync(),
    ) as Map<String, dynamic>;

/// The bundled English for ayat [from]..[to] of [surah], joined by spaces.
String quranEnglish(int surah, int from, int to) {
  final List<dynamic> quran = json.decode(
    File('assets/quran/quran.json').readAsStringSync(),
  ) as List<dynamic>;
  final List<dynamic> verses =
      (quran[surah - 1] as Map<String, dynamic>)['v'] as List<dynamic>;
  final StringBuffer b = StringBuffer();
  for (int a = from; a <= to; a++) {
    b.write('${(verses[a - 1] as List<dynamic>)[2] as String} ');
  }
  return b.toString();
}

/// Letters and digits only, lower case.
String condenseText(String s) =>
    s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// The local index over the real guides, Q&A bank and story packs.
LocalKnowledge loadRealKnowledge() {
  List<dynamic> list(String path) =>
      json.decode(File(path).readAsStringSync()) as List<dynamic>;
  final List<dynamic> stories = <dynamic>[
    for (final String n in kHadiKnowledgeStoryPacks)
      ...list('assets/stories/$n.json'),
  ];
  return LocalKnowledge.fromJson(
    guides: list('assets/guides/guides.json'),
    qa: (json.decode(File('assets/qa/qa_bank.json').readAsStringSync())
        as Map<String, dynamic>)['questions'] as List<dynamic>,
    stories: stories,
  );
}
