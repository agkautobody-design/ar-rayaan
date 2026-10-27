import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/scholar_review.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/sources/domain/scholar_review_summary.dart';
import 'package:ar_rayaan/features/sources/presentation/review_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _register() =>
    jsonDecode(File('tool/scholar_review/register.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('label wording', () {
    test('one wording', () {
      expect(kScholarReviewNeeded, 'Scholar review needed');
    });

    test('with no sign-off the text is the label', () {
      expect(scholarReviewText('huda.guide.huda-wudu'), kScholarReviewNeeded);
      expect(scholarReviewStillNeeded('hadi'), isTrue);
    });
  });

  group('sign-off ledger', () {
    test('the shipped ledger holds only complete, named sign-offs', () {
      kScholarSignoffs.forEach((String key, ScholarSignoff s) {
        expect(s.isComplete, isTrue, reason: key);
      });
    });

    test('a sign-off needs a name and an ISO date', () {
      expect(const ScholarSignoff(reviewedBy: '', reviewedOn: '2026-10-27').isComplete,
          isFalse);
      expect(const ScholarSignoff(reviewedBy: 'A', reviewedOn: '27 Oct').isComplete,
          isFalse);
      expect(const ScholarSignoff(reviewedBy: 'A', reviewedOn: '2026-10-27').isComplete,
          isTrue);
    });

    test('a sign-off on a parent covers everything beneath it', () {
      const Map<String, ScholarSignoff> ledger = <String, ScholarSignoff>{
        'huda.guide': ScholarSignoff(reviewedBy: 'Test', reviewedOn: '2026-01-02'),
      };
      expect(scholarReviewText('huda.guide.huda-wudu', ledger: ledger),
          'Reviewed by Test on 2026-01-02');
      expect(scholarReviewText('huda.madhhab.huda-wudu', ledger: ledger),
          kScholarReviewNeeded);
    });

    test('an incomplete entry never removes the label', () {
      const Map<String, ScholarSignoff> ledger = <String, ScholarSignoff>{
        'hadi': ScholarSignoff(reviewedBy: 'Test', reviewedOn: ''),
      };
      expect(scholarReviewText('hadi.core.music', ledger: ledger),
          kScholarReviewNeeded);
    });

    test('data that carries reviewedBy and reviewedOn wins', () {
      expect(
        scholarReviewText('x', reviewedBy: 'Test', reviewedOn: '2026-01-02'),
        'Reviewed by Test on 2026-01-02',
      );
      expect(scholarReviewText('x', reviewedBy: 'Test'), kScholarReviewNeeded);
    });

    test('story keys follow the register ids', () {
      expect(storyReviewKey('prophets', 'prophet-nuh'), 'story.prophets.prophet-nuh');
      expect(storyReviewKey('newmuslim', 'newmuslim-01'), 'new-muslim.newmuslim-01');
      expect(storyReviewKey('dailyduas', 'dua-x'), 'dua.daily.dua-x');
    });
  });

  group('widget', () {
    testWidgets('shows the label and is read as one sentence', (tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ScholarReviewNote(reviewKey: 'hadi')),
      ));
      expect(find.text('Scholar review needed'), findsOneWidget);
      expect(find.bySemanticsLabel('Scholar review needed'), findsOneWidget);
      h.dispose();
    });

    testWidgets('shows the reviewer once a sign-off is passed in', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ScholarReviewNote(
            reviewKey: 'hadi',
            reviewedBy: 'Test',
            reviewedOn: '2026-01-02',
            detail: 'hidden once reviewed',
          ),
        ),
      ));
      expect(find.text('Reviewed by Test on 2026-01-02'), findsOneWidget);
      expect(find.textContaining('hidden once reviewed'), findsNothing);
    });

    testWidgets('the Sources review screen lists the areas and counts',
        (tester) async {
      tester.view.physicalSize = const Size(430, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: const ReviewStatusScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('$kScholarReviewTotal items'), findsOneWidget);
      expect(find.text(kScholarReviewAreas.first.title), findsOneWidget);
    });
  });

  group('register', () {
    test('every item is open, has a reviewer, and ids are unique', () {
      final List<dynamic> items = _register()['items'] as List<dynamic>;
      final Set<String> ids = <String>{};
      for (final dynamic raw in items) {
        final Map<String, dynamic> i = raw as Map<String, dynamic>;
        expect(ids.add(i['id'] as String), isTrue, reason: i['id'] as String);
        expect(i['status'], 'open', reason: i['id'] as String);
        expect((i['reviewer_type'] as String).isNotEmpty, isTrue);
        expect((i['why_flagged'] as String).isNotEmpty, isTrue);
        expect((i['where_in_app'] as String).isNotEmpty, isTrue);
      }
      expect(ids.length, items.length);
    });

    test('the Dart summary matches register.json', () {
      final Map<String, dynamic> r = _register();
      expect(kScholarReviewTotal, r['total']);
      final Map<String, dynamic> byArea =
          r['totals_by_area'] as Map<String, dynamic>;
      expect(kScholarReviewAreas.length, byArea.length);
      int sum = 0;
      for (final ScholarReviewArea a in kScholarReviewAreas) {
        final Map<String, dynamic> row = byArea[a.key] as Map<String, dynamic>;
        expect(a.items, row['items'], reason: a.key);
        expect(a.highPriority, row['high_priority'], reason: a.key);
        sum += a.items;
      }
      expect(sum, kScholarReviewTotal);
    });

    test('every key a screen uses is a register id or a parent of one', () {
      final List<dynamic> items = _register()['items'] as List<dynamic>;
      final Set<String> ids = <String>{
        for (final dynamic i in items) (i as Map<String, dynamic>)['id'] as String,
      };
      bool known(String k) =>
          ids.contains(k) || ids.any((String id) => id.startsWith('$k.'));
      final RegExp lit = RegExp(r"reviewKey:\s*'([^'$]+)'");
      final List<String> bad = <String>[];
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        for (final RegExpMatch m in lit.allMatches(f.readAsStringSync())) {
          if (!known(m.group(1)!)) bad.add('${f.path}: ${m.group(1)}');
        }
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('every sign-off key in the ledger is a register id or a parent', () {
      final List<dynamic> items = _register()['items'] as List<dynamic>;
      final Set<String> ids = <String>{
        for (final dynamic i in items) (i as Map<String, dynamic>)['id'] as String,
      };
      for (final String k in kScholarSignoffs.keys) {
        expect(ids.contains(k) || ids.any((String id) => id.startsWith('$k.')), isTrue,
            reason: k);
      }
    });
  });
}
