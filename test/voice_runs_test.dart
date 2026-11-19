import 'package:flutter_test/flutter_test.dart';
import 'package:ar_rayaan/app/core/sound/voice_book.dart';

void main() {
  test('English alone is one run', () {
    final List<SpeechRun> r = SpeechRuns.split('Say it with me, slowly.');
    expect(r.length, 1);
    expect(r.single.arabic, isFalse);
  });

  test('Arabic inside English becomes its own run', () {
    final List<SpeechRun> r = SpeechRuns.split(
        'Say \u0628\u0633\u0645 \u0627\u0644\u0644\u0647 before eating.');
    expect(r.map((SpeechRun x) => x.arabic).toList(),
        <bool>[false, true, false]);
    expect(r[0].text, 'Say');
    expect(r[2].text, 'before eating.');
  });

  test('Arabic comma and digits do not switch the voice', () {
    final List<SpeechRun> r = SpeechRuns.split('Ayah 2 \u060C then more');
    expect(r.length, 1);
    expect(r.single.arabic, isFalse);
  });

  test('punctuation alone makes no run', () {
    expect(SpeechRuns.split(' ... 12 '), isEmpty);
  });
}
