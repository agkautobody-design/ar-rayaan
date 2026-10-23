/// Pure logic for the Jumu'ah row: when is the next Friday congregation at
/// the time the person typed in for their mosque, and how to say how far away
/// it is. No Flutter, no providers, so it is unit tested on its own.
library;

/// The next Friday occurrence of [hhmm] ("HH:mm", the saved mosque time) at or
/// after [now], in the same wall clock as [now]. Null when [hhmm] is missing
/// or not a valid time.
///
/// On a Friday before the time it is today; on a Friday after the time it is
/// next Friday.
DateTime? nextJumuah(DateTime now, String? hhmm) {
  if (hhmm == null) return null;
  final List<String> parts = hhmm.trim().split(':');
  if (parts.length != 2) return null;
  final int? h = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  // Walk day by day so a daylight-saving change cannot skip or repeat a day.
  for (int add = 0; add <= 7; add++) {
    final DateTime day = DateTime(now.year, now.month, now.day + add);
    if (day.weekday != DateTime.friday) continue;
    final DateTime at = DateTime(day.year, day.month, day.day, h, m);
    if (!at.isBefore(now)) return at;
  }
  return null;
}

/// "Today in 1h 20m", "Tomorrow", "In 3 days" style text for the gap between
/// [now] and [at]. Plain words, no jargon.
String jumuahCountdown(DateTime now, DateTime at) {
  final Duration d = at.difference(now);
  if (d.inMinutes <= 0) return 'Now';
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime thatDay = DateTime(at.year, at.month, at.day);
  final int days = thatDay.difference(today).inDays;
  if (days == 0) {
    final int h = d.inMinutes ~/ 60;
    final int m = d.inMinutes % 60;
    if (h == 0) return 'Today, in $m min';
    if (m == 0) return 'Today, in ${h}h';
    return 'Today, in ${h}h ${m}m';
  }
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}
