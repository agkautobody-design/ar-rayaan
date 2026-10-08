/// Letters school data — the 28 Arabic letters in hijā'ī order.
/// Makhraj notes in plain words; "Hear it" plays a short verified ayah
/// containing the letter (resolved from the bundled Quran text).
library;

import 'recitation_audio.dart';

class LetterEntry {
  const LetterEntry({
    required this.name,
    required this.isolated,
    required this.makhraj,
    required this.example,
    required this.exampleAyah,
  });

  final String name;
  final String isolated;
  final String makhraj;
  final String example;

  /// A short, verified ayah where the letter sounds — the audio source
  /// for "Hear it" (resolved from the bundled, checksummed Quran text).
  final AyahRef exampleAyah;
}

const List<LetterEntry> kHijaiLetters = <LetterEntry>[
  LetterEntry(name: 'Alif', isolated: 'ا', makhraj: 'From the empty space of the mouth — open it fully.', exampleAyah: AyahRef(1, 5), example: 'الله'),
  LetterEntry(name: 'Bā', isolated: 'ب', makhraj: 'Both lips together.', exampleAyah: AyahRef(1, 1), example: 'بِسْمِ'),
  LetterEntry(name: 'Tā', isolated: 'ت', makhraj: 'Tip of the tongue to the upper front teeth.', exampleAyah: AyahRef(1, 5), example: 'تَبَّتْ'),
  LetterEntry(name: 'Thā', isolated: 'ث', makhraj: 'Tongue tip between the front teeth (gentle).', exampleAyah: AyahRef(18, 3), example: 'ثُمَّ'),
  LetterEntry(name: 'Jīm', isolated: 'ج', makhraj: 'Middle of the tongue with the palate.', exampleAyah: AyahRef(7, 120), example: 'جَنَّة'),
  LetterEntry(name: 'Ḥā', isolated: 'ح', makhraj: 'Deep in the throat, a gentle breath.', exampleAyah: AyahRef(1, 1), example: 'الرَّحْمَٰن'),
  LetterEntry(name: 'Khā', isolated: 'خ', makhraj: 'Back of the tongue to the soft palate.', exampleAyah: AyahRef(15, 40), example: 'خَلَقَ'),
  LetterEntry(name: 'Dāl', isolated: 'د', makhraj: 'Tongue tip to the upper teeth (heavy).', exampleAyah: AyahRef(1, 2), example: 'دِين'),
  LetterEntry(name: 'Dhāl', isolated: 'ذ', makhraj: 'Tongue tip between the teeth (heavy).', exampleAyah: AyahRef(10, 63), example: 'ذَٰلِك'),
  LetterEntry(name: 'Rā', isolated: 'ر', makhraj: 'Tongue tip vibrates against the palate.', exampleAyah: AyahRef(1, 1), example: 'رَبِّ'),
  LetterEntry(name: 'Zāy', isolated: 'ز', makhraj: 'Tongue tip to the teeth, voiced.', exampleAyah: AyahRef(15, 69), example: 'زَكَاة'),
  LetterEntry(name: 'Sīn', isolated: 'س', makhraj: 'Tongue tip near the teeth, a whistle.', exampleAyah: AyahRef(1, 1), example: 'سَمَاء'),
  LetterEntry(name: 'Shīn', isolated: 'ش', makhraj: 'Tongue with the palate, wide.', exampleAyah: AyahRef(12, 16), example: 'شَمْس'),
  LetterEntry(name: 'Ṣād', isolated: 'ص', makhraj: 'Heavy: tongue flat, lips rounded.', exampleAyah: AyahRef(1, 6), example: 'صَلَاة'),
  LetterEntry(name: 'Ḍād', isolated: 'ض', makhraj: 'Heavy: tongue side pressed to the molars.', exampleAyah: AyahRef(15, 51), example: 'ضَالَّ'),
  LetterEntry(name: 'Ṭā', isolated: 'ط', makhraj: 'Heavy: tongue tip to the gums firmly.', exampleAyah: AyahRef(1, 6), example: 'طَيِّبَة'),
  LetterEntry(name: 'Ẓā', isolated: 'ظ', makhraj: 'Heavy: tongue tip between the teeth.', exampleAyah: AyahRef(7, 15), example: 'ظَهَرَ'),
  LetterEntry(name: 'ʿAyn', isolated: 'ع', makhraj: 'Middle of the throat, voiced.', exampleAyah: AyahRef(1, 2), example: 'عِلْم'),
  LetterEntry(name: 'Ghayn', isolated: 'غ', makhraj: 'Back of the throat, voiced growl.', exampleAyah: AyahRef(7, 119), example: 'غَفُور'),
  LetterEntry(name: 'Fā', isolated: 'ف', makhraj: 'Lower lip to the upper front teeth.', exampleAyah: AyahRef(7, 119), example: 'فِي'),
  LetterEntry(name: 'Qāf', isolated: 'ق', makhraj: 'Back of the tongue to the soft palate.', exampleAyah: AyahRef(1, 6), example: 'قُلْ'),
  LetterEntry(name: 'Kāf', isolated: 'ك', makhraj: 'Tongue to the palate, lighter than qāf.', exampleAyah: AyahRef(1, 4), example: 'كِتَاب'),
  LetterEntry(name: 'Lām', isolated: 'ل', makhraj: 'Tongue tip to the palate, flowing.', exampleAyah: AyahRef(1, 1), example: 'لِلَّه'),
  LetterEntry(name: 'Mīm', isolated: 'م', makhraj: 'Both lips closed, humming.', exampleAyah: AyahRef(1, 1), example: 'مُحَمَّد'),
  LetterEntry(name: 'Nūn', isolated: 'ن', makhraj: 'Tongue tip to the gums, voiced.', exampleAyah: AyahRef(1, 1), example: 'نُور'),
  LetterEntry(name: 'Hā', isolated: 'ه', makhraj: 'A light breath from the throat.', exampleAyah: AyahRef(1, 1), example: 'هُوَ'),
  LetterEntry(name: 'Wāw', isolated: 'و', makhraj: 'Lips rounded, then opened.', exampleAyah: AyahRef(1, 4), example: 'وَ'),
  LetterEntry(name: 'Yā', isolated: 'ي', makhraj: 'Middle of the tongue to the palate.', exampleAyah: AyahRef(1, 1), example: 'يَوْم'),
];
