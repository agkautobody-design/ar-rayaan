/// How long a story is to read, worked out from its text. Nothing here says
/// who a story is for: age labels are decided by the owner
/// (docs/content_needed/story_age_labels.md), not guessed by the app.
library;

import 'story.dart';

/// A story of this many words or fewer counts as a short read (about a
/// minute at a relaxed pace).
const int kShortReadWords = 150;

/// Words a relaxed reader (or a child being read to) covers in a minute.
const int kWordsPerMinute = 150;

int _words(String s) =>
    s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

extension StoryLength on Story {
  /// Words in all chapters' body text.
  int get wordCount =>
      chapters.fold<int>(0, (int a, StoryChapter c) => a + _words(c.body));

  bool get isShortRead => wordCount <= kShortReadWords;

  /// Whole minutes to read, at least 1.
  int get readMinutes {
    final int m = (wordCount / kWordsPerMinute).ceil();
    return m < 1 ? 1 : m;
  }
}
