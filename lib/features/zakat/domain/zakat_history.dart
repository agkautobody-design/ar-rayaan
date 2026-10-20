/// A saved zakat calculation: the result and the choices behind it, never the
/// individual balances. Kept on the device only.
///
/// "Compare with last year" is arithmetic on two saved results; it says
/// nothing about what is owed beyond what the calculator itself computed.
library;

import 'dart:convert';

class ZakatRecord {
  const ZakatRecord({
    required this.date,
    required this.madhab,
    required this.nisabBasis,
    required this.tolaFigures,
    required this.netZakatable,
    required this.nisabValue,
    required this.zakatDue,
    required this.eligible,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    this.currency = '',
    this.note = '',
  });

  /// Calendar day the calculation was saved (time of day dropped).
  final DateTime date;

  /// 'hanafi' | 'maliki' | 'shafii' | 'hanbali'.
  final String madhab;

  /// 'silver' | 'gold'.
  final String nisabBasis;

  /// True when the South Asian tola figures were used for nisab.
  final bool tolaFigures;

  final double netZakatable;
  final double nisabValue;
  final double zakatDue;
  final bool eligible;

  /// Prices the user had entered (per gram, in their own currency).
  final double goldPricePerGram;
  final double silverPricePerGram;

  /// Free text the user typed, such as "CAD" (the app never assumes one).
  final String currency;
  final String note;

  Map<String, Object> toJson() => <String, Object>{
    'date': _stamp(date),
    'madhab': madhab,
    'nisabBasis': nisabBasis,
    'tola': tolaFigures,
    'net': netZakatable,
    'nisab': nisabValue,
    'due': zakatDue,
    'eligible': eligible,
    'gold': goldPricePerGram,
    'silver': silverPricePerGram,
    'currency': currency,
    'note': note,
  };

  /// Null when [j] is not a usable record.
  static ZakatRecord? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final DateTime? d = DateTime.tryParse('${j['date']}');
    if (d == null) return null;
    double num0(String k) => (j[k] is num) ? (j[k] as num).toDouble() : 0;
    return ZakatRecord(
      date: DateTime(d.year, d.month, d.day),
      madhab: '${j['madhab'] ?? ''}',
      nisabBasis: '${j['nisabBasis'] ?? 'silver'}',
      tolaFigures: j['tola'] == true,
      netZakatable: num0('net'),
      nisabValue: num0('nisab'),
      zakatDue: num0('due'),
      eligible: j['eligible'] == true,
      goldPricePerGram: num0('gold'),
      silverPricePerGram: num0('silver'),
      currency: '${j['currency'] ?? ''}',
      note: '${j['note'] ?? ''}',
    );
  }

  static String _stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// The most records kept; the oldest is dropped past this.
const int kMaxZakatRecords = 20;

abstract final class ZakatHistory {
  static String encode(List<ZakatRecord> records) =>
      jsonEncode(<Object>[for (final ZakatRecord r in records) r.toJson()]);

  /// Records newest first; unreadable entries are skipped.
  static List<ZakatRecord> decode(String? raw) {
    if (raw == null) return <ZakatRecord>[];
    try {
      final Object? j = jsonDecode(raw);
      if (j is! List<dynamic>) return <ZakatRecord>[];
      final List<ZakatRecord> out = <ZakatRecord>[
        for (final dynamic e in j)
          if (ZakatRecord.fromJson(e) case final ZakatRecord r) r,
      ];
      out.sort((ZakatRecord a, ZakatRecord b) => b.date.compareTo(a.date));
      return out;
    } catch (_) {
      return <ZakatRecord>[];
    }
  }

  /// [record] added to [records] (newest first). A second save on the same
  /// day replaces that day's record; the list is capped at
  /// [kMaxZakatRecords].
  static List<ZakatRecord> add(List<ZakatRecord> records, ZakatRecord record) {
    final List<ZakatRecord> next = <ZakatRecord>[
      record,
      for (final ZakatRecord r in records)
        if (r.date != record.date) r,
    ]..sort((ZakatRecord a, ZakatRecord b) => b.date.compareTo(a.date));
    return next.length <= kMaxZakatRecords
        ? next
        : next.sublist(0, kMaxZakatRecords);
  }

  /// The saved record to compare [record] with: the one closest to a year
  /// earlier, if any falls between 300 and 430 days before; otherwise the
  /// most recent earlier record. Null when there is none.
  static ZakatRecord? comparisonFor(
    ZakatRecord record,
    List<ZakatRecord> records,
  ) {
    ZakatRecord? best;
    int bestGap = 1 << 30;
    ZakatRecord? latestEarlier;
    for (final ZakatRecord r in records) {
      final int days = record.date.difference(r.date).inDays;
      if (days <= 0) continue;
      if (latestEarlier == null || r.date.isAfter(latestEarlier.date)) {
        latestEarlier = r;
      }
      if (days >= 300 && days <= 430) {
        final int gap = (days - 365).abs();
        if (gap < bestGap) {
          best = r;
          bestGap = gap;
        }
      }
    }
    return best ?? latestEarlier;
  }

  /// True when [earlier] is roughly a year before [record].
  static bool isYearApart(ZakatRecord record, ZakatRecord earlier) {
    final int days = record.date.difference(earlier.date).inDays;
    return days >= 300 && days <= 430;
  }
}
