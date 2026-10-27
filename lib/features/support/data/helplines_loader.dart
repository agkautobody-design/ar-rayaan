import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../sakina/domain/sakina_content.dart';

/// Reads `assets/support/helplines.json` (built and checked by tool/support)
/// into [HelpResource] rows.
///
/// Only rows with `status: verified`, a `verifiedOn` date and a `source` are
/// returned. The `toVerify` list is never read. Numbers are never typed in
/// code: they come from the file. The file is the single place a new help line
/// is added.
abstract final class HelplinesLoader {
  static const String asset = 'assets/support/helplines.json';

  static const Map<String, String> _regions = <String, String>{
    'US': 'United States',
    'CA': 'Canada',
    'GB': 'United Kingdom',
    'AU': 'Australia',
    'NZ': 'New Zealand',
    'IE': 'Ireland',
    'IN': 'India',
    'PK': 'Pakistan',
    'BD': 'Bangladesh',
    'AE': 'United Arab Emirates',
    'SA': 'Saudi Arabia',
    'QA': 'Qatar',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
    'TR': 'Türkiye',
    'EG': 'Egypt',
    'NG': 'Nigeria',
    'ZA': 'South Africa',
    'KW': 'Kuwait',
    'SG': 'Singapore',
  };

  static const Map<String, Set<HelpKind>> _kinds = <String, Set<HelpKind>>{
    'suicide': <HelpKind>{HelpKind.suicide, HelpKind.general},
    'general': <HelpKind>{HelpKind.general},
    'emergency': <HelpKind>{HelpKind.emergency},
    'poison': <HelpKind>{HelpKind.emergency},
    'addiction': <HelpKind>{HelpKind.addiction},
    'domestic-abuse': <HelpKind>{HelpKind.abuse},
    'sexual-violence': <HelpKind>{HelpKind.abuse},
    'child': <HelpKind>{HelpKind.child, HelpKind.abuse},
    'smoking': <HelpKind>{HelpKind.counselling},
    'gambling': <HelpKind>{HelpKind.counselling},
    'elder': <HelpKind>{HelpKind.counselling},
    'eating': <HelpKind>{HelpKind.eating},
    'muslim': <HelpKind>{HelpKind.muslim},
  };

  /// The scopes of a parsed row, kept for [forScope].
  static final Map<HelpResource, Set<String>> _scopes =
      <HelpResource, Set<String>>{};

  /// Parses the file text. Never throws: a malformed file gives an empty list.
  static List<HelpResource> parse(String raw) {
    final List<HelpResource> out = <HelpResource>[];
    try {
      final Object? doc = json.decode(raw);
      if (doc is! Map<String, dynamic>) return out;
      final Object? rows = doc['helplines'];
      if (rows is! List<dynamic>) return out;
      for (final Object? e in rows) {
        if (e is! Map<String, dynamic>) continue;
        final HelpResource? r = _row(e);
        if (r != null) out.add(r);
      }
    } catch (_) {
      return <HelpResource>[];
    }
    return out;
  }

  static HelpResource? _row(Map<String, dynamic> e) {
    if (e['status'] != 'verified') return null;
    final String? verifiedOn = e['verifiedOn'] as String?;
    final String? source = e['source'] as String?;
    if (verifiedOn == null || source == null || !source.startsWith('https://')) {
      return null;
    }
    final String? number = e['number'] as String?;
    final String? text = e['text'] as String?;
    final String? url = e['url'] as String?;
    final String contact = number ?? text ?? '';
    if (contact.isEmpty) return null;
    final String cc = (e['country'] as String?) ?? 'INT';
    final List<String> scope = <String>[
      for (final Object? s in (e['scope'] as List<dynamic>? ?? <dynamic>[]))
        s.toString(),
    ];
    final Set<HelpKind> kinds = <HelpKind>{
      for (final String s in scope) ...?_kinds[s],
    };
    final String digits = (number ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final bool plainPhone = number != null &&
        RegExp(r'^[0-9][0-9 \-()]*$').hasMatch(number) &&
        digits.length >= 2 &&
        digits.length <= 11;
    final String? hours = e['hours'] as String?;
    final List<String> bits = <String>[
      if (number != null && text != null) text,
      if (hours != null) 'Open $hours',
    ];
    final HelpResource r = HelpResource(
      name: (e['service'] as String?) ?? contact,
      detail: bits.isEmpty ? 'Read on the service’s own page on $verifiedOn.' : bits.join('. '),
      contact: contact,
      region: cc == 'INT' ? 'Worldwide' : (_regions[cc] ?? cc),
      dial: plainPhone ? digits : null,
      url: plainPhone ? null : (url ?? source),
      countries: cc == 'INT' ? const <String>[] : <String>[cc],
      kinds: kinds.isEmpty ? const <HelpKind>{HelpKind.general} : kinds,
      verifiedOn: verifiedOn,
      source: source,
    );
    _scopes[r] = scope.toSet();
    return r;
  }

  /// Loads the file and makes its verified rows available through
  /// [HelpResources.shown]. Call once at start-up. Never throws.
  static Future<void> load() async {
    try {
      HelpResources.extra = parse(await rootBundle.loadString(asset));
    } catch (_) {
      HelpResources.extra = <HelpResource>[];
    }
  }

  /// The verified rows for a support [scope] (for example `gambling`) in
  /// [countryCode], country rows first, then worldwide ones.
  static List<HelpResource> forScope(String scope, String? countryCode) {
    final String? cc = countryCode?.trim().toUpperCase();
    bool has(HelpResource r) => _scopes[r]?.contains(scope) ?? false;
    final List<HelpResource> rows = HelpResources.extra.where(has).toList();
    return <HelpResource>[
      for (final HelpResource r in rows)
        if (cc != null && r.countries.contains(cc)) r,
      for (final HelpResource r in rows)
        if (r.countries.isEmpty) r,
    ];
  }
}
