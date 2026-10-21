/// The Academy's local reminders: what a parent can switch on, and the plan
/// of notifications that follows from it.
///
/// OFF BY DEFAULT. Nothing is scheduled, and no permission is asked, until a
/// parent turns a reminder on. At most one quiet notification a day, at the
/// time the parent chose, for the next [kAcademyReminderDays] days; no
/// streaks, no counts, no guilt, and nothing about a child in the text. It is
/// all on this device: no account and no server is involved.
///
/// Pure Dart: the plan is a function of the settings, the clock and whether
/// any lesson is waiting to be revisited.
library;

import 'dart:convert';

const String kAcademyRemindPref = 'ar.academy.remind.v1';

/// How many days ahead are planned. The plan is rebuilt on every launch and
/// resume, so it is a rolling window, and it stays well under the 64
/// notifications iOS keeps.
const int kAcademyReminderDays = 7;

class AcademyReminderSettings {
  const AcademyReminderSettings({
    this.lesson = false,
    this.reviews = false,
    this.hour = 19,
    this.minute = 0,
  });

  /// Remind about the day's lesson.
  final bool lesson;

  /// Remind about lessons waiting to be revisited.
  final bool reviews;

  /// Local time of day.
  final int hour;
  final int minute;

  bool get any => lesson || reviews;

  AcademyReminderSettings copyWith({
    bool? lesson,
    bool? reviews,
    int? hour,
    int? minute,
  }) =>
      AcademyReminderSettings(
        lesson: lesson ?? this.lesson,
        reviews: reviews ?? this.reviews,
        hour: (hour ?? this.hour).clamp(0, 23),
        minute: (minute ?? this.minute).clamp(0, 59),
      );

  String encode() => jsonEncode(<String, Object>{
        'lesson': lesson,
        'reviews': reviews,
        'hour': hour,
        'minute': minute,
      });

  /// The settings stored in [raw]; everything off when there are none or
  /// they cannot be read.
  static AcademyReminderSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return const AcademyReminderSettings();
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const AcademyReminderSettings();
      return const AcademyReminderSettings().copyWith(
        lesson: j['lesson'] == true,
        reviews: j['reviews'] == true,
        hour: (j['hour'] as num?)?.toInt(),
        minute: (j['minute'] as num?)?.toInt(),
      );
    } catch (_) {
      return const AcademyReminderSettings();
    }
  }
}

/// One notification to hand to the scheduler. [at] is a local wall-clock
/// time; the caller converts it to the absolute instant.
class AcademyReminder {
  const AcademyReminder({
    required this.dayOffset,
    required this.at,
    required this.title,
    required this.body,
  });

  /// 0 = today. The notification id is the Academy id base plus this.
  final int dayOffset;
  final DateTime at;
  final String title;
  final String body;
}

const String kAcademyReminderTitle = 'Wasia Academy';

/// What the notification says for the switches that are on.
String academyReminderBody({required bool lesson, required bool reviews}) {
  if (lesson && reviews) {
    return 'A few quiet minutes: today’s lesson, and the lessons ready '
        'to revisit.';
  }
  if (lesson) {
    return 'Today’s lesson is ready when you are. A few minutes is '
        'plenty.';
  }
  return 'Some lessons are ready to revisit. A few minutes is plenty.';
}

/// The notifications for the next [kAcademyReminderDays] days.
///
/// [reviewsWaiting] is whether any lesson is in the review queue. A
/// reviews-only reminder is not planned while nothing is waiting, so it never
/// announces an empty queue. Times that are already past are left out.
List<AcademyReminder> planAcademyReminders({
  required DateTime now,
  required AcademyReminderSettings settings,
  required bool reviewsWaiting,
}) {
  final bool lesson = settings.lesson;
  final bool reviews = settings.reviews && reviewsWaiting;
  if (!lesson && !reviews) return const <AcademyReminder>[];
  final String body = academyReminderBody(lesson: lesson, reviews: reviews);
  final List<AcademyReminder> out = <AcademyReminder>[];
  for (int d = 0; d < kAcademyReminderDays; d++) {
    final DateTime at = DateTime(
      now.year,
      now.month,
      now.day + d,
      settings.hour,
      settings.minute,
    );
    if (!at.isAfter(now)) continue;
    out.add(AcademyReminder(
      dayOffset: d,
      at: at,
      title: kAcademyReminderTitle,
      body: body,
    ));
  }
  return out;
}
