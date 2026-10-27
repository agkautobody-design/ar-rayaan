import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/subscription/subscription_service.dart';
import '../../hadi/application/hadi_provider.dart';
import '../../hadi/data/api_key_vault.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../../sakina/domain/crisis_latch.dart';
import '../../hadi/grounding/ruling_gate.dart';
import '../../hadi/data/groq_hadi_provider.dart';
import '../data/offline_wasia_provider.dart';
import '../domain/lesson_grounding.dart';
import '../../support/data/pack_repository.dart';
import '../../support/domain/student_routing.dart';
import '../../support/domain/support_engine.dart';
import '../../support/domain/child_distress.dart';
import 'child_age_band.dart';

enum WasiaPersona { student, parent, teacher }

/// Parent-controlled switch: may a child's questions go to an AI service?
/// Off by default. Even when on, the child's name is never sent.
const String kWasiaChildLlmPref = 'ar.wasia.child_llm';

/// Fixed reply when a message may describe self-harm, abuse or danger. It
/// runs before ANY answer (shelf or live AI), nothing the person wrote is
/// sent anywhere, and it never invents a phone number.
String wasiaCrisisReply(WasiaPersona persona) {
  // No pointer to the Sakina section: child mode closes it. The help lines
  // are shown under this message by the thread itself.
  const String help =
      'If you or someone else is in danger right now, call your country\u2019s '
      'emergency number. The help lines are listed just below this message.';
  if (persona == WasiaPersona.student) {
    return 'Thank you for telling me \u2014 I am so glad you did. This is '
        'something ${CrisisResponses.trustedAdultForChild} needs to know '
        'about today. You choose who to tell. I cannot call or tell anyone '
        'for you, so please do it now. You are not in trouble, and you are '
        'not alone. $help';
  }
  return 'I am so sorry you are carrying this, and I am glad you wrote it '
      'down. This needs a real person, not a lesson. Please reach out to '
      'someone you trust today, or a local professional. $help';
}

/// Pointer added to a parent's reply about a hurting or bullied child.
const String kWasiaParentListeningPointer =
    'There is a short guide for exactly this, with what to say, what not to '
    'say, and when to ask the school or a doctor: open \u201cHow to listen to a '
    'child who is hurting\u201d just below this box.';

/// What a parent is told when the lessons do not cover the question. Not the
/// child-directed "back to your letters".
const String kWasiaParentDecline =
    'I cannot answer that from my lessons, and I would rather not guess. If '
    'it is about helping a child who is hurting or bullied, open \u201cHow to '
    'listen to a child who is hurting\u201d just below this box. For worship '
    'or daily-life questions, H\u0101di can help, or a teacher or scholar you '
    'trust.';

/// One brain, three voices. Research-backed shape: a specific, in-domain
/// persona that NAMES its audience and context beats a generic role label —
/// so each voice rides on top of Wasia's teaching laws, not instead of them.
///
/// PRIVACY: nothing about a child ever goes into a prompt. Not the name (also
/// accepted only for API compatibility and never written), and not the
/// child's progress either: the prompt goes to a third-party AI service, and
/// the children's privacy text promises that no profile data leaves the
/// device. If you add a field here, change `children_privacy.dart` in the
/// same commit.
String personaPrompt(WasiaPersona p, {String? childName}) {
  switch (p) {
    case WasiaPersona.student:
      return '$kWasiaSystemPrompt\n'
          'YOU ARE SPEAKING WITH A STUDENT. You are told nothing about them: '
          'no name, no progress, no history. Never claim to know what they '
          'have or have not finished. Teach with warmth and suggest one '
          'small next step.';
    case WasiaPersona.parent:
      return '$kWasiaSystemPrompt\n'
          'YOU ARE SPEAKING WITH A PARENT, '
          'gently, without jargon. You are not given their child\u2019s name '
          'or progress; if they ask how their child is doing, say the Family '
          'Wing shows each child\u2019s lessons and exams. '
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

/// Most characters of a lesson sent as the ground of an answer.
const int kWasiaLessonTextCap = 6000;

/// The block that makes the lesson text the only ground of a live answer. It
/// is the app's own lesson wording: nothing about the learner is in it.
String lessonGroundingBlock(LessonGrounding lesson) {
  final String text = lesson.text.length > kWasiaLessonTextCap
      ? lesson.text.substring(0, kWasiaLessonTextCap)
      : lesson.text;
  return 'THE LESSON IN FRONT OF THE STUDENT: ${lesson.title}\n'
      'Answer ONLY from the lesson text below. If the answer is not in it, '
      'say you cannot find it in this lesson and point to Hādi or a teacher. '
      'Add no fact, ruling, hadith, verse reference or Arabic that is not in '
      'this text. Never give a ruling.\n'
      'LESSON TEXT (between the two lines of dashes):\n'
      '-----\n$text\n-----';
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
    'or unsafe, tell them to speak to a trusted adult today (a parent if it '
    'is safe, a teacher, a school counsellor, or a child helpline) and let '
    'them choose who. Never say you will tell anyone.';

/// Wasia's conversation: every box feeds one thread, so she remembers
/// follow-ups ("what about the second letter?") across the whole session.
class WasiaState {
  const WasiaState({
    this.messages = const <HadiMessage>[],
    this.isLoading = false,
    this.notice,
  });

  final List<HadiMessage> messages;
  final bool isLoading;

  /// A plain note for the person when the last question could not be
  /// answered (for example Wasia could not reach her voice). Cleared by the
  /// next question.
  final String? notice;

  WasiaState copy({
    List<HadiMessage>? messages,
    bool? isLoading,
    String? notice,
    bool clearNotice = false,
  }) {
    return WasiaState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

/// Wasia reuses the same user-owned AI key as Hadi — one key, both teachers.
class WasiaController extends StateNotifier<WasiaState> {
  WasiaController(
    this.ref, {
    HadiProvider Function(String name, String key)? providerFor,
    this.forParent = false,
  })  : _providerFor = providerFor,
        super(const WasiaState());

  final Ref ref;

  /// True for the parent's own box. A parent has a separate conversation from
  /// every child: nothing a child types is ever in it, and nothing the parent
  /// types reaches a child.
  final bool forParent;

  /// Which child the thread belongs to (null = no child chosen). A thread
  /// never carries one child's words to another.
  String? _threadChild;
  bool _childSeen = false;

  /// Drops the conversation when the active child is not the one it belongs
  /// to. Call when a screen opens and before every question.
  Future<void> syncChild() async {
    if (forParent) return;
    final String? id = await ChildAgeBand.activeId();
    if (_childSeen && _threadChild != id && state.messages.isNotEmpty) clear();
    _threadChild = id;
    _childSeen = true;
  }

  /// Test seam: builds the live provider. Null = the real one.
  final HadiProvider Function(String name, String key)? _providerFor;

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
    final k = ApiKeyVault.read(prefs);
    if (k != null && k.trim().isNotEmpty) return k.trim();
    // Subscription fallback, same rules as Hādi: managed key, one quota
    // per question. Quota spent or inactive → her own shelf below.
    final sub = ref.read(subscriptionServiceProvider.notifier);
    if (sub.isEntitled && sub.consumeQuestion()) return sub.managedKey;
    return null;
  }

  /// Kept in memory only: set once a crisis card has been shown, so the next
  /// short replies ("ok", "tonight") get a safety check instead of a lesson.
  CrisisKind? _latch;
  int _latchChecks = 0;

  /// The memory of a school-and-learning support conversation: rotation
  /// history only. It lives in memory, holds nothing about the child, and is
  /// dropped with the thread.
  SupportSession _support = SupportSession(seed: DateTime.now().microsecondsSinceEpoch);

  /// The age band a parent set for the active child, or the default.
  Future<String> _band() => ChildAgeBand.active();

  /// Whose voice the current thread was started in. A thread never mixes
  /// voices: the persona prompt is sent once, with the first message, so a
  /// parent's words must not ride along into a child's conversation.
  WasiaPersona? _threadPersona;

  /// The lesson the current thread is about (null = a thread outside any
  /// lesson). A thread never carries one lesson's questions into another, so
  /// the lesson text is sent once, with the first message, and a new lesson
  /// starts a new thread.
  String? _threadLesson;

  /// Called when a screen about [lessonId] opens (null = a screen outside any
  /// lesson): a thread that belongs to another lesson is dropped, so the
  /// learner never sees, or continues, a conversation about a different one.
  void openLesson(String? lessonId) {
    if (_threadLesson != lessonId && state.messages.isNotEmpty) clear();
  }

  /// Start a fresh conversation with Wasia.
  void clear() {
    _latch = null;
    _latchChecks = 0;
    _support = SupportSession(seed: DateTime.now().microsecondsSinceEpoch);
    _threadPersona = null;
    _threadLesson = null;
    state = const WasiaState();
  }

  /// Whether this voice may reach an AI service at all. DEFAULT-DENY:
  ///  * a student: only when a parent switched the child AI route on;
  ///  * a parent: only when the caller has just passed the parent check
  ///    ([parentVerified]);
  ///  * a teacher: never (there is no screen for it; the shelf answers).
  Future<bool> aiAllowedFor(WasiaPersona persona,
      {bool parentVerified = false}) async {
    switch (persona) {
      case WasiaPersona.student:
        return childLlmAllowed();
      case WasiaPersona.parent:
        return parentVerified;
      case WasiaPersona.teacher:
        return false;
    }
  }

  /// Ask Wasia a question. With [lesson] she answers about THAT lesson only:
  /// offline from the lesson's own sentences, or (when this voice may reach an
  /// AI service) from the AI with the lesson text as the only ground and every
  /// reply checked by [WasiaAnswerVerifier]. A question that asks for a ruling
  /// is never sent anywhere.
  Future<String> ask(String question,
      {WasiaPersona persona = WasiaPersona.student,
      bool parentVerified = false,
      LessonGrounding? lesson}) async {
    final q = question.trim();
    if (q.isEmpty || state.isLoading) return '';
    await syncChild();
    if (_threadPersona != persona || _threadLesson != lesson?.id) {
      _threadPersona = persona;
      _threadLesson = lesson?.id;
      state = const WasiaState();
    }
    // Safety net first: before the shelf, before any AI, nothing is sent.
    final CrisisKind? crisis = CrisisDetector.detect(q);
    if (crisis != null) {
      _latch = crisis == CrisisKind.extremism ? null : crisis;
      _latchChecks = 0;
      final String reply = wasiaCrisisReply(persona);
      state = state.copy(
        clearNotice: true,
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q, sensitive: true),
          HadiMessage(
              fromHadi: true, text: reply, crisis: crisis, sensitive: true),
        ],
      );
      return reply;
    }
    final CrisisKind? latched = _latch;
    if (latched != null) {
      final bool safe = CrisisLatch.saysSafe(q);
      if (safe || CrisisLatch.isAmbiguous(q)) {
        final String reply = safe
            ? CrisisLatch.relief
            : CrisisLatch.checkFor(latched, _latchChecks,
                child: persona == WasiaPersona.student);
        if (safe) {
          _latch = null;
          _latchChecks = 0;
        } else {
          _latchChecks++;
        }
        state = state.copy(
          clearNotice: true,
          messages: <HadiMessage>[
            ...state.messages,
            HadiMessage(fromHadi: false, text: q, sensitive: true),
            HadiMessage(
                fromHadi: true,
                text: reply,
                crisis: safe ? null : latched,
                sensitive: true),
          ],
        );
        return reply;
      }
    }
    // A child who says they are unhappy, scared or hurt (mean children, nobody
    // likes me, I do not want to go home, someone hurts me) or who asks for a
    // secret to be kept gets a listening reply, with trusted-adult choices and
    // the child helpline button, never "beyond what I can teach" and never a
    // push back to the lessons. Fixed wording by age band. Nothing is sent
    // anywhere and nothing is kept.
    if (persona == WasiaPersona.student) {
      final ChildDistressKind? d = ChildDistress.detect(q);
      if (d != null) {
        final String band = await _band();
        final String reply = ChildDistress.reply(d, band);
        _latch = CrisisKind.childSafety;
        _latchChecks = 0;
        state = state.copy(
          clearNotice: true,
          messages: <HadiMessage>[
            ...state.messages,
            HadiMessage(fromHadi: false, text: q, sensitive: true),
            HadiMessage(
              fromHadi: true,
              text: reply,
              sensitive: true,
              crisis: CrisisKind.childSafety,
            ),
          ],
        );
        return reply;
      }
    }
    // School and learning worries (bullying, exam fear, "I am stupid", a
    // video that upset them, a parent's worry about a learning difference) are
    // answered on the device from the student_problems pack. Nothing is sent
    // anywhere, nothing is saved, no label is put on the child, and a learning
    // difference is referred, never diagnosed.
    if (persona != WasiaPersona.teacher) {
      final bool parent = persona == WasiaPersona.parent;
      final StudentConcern? concern = StudentRouting.classify(q, parent: parent);
      final SupportEngine? eng = SupportPackRepository.engine;
      if (concern != null && (eng != null || parent)) {
        final String band = parent ? 'adult' : await _band();
        final SupportTurn? turn = eng?.reply(
          _support,
          pack: 'student_problems',
          userText: q,
          ageBand: band,
          extraCues: StudentRouting.cues(concern),
        );
        if (turn != null || parent) {
          final bool childAtRisk = !parent &&
              (concern == StudentConcern.bullying ||
                  concern == StudentConcern.exposure ||
                  concern == StudentConcern.familyStrain);
          final String base = turn?.text ?? '';
          final String text = parent
              ? <String>[
                  if (base.isNotEmpty) base,
                  kWasiaParentListeningPointer,
                ].join('\n\n')
              : childAtRisk
                  ? '$base\n\nIf it keeps happening or it scares you, tell ${CrisisResponses.trustedAdultForChild}.'
                  : base;
          state = state.copy(
            clearNotice: true,
            messages: <HadiMessage>[
              ...state.messages,
              HadiMessage(fromHadi: false, text: q, sensitive: true),
              HadiMessage(
                fromHadi: true,
                text: text,
                sensitive: true,
                supportIds: turn?.ids ?? const <String>[],
                crisis: childAtRisk ? CrisisKind.childSafety : null,
              ),
            ],
          );
          return text;
        }
      }
    }
    // Keyless: Wasia teaches from her OWN curated shelf — the Academy
    // curriculum (letters, units, exams, parent FAQ). She never borrows
    // Hadi's religious shelf for a child's letter question, and never
    // invents what she does not know.
    // A child's questions stay on the shelf unless a parent has switched the
    // AI service on (and then no name is sent).
    // A ruling question inside a lesson is answered with a fixed redirect:
    // nothing about it goes to an AI service.
    // The same holds outside a lesson: a ruling question never goes to an AI
    // service, whoever asks.
    final bool ruled = RulingGate.classify(q) != RulingClass.none;
    final bool aiAllowed = !ruled &&
        await aiAllowedFor(persona, parentVerified: parentVerified);
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
      var offline = lesson != null
          ? (ruled
              ? kWasiaNoRulings
              : LessonAnswerer.answer(q, lesson.text) ?? kWasiaNotInLesson)
          : await const OfflineWasiaProvider().ask(q, state.messages);
      offline = offline.replaceAll(RegExp(r'\[GO:[^\]]+\]'), '').trim();
      // A parent is never told "get back to your letters".
      if (persona == WasiaPersona.parent &&
          (offline == OfflineWasiaProvider.decline ||
              offline.contains('your letters'))) {
        offline = kWasiaParentDecline;
      }
      if (quotaNote != null) offline = quotaNote + offline;
      state = state.copy(
        clearNotice: true,
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q),
          HadiMessage(fromHadi: true, text: offline),
        ],
      );
      return offline;
    }

    // What was said before this question. The question itself is sent once,
    // as the new message, never also inside the history.
    // Sensitive turns (a crisis card and the words that led to it) are never
    // part of what a model is sent.
    final List<HadiMessage> before = state.messages
        .where((HadiMessage m) => !m.sensitive)
        .toList(growable: false);
    state = state.copy(
      isLoading: true,
      clearNotice: true,
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: false, text: q),
      ],
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ar.hadi.provider') ?? 'groq';
      final HadiProvider Function(String, String)? make = _providerFor;
      final HadiProvider p = make != null
          ? make(provider, k)
          : switch (provider) {
              'openrouter' => OpenRouterHadiProvider(apiKey: k),
              'xai' => XaiHadiProvider(apiKey: k),
              _ => GroqHadiProvider(apiKey: k),
            };
      // The voice (and, inside a lesson, the lesson text) is the SYSTEM
      // message of every request, so a follow-up is taught under the same
      // rules as the first question. A provider that cannot take a system
      // prompt is sent the same text in front of the question instead.
      final String voice = personaPrompt(persona);
      final String who = switch (persona) {
        WasiaPersona.student => 'Student',
        WasiaPersona.parent => 'Parent',
        WasiaPersona.teacher => 'Teacher',
      };
      final String grounding =
          lesson == null ? '' : '\n\n${lessonGroundingBlock(lesson)}';
      final String system = '$voice$grounding';
      String answer;
      if (p is SystemPromptProvider) {
        answer = await p.askWithSystem(system, '$who asks: $q', before);
      } else {
        answer = await p.ask('$system\n\n$who asks: $q', before);
      }
      // Every live reply is checked, in a lesson or not. In a lesson a
      // reference, quotation, Arabic or hadith grade the lesson does not carry
      // is removed; outside one nothing is carried, so every reference,
      // quotation, run of Arabic and grade goes. Raw [GO:], [DO:] and [[src:]]
      // tokens never reach a child, and neither does a verdict on the
      // person's own case.
      final VerifiedWasiaAnswer v =
          WasiaAnswerVerifier.verify(answer, lesson?.text ?? '');
      final ({String text, bool changed}) f = RulingGate.filterLive(v.text);
      answer = f.text;
      if (answer.trim().isEmpty) answer = kWasiaNotInLesson;
      if (v.changed || f.changed) {
        answer = lesson != null
            ? '$answer\n\n$kWasiaRemovedNote'
            : '$answer\n\n$kWasiaRemovedNoteOutside';
      }
      var msgs = <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: true, text: answer),
      ];
      // Cap the thread: keep the most recent turns.
      if (msgs.length > 14) {
        msgs = msgs.sublist(msgs.length - 12);
      }
      state = state.copy(messages: msgs, isLoading: false);
      return answer;
    } catch (_) {
      // A failed turn must not wedge the conversation: drop the pending
      // question so the user can rephrase, and say so on screen.
      // The error text is never shown: it can carry a key, a URL or a stack.
      const String note = 'Wasia could not reach her voice just now. '
          'The lesson above still carries everything — keep walking it.';
      state = state.copy(
        isLoading: false,
        notice: note,
        messages: state.messages.sublist(0, state.messages.length - 1),
      );
      return note;
    }
  }
}

final wasiaControllerProvider =
    StateNotifierProvider<WasiaController, WasiaState>((ref) {
  return WasiaController(ref);
});

/// The parent's own conversation. It is a different thread from every child's:
/// a parent screen never reads [wasiaControllerProvider].
final wasiaParentControllerProvider =
    StateNotifierProvider<WasiaController, WasiaState>((ref) {
  return WasiaController(ref, forParent: true);
});
