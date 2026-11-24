/// Which picture a story card shows.
///
/// Most stories have a picture named after their id
/// (assets/story_art/<id>.webp). The duas share one picture per theme
/// (assets/story_art/dua-theme-<theme>.webp) so each theme is painted once.
library;

const Map<String, String> _duaThemes = <String, String>{
  'dua-waking': 'morning',
  'dua-morning-master': 'morning',
  'dua-sleep': 'sleep',
  'dua-sleep2': 'sleep',
  'dua-evening-shield': 'sleep',
  'dua-home-in': 'home',
  'dua-exit-home': 'home',
  'dua-eat-before': 'food',
  'dua-eat-after': 'food',
  'dua-suhoor': 'food',
  'dua-fasting': 'food',
  'dua-travel': 'travel',
  'dua-travel-full': 'travel',
  'dua-anxiety': 'distress',
  'dua-distress': 'distress',
  'dua-debt': 'distress',
  'dua-loss': 'distress',
  'dua-seeing-afflicted': 'distress',
  'dua-hawqala': 'distress',
  'dua-illness': 'illness',
  'dua-visit-sick': 'illness',
  'dua-parents': 'family',
  'dua-children': 'family',
  'dua-children-shield': 'family',
  'dua-rain': 'rain',
  'dua-rain2': 'rain',
  'dua-mosque': 'prayer',
  'dua-after-salah': 'prayer',
  'dua-sajdah': 'prayer',
  'dua-between-sajdah': 'prayer',
  'dua-witr-qunut': 'prayer',
  'dua-istikhara': 'prayer',
  'dua-istikhara-full': 'prayer',
  'dua-rabbana-atina': 'prayer',
  'dua-istikhlas': 'prayer',
  'dua-forgiveness-night': 'prayer',
  'dua-rizq': 'prayer',
  'dua-takbir-days': 'prayer',
};

/// Asset path of the picture for [storyId].
String storyArtAsset(String storyId) {
  final String? theme = _duaThemes[storyId];
  return theme == null
      ? 'assets/story_art/$storyId.webp'
      : 'assets/story_art/dua-theme-$theme.webp';
}
