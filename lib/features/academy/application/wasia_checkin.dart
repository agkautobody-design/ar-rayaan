import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../sakina/domain/crisis_detector.dart';
import '../../support/application/support_settings.dart';
import '../../support/data/pack_repository.dart';
import '../../support/domain/checkin_scheduler.dart';
import '../../support/domain/support_pack.dart';
import 'child_age_band.dart';

/// The check-in lines used when no pack is loaded, by age band.
const Map<String, String> kWasiaCheckinFallback = <String, String>{
  '5-8': 'Hello. How are you today?',
  '9-12': 'No hurry, I just like to ask now and then: how are you, really?',
  '13-17': 'No agenda, I just like to check in now and then. How are you really doing?',
  'adult': 'No agenda, I just like to ask now and then: how are you really doing?',
};

/// Wasia's reply to a grown-up who says it has been hard. Adult words: no
/// "you are not in trouble", no "a grown-up you trust". (CLINICIAN REVIEW
/// NEEDED.)
const String kWasiaCheckinHardAdult =
    'Thank you for telling me. Hard stretches come to everyone, and there is '
    'no pressure to explain. If it would help to talk, a friend, someone in '
    'your family or a doctor can be a good first step, and the help lines '
    'just below are there any time.';

/// What the check-in card shows. Held in memory only.
class WasiaCheckinState {
  const WasiaCheckinState({
    this.line,
    this.reply,
    this.hard = false,
    this.adult = false,
  });

  /// The question, while it is waiting for an answer.
  final String? line;

  /// Wasia's reply after an answer.
  final String? reply;

  /// The answer was "it has been hard": the card offers help lines.
  final bool hard;

  /// The card was asked in the adult register (a grown-up using the Academy
  /// home), so the reply and the help lines are written for an adult, not
  /// for a child.
  final bool adult;
}

/// Wasia's own gentle check-in. It is separate from Hadi's: a child is asked
/// in the words of their age band, once per interval, in the app only (never a
/// notification). Only the last-asked day and the off flag are stored, on the
/// device, per child. The answer is never stored and nothing here is read by
/// any parent screen. No guilt, no streak wording.
class WasiaCheckinNotifier extends StateNotifier<WasiaCheckinState> {
  WasiaCheckinNotifier(this.ref) : super(const WasiaCheckinState());

  final Ref ref;

  static const String keyPrefix = SupportKeys.wasiaCheckinPrefix;

  /// The clock is per child. A grown-up using the Academy home has a clock of
  /// their own, so their answers never move a child's.
  Future<String> _key({bool adult = false}) async =>
      adult ? '${keyPrefix}adult' : '$keyPrefix${await ChildAgeBand.activeId() ?? 'none'}';

  CheckinState _decode(String raw, CheckinState global) {
    try {
      final Map<String, dynamic> m = json.decode(raw) as Map<String, dynamic>;
      return CheckinState(
        lastAsked: DateTime.tryParse((m['last'] as String?) ?? ''),
        nextDue: DateTime.tryParse((m['next'] as String?) ?? ''),
        off: m['off'] == true,
        frequency: global.frequency,
      );
    } catch (_) {
      return CheckinState(frequency: global.frequency);
    }
  }

  String _encode(CheckinState c) => json.encode(<String, Object?>{
        'last': c.lastAsked?.toIso8601String().substring(0, 10),
        'next': c.nextDue?.toIso8601String().substring(0, 10),
        'off': c.off,
      });

  Future<CheckinState> _state(SharedPreferences p, String key) async {
    final CheckinState g = ref.read(supportSettingsProvider).checkin;
    if (p.getString(key) == null) {
      return CheckinState(frequency: g.frequency);
    }
    return _decode(p.getString(key)!, g);
  }

  Future<void> _save(SharedPreferences p, String key, CheckinState c) =>
      p.setString(key, _encode(c));

  /// Show the check-in when it is due. Call when a Wasia screen opens.
  /// [parentOpen] is true while the parent check is open: then nothing is
  /// shown (it is for the child).
  ///
  /// [register] says who is looking at the screen: `'adult'` (a grown-up on
  /// the Academy home: adult words, adult help lines, a clock of their own),
  /// `'13-17'` (the Teen track), or null (the active child's own band, as set
  /// by the parent).
  Future<void> maybeShow({
    bool parentOpen = false,
    DateTime? now,
    String? register,
  }) async {
    try {
      if (state.line != null || state.reply != null || parentOpen) return;
      final SupportSettings s = ref.read(supportSettingsProvider);
      if (s.privateMode || s.checkin.off) return;
      final DateTime t = now ?? DateTime.now();
      final bool adult = register == 'adult';
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String key = await _key(adult: adult);
      final CheckinState c = await _state(p, key);
      if (c.off) return;
      if (c.lastAsked == null) {
        // First open: start the clock, ask nothing.
        await _save(p, key, CheckinScheduler.start(c, t));
        return;
      }
      if (!CheckinScheduler.isDue(c, t)) return;
      final String? id = await ChildAgeBand.activeId();
      final String band = adult
          ? 'adult'
          : (register ??
              (id == null ? 'adult' : await ChildAgeBand.active()));
      String line = kWasiaCheckinFallback[band] ?? kWasiaCheckinFallback['9-12']!;
      final SupportPack? pack = SupportPackRepository.byName('checkin');
      if (pack != null && !pack.expiredAt(t)) {
        final List<String> options = <String>[
          for (final SupportSnippet x in pack.snippets)
            if (x.kind == 'checkin' &&
                x.matchesAge(band) &&
                (SupportPackRepository.allowDraft || x.shippable) &&
                x.fill('en', const <String, String>{}) != null)
              x.fill('en', const <String, String>{})!,
        ];
        if (options.isNotEmpty) line = options[t.day % options.length];
      }
      await _save(p, key, CheckinScheduler.after(c, CheckinAnswer.ignored, t));
      state = WasiaCheckinState(line: line, adult: band == 'adult');
    } catch (_) {}
  }

  /// The answer. Not stored, not shown to a parent. If it has been hard,
  /// Wasia offers a trusted adult and a child helpline, never "tell a parent"
  /// as the only choice.
  Future<void> answer(CheckinAnswer a, {DateTime? now}) async {
    final bool adult = state.adult;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String key = await _key(adult: adult);
      final CheckinState c = await _state(p, key);
      await _save(p, key, CheckinScheduler.after(c, a, now ?? DateTime.now()));
    } catch (_) {}
    final String reply = switch (a) {
      CheckinAnswer.okay => 'That is good to hear. I am here whenever you like.',
      CheckinAnswer.hard => adult ? kWasiaCheckinHardAdult : _hardForChild,
      CheckinAnswer.rather => 'That is fine. You do not have to say.',
      CheckinAnswer.ignored => '',
    };
    state = WasiaCheckinState(
      reply: reply.isEmpty ? null : reply,
      hard: a == CheckinAnswer.hard,
      adult: adult,
    );
  }

  static String get _hardForChild =>
      'Thank you for telling me. Hard days happen, and you are not in trouble. '
      'If it feels heavy, you can talk to ${CrisisResponses.trustedAdultForChild}. You choose who. '
      'The help lines are just below.';

  /// "Don't ask me again": off for this child (or, in the adult register, for
  /// this grown-up) until switched on in Settings.
  Future<void> stop({DateTime? now}) async {
    final bool adult = state.adult;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String key = await _key(adult: adult);
      final CheckinState c = await _state(p, key);
      await _save(p, key, CheckinScheduler.turnOff(c, now ?? DateTime.now()));
    } catch (_) {}
    state = const WasiaCheckinState();
  }

  /// Drop the card (a new child, a hand-over, the app closed).
  void reset() => state = const WasiaCheckinState();
}

final wasiaCheckinProvider =
    StateNotifierProvider<WasiaCheckinNotifier, WasiaCheckinState>(
  (Ref ref) => WasiaCheckinNotifier(ref),
);
