import 'package:flutter_test/flutter_test.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_learned.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';

const String _pack = '''
{"schema":1,"entries":[
 {"id":"l-1","keys":["explain the lesson about the spider web house"],
  "answer":"Allah is with the patient (Qur\\u2019an 2:153). Scholar review needed.",
  "refs":["2:153"],"created":"2026-11-19","expires":"2027-02-17"},
 {"id":"l-2","keys":["an expired question about something"],
  "answer":"old","refs":["1:1"],"created":"2026-01-01","expires":"2026-04-01"}
]}
''';

void main() {
  test('a learned answer is used for the exact normalised question', () async {
    HadiLearned.parse(_pack, now: DateTime(2026, 11, 20));
    expect(HadiLearned.count, 1);
    final String a = await const OfflineHadiProvider()
        .ask('Please tell me: Explain the lesson about the spider web house?',
            const []);
    expect(a, contains('2:153'));
    expect(a, contains('Scholar review needed'));
  });

  test('expired and near-miss questions are not answered from the pack', () {
    HadiLearned.parse(_pack, now: DateTime(2026, 11, 20));
    expect(HadiLearned.answer('an expired question about something'), isNull);
    expect(HadiLearned.answer('explain the lesson about the spider'), isNull);
    expect(HadiLearned.answer('hi'), isNull);
  });

  test('a broken pack leaves Hadi as it was', () {
    expect(() => HadiLearned.parse('not json'), throwsA(anything));
    HadiLearned.parse('{"entries":[]}');
    expect(HadiLearned.count, 0);
  });
}
