import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/distress_signal.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// 14 Nov 2026 persona test: after a grief message, "can I fast with
/// diabetes" and an interfaith question were answered with a wellbeing check
/// and helplines. A fresh factual question leaves the listening flow; a
/// question about the person's own feelings stays in it.
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

  test('the detector splits fresh questions from feelings', () {
    expect(DistressSignal.asksToLearn('can I fast with diabetes'), isTrue);
    expect(
        DistressSignal.asksToLearn('what do we share with Christians'), isTrue);
    expect(DistressSignal.asksToLearn('how do I make wudu'), isTrue);
    expect(DistressSignal.asksToLearn('how do I cope with this'), isFalse);
    expect(DistressSignal.asksToLearn('why do I feel so empty'), isFalse);
    expect(DistressSignal.asksToLearn('what can I do'), isFalse);
    expect(DistressSignal.asksToLearn('yes please'), isFalse);
    expect(DistressSignal.asksToLearn('it has been months'), isFalse);
  });

  test('after grief, a fasting question gets the fasting answer', () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    await ctrl.ask('my mother died last week',
        provider: const OfflineHadiProvider());
    final String a = await ctrl.ask('can I fast with diabetes',
        provider: const OfflineHadiProvider());
    expect(a.toLowerCase(), contains('fast'));
    expect(a, isNot(contains('9-8-8')));
    final HadiMessage last = c.read(hadiControllerProvider).messages.last;
    expect(last.support, isNull);
  });

  test('after grief, a feelings question stays with the person', () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    await ctrl.ask('my mother died last week',
        provider: const OfflineHadiProvider());
    await ctrl.ask('why do I feel so empty',
        provider: const OfflineHadiProvider());
    final HadiMessage last = c.read(hadiControllerProvider).messages.last;
    expect(last.support, isNotNull);
  });
}
