import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/presentation/lesson_player_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/my_additions_screen.dart';
import 'package:ar_rayaan/features/hadi/grounding/passage.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_screen.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/hadith/presentation/hadith_screen.dart';
import 'package:ar_rayaan/features/share/application/share_service.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:ar_rayaan/features/share/domain/handout.dart';
import 'package:ar_rayaan/features/share/presentation/handout_screen.dart';
import 'package:ar_rayaan/features/share/presentation/share_actions.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/presentation/story_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const Story _story = Story(
  id: 's1',
  collection: 'prophets',
  title: 'The Cave',
  kicker: 'PROPHETS',
  subtitle: 'A night of trust',
  sourceLabel: kLabelEstablished,
  sources: <String>["Qur'an 9:40", 'Sahih al-Bukhari 3653'],
  chapters: <StoryChapter>[
    StoryChapter(heading: 'The road', body: 'They left at night.'),
    StoryChapter(
      heading: 'The cave',
      body: 'Do not grieve.',
      arabic: 'لَا تَحْزَنْ',
    ),
  ],
  familyQuestion: 'When did you last trust Allah with a worry?',
);

/// Replaces the platform clipboard. [blocked] makes setData throw, like a
/// browser that refuses clipboard access.
void _install(WidgetTester tester, {bool blocked = false}) {
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      if (blocked) throw PlatformException(code: 'denied');
      _copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  _copied = null;
}

String? _copied;

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('copy feedback', () {
    Widget copyButton(String text) => Builder(
          builder: (BuildContext context) => IconButton(
            key: const Key('test-copy'),
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () => copyWithFeedback(context, text),
          ),
        );

    testWidgets('copy puts the text on the clipboard and says Copied',
        (tester) async {
      _install(tester);
      await _pump(tester, copyButton('hello'));
      await tester.tap(find.byKey(const Key('test-copy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_copied, 'hello');
      expect(find.textContaining('Copied'), findsOneWidget);
    });

    testWidgets('a blocked clipboard still gets a visible message',
        (tester) async {
      _install(tester, blocked: true);
      await _pump(tester, copyButton('hello'));
      await tester.tap(find.byKey(const Key('test-copy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Could not copy'), findsOneWidget);
    });
  });

  group('the share button', () {
    testWidgets('has a tooltip naming what is shared and is 48dp',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ShareButton(
                  doc: ShareDoc.invite(),
                  subject: 'this hadith',
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Share this hadith'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('share-card'))).shortestSide,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('sharing existing content', () {
    test('a story chapter carries its sources and the credit', () {
      final String t = storyChapterShareText(_story, _story.chapters[1]);
      expect(t, contains('Do not grieve.'));
      expect(t, contains('لَا تَحْزَنْ'));
      expect(t, contains("Qur'an 9:40; Sahih al-Bukhari 3653"));
      expect(t, contains('Shared from Ar-Rayaan'));
      expect(t, contains('Scholar review needed'));
      expect(t.trimRight(), endsWith(kInviteUrl));
    });

    test('an unverified story says so in what it shares', () {
      const Story unverified = Story(
        id: 's2',
        collection: 'prophets',
        title: 'T',
        kicker: 'K',
        subtitle: 'S',
        sourceLabel: kLabelSeerahUnchecked,
        sources: <String>['Ibn Hisham'],
        chapters: <StoryChapter>[StoryChapter(heading: 'H', body: 'B')],
        familyQuestion: 'Q?',
      );
      final String t = storyChapterShareText(
        unverified,
        unverified.chapters.first,
      );
      expect(t, contains('Unverified'));
    });

    test('a Forty Hadith share has Arabic, English, source and credit', () {
      const Hadith h = Hadith(
        number: 1,
        arabic: 'إنما الأعمال بالنيات',
        english: 'Actions are by intentions.',
        source: 'Bukhari & Muslim',
      );
      final String t = hadithShareText(h);
      expect(t, contains('إنما الأعمال بالنيات'));
      expect(t, contains('Actions are by intentions.'));
      expect(t, contains('Bukhari & Muslim'));
      expect(t, contains('Shared from Ar-Rayaan'));
    });

    test('a Hadi reply copies with the passages it cites', () {
      const Passage p = Passage(
        id: 'q:94:5-6',
        kind: PassageKind.quran,
        reference: 'Qur’an 94:5–6',
        english: 'With hardship comes ease.',
      );
      final String t = hadiReplyShareText('Ease follows hardship.', <Passage>[p]);
      expect(t, contains('Ease follows hardship.'));
      expect(t, contains('Qur’an 94:5–6'));
      expect(t, contains('With hardship comes ease.'));
      expect(t, endsWith('Shared from Ar-Rayaan'));
    });
  });

  group('handout', () {
    test('a story handout holds its chapters, sources and question', () {
      final HandoutData d = storyHandout(_story);
      expect(d.sections.length, 2);
      expect(d.sources, _story.sources);
      expect(d.questions, <String>[_story.familyQuestion]);
      final String text = d.toPlainText();
      expect(text, contains('They left at night.'));
      expect(text, contains('To talk about'));
      expect(text, contains('Sahih al-Bukhari 3653'));
      expect(text, contains('Shared from Ar-Rayaan'));
    });

    test('the print page escapes content and has no script', () {
      const HandoutData d = HandoutData(
        title: 'A <b>title</b> & more',
        sections: <HandoutSection>[
          HandoutSection(body: '<script>alert(1)</script>'),
        ],
      );
      final String html = d.toHtml();
      expect(html, isNot(contains('<script>')));
      expect(html, contains('&lt;script&gt;'));
      expect(html, contains('A &lt;b&gt;title&lt;/b&gt; &amp; more'));
    });

    test('a lesson handout is built from the lesson only', () {
      final HandoutData d =
          lessonHandout(kAcademyCourses.first.units.first.lessons.first);
      expect(d.title.trim(), isNotEmpty);
      expect(d.toPlainText(), contains('Shared from Ar-Rayaan'));
    });

    testWidgets('the handout page copies its text and explains printing',
        (tester) async {
      _install(tester);
      await tester.pumpWidget(
        MaterialApp(home: HandoutScreen(data: storyHandout(_story))),
      );
      expect(find.text('The Cave'), findsOneWidget);
      await tester.tap(find.byKey(const Key('handout-copy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_copied, contains('They left at night.'));
      expect(find.textContaining('Copied'), findsOneWidget);
      // Tests run off the web, so printing is honestly described as web-only.
      expect(find.textContaining('web version'), findsOneWidget);
    });

    testWidgets('the handout page without content says what to do',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HandoutScreen()));
      expect(find.textContaining('Make a handout'), findsOneWidget);
    });
  });

  group('adding a link', () {
    test('needs a title and a usable link', () {
      expect(validateAddition('', 'https://example.com/a.mp3'), isNotNull);
      expect(validateAddition('A', ''), isNotNull);
      expect(validateAddition('A', 'not a link'), isNotNull);
      expect(validateAddition('A', 'ftp://example.com/a.mp3'), isNotNull);
    });

    test('accepts YouTube, Spotify and direct audio links', () {
      expect(
        validateAddition('A', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        validateAddition('A', 'https://youtu.be/dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        validateAddition(
            'A', 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC'),
        isNull,
      );
      expect(validateAddition('A', 'https://example.com/a.mp3'), isNull);
    });
  });
}
