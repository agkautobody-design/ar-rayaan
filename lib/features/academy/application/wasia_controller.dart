import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/subscription/subscription_service.dart';

import '../../hadi/application/hadi_provider.dart';
import '../../hadi/data/groq_hadi_provider.dart';
import '../../hadi/data/offline_hadi_provider.dart';
import '../data/offline_wasia_provider.dart';

enum WasiaPersona { student, parent, teacher }

/// One brain, three voices. Research-backed shape: a specific, in-domain
/// persona that NAMES its audience and context beats a generic role label —
/// so each voice rides on top of Wasia's teaching laws, not instead of them.
String personaPrompt(WasiaPersona p,
    {String? childName, int? lessonsDone, int? examsTaken}) {
  switch (p) {
    case WasiaPersona.student:
      return kWasiaSystemPrompt;
    case WasiaPersona.parent:
      return '$kWasiaSystemPrompt\n'
          'YOU ARE SPEAKING WITH A PARENT'
          '${childName != null ? " — their child is $childName" : ""}, '
          'gently, without jargon. '
          '${lessonsDone != null ? "Progress so far: $lessonsDone of 28 letter lessons, ${examsTaken ?? 0} exams. " : ""}'
          'Encourage honestly, suggest ONE concrete practice, and always '
          'leave them feeling capable.';
    case WasiaPersona.teacher:
      return '$kWasiaSystemPrompt\n'
          'YOU ARE SPEAKING WITH A TEACHER or a homeschool parent running '
          'a classroom. Share pedagogy: how to sequence letters, when to '
          'introduce joining, how to run the unit exam, how to handle a '
          'struggling student. Be collegial, practical, and cite the '
          'lessons by name.';
  }
}

const String kWasiaSystemPrompt =
    'You are Wasia, the beloved teacher of Wasia Academy inside the Ar-Rayaan '
    'app, named after the founder\u2019s daughter. You teach Qur\u2019an, Arabic '
    'letters, tajweed, duas, and Islamic knowledge to students of every age.\n'
    'Teaching laws:\n'
    '1. Greet with warmth; praise effort, not just results.\n'
    '2. Teach in small steps; one idea at a time; end with a tiny question.\n'
    '3. Never invent religious rulings — if fiqh arises, give the mainstream '
    'view and advise asking a local scholar.\n'
    '4. Keep answers under 90 words: gentle, clear, hopeful.\n'
    '5. When teaching Qur\u2019an or hadith content, stay with the established text.\n'
    '6. TEACH the app as well: when a parent asks about progress, explain the '
    'Family Wing shows each child\u2019s lessons and exams, and offer to help '
    'them write a progress report to send.\n'
    '7. When a parent asks a fiqh or worship question beyond teaching '
    'children, do not rule — say: "Hādi answers this best — you will find '
    'him under Ask Hādi."\n'
    '8. When a student passes an exam or finishes a unit, mark the moment '
    'warmly in words — "Mā shā’ Allāh, tell your family" — and suggest one '
    'small next step. Celebrations are spoken, never scored.';

/// Wasia's conversation: every box feeds one thread, so she remembers
/// follow-ups ("what about the second letter?") across the whole session.
class WasiaState {
  const WasiaState({
    this.messages = const <HadiMessage>[],
    this.isLoading = false,
  });

  final List<HadiMessage> messages;
  final bool isLoading;

  WasiaState copy({List<HadiMessage>? messages, bool? isLoading}) {
    return WasiaState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Wasia reuses the same user-owned AI key as Hadi — one key, both teachers.
class WasiaController extends StateNotifier<WasiaState> {
  WasiaController(this.ref) : super(const WasiaState());

  final Ref ref;

  static const String _keyPref = 'ar.hadi.apikey';

  Future<String?> _key() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(_keyPref);
    if (k != null && k.trim().isNotEmpty) return k.trim();
    // Subscription fallback, same rules as Hādi: managed key, one quota
    // per question. Quota spent or inactive → her own shelf below.
    final sub = ref.read(subscriptionServiceProvider.notifier);
    if (sub.isEntitled && sub.consumeQuestion()) return sub.managedKey;
    return null;
  }

  /// Start a fresh conversation with Wasia.
  void clear() => state = const WasiaState();

  Future<String> ask(String question,
      {WasiaPersona persona = WasiaPersona.student,
      String? childName,
      int? lessonsDone,
      int? examsTaken}) async {
    final q = question.trim();
    if (q.isEmpty || state.isLoading) return '';
    // Keyless: Wasia teaches from her OWN curated shelf — the Academy
    // curriculum (letters, units, exams, parent FAQ). She never borrows
    // Hadi's religious shelf for a child's letter question, and never
    // invents what she does not know.
    final k = await _key();
    if (k == null) {
      // Quota spent (but still subscribed)? Say so honestly before the
      // shelf answer — never let a limit masquerade as ignorance.
      String? quotaNote;
      final sub = ref.read(subscriptionServiceProvider.notifier);
      if (sub.isEntitled && sub.managedKey != null) {
        quotaNote = 'Your live questions for today are finished — the '
            'subscription resets at midnight. Meanwhile, from my lesson '
            'shelf:\n\n';
      }
      // Wasia's own shelf — the Academy curriculum, not Hadi's. She
      // doesn't navigate: strip any [GO:] token so her thread stays clean.
      var offline =
          await const OfflineWasiaProvider().ask(q, state.messages);
      offline = offline.replaceAll(RegExp(r'\[GO:[^\]]+\]'), '').trim();
      if (quotaNote != null) offline = quotaNote + offline;
      state = state.copy(
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q),
          HadiMessage(fromHadi: true, text: offline),
        ],
      );
      return offline;
    }

    final first = state.messages.isEmpty;
    state = state.copy(
      isLoading: true,
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: false, text: q),
      ],
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ar.hadi.provider') ?? 'groq';
      final HadiProvider p = switch (provider) {
        'openrouter' => OpenRouterHadiProvider(apiKey: k),
        'xai' => XaiHadiProvider(apiKey: k),
        _ => GroqHadiProvider(apiKey: k),
      };
      // The voice lands in the FIRST message only, like a system prompt;
      // follow-ups ride the conversation history.
      final voice = personaPrompt(persona,
          childName: childName,
          lessonsDone: lessonsDone,
          examsTaken: examsTaken);
      final who = switch (persona) {
        WasiaPersona.student => 'Student',
        WasiaPersona.parent => 'Parent',
        WasiaPersona.teacher => 'Teacher',
      };
      final content = first ? '$voice\n\n$who asks: $q' : q;
      final answer = await p.ask(content, state.messages);
      var msgs = <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: true, text: answer),
      ];
      // Cap the thread: keep the persona anchor + the most recent turns.
      if (msgs.length > 14) {
        msgs = <HadiMessage>[msgs.first, ...msgs.sublist(msgs.length - 12)];
      }
      state = state.copy(messages: msgs, isLoading: false);
      return answer;
    } catch (e) {
      // A failed turn must not wedge the conversation: drop the pending
      // question so the user can rephrase.
      state = state.copy(
        isLoading: false,
        messages: state.messages.sublist(0, state.messages.length - 1),
      );
      return 'Wasia could not reach her voice just now ($e). '
          'The lesson above still carries everything — keep walking it.';
    }
  }
}

final wasiaControllerProvider =
    StateNotifierProvider<WasiaController, WasiaState>((ref) {
  return WasiaController(ref);
});
