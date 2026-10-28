/// The gentle check-in: "No agenda, I just like to ask now and then: how are
/// you really doing?"
///
/// Rules (owner decision):
///  * in-app only, when the person opens Hadi or Wasia. Never a notification;
///  * at most once in the chosen interval (default two weeks);
///  * after "I'm okay": ask again after the interval. After "I'd rather not
///    say", or when it was ignored: after twice the interval;
///  * "Don't ask me again" is permanent until switched on in Settings;
///  * only two things are stored, on the device: the day it was last asked and
///    the off flag (plus the interval the person chose). Never tied to
///    streaks, logs or activity, and never worded as "we have not heard from
///    you".
enum CheckinAnswer { okay, hard, rather, ignored }

enum CheckinFrequency { off, weekly, fortnightly, monthly }

class CheckinState {
  const CheckinState({
    this.lastAsked,
    this.nextDue,
    this.off = false,
    this.frequency = CheckinFrequency.fortnightly,
  });

  /// The day it was last shown, date only.
  final DateTime? lastAsked;

  /// The earliest day it may be shown again.
  final DateTime? nextDue;
  final bool off;
  final CheckinFrequency frequency;

  CheckinState copy({
    DateTime? lastAsked,
    DateTime? nextDue,
    bool? off,
    CheckinFrequency? frequency,
    bool clearNextDue = false,
  }) =>
      CheckinState(
        lastAsked: lastAsked ?? this.lastAsked,
        nextDue: clearNextDue ? null : (nextDue ?? this.nextDue),
        off: off ?? this.off,
        frequency: frequency ?? this.frequency,
      );
}

abstract final class CheckinScheduler {
  static int intervalDays(CheckinFrequency f) {
    switch (f) {
      case CheckinFrequency.weekly:
        return 7;
      case CheckinFrequency.fortnightly:
        return 14;
      case CheckinFrequency.monthly:
        return 30;
      case CheckinFrequency.off:
        return 0;
    }
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// [days] calendar days after [t]. Not `t.add(Duration(days: n))`: that adds
  /// 24-hour blocks, and across a clock change it lands an hour off, which
  /// made a check-in due a whole day late.
  static DateTime _plusDays(DateTime t, int days) =>
      DateTime(t.year, t.month, t.day + days);

  /// Whether the check-in may be shown now. [busy] is true while a crisis
  /// card or latch is active, or the person is mid-conversation about
  /// something else: then it waits.
  static bool isDue(CheckinState s, DateTime now, {bool busy = false}) {
    if (busy || s.off || s.frequency == CheckinFrequency.off) return false;
    final DateTime? due = s.nextDue;
    if (due != null) return !_day(now).isBefore(due);
    final DateTime? last = s.lastAsked;
    // Never asked and no clock yet: the clock starts the first time the
    // person opens Hadi (see [start]), so a new person is not asked on day one.
    if (last == null) return false;
    return !_day(now).isBefore(_plusDays(last, intervalDays(s.frequency)));
  }

  /// The state after the check-in was shown (and the person answered, or did
  /// not).
  static CheckinState after(CheckinState s, CheckinAnswer a, DateTime now) {
    final int base = intervalDays(s.frequency);
    // Owner rule: at most once in the chosen interval, whatever the answer.
    // "It has been hard" is answered with care and the help lines there and
    // then; asking again sooner would feel like being watched. So it waits the
    // same interval as "I'm okay". Turning check-ins off still ends it.
    final int days = (a == CheckinAnswer.okay || a == CheckinAnswer.hard)
        ? base
        : base * 2;
    return s.copy(
      lastAsked: _day(now),
      nextDue: _plusDays(now, days),
    );
  }

  /// Starts the clock on first use without asking.
  static CheckinState start(CheckinState s, DateTime now) =>
      s.lastAsked == null ? s.copy(lastAsked: _day(now)) : s;

  /// "Don't ask me again": off until the person switches it on in Settings.
  static CheckinState turnOff(CheckinState s, DateTime now) =>
      s.copy(off: true, lastAsked: _day(now), clearNextDue: true);

  static CheckinState turnOn(CheckinState s) => s.copy(off: false, clearNextDue: true);

  static CheckinState setFrequency(CheckinState s, CheckinFrequency f) {
    if (f == CheckinFrequency.off) return s.copy(off: true, frequency: CheckinFrequency.fortnightly, clearNextDue: true);
    return s.copy(off: false, frequency: f, clearNextDue: true);
  }
}
