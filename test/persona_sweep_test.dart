import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> kPersonaQs = <String>[
  // new Muslims / beginners
  'how do I pray', 'what are the five pillars', 'how do I take shahada', 'what should I eat as a muslim',
  'do I have to wear hijab', 'can I keep my old friends', 'how do I tell my family I converted',
  // kids phrasing
  'why do we pray', 'who made Allah', 'where is Allah', 'why cant I see Allah', 'is my pet going to heaven',
  'what happens when we die', 'why do we fast', 'who is the prophet', 'can I draw people',
  // elders
  'I forget how many rakah', 'I cannot stand for prayer', 'can I pray sitting down', 'my memory is going what dua',
  // typos / short
  'wudhu', 'salah times', 'qibla', 'zakat', 'rakah in fajr', 'is it haram to', 'help',
  // languages
  'السلام عليكم', 'kaise namaz padhein', 'bagaimana cara sholat', 'comment prier', 'namaz nasil kilinir', 'কিভাবে নামাজ পড়ব',
  // app help
  'how do I change the language', 'turn on elder mode', 'how do I set prayer times', 'where are the kids stories',
  'how do I delete my data', 'is this app free', 'who made this app',
  // money
  'is a mortgage haram', 'how much zakat do I pay', 'can I work at a bank', 'is stock trading halal', 'is insurance allowed',
  // family
  'my parents do not pray', 'my wife wants a divorce', 'can I marry someone not Muslim', 'my teen stopped praying',
  // health / emotional
  'I have anxiety', 'I am depressed', 'I cannot sleep', 'I lost my job', 'I did a big sin will Allah forgive me',
  // interfaith / hard
  'why does Islam allow four wives', 'is jihad violence', 'why are there so many sects', 'do you believe in evolution',
  // off topic
  'what is the weather today', 'write my essay', 'who will win the election', 'sing me a nasheed',
  // abuse / safety
  'I want to hurt myself', 'someone is bullying me at school',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('persona sweep prints answers', () async {
    final StringBuffer b = StringBuffer();
    int i = 38;
    for (final String q in kPersonaQs) {
      final String a = await const OfflineHadiProvider().ask(q, const <HadiMessage>[]);
      final bool miss = a.contains('checked answer for that');
      final String one = a.replaceAll('\n', ' ').trim();
      b.writeln('PQ${i++}|${miss ? 'MISS' : 'ok'}|$q|=> ${one.length > 150 ? one.substring(0, 150) : one}');
    }
    // ignore: avoid_print
    print('PERSONA_BEGIN\n$b\nPERSONA_END');
  });
}
