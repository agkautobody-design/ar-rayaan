/// Dated reminders for the zakat year (hawl) and Zakat al-Fitr.
///
/// Pure planning: the dates come from the app's own Hijri calendar (the
/// basis and day adjustment the user chose), the clock time is 09:00 on the
/// device's own clock, and nothing leaves the device. The wording states the
/// rule and its source and rules on nothing else; Eid and the end of a lunar
/// year can fall a day either side of any calendar, so the text says so.
library;

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../ramadan/domain/ramadan_season.dart';
import 'hawl_tracker.dart';
import 'zakat_al_fitr.dart';

/// Ids inside the reminder range.
const int kHawlLeadReminderId = kReminderIdBase + 1;
const int kHawlDueReminderId = kReminderIdBase + 2;
const int kFitrEarlyReminderId = kReminderIdBase + 3;
const int kFitrLastReminderId = kReminderIdBase + 4;

/// Days before the hawl ends that the first reminder is delivered.
const int kHawlLeadDays = 3;

/// 09:00 on [day]'s calendar date, on the device clock, as an absolute time.
DateTime _morning(DateTime day, {int offsetDays = 0}) =>
    DateTime(day.year, day.month, day.day + offsetDays, 9).toUtc();

/// The reminders still in the future at [now].
///
/// [hawlStart] is the day the user marked; [hawlOn] and [fitrOn] are their
/// opt-ins (everything is off until they choose).
List<PlannedReminder> planZakatReminders({
  required DateTime now,
  required bool hawlOn,
  required bool fitrOn,
  DateTime? hawlStart,
}) {
  final DateTime t = now.toUtc();
  final List<PlannedReminder> out = <PlannedReminder>[];

  void add(int id, DateTime at, String title, String body) {
    if (at.isAfter(t)) {
      out.add(PlannedReminder(id: id, at: at, title: title, body: body));
    }
  }

  if (hawlOn && hawlStart != null) {
    final HawlStatus s = HawlTracker.status(hawlStart, now);
    add(
      kHawlLeadReminderId,
      _morning(s.dueDate, offsetDays: -kHawlLeadDays),
      'Your zakat year ends in $kHawlLeadDays days',
      'By your calendar. Open Ar-Rayaan to work out your zakat.',
    );
    add(
      kHawlDueReminderId,
      _morning(s.dueDate),
      'Your zakat year is complete',
      'Zakat is due. Open Ar-Rayaan to work it out.',
    );
  }

  if (fitrOn) {
    final DateTime eid = RamadanSeason.forDate(now).end;
    add(
      kFitrEarlyReminderId,
      _morning(eid, offsetDays: -2),
      'Zakat al-Fitr',
      'It is paid before the Eid prayer (${ZakatAlFitr.source}). '
          'Eid can fall a day either side of the calendar.',
    );
    add(
      kFitrLastReminderId,
      _morning(eid, offsetDays: -1),
      'Zakat al-Fitr: Eid is close',
      'Pay it before the Eid prayer (${ZakatAlFitr.source}).',
    );
  }
  return out;
}
