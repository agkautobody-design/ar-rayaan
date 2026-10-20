/// The school of law a person follows, kept on the device and used only to
/// tell Hādi which school's view to name first.
enum Madhhab {
  notSure('Not sure', 'ns'),
  hanafi('Hanafi', 'hanafi'),
  shafii('Shafi’i', 'shafii'),
  maliki('Maliki', 'maliki'),
  hanbali('Hanbali', 'hanbali');

  const Madhhab(this.label, this.code);

  final String label;
  final String code;

  static Madhhab fromCode(String? code) {
    for (final Madhhab m in Madhhab.values) {
      if (m.code == code) return m;
    }
    return Madhhab.notSure;
  }

  /// One line added to the live prompt.
  String get promptLine {
    if (this == Madhhab.notSure) {
      return 'The user has not said which school of law they follow. Where '
          'the four Sunni schools differ, say that they differ and do not '
          'pick one for them.';
    }
    return 'The user follows the $label school. Where the four Sunni schools '
        'differ, name the $label view first and say plainly that other '
        'schools differ. Never say another school is wrong.';
  }
}

/// What Hādi covers. Said once in the prompt and once in the app.
const String kHadiScopeNote =
    'Hādi answers from the Sunni tradition: the Qur’an and the six '
    'canonical hadith books. It is a study aid, not a mufti.';
