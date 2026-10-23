import 'package:ar_rayaan/features/huda/domain/guide_glossary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds terms whatever the apostrophe or case', () {
    final List<String> found = glossaryFor(
      'State the Niyyah, say the thana’, then bow in ruku\'.',
    ).map((GlossaryEntry e) => e.term).toList();
    expect(found, containsAll(<String>['niyyah', 'thana’', 'ruku’']));
  });

  test('does not match inside longer words', () {
    expect(glossaryFor('The imamate and sahihain are not the same'), isEmpty);
  });

  test('plain text with no terms yields nothing', () {
    expect(glossaryFor('Wash your hands and face.'), isEmpty);
  });

  test('every gloss is non-empty and states no ruling words', () {
    for (final GlossaryEntry e in kGuideGlossary) {
      expect(e.gloss.trim(), isNotEmpty);
      expect(
        RegExp(r'\b(must|obligatory|forbidden|required|invalid|allowed)\b')
            .hasMatch(e.gloss),
        isFalse,
        reason: e.term,
      );
    }
  });
}
