import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LANGUAGE SETTINGS — the founder's law: a user chooses their language;
/// GPS never decides it for them.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _load();
  }

  static const _pref = 'ar.locale';

  static const supported = <Locale, String>{
    Locale('en'): 'English',
    Locale('ur'): 'اردو · Urdu',
    Locale('ar'): 'العربية · Arabic',
    Locale('id'): 'Indonesia',
    Locale('fr'): 'Français',
    Locale('tr'): 'Türkçe',
    Locale('bn'): 'বাংলা · Bangla',
    Locale('ms'): 'Melayu',
  };

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

  String t(String key) {
    final map = _strings[locale.languageCode];
    return map?[key] ?? _strings['en']?[key] ?? key;
  }
}

final l10nProvider = Provider<L10n>((ref) {
  final locale = ref.watch(localeProvider);
  return L10n(locale);
});
