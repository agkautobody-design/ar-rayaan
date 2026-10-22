import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

class _Stub implements HadiProvider {
  _Stub(this.reply);
  final String reply;

  @override
  Future<String> ask(String q, List<HadiMessage> h) async => reply;
}

/// P1-3: a throw anywhere after the model answered (tokens, verification,
/// the ruling filter) used to leave `typing == true`, and `ask()` refuses to
/// run while typing, so Hadi stayed dead until a reload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final HadiCorpus corpus = loadRealCorpus();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a failure after the answer exists never leaves Hadi typing', () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    ctrl.debugBeforeTail = (String answer) => throw StateError('boom');

    final String reply = await ctrl.ask(
      'I feel anxious and worried',
      provider: _Stub('Peace be with you.'),
    );

    final HadiState s = c.read(hadiControllerProvider);
    expect(s.typing, isFalse);
    expect(reply, contains('Something went wrong'));
    expect(s.messages.last.fromHadi, isTrue);
    expect(s.messages.last.text, contains('Something went wrong'));
    // The question the person asked is on screen above the reply.
    expect(
      s.messages.any((HadiMessage m) =>
          !m.fromHadi && m.text == 'I feel anxious and worried'),
      isTrue,
    );
    // The failure notice is never written to the saved thread.
    expect(s.messages.last.sensitive, isTrue);
  });

  test('Hadi answers again after a failure', () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    ctrl.debugBeforeTail = (String answer) => throw StateError('boom');
    await ctrl.ask('I feel anxious and worried', provider: _Stub('x'));

    ctrl.debugBeforeTail = null;
    final String again = await ctrl.ask(
      'I feel anxious and worried',
      provider: _Stub('Peace be with you.'),
    );

    expect(again, contains('Peace be with you.'));
    final HadiState s = c.read(hadiControllerProvider);
    expect(s.typing, isFalse);
    expect(s.messages.last.text, contains('Peace be with you.'));
  });
}
