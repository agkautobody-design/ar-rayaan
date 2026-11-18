import 'package:flutter_test/flutter_test.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_multipart.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';

void main() {
  test('splits the compound question from the audit', () {
    final List<String> p = HadiMultiPart.split(
        'I want to learn about Islam tell me about the battle of uhud tell me '
        'about all the prophets before Prophet Muhammad and how they were or '
        'were not Muslim?');
    expect(p.length, 2);
    expect(p[0].toLowerCase(), contains('uhud'));
    expect(p[1].toLowerCase(), contains('prophets'));
  });

  test('a single question is not split', () {
    expect(HadiMultiPart.split('How do I pray fajr?'), isEmpty);
    expect(HadiMultiPart.split('What is the ruling on music?'), isEmpty);
    expect(HadiMultiPart.split('explain wudu'), isEmpty);
  });

  test('two question marks make two parts, at most three', () {
    final List<String> p = HadiMultiPart.split(
        'How many rakat is fajr? How many rakat is maghrib? '
        'How many rakat is isha? How many rakat is zuhr?');
    expect(p.length, 3);
  });

  test('both parts of a compound question are answered', () async {
    final String r = await const OfflineHadiProvider().ask(
        'tell me about the battle of uhud and also tell me about the '
        'prophets before prophet muhammad',
        const []);
    expect(r.toLowerCase(), contains('uhud'));
    expect(r.toLowerCase(), contains('prophets'));
  });
}
