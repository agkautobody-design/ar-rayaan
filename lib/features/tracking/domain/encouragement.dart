/// Warm words for the private log. Pure Dart so every line can be tested.
///
/// The rules, from the owner: congratulate people who are new, welcome people
/// back, and nudge gently (and only if they want it) when someone logs rarely.
/// Never guilt. An empty day is empty space, and nothing here
/// is a run length, a loss, a comparison or a reward. The words are about
/// gratitude and encouragement only.
library;

import 'tracking_math.dart';

/// What kind of line this is.
enum EncouragementKind {
  /// Nothing logged yet: an open door.
  startAnyTime,

  /// The very first thing the person logged.
  firstLog,

  /// Still inside the first week of using the log.
  firstWeek,

  /// Back after a gap of a week or more.
  welcomeBack,

  /// Logging rarely: only the optional small-step nudge applies.
  quiet,

  /// Nothing special to say.
  none,
}

/// A line to show, and an optional nudge the person can dismiss.
class Encouragement {
  const Encouragement(this.kind, this.text, {this.nudge});

  final EncouragementKind kind;

  /// The main line, or null when there is nothing special to say.
  final String? text;

  /// An optional, dismissible invitation. Never guilt.
  final String? nudge;
}

abstract final class EncouragementMath {
  /// A gap of at least this many days counts as "coming back".
  static const int welcomeBackAfterDays = 7;

  /// Without a log for this many days the small-step nudge may appear.
  static const int nudgeAfterDays = 3;

  static const String startText =
      'Nothing is logged yet. Start whenever you like, there is no rush.';
  static const String firstLogText =
      'Your first one is logged. Welcome, and thank you for being here.';
  static const String firstWeekText =
      'Your first week with the log. Glad you are here.';
  static const String welcomeBackText = 'Welcome back, glad you’re here.';
  static const String nudgeText = 'A small step today?';

  /// The line for a person whose logged days (across everything) are [days].
  static Encouragement forDays(Set<String> days, DateTime today) {
    final DateTime now = TrackingMath.dayOf(today);
    final Set<String> ok = TrackingMath.clean(days, now);
    if (ok.isEmpty) {
      return const Encouragement(
        EncouragementKind.startAnyTime,
        startText,
      );
    }
    final String todayKey = TrackingMath.stamp(now);
    final bool loggedToday = ok.contains(todayKey);
    final DateTime first = TrackingMath.firstLogged(ok, now)!;
    final DateTime last = TrackingMath.lastLogged(ok, now)!;
    final bool inFirstWeek = TrackingMath.daysBetween(first, now) <= 6;

    if (loggedToday) {
      if (ok.length == 1) {
        return const Encouragement(EncouragementKind.firstLog, firstLogText);
      }
      final Set<String> before = <String>{...ok}..remove(todayKey);
      final DateTime prior = TrackingMath.lastLogged(before, now)!;
      if (TrackingMath.daysBetween(prior, now) >= welcomeBackAfterDays) {
        return const Encouragement(
          EncouragementKind.welcomeBack,
          welcomeBackText,
        );
      }
      if (inFirstWeek) {
        return const Encouragement(EncouragementKind.firstWeek, firstWeekText);
      }
      return const Encouragement(EncouragementKind.none, null);
    }

    final int gap = TrackingMath.daysBetween(last, now);
    if (gap >= welcomeBackAfterDays) {
      return const Encouragement(
        EncouragementKind.welcomeBack,
        welcomeBackText,
        nudge: nudgeText,
      );
    }
    if (inFirstWeek) {
      return const Encouragement(EncouragementKind.firstWeek, firstWeekText);
    }
    if (gap >= nudgeAfterDays) {
      return const Encouragement(
        EncouragementKind.quiet,
        null,
        nudge: nudgeText,
      );
    }
    return const Encouragement(EncouragementKind.none, null);
  }

  /// Plain total lines, for a period. Never a run, never a loss.
  static String totalLine({
    required int count,
    required String unitOne,
    required String unitMany,
    required String periodWords,
  }) {
    if (count <= 0) return 'Nothing logged $periodWords. Start whenever you like.';
    return '$count ${count == 1 ? unitOne : unitMany} $periodWords.';
  }
}
