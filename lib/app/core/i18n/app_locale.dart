import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_labels.dart';

/// LANGUAGE SETTINGS — the founder's law: a user chooses their language;
/// GPS never decides it for them.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _load();
  }

  static const _pref = 'ar.locale';

  static final supported = <Locale, String>{
    Locale('en'): 'English',
    Locale('ur'): 'اردو · Urdu',
    Locale('ar'): 'العربية · Arabic',
    Locale('id'): 'Indonesia',
    Locale('fr'): 'Français',
    Locale('tr'): 'Türkçe',
    Locale('bn'): 'বাংলা · Bangla',
    Locale('ms'): 'Melayu',
  };

  /// Languages written right-to-left.
  static const Set<String> rtlLanguages = <String>{'ar', 'ur'};

  static bool isRtl(Locale l) => rtlLanguages.contains(l.languageCode);

  /// Languages the first-run chooser offers, in this order.
  static const List<Locale> firstRunChoices = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('ur'),
  ];

  /// Languages whose navigation, home tiles, first-run questions and Settings
  /// top rows are translated (ui_labels.dart). Only these may mirror the
  /// layout, and only if they are written right-to-left. Lessons, stories,
  /// hadith, Hadi and long texts are still English everywhere, so the Language
  /// screen says exactly that. Add a language here only when its labels in
  /// ui_labels.dart exist and a native speaker has looked at them.
  static const Set<String> shellTranslated = kUiLabelLanguages;

  /// The layout direction for [l]: right-to-left for Arabic and Urdu (their
  /// shell labels are translated), otherwise left-to-right. Arabic scripture
  /// draws right-to-left by its own script in every language.
  static TextDirection layoutDirection(Locale l) =>
      isRtl(l) && shellTranslated.contains(l.languageCode)
          ? TextDirection.rtl
          : TextDirection.ltr;

  /// Languages that have any translated UI text at all (the short labels in
  /// ui_labels.dart, or the Language & Voice labels in L10n below).
  static bool translatedChrome(Locale l) =>
      L10n._strings.containsKey(l.languageCode) ||
      kUiLabelLanguages.contains(l.languageCode);

  /// A one-line, truthful statement of what is translated in [l].
  static String translationScope(Locale l) {
    final String c = l.languageCode;
    if (c == 'en') return 'Everything is in English';
    if (kUiLabelLanguages.contains(c)) {
      return 'Menus, home tiles and the first questions are translated. '
          'Everything else is English';
    }
    if (L10n._strings.containsKey(c)) {
      return 'Only the Language & Voice labels are translated';
    }
    return 'Not translated yet; the app stays in English';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final tag = p.getString(_pref);
    if (tag != null) {
      state = Locale(tag);
    }
  }

  Future<void> setLocale(Locale l) async {
    state = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_pref, l.languageCode);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController());

/// UI chrome strings — localizable NOW. Content strings (stories, lessons)
/// flow through the same door as translations land (pipeline documented in
/// the i18n plan).
class L10n {
  final Locale locale;
  L10n(this.locale);

  static const _strings = <String, Map<String, String>>{
    'en': {
      'settings.language': 'Language',
      'settings.language.sub': 'Choose the app\u2019s tongue — your location never chooses for you',
      'settings.voice': 'Voice',
      'settings.voice.sub': 'Wasia and Hadi\u2019s speech language follows your language',
    },
    'ur': {
      'settings.language': 'زبان',
      'settings.language.sub': 'ایپ کی زبان خود منتخب کریں — مقام آپ کے لیے فیصلہ نہیں کرتا',
      'settings.voice': 'آواز',
      'settings.voice.sub': 'وصیہ اور ہادی کی آواز آپ کی زبان میں',
    },
    'ar': {
      'settings.language': 'اللغة',
      'settings.language.sub': 'اختر لغة التطبيق — موقعك لا يختار عنك',
      'settings.voice': 'الصوت',
      'settings.voice.sub': 'صوت وصية وهادي يتبع لغتك',
    },
    'id': {
      'settings.language': 'Bahasa',
      'settings.language.sub': 'Pilih bahasa aplikasi — lokasi tidak memilih untukmu',
      'settings.voice': 'Suara',
      'settings.voice.sub': 'Suara Wasia dan Hadi mengikuti bahasamu',
    },
  };

  // Multilingual salvage (2026-10-10): the app's time-and-calendar layer
  // genuinely speaks its eight tongues — every prayer name and phase label
  // has a real translation in L10n.words.
  static const words = <String, Map<String, String>>{
    'prayer.fajr': {'en': 'Fajr', 'ur': 'فجر', 'ar': 'الفجر', 'id': 'Subuh',
      'fr': 'Fajr', 'tr': 'İmsak', 'bn': 'ফজর', 'ms': 'Subuh'},
    'prayer.sunrise': {'en': 'Sunrise', 'ur': 'طلوعِ فجر', 'ar': 'الشروق',
      'id': 'Terbit', 'fr': 'Lever du soleil', 'tr': 'Güneş', 'bn': 'সূর্যোদয়', 'ms': 'Terbit'},
    'prayer.dhuhr': {'en': 'Dhuhr', 'ur': 'ظہر', 'ar': 'الظهر', 'id': 'Dzuhur',
      'fr': 'Dhuhr', 'tr': 'Öğle', 'bn': 'যোহর', 'ms': 'Zohor'},
    'prayer.asr': {'en': 'Asr', 'ur': 'عصر', 'ar': 'العصر', 'id': 'Ashar',
      'fr': 'Asr', 'tr': 'İkindi', 'bn': 'আসর', 'ms': 'Asar'},
    'prayer.maghrib': {'en': 'Maghrib', 'ur': 'مغرب', 'ar': 'المغرب', 'id': 'Maghrib',
      'fr': 'Maghrib', 'tr': 'Akşam', 'bn': 'মাগরিব', 'ms': 'Maghrib'},
    'prayer.isha': {'en': 'Isha', 'ur': 'عشاء', 'ar': 'العشاء', 'id': 'Isya',
      'fr': 'Isha', 'tr': 'Yatsı', 'bn': 'এশা', 'ms': 'Isyak'},
    'phase.next': {'en': 'Next prayer', 'ur': 'اگلی نماز', 'ar': 'الصلاة القادمة',
      'id': 'Sholat berikutnya', 'fr': 'Prochaine prière', 'tr': 'Sıradaki namaz',
      'bn': 'পরবর্তী নামাজ', 'ms': 'Solat seterusnya'},
    'phase.passed': {'en': 'just passed', 'ur': 'ابھی گزری', 'ar': 'مرت للتو',
      'id': 'baru lewat', 'fr': 'vient de passer', 'tr': 'az önce geçti',
      'bn': 'এইমাত্র শেষ', 'ms': 'baru sahaja lepas'},
    'phase.now': {'en': 'in progress', 'ur': 'جاری ہے', 'ar': 'جارية الآن',
      'id': 'sedang berlangsung', 'fr': 'en cours', 'tr': 'devam ediyor',
      'bn': 'চলমান', 'ms': 'sedang berlangsung'},
    'day.mon': {'en': 'Mon', 'ur': 'پیر', 'ar': 'الاثنين', 'id': 'Sen', 'fr': 'Lun',
      'tr': 'Pzt', 'bn': 'সোম', 'ms': 'Isn'},
    'day.fri': {'en': 'Fri', 'ur': 'جمعہ', 'ar': 'الجمعة', 'id': 'Jum', 'fr': 'Ven',
      'tr': 'Cum', 'bn': 'শুক্র', 'ms': 'Jum'},
    'month.ramadan': {'en': 'Ramadan', 'ur': 'رمضان', 'ar': 'رمضان', 'id': 'Ramadan',
      'fr': 'Ramadan', 'tr': 'Ramazan', 'bn': 'রমজান', 'ms': 'Ramadan'},
  };

  String w(String key) {
    final map = words[key];
    return map?[locale.languageCode] ?? map?['en'] ?? key;
  }

  /// A short interface label from ui_labels.dart (English when this language
  /// has none).
  String ui(String key) => uiLabel(key, locale.languageCode);

  /// Translates a label written in English at the call site; unknown text is
  /// returned unchanged.
  String english(String text) => uiLabelForEnglish(text, locale.languageCode);

  String t(String key) {
    final map = _strings[locale.languageCode];
    return map?[key] ?? _strings['en']?[key] ?? key;
  }
}

final l10nProvider = Provider<L10n>((ref) {
  final locale = ref.watch(localeProvider);
  return L10n(locale);
});
