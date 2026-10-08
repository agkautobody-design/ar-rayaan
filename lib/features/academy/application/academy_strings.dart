/// Al-Wasia Academy strings — i18n scaffold (all-language tables).
///
/// Every UI string is keyed here; locales fall back to English. Lesson
/// *content* ships in English first (fallback), chrome strings are
/// translated per locale. Sacred content is never machine-translated
/// without scholar review — locked rule.
library;

abstract final class AcademyStrings {
  static const String defaultLocale = 'en';

  static const Map<String, Map<String, String>> _data =
      <String, Map<String, String>>{
    'en': <String, String>{
      'academy.title': 'Al-Wasia Academy of Sacred Knowledge',
      'academy.comingSoon': 'Coming soon — insha’Allah',
      'academy.continue': 'Continue where you left off',
      'academy.startPath': 'Begin the Path',
      'academy.today': 'Today',
      'academy.lessonsDone': 'lessons completed',
      'academy.wordsReviewed': 'words reviewed',
      'academy.ayatListened': 'ayat listened',
      'academy.dailyVerse': 'A verse for the learner',
      'academy.translationCredit':
          'Translation: Saheeh International (interim) — The Clear Quran® preferred, license pending',
      'common.next': 'Next',
      'common.back': 'Back',
      'common.done': 'Done',
      'common.open': 'Open',
      'check.title': 'Check your understanding',
      'check.passed': 'Alhamdulillah — every answer correct.',
      'check.tryAgain': 'Let’s look at it once more, gently.',
      'check.continue': 'Continue',
      'lesson.completeTitle': 'Lesson complete',
      'lesson.completeBody': 'Every step counts — no matter how small.',
      'path.title': 'The Path',
      'path.subtitle':
          'For the one new to Islam — from the first word to daily practice',
      'path.u0.title': 'Welcome',
      'path.u0.subtitle': 'The beginning',
      'path.u0.l1.title': 'Your first step',
      'path.u0.s1.title': 'You are welcome here',
      'path.u0.s1.body':
          'Saying the shahada — the testimony that there is no god but Allah and that Muhammad ﷺ is His Messenger — is the doorway into Islam. There is no ceremony required, no permission needed. Your intention, spoken honestly, is enough.',
      'path.u0.s2.title': 'Take your time',
      'path.u0.s2.body':
          'This Path walks with you from your very first step — welcome, then purification, then your first prayer — at your pace. There are no timers and no tests that can fail you here.',
      'path.u0.s3.title': 'Meet Hādi',
      'path.u0.s3.body':
          'Hādi is your guide inside Ar-Rayaan. Ask anything — every answer carries its source on screen.',
      'path.u0.s4.title': 'Never despair',
      'path.u0.s4.body':
          '“Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins.” — Qur’an 39:53',
      'path.u1.title': 'Purification',
      'path.u1.subtitle': 'Preparing to stand before Allah',
      'path.u1.l1.title': 'Wudu — the washing before prayer',
      'path.u1.s1.title': 'Why we purify',
      'path.u1.s1.body':
          'Before standing in prayer, the Prophet ﷺ taught us to wash in a specific way — wudu. Purity is half of faith, he said (Muslim 223). It is both a clean body and a quiet heart.',
      'path.u1.s2.title': 'See the prayer times',
      'path.u1.s2.body':
          'Wudu is the doorway; prayer is the room beyond. Ar-Rayaan already keeps the day’s prayer times for you — open them now to see when your next prayer arrives.',
      'path.u1.s3.title': 'Order matters',
      'path.u1.s3.body':
          'Wudu has an order the Prophet ﷺ taught: beginning with the intention, then washing the hands, rinsing the mouth and nose, washing the face, the arms to the elbows, wiping the head and ears, and finally the feet. Each step will be practiced hands-on in the next update of this lesson.',
      'path.u1.check.title': 'A gentle check',
      'check.wudu.q1': 'What comes first in wudu?',
      'check.wudu.q1.a': 'The intention (niyyah)',
      'check.wudu.q1.b': 'Washing the feet',
      'check.wudu.q1.c': 'Wiping the head',
      'check.wudu.q1.reteach':
          'Wudu begins with the intention in the heart, then the hands — remember the order: intention first.',
      'check.wudu.q2': 'In the taught order, the feet are washed…',
      'check.wudu.q2.reteach':
          'The feet come last in wudu, after wiping the head and ears — the order the Prophet ﷺ taught.',
      'path.u2.title': 'Prayer I — The Body',
      'path.u2.subtitle': 'Standing, bowing, prostrating',
      'path.u2.l1.title': 'Your first salah, step by step',
      'path.u2.s1.title': 'The call to prayer',
      'path.u2.s1.body':
          'The adhan calls: Allahu Akbar — Allah is Greatest. You stand facing the qibla, intending prayer in your heart. Intention is not spoken — the Prophet ﷺ said actions are by intentions (Bukhari 1). Then you raise your hands and say Allahu Akbar — the prayer has begun, and the world can wait.',
      'path.u2.s2.title': 'The positions',
      'path.u2.s2.body':
          'Standing, you recite Al-Fatihah. Then bowing (rukooʿ) with hands on knees, saying Subhana Rabbiy al-ʿAzeem. Then standing again, then prostration (sujood) — forehead, nose, palms, knees, toes on the ground — saying Subhana Rabbiy al-Aʿla. Sit, prostrate again: that is one rakʿah. The Prophet ﷺ taught every position with its words (Bukhari 6666, Muslim 397).',
      'path.u2.s3.title': 'Go slowly',
      'path.u2.s3.body':
          'Your first prayer may feel long. That is worship, not a performance. Ar-Rayaan keeps today’s prayer times for you — open them, and when the next prayer arrives, walk through each position with this lesson beside you.',
      'path.u3.title': 'Prayer II — The Words',
      'path.u3.subtitle': 'What you are saying to Allah',
      'path.u3.l1.title': 'Al-Fatihah, word by word',
      'path.u3.s1.title': 'Why Al-Fatihah matters',
      'path.u3.s1.body':
          'The Prophet ﷺ said there is no prayer for the one who does not recite the Opening of the Book (Bukhari 714). Al-Fatihah is a conversation: Allah says “between Me and My servant is Al-Fatihah” (Ahmad). You praise, you ask, you worship.',
      'path.u3.s2.title': 'Read it now, slowly',
      'path.u3.s2.body':
          'Open the reader and recite Al-Fatihah — one ayah at a time. Pause after each ayah and hold its meaning: praise → mercy → the Day → guidance.',
      'path.u3.check.title': 'A gentle check',
      'check.fatihah.q1': 'Al-Fatihah begins with…',
      'check.fatihah.q1.a': 'Praise of Allah, Lord of the worlds',
      'check.fatihah.q1.b': 'A list of rules',
      'check.fatihah.q1.c': 'Stories of the prophets',
      'check.fatihah.q1.reteach':
          'Al-Fatihah opens with praise — “All praise is for Allah, Lord of the worlds.” Try reciting the first ayah once more.',
      'path.u4.title': 'Prayer III — The Life',
      'path.u4.subtitle': 'Missed prayers, travel, Friday',
      'path.u4.l1.title': 'Prayer in real life',
      'path.u4.s1.title': 'Anchor to your day',
      'path.u4.s1.body':
          'Prayer is five appointments a day. Ar-Rayaan shows their times and the qibla direction — the app is built around them, because they are the skeleton of a Muslim’s day.',
      'path.u4.s2.title': 'When you miss one',
      'path.u4.s2.body':
          'Missed prayers are made up (qada) — the Gentle Ledger in My Journey helps you track them gently, one at a time. Never let shame stop you from returning; the door is always open.',
      'path.u4.s3.title': 'Different schools, one prayer',
      'path.u4.s3.body':
          'Hands folded or at the sides, saying Ameen aloud or silently — the madhabs differ on details and agree on the prayer itself. Ar-Rayaan notes differences where they matter, exactly as it does with zakat. [Interpretive: madhab positions summarized; details sit with your local scholars.]',
      'path.u5.title': 'Fasting',
      'path.u5.subtitle': 'The month and the voluntary days',
      'path.u5.l1.title': 'How fasting works',
      'path.u5.s1.title': 'The shape of a fast',
      'path.u5.s1.body':
          'From dawn (Fajr) to sunset (Maghrib): no food, no drink, no intimacy — and the Prophet ﷺ added: no bad speech or action (Bukhari 1903). The body fasts; the tongue and heart fast too.',
      'path.u5.s2.title': 'Begin with the voluntary',
      'path.u5.s2.body':
          'Outside Ramadan, the Prophet ﷺ loved Mondays and Thursdays, and the White Days — the 13th, 14th, 15th of the lunar month (Tirmidhi 759; Abu Dawud 2449). The Ar-Rayaan calendar marks them for you — start there.',
      'path.u6.title': 'Zakat',
      'path.u6.subtitle': 'Purification of wealth',
      'path.u6.l1.title': 'Zakat, learned by doing',
      'path.u6.s1.title': 'The third pillar',
      'path.u6.s1.body':
          'Zakat is a yearly giving of a small portion of saved wealth to eight categories of recipients (Qur’an 9:60) — it purifies the rest. The word itself means purification and growth.',
      'path.u6.s2.title': 'Compute a real example',
      'path.u6.s2.body':
          'Open the Guided Zakat Calculator and walk a full example through its seven sections — cash, gold, investments, debts. The calculator teaches nisab, hawl, and the madhab differences as you go.',
      'path.u7.title': 'Daily Life',
      'path.u7.subtitle': 'Adhkar, food, the masjid',
      'path.u7.l1.title': 'The rhythm of a Muslim day',
      'path.u7.s1.title': 'Morning and evening adhkar',
      'path.u7.s1.body':
          'The Prophet ﷺ taught words of protection and remembrance for morning and evening (Muslim 2723). The Dhikr & Duʿa module carries them — begin with Ayat al-Kursi after Fajr.',
      'path.u7.s2.title': 'Eating and gathering',
      'path.u7.s2.body':
          'Mention Allah’s name before eating, eat with your right hand, and say the taught supplications after — small sunnahs that fill an ordinary day with light.',
      'path.u8.title': 'Beliefs',
      'path.u8.subtitle': 'What a Muslim believes',
      'path.u8.l1.title': 'The six articles of faith',
      'path.u8.s1.title': 'The foundations',
      'path.u8.s1.body':
          'The Prophet ﷺ defined faith in the hadith of Jibreel (Muslim 8): belief in Allah, His angels, His books, His messengers, the Last Day, and the divine decree. Everything else in the deen stands on these six.',
      'path.u8.s2.title': 'Belief with the heart',
      'path.u8.s2.body':
          'Each article will grow with you for the rest of your life — faith deepens through worship and reflection, not through a single lesson. This is the beginning, not the test.',
      'path.u9.title': 'Character & Community',
      'path.u9.subtitle': 'Living among people',
      'path.u9.l1.title': 'The Muslim with family and strangers',
      'path.u9.s1.title': 'When family does not understand',
      'path.u9.s1.body':
          'Many converts meet resistance at home. The Prophet ﷺ was patient with those who opposed him, and honored his mother even when she opposed Islam — kindness without compromise. If this weight feels heavy, the Sakina rooms are always open.',
      'path.u9.s2.title': 'The best of you',
      'path.u9.s2.body':
          'The best of you are the best to their families (Tirmidhi 3895), and the most beloved to the Prophet ﷺ are those best in character (Tirmidhi 2018). Start with one person, today.',
      'school.letters.title': 'Letters',
      'school.letters.subtitle': 'Learn the letters and their sounds',
      'school.recitation.title': 'Recitation',
      'school.recitation.subtitle': 'Tajweed, listening, and correction',
      'school.arabic.title': 'Quranic Arabic',
      'school.arabic.subtitle': 'The words of the Qur’an, one by one',
      'school.understanding.title': 'Understanding',
      'school.understanding.subtitle': 'Word-by-word meanings and roots',
      'school.soonBody':
          'This school is being built with scholarly review — lesson by lesson. The Path is ready for you today.',
    },
    'ar': <String, String>{
      'academy.title': 'أكاديمية الوسيع للعلوم الشرعية',
      'academy.comingSoon': 'قريبًا — إن شاء الله',
      'academy.continue': 'أكمل من حيث توقفت',
      'academy.startPath': 'ابدأ الرحلة',
      'academy.today': 'اليوم',
      'academy.lessonsDone': 'دروس مكتملة',
      'academy.wordsReviewed': 'كلمات مراجَعة',
      'academy.ayatListened': 'آيات مستمعَة',
      'academy.dailyVerse': 'آية لطالب العلم',
      'common.next': 'التالي',
      'common.back': 'رجوع',
      'common.done': 'تم',
      'common.open': 'فتح',
      'lesson.completeTitle': 'اكتمل الدرس',
      'lesson.completeBody': 'كل خطوة تحسب — مهما صغُرت.',
      'path.title': 'الرحلة',
      'path.subtitle': 'للمسلم الجديد — من أول كلمة إلى العمل اليومي',
      'path.u0.title': 'أهلًا بك',
      'school.letters.title': 'الحروف',
      'school.recitation.title': 'التلاوة',
      'school.arabic.title': 'العربية القرآنية',
      'school.understanding.title': 'الفهم',
    },
    'ur': <String, String>{
      'academy.title': 'الوسیع اکیڈمی آف سیکرڈ نالیج',
      'academy.comingSoon': 'جلد — ان شاء اللہ',
      'academy.continue': 'جہاں چھوڑا تھا، وہیں سے جاری رکھیں',
      'academy.startPath': 'راستہ شروع کریں',
      'academy.today': 'آج',
      'academy.lessonsDone': 'مکمل اسباق',
      'common.next': 'آگے',
      'common.back': 'واپس',
      'common.done': 'ہو گیا',
      'common.open': 'کھولیں',
      'lesson.completeTitle': 'سبق مکمل ہوا',
      'path.title': 'راستہ',
      'path.subtitle': 'نئے مسلمان کے لیے — پہلے لفظ سے روزانہ عمل تک',
      'path.u0.title': 'خوش آمدید',
      'school.letters.title': 'حروف',
      'school.recitation.title': 'تلاوت',
      'school.arabic.title': 'قرآنی عربی',
      'school.understanding.title': 'فہم',
    },
    'fr': <String, String>{
      'academy.title': 'Académie Al-Wasia du Savoir Sacré',
      'academy.comingSoon': 'Bientôt — inchâ’Allah',
      'academy.continue': 'Continuer où vous étiez',
      'academy.startPath': 'Commencer le Chemin',
      'academy.today': "Aujourd'hui",
      'academy.lessonsDone': 'leçons terminées',
      'common.next': 'Suivant',
      'common.back': 'Retour',
      'common.done': 'Terminé',
      'common.open': 'Ouvrir',
      'lesson.completeTitle': 'Leçon terminée',
      'path.title': 'Le Chemin',
      'path.u0.title': 'Bienvenue',
      'school.letters.title': 'Lettres',
      'school.recitation.title': 'Récitation',
      'school.arabic.title': 'Arabe coranique',
      'school.understanding.title': 'Compréhension',
    },
    'tr': <String, String>{
      'academy.title': 'El-Vasia Kutsal Bilimler Akademisi',
      'academy.comingSoon': 'Yakında — inşaallah',
      'academy.continue': 'Kaldığın yerden devam et',
      'academy.startPath': 'Yola Başla',
      'academy.today': 'Bugün',
      'academy.lessonsDone': 'tamamlanan ders',
      'common.next': 'İleri',
      'common.back': 'Geri',
      'common.done': 'Bitti',
      'common.open': 'Aç',
      'lesson.completeTitle': 'Ders tamamlandı',
      'path.title': 'Yol',
      'path.u0.title': 'Hoş geldin',
      'school.letters.title': 'Harfler',
      'school.recitation.title': 'Tilavet',
      'school.arabic.title': 'Kur’an Arapçası',
      'school.understanding.title': 'Anlayış',
    },
    'id': <String, String>{
      'academy.title': 'Akademi Al-Wasia Ilmu Agama',
      'academy.comingSoon': 'Segera — insya Allah',
      'academy.continue': 'Lanjutkan dari terakhir',
      'academy.startPath': 'Mulai Perjalanan',
      'academy.today': 'Hari ini',
      'academy.lessonsDone': 'pelajaran selesai',
      'common.next': 'Lanjut',
      'common.back': 'Kembali',
      'common.done': 'Selesai',
      'common.open': 'Buka',
      'lesson.completeTitle': 'Pelajaran selesai',
      'path.title': 'Perjalanan',
      'path.u0.title': 'Selamat datang',
      'school.letters.title': 'Huruf',
      'school.recitation.title': 'Tilawah',
      'school.arabic.title': 'Bahasa Arab Al-Qur’an',
      'school.understanding.title': 'Pemahaman',
    },
  };

  /// Look up [key] for [locale], falling back to English, then the key.
  static String get(String key, {String locale = defaultLocale}) {
    final Map<String, String>? table = _data[locale];
    final String? hit = table?[key];
    if (hit != null && hit.isNotEmpty) return hit;
    final String? en = _data[defaultLocale]?[key];
    return (en != null && en.isNotEmpty) ? en : key;
  }

  /// Locales with at least partial coverage (scaffold).
  static List<String> get supportedLocales => _data.keys.toList();
}
