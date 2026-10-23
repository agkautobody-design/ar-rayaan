/// The smallest honest string table for short interface labels.
///
/// Only labels a person needs to find their way (navigation, tile titles,
/// buttons, the first-run questions) live here, in the three languages the
/// first-run chooser offers besides English: Arabic (ar), Bangla (bn) and
/// Urdu (ur). Every entry is a plain, widely used interface word and is a
/// machine-style translation that still needs a native speaker's review: see
/// docs/content_needed/translation_review.md. Religious content, Hadi's
/// answers, stories and lessons are NOT here and are never translated by
/// this table.
///
/// Pure Dart on purpose (no Flutter import) so it can be unit tested alone.
library;

/// Language codes that have a translated set of the labels below.
const Set<String> kUiLabelLanguages = <String>{'ar', 'bn', 'ur'};

/// key -> language code -> text. English is the key's `en` entry and is the
/// fallback for every other language.
const Map<String, Map<String, String>>
kUiLabels = <String, Map<String, String>>{
  'nav.home': {'en': 'Home', 'ar': 'الرئيسية', 'bn': 'হোম', 'ur': 'ہوم'},
  'nav.faith': {'en': 'Faith', 'ar': 'الإيمان', 'bn': 'ঈমান', 'ur': 'ایمان'},
  'nav.family': {
    'en': 'Family',
    'ar': 'العائلة',
    'bn': 'পরিবার',
    'ur': 'خاندان',
  },
  'nav.hadi': {'en': 'Hādi', 'ar': 'هادي', 'bn': 'হাদী', 'ur': 'ہادی'},
  'nav.you': {'en': 'You', 'ar': 'أنت', 'bn': 'আপনি', 'ur': 'آپ'},
  'tile.prayer': {
    'en': 'Prayer Times',
    'ar': 'مواقيت الصلاة',
    'bn': 'নামাজের সময়',
    'ur': 'نماز کے اوقات',
  },
  'tile.quran': {'en': 'Qur’an', 'ar': 'القرآن', 'bn': 'কুরআন', 'ur': 'قرآن'},
  'tile.dhikr': {
    'en': 'Dhikr & Du’a',
    'ar': 'الأذكار والدعاء',
    'bn': 'যিকির ও দোয়া',
    'ur': 'ذکر اور دعا',
  },
  'tile.hadith': {'en': 'Hadith', 'ar': 'الحديث', 'bn': 'হাদিস', 'ur': 'حدیث'},
  'tile.noor': {
    'en': 'Today’s NOOR',
    'ar': 'نور اليوم',
    'bn': 'আজকের নূর',
    'ur': 'آج کا نور',
  },
  'tile.calendar': {
    'en': 'Islamic Calendar',
    'ar': 'التقويم الإسلامي',
    'bn': 'ইসলামি ক্যালেন্ডার',
    'ur': 'اسلامی کیلنڈر',
  },
  'tile.knowledge': {
    'en': 'Knowledge',
    'ar': 'المعرفة',
    'bn': 'জ্ঞান',
    'ur': 'علم',
  },
  'tile.academy': {
    'en': 'Wasia Academy',
    'ar': 'أكاديمية وصية',
    'bn': 'ওয়াসিয়া একাডেমি',
    'ur': 'وصیہ اکیڈمی',
  },
  'tile.journey': {
    'en': 'My Journey',
    'ar': 'رحلتي',
    'bn': 'আমার যাত্রা',
    'ur': 'میرا سفر',
  },
  'ui.qibla': {'en': 'Qibla', 'ar': 'القبلة', 'bn': 'কিবলা', 'ur': 'قبلہ'},
  'ui.settings': {
    'en': 'Settings',
    'ar': 'الإعدادات',
    'bn': 'সেটিংস',
    'ur': 'ترتیبات',
  },
  'ui.next': {'en': 'Next', 'ar': 'التالي', 'bn': 'পরবর্তী', 'ur': 'اگلا'},
  'ui.skip': {'en': 'Skip', 'ar': 'تخطَّ', 'bn': 'এড়িয়ে যান', 'ur': 'چھوڑیں'},
  'ui.continue': {
    'en': 'Continue',
    'ar': 'متابعة',
    'bn': 'চালিয়ে যান',
    'ur': 'جاری رکھیں',
  },
  'ui.begin': {
    'en': 'Begin',
    'ar': 'ابدأ',
    'bn': 'শুরু করুন',
    'ur': 'شروع کریں',
  },
  'ui.search': {'en': 'Search', 'ar': 'بحث', 'bn': 'অনুসন্ধান', 'ur': 'تلاش'},
  'ui.back': {'en': 'Back', 'ar': 'رجوع', 'bn': 'পিছনে', 'ur': 'واپس'},
  'ui.language': {'en': 'Language', 'ar': 'اللغة', 'bn': 'ভাষা', 'ur': 'زبان'},
  'ui.about': {
    'en': 'About',
    'ar': 'حول التطبيق',
    'bn': 'পরিচিতি',
    'ur': 'تعارف',
  },
  'ui.sources': {
    'en': 'Our Sources',
    'ar': 'مصادرنا',
    'bn': 'আমাদের সূত্র',
    'ur': 'ہمارے ذرائع',
  },
  'onb.question': {
    'en': 'What brings you here?',
    'ar': 'ما الذي جاء بك إلى هنا؟',
    'bn': 'আপনি এখানে কেন এসেছেন?',
    'ur': 'آپ یہاں کیوں آئے ہیں؟',
  },
  'onb.learn': {
    'en': 'Learning about Islam',
    'ar': 'تعلّم الإسلام',
    'bn': 'ইসলাম সম্পর্কে শেখা',
    'ur': 'اسلام کے بارے میں سیکھنا',
  },
  'onb.peace': {
    'en': 'Peace for my heart',
    'ar': 'سكينة لقلبي',
    'bn': 'মনের শান্তি',
    'ur': 'دل کا سکون',
  },
  'onb.children': {
    'en': 'Teaching my children',
    'ar': 'تعليم أطفالي',
    'bn': 'আমার সন্তানদের শেখানো',
    'ur': 'اپنے بچوں کو سکھانا',
  },
  'onb.pray': {
    'en': 'Praying on time',
    'ar': 'الصلاة في وقتها',
    'bn': 'সময়মতো নামাজ',
    'ur': 'وقت پر نماز',
  },
  'onb.new': {
    'en': 'New to Islam or just curious',
    'ar': 'جديد على الإسلام أو فضولي فقط',
    'bn': 'ইসলামে নতুন বা শুধু কৌতূহলী',
    'ur': 'اسلام میں نیا یا صرف متجسس',
  },
  'onb.community': {
    'en': 'A community',
    'ar': 'مجتمع',
    'bn': 'একটি সম্প্রদায়',
    'ur': 'ایک کمیونٹی',
  },
};

/// The label for [key] in [lang] (a language code); English when the
/// language has no entry, and the key itself when the key is unknown.
String uiLabel(String key, String lang) {
  final Map<String, String>? m = kUiLabels[key];
  if (m == null) return key;
  return m[lang] ?? m['en'] ?? key;
}

final Map<String, String> _byEnglish = <String, String>{
  for (final MapEntry<String, Map<String, String>> e in kUiLabels.entries)
    if (e.value['en'] != null) e.value['en']!: e.key,
};

/// Translates a label that is written in English at the call site (a home
/// tile title, say). Text that is not in the table comes back unchanged.
String uiLabelForEnglish(String english, String lang) {
  final String? key = _byEnglish[english];
  return key == null ? english : uiLabel(key, lang);
}
