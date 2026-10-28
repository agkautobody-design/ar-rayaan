import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/legal/presentation/legal_screens.dart';
import 'package:ar_rayaan/features/sources/presentation/sources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who is behind the app, exactly as the owner stated it (Oct 2026): "it is
/// my app, RHW Technologies, I am the owner, Abdul G Khokhar". Nothing else
/// is claimed: no address, no company number, no incorporation, no funder,
/// no scholar behind it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> ask(String q) =>
      const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

  // Words that would claim something the owner has not said.
  final List<RegExp> invented = <RegExp>[
    RegExp(r'\b(?:Ltd|Limited|Inc|LLC|Corp|Corporation|GmbH)\b'),
    RegExp(r'\bincorporated\b', caseSensitive: false),
    RegExp(r'\bregistered (?:company|office|number|in)\b', caseSensitive: false),
    RegExp(r'\bfunded by\b', caseSensitive: false),
    RegExp(r'\bendorsed by\b', caseSensitive: false),
    RegExp(r'\breviewed by\b', caseSensitive: false),
    RegExp(r'@'),
    RegExp(r'\d{3}[ -]\d{3,4}'),
  ];

  void expectOwnerNamed(String text) {
    expect(text, contains('RHW Technologies'));
    expect(text, contains('Abdul G Khokhar'));
    for (final RegExp r in invented) {
      expect(r.hasMatch(text), isFalse, reason: '$r in: $text');
    }
  }

  group('legal pages', () {
    test('the terms and the privacy policy both say who we are', () {
      for (final List<LegalSection> sections in <List<LegalSection>>[
        kTermsSections,
        kPrivacySections,
      ]) {
        final LegalSection who =
            sections.firstWhere((LegalSection s) => s.heading == 'Who we are');
        expectOwnerNamed(who.body);
        expect(who.body, contains('they mean RHW Technologies'));
      }
    });

    test('the contact address is still pending, not invented', () {
      final String all = <String>[
        for (final LegalSection s in kTermsSections) s.body,
        for (final LegalSection s in kPrivacySections) s.body,
      ].join(' ');
      expect(all, contains(kLegalContactPending));
      expect(kLegalDraftNotice, contains('contact address'));
    });

    test('the privacy policy discloses the price services', () {
      final String p = kPrivacySections
          .map((LegalSection s) => '${s.heading} ${s.body}')
          .join(' ');
      expect(p, contains('gold-api.com'));
      expect(p, contains('jsDelivr'));
      expect(p, contains('Cloudflare'));
      expect(p, contains('nothing about your balances'));
    });
  });

  group('Hadi', () {
    test('the fixed reply names the maker and claims nothing more', () {
      expectOwnerNamed(HadiRouting.whoRunsReply);
      expect(HadiRouting.whoRunsReply, contains('free today'));
      expect(HadiRouting.whoRunsReply, contains('[GO:/sources]'));
      expect(HadiRouting.whoRunsReply,
          contains('no named scholar has reviewed the app yet'));
    });

    test('questions about who made, owns or runs the app get it', () async {
      for (final String q in <String>[
        'Who made this app?',
        'Who is behind this app?',
        'Who owns the app?',
        'Who is the owner of this app?',
        'Who runs this app and who funds it?',
      ]) {
        expect(await ask(q), HadiRouting.whoRunsReply, reason: q);
      }
    });

    test('"who made this app" is no longer sent to a support-address reply',
        () async {
      final String a = await ask('who made this app');
      expect(a, isNot(contains('I do not have a support address')));
    });

    test('the maker-and-tradition answer names the maker too', () async {
      final String a =
          await ask('Who made this app and is it Sunni or Shia?');
      expect(a, contains('RHW Technologies'));
      expect(a, contains('Abdul G Khokhar'));
      expect(a, contains('Sunni tradition'));
    });
  });

  group('Our Sources', () {
    testWidgets('names the maker and lists the price sources', (tester) async {
      tester.view.physicalSize = const Size(430, 5600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: AppTheme.dark(), home: const SourcesScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Who is behind this app'), findsOneWidget);
      expect(find.textContaining('made by RHW Technologies'), findsOneWidget);
      expect(find.textContaining('Abdul G Khokhar'), findsOneWidget);
      expect(find.textContaining('does not claim that any scholar'),
          findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('source-exchange-rates')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('source-live-prices')), findsOneWidget);
      expect(find.textContaining('gold-api.com'), findsWidgets);
      expect(find.textContaining('currency-api'), findsWidgets);
    });
  });
}
