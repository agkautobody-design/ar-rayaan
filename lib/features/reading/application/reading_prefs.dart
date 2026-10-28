/// How much reading support a person wants around Arabic: the transliteration
/// (Arabic written in Latin letters, a reading aid) and the meaning.
///
/// Stored on this device only. Defaults show everything, so nobody who cannot
/// read Arabic is ever left with Arabic alone. Nothing here counts, scores or
/// rewards anything; it only decides what is shown.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';

/// The three ways of reading.
enum ReadingSupport {
  /// Arabic, transliteration and meaning, always. The default.
  beginner,

  /// Like [beginner], but the transliteration of an item the person has
  /// mastered moves behind a "Read it" button.
  learning,

  /// Arabic and meaning; the transliteration is one tap away.
  reader,
}

/// How one layer (transliteration or meaning) is shown right now.
enum LayerView {
  /// Visible.
  shown,

  /// Behind a small "Read it" button.
  button,

  /// Not shown (the person switched it off).
  hidden,
}

/// The person's reading-support choices.
class ReadingPrefs {
  const ReadingPrefs({
    this.mode = ReadingSupport.beginner,
    this.showTranslit = true,
    this.showMeaning = true,
    this.asked = false,
  });

  final ReadingSupport mode;

  /// Master switch for transliteration. On by default.
  final bool showTranslit;

  /// Master switch for meaning. On by default.
  final bool showMeaning;

  /// True once the person answered "Can you read Arabic?".
  final bool asked;

  ReadingPrefs copyWith({
    ReadingSupport? mode,
    bool? showTranslit,
    bool? showMeaning,
    bool? asked,
  }) => ReadingPrefs(
    mode: mode ?? this.mode,
    showTranslit: showTranslit ?? this.showTranslit,
    showMeaning: showMeaning ?? this.showMeaning,
    asked: asked ?? this.asked,
  );

  /// How the transliteration is shown. [mastered] is true for an item the
  /// person already knows (only used in [ReadingSupport.learning]).
  LayerView translit({bool mastered = false}) {
    if (!showTranslit) return LayerView.hidden;
    switch (mode) {
      case ReadingSupport.beginner:
        return LayerView.shown;
      case ReadingSupport.learning:
        return mastered ? LayerView.button : LayerView.shown;
      case ReadingSupport.reader:
        return LayerView.button;
    }
  }

  /// How the meaning is shown.
  LayerView get meaning => showMeaning ? LayerView.shown : LayerView.hidden;
}

/// The answer to "Can you read Arabic?".
enum ArabicAnswer { no, little, yes }

class ReadingPrefsController extends Notifier<ReadingPrefs> {
  static const String keyMode = 'ar.read.mode';
  static const String keyTranslit = 'ar.read.translit';
  static const String keyMeaning = 'ar.read.meaning';
  static const String keyAsked = 'ar.read.asked';

  @override
  ReadingPrefs build() {
    try {
      final p = ref.watch(sharedPreferencesProvider);
      final String? m = p.getString(keyMode);
      return ReadingPrefs(
        mode: ReadingSupport.values.firstWhere(
          (ReadingSupport v) => v.name == m,
          orElse: () => ReadingSupport.beginner,
        ),
        showTranslit: p.getBool(keyTranslit) ?? true,
        showMeaning: p.getBool(keyMeaning) ?? true,
        asked: p.getBool(keyAsked) ?? false,
      );
    } catch (_) {
      // No storage (a bare test, a blocked browser): the defaults.
      return const ReadingPrefs();
    }
  }

  Future<void> _save() async {
    try {
      final p = ref.read(sharedPreferencesProvider);
      await p.setString(keyMode, state.mode.name);
      await p.setBool(keyTranslit, state.showTranslit);
      await p.setBool(keyMeaning, state.showMeaning);
      await p.setBool(keyAsked, state.asked);
    } catch (_) {
      // Kept for this session only.
    }
  }

  Future<void> setMode(ReadingSupport m) {
    state = state.copyWith(mode: m);
    return _save();
  }

  Future<void> setShowTranslit(bool v) {
    state = state.copyWith(showTranslit: v);
    return _save();
  }

  Future<void> setShowMeaning(bool v) {
    state = state.copyWith(showMeaning: v);
    return _save();
  }

  /// The first-run question. "No" and "A little" both keep everything
  /// visible; "Yes" moves the transliteration behind a button.
  Future<void> answer(ArabicAnswer a) {
    state = state.copyWith(
      asked: true,
      mode: a == ArabicAnswer.yes
          ? ReadingSupport.reader
          : ReadingSupport.beginner,
    );
    return _save();
  }
}

final NotifierProvider<ReadingPrefsController, ReadingPrefs>
readingPrefsProvider =
    NotifierProvider<ReadingPrefsController, ReadingPrefs>(
      ReadingPrefsController.new,
    );
