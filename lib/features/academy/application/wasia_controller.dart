import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/subscription/subscription_service.dart';
import '../../../app/core/content/content_sync.dart';
import 'family_service.dart';
import 'dart:convert';

import '../../hadi/application/hadi_provider.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../../hadi/data/groq_hadi_provider.dart';
import '../data/offline_wasia_provider.dart';
import '../domain/letters_meta.dart';

enum WasiaPersona { student, parent, teacher }

/// Parent-controlled switch: may a child's questions go to an AI service?
/// Off by default. Even when on, the child's name is never sent.
const String kWasiaChildLlmPref = 'ar.wasia.child_llm';

/// Fixed reply when a message may describe self-harm, abuse or danger. It
/// runs before ANY answer (shelf or live AI), nothing the person wrote is
/// sent anywhere, and it never invents a phone number.
String wasiaCrisisReply(WasiaPersona persona) {
  const String help =
      'If you or someone else is in danger right now, call your country\u2019s '
      'emergency number. The Sakina section in the app lists help lines for '
      'your country, and H\u0101di can talk with you gently.';
  if (persona == WasiaPersona.student) {
    return 'Thank you for telling me \u2014 I am so glad you did. This is '
        'something a grown-up you trust needs to know about today: a parent, '
        'a teacher, or another adult in your family. Please tell them '
        'now. You are not in trouble, and you are not alone. $help';
  }
  return 'I am so sorry you are carrying this, and I am glad you wrote it '
      'down. This needs a real person, not a lesson. Please reach out to '
      'someone you trust today, or a local professional. $help';
}

/// One brain, three voices. Research-backed shape: a specific, in-domain
/// persona that NAMES its audience and context beats a generic role label —
/// so each voice rides on top of Wasia's teaching laws, not instead of them.
/// [childName] is accepted for API compatibility but is NEVER written into
/// the prompt: the prompt goes to a third-party AI service and a child's
/// name must not leave the device.
String personaPrompt(WasiaPersona p,
    {String? childName, int? lessonsDone, int? examsTaken,
    String? studentBlock}) {
  switch (p) {
    case WasiaPersona.student:
      return '$kWasiaSystemPrompt\n'
          'STUDENT PROGRESS (real, from this device\u2019s Family Wing — '
          'never guess beyond it):\n'
          '${studentBlock?.trim().isNotEmpty == true ? studentBlock!.trim() : "No progress recorded yet."}\n'
          'Use it to encourage specifically: name what they finished and '
          'suggest one small next step. Never quiz the child on facts not '
          'in this block. If the block is empty, simply teach with '
          'warmth.';
    case WasiaPersona.parent:
      return '$kWasiaSystemPrompt\n'
          'YOU ARE SPEAKING WITH A PARENT, '
          'gently, without jargon. '
          '${lessonsDone != null ? "Progress so far: $lessonsDone of $kLettersLessonCount letter lessons, ${examsTaken ?? 0} exams. " : ""}'
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
    '3. Never give a religious ruling. If fiqh arises, say you cannot rule on '
    'it, point to Hādi (who names his sources) and advise asking a local '
    'scholar.\n'
    '4. Keep answers under 90 words: gentle, clear, hopeful.\n'
    '5. Do not quote Qur\u2019an or hadith from memory. Teach only what the '
    'lesson in front of the student says; if you are not sure, say so and '
    'point to the lesson or to Hādi.\n'
    '6. TEACH the app as well: when a parent asks about progress, explain the '
    'Family Wing shows each child\u2019s lessons and exams, and offer to help '
    'them write a progress report to send.\n'
    '7. When a parent asks a fiqh or worship question beyond teaching '
    'children, do not rule — say: "Hādi answers this best — you will find '
    'him under Ask Hādi."\n'
    '8. When a student passes an exam or finishes a unit, mark the moment '
    'warmly in words — "Mā shā’ Allāh, tell your family" — and suggest one '
    'small next step. Celebrations are spoken, never scored.\n'
    '9. The Academy has more than twenty schools; if a question belongs to another '
    'school, name it and point: the Q&A Bank answers this, or Hisn '
    'al-Muslim holds the dua you need. You teach letters; the Academy '
    'teaches everything else.\n'
    '10. Never ask for, repeat or use a child\u2019s name, age, school, '
    'address or any personal detail. If a child says they are hurt, scared '
    'or unsafe, tell them to speak to a trusted adult today.';

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


  /// Per-student detail for her student voice: the active child's real
  /// progress from the Family Wing on THIS device (lessons with their
  /// titles, last exam score). Empty string when there is no active
  /// child — she simply teaches, and never invents progress.
  Future<String> _studentBlock(WasiaPersona persona) async {
    if (persona != WasiaPersona.student) return '';
    try {
      final FamilyService fam = FamilyService();
      final String? childId = await fam.activeChildId();
      if (childId == null) return '';
      final Map<String, dynamic> prog = await fam.progress(childId);
      final Map<dynamic, dynamic> lessons =
          prog['lessons'] as Map<dynamic, dynamic>? ?? <String, dynamic>{};
      final Map<dynamic, dynamic> exams =
          prog['exams'] as Map<dynamic, dynamic>? ?? <String, dynamic>{};
      // Lesson titles from the curriculum — ids become names.
      Map<String, dynamic>? v2;
      try {
        v2 = json.decode(
                await ContentSync.load('academy/letters_v2_curriculum.json'))
            as Map<String, dynamic>;
      } catch (_) {
        v2 = null;
      }
      final Map<String, dynamic> cur = mergeLettersCurriculum(
          json.decode(
                  await ContentSync.load('academy/letters_curriculum.json'))
              as Map<String, dynamic>,
          v2);
      final Map<String, String> titles = <String, String>{};
      for (final dynamic u in cur['units'] as List<dynamic>? ?? <dynamic>[]) {
        final List<dynamic> ls =
            (u as Map)['lessons'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic l in ls) {
          titles[(l as Map)['id'] as String] = l['title'] as String;
        }
      }
      final List<String> done = lessons.keys
          .map((dynamic k) => titles[k as String] ?? k)
          .toList()
        ..sort();
      // The child's name is deliberately NOT put in the prompt: it would be
      // sent to a third-party AI service. Progress only.
      final StringBuffer buf = StringBuffer('This student has completed '
          '${done.length} of $kLettersLessonCount letter lessons.');
      if (done.isNotEmpty) {
        buf.write(' Most recent: ${done.last}.');
      }
      if (exams.isNotEmpty) {
        final String lastExam = exams.keys.last as String;
        final Map<dynamic, dynamic> e = exams[lastExam] as Map<dynamic, dynamic>;
        buf.write(' Last exam: ${e['score']}/${e['total'] ?? 10}.');
      }
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  /// Whether a parent has allowed a child's questions to reach an AI service.
  static Future<bool> childLlmAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kWasiaChildLlmPref) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setChildLlmAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kWasiaChildLlmPref, value);
  }

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
    // Safety net first: before the shelf, before any AI, nothing is sent.
    final CrisisKind? crisis = CrisisDetector.detect(q);
    if (crisis != null) {
      final String reply = wasiaCrisisReply(persona);
      state = state.copy(
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q, sensitive: true),
          HadiMessage(
              fromHadi: true, text: reply, crisis: crisis, sensitive: true),
        ],
      );
      return reply;
    }
    // Keyless: Wasia teaches from her OWN curated shelf — the Academy
    // curriculum (letters, units, exams, parent FAQ). She never borrows
    // Hadi's religious shelf for a child's letter question, and never
    // invents what she does not know.
    // A child's questions stay on the shelf unless a parent has switched the
    // AI service on (and then no name is sent).
    final bool aiAllowed = persona != WasiaPersona.student ||
        await childLlmAllowed();
    final k = aiAllowed ? await _key() : null;
    if (k == null) {
      // Quota spent (but still subscribed)? Say so honestly before the
      // shelf answer — never let a limit masquerade as ignorance.
      String? quotaNote;
      final sub = ref.read(subscriptionServiceProvider.notifier);
      if (aiAllowed && sub.isEntitled && sub.managedKey != null) {
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
          examsTaken: examsTaken,
          studentBlock: await _studentBlock(persona));
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
    } catch (_) {
      // A failed turn must not wedge the conversation: drop the pending
      // question so the user can rephrase.
      state = state.copy(
        isLoading: false,
        messages: state.messages.sublist(0, state.messages.length - 1),
      );
      // The error text is never shown: it can carry a key, a URL or a stack.
      return 'Wasia could not reach her voice just now. '
          'The lesson above still carries everything — keep walking it.';
    }
  }
}

final wasiaControllerProvider =
    StateNotifierProvider<WasiaController, WasiaState>((ref) {
  return WasiaController(ref);
});
