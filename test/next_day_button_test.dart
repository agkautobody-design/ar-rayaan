import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/presentation/story_reader_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Story _day(String id) => Story(
      id: id,
      collection: 'newmuslim',
      title: 'Day $id',
      kicker: '',
      subtitle: '',
      sourceLabel: 'Reflection',
      sources: const <String>[],
      chapters: const <StoryChapter>[StoryChapter(heading: 'h', body: 'b')],
      familyQuestion: '',
    );

void main() {
  group('nextNewMuslimDay — the continue button at the end of a day', () {
    final List<Story> days = <Story>[_day('03'), _day('01'), _day('02')];

    test('walks in id order, not list order', () {
      expect(nextNewMuslimDay(days, '01')!.id, '02');
      expect(nextNewMuslimDay(days, '02')!.id, '03');
    });

    test('the last day has no next, so the reader shows the road instead',
        () {
      expect(nextNewMuslimDay(days, '03'), isNull);
    });

    test('an unknown day has no next', () {
      expect(nextNewMuslimDay(days, '99'), isNull);
    });

    test('other collections are never offered as the next day', () {
      final List<Story> mixed = <Story>[
        _day('01'),
        Story(
          id: '02-other',
          collection: 'prophets',
          title: 'Not the path',
          kicker: '',
          subtitle: '',
          sourceLabel: 'Reflection',
          sources: const <String>[],
          chapters: const <StoryChapter>[
            StoryChapter(heading: 'h', body: 'b')
          ],
          familyQuestion: '',
        ),
      ];
      expect(nextNewMuslimDay(mixed, '01'), isNull);
    });
  });
}
