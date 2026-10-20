import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/madhhab.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

class _Stub implements HadiProvider {
  _Stub(this.reply);
  String reply;
  int calls = 0;
  final List<String> questions = <String>[];

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    questions.add(q);
    return reply;
  }
}

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

  test('a hostile live reply is cleaned before anyone sees it', () async {
    final ProviderContainer c = await container();
    final _Stub live = _Stub(
      'That is heavy. The Prophet said it in Sahih Bukhari 99999. '
      'Ease comes with hardship. [[src:q:94:5-6]] [[src:h:bukhari-424242]]',
    );
    final String a = await c
        .read(hadiControllerProvider.notifier)
        .ask('I feel anxious and worried', provider: live);
    expect(a.contains('99999'), isFalse);
    expect(a.contains('[['), isFalse);
    final HadiMessage m = c.read(hadiControllerProvider).messages.last;
    expect(m.sources, <String>['q:94:5-6']);
    expect(m.live, isTrue);
    expect(m.notes, isNotEmpty);
  });

  test('the live prompt is given passages with IDs and the school of law',
      () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    await ctrl.setMadhhab(Madhhab.shafii);
    expect(c.read(hadiControllerProvider).madhhab, Madhhab.shafii);
    final _Stub live = _Stub('Peace be with you.');
    await ctrl.ask('I feel anxious and worried', provider: live);
    final String sent = live.questions.single;
    expect(sent, contains('[[src:'));
    expect(sent, contains('Shafi'));
    expect(sent.contains('table of contents'), isFalse,
        reason: 'the contents list is only for questions about the app');
  });

  test('with nothing in the library the model is told to cite nothing',
      () async {
    final ProviderContainer c = await container();
    final _Stub live = _Stub('I do not know.');
    await c
        .read(hadiControllerProvider.notifier)
        .ask('who will win the football match', provider: live);
    expect(live.questions.single, contains('none in the library'));
  });

  test('a personal ruling never reaches a model', () async {
    final ProviderContainer c = await container();
    final _Stub live = _Stub('You must divorce.');
    final String a = await c
        .read(hadiControllerProvider.notifier)
        .ask('Is my divorce valid if I said it in anger?', provider: live);
    expect(live.calls, 0);
    expect(a.toLowerCase(), contains('qualified scholar'));
  });

  test('a general ruling gets the not-a-fatwa footer', () async {
    final ProviderContainer c = await container();
    final _Stub live = _Stub('Riba is prohibited in the Qur’an.');
    final String a = await c
        .read(hadiControllerProvider.notifier)
        .ask('What is the ruling on interest loan in Islam?', provider: live);
    expect(a, contains('not a fatwa'));
  });

  test('a verdict on the person\'s own case in a live reply is removed',
      () async {
    final ProviderContainer c = await container();
    final _Stub live = _Stub('Patience matters. You must leave the house now.');
    final String a = await c
        .read(hadiControllerProvider.notifier)
        .ask('Tell me about patience', provider: live);
    expect(a.contains('You must leave'), isFalse);
  });

  test('someone who says they are under 18 gets the fixed reply, no model',
      () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    final _Stub live = _Stub('Hello.');
    final String a = await ctrl.ask('I am 14, how do I pray?', provider: live);
    expect(live.calls, 0);
    expect(a.toLowerCase(), contains('parent'));
    final HadiMessage m = c.read(hadiControllerProvider).messages.last;
    expect(m.crisis, CrisisKind.childSafety);
    expect(m.sensitive, isTrue);
    // And it stays that way for the rest of the visit.
    final String b = await ctrl.ask('What is witr?', provider: live);
    expect(live.calls, 0);
    expect(b, isNot(a));
  });

  test('a repeated abuse message is answered on the device only', () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    final _Stub live = _Stub('Live reply.');
    await ctrl.ask('my husband beats me', provider: live);
    await ctrl.ask('my husband beats me again', provider: live);
    expect(live.calls, 0);
  });

  test('the new crisis kinds get fixed replies and never reach the model',
      () async {
    final ProviderContainer c = await container();
    final HadiController ctrl = c.read(hadiControllerProvider.notifier);
    final _Stub live = _Stub('Live reply.');
    await ctrl.ask('I have been starving myself for a week', provider: live);
    await ctrl.ask('I want to join a terrorist group', provider: live);
    expect(live.calls, 0);
  });

  test('the whitelist no longer points at rooms that are not open', () {
    expect(kHadiNavWhitelist.contains('/majlis'), isFalse);
    expect(kHadiNavWhitelist.contains('/community'), isFalse);
    expect(kHadiSystemPrompt.contains('(/majlis)'), isFalse);
    expect(kHadiSystemPrompt.contains('(/community)'), isFalse);
  });

  test('the prompt keeps its core rules and adds the scripture rule', () {
    expect(kHadiSystemPrompt, contains('six canonical books'));
    expect(kHadiSystemPrompt, contains('NEVER invent'));
    expect(kHadiSystemPrompt, contains('[[src:'));
    expect(kHadiSystemPrompt, contains('adults'));
  });

  test('navigation-like questions are told apart', () {
    expect(HadiController.isNavigationLike('Where can I find the khutbahs?'),
        isTrue);
    expect(HadiController.isNavigationLike('I feel anxious'), isFalse);
  });
}
