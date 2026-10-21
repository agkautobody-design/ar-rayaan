import 'prayer_notification_scheduler.dart';

/// Pure helpers for keeping the OS notification set equal to a plan. Kept
/// free of any plugin import so they can be unit tested on any platform.

/// Which scheduled ids to cancel so that, inside the id range chosen by
/// [inRange], exactly [wanted] remain. Ids outside the range are never
/// touched. Re-scheduling an id that is already pending replaces it, so
/// wanted ids are not cancelled first.
List<int> staleIds({
  required Iterable<int> pending,
  required Set<int> wanted,
  required bool Function(int id) inRange,
}) {
  return <int>[
    for (final int id in pending)
      if (inRange(id) && !wanted.contains(id)) id,
  ];
}

/// True for ids owned by the prayer plan.
bool isPrayerId(int id) => id < kReminderIdBase;

/// True for ids owned by the zakat reminders.
bool isReminderId(int id) =>
    id >= kReminderIdBase && id < kAcademyReminderIdBase;

/// True for ids owned by the Academy reminders.
bool isAcademyReminderId(int id) => id >= kAcademyReminderIdBase;

/// The most notifications handed to the OS at once. iOS keeps only the 64
/// soonest pending local notifications, so the plan is a rolling window
/// rebuilt on every launch, resume and settings change, and a few slots are
/// left for reminders.
const int kMaxPrayerNotifications = 56;
