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

  String t(String key) {
    final map = _strings[locale.languageCode];
    return map?[key] ?? _strings['en']?[key] ?? key;
  }
}

final l10nProvider = Provider<L10n>((ref) {
  final locale = ref.watch(localeProvider);
  return L10n(locale);
});
