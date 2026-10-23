# Translation review: short interface labels

Status: MACHINE-STYLE, NOT YET CHECKED BY A NATIVE SPEAKER.

Source of truth: `lib/app/core/i18n/ui_labels.dart` (a plain Dart table, one entry per label). Each label below was written as a standard, widely used interface word. None has been reviewed by a native speaker. Until a reviewer signs off, the Language screen says these are first drafts.

What is covered: bottom navigation, Home tile titles, the onboarding questions and buttons, and the top rows of Settings. Nothing else is translated: no religious content, no Hadi answers, no stories, lessons or long texts.

## What the reviewer should do

1. For each row, mark the language cell OK or write the corrected word.
2. Pay particular attention to: Faith (nav tab, meaning the Faith section, not "belief" alone), Hadi (a name, keep it recognisable), Wasia Academy and Today's NOOR (product names), Dhikr & Du'a (a section name), and the onboarding question and answers (tone should be warm, not formal).
3. Send corrections to the owner; Claude edits the table and the test (`test/language_trust_jumuah_test.dart`) keeps all four languages complete.

## Direction

Arabic and Urdu switch the whole layout to right-to-left. Bangla stays left-to-right. A reviewer who reads Arabic or Urdu should also look at Home, Settings and the first-run slides in RTL and report anything that looks broken (icons that should flip, misaligned text).

## Labels

| Key | English | Arabic | Bangla | Urdu |
|---|---|---|---|---|
| `nav.home` | Home | الرئيسية | হোম | ہوم |
| `nav.faith` | Faith | الإيمان | ঈমান | ایمان |
| `nav.family` | Family | العائلة | পরিবার | خاندان |
| `nav.hadi` | Hādi | هادي | হাদী | ہادی |
| `nav.you` | You | أنت | আপনি | آپ |
| `tile.prayer` | Prayer Times | مواقيت الصلاة | নামাজের সময় | نماز کے اوقات |
| `tile.quran` | Qur’an | القرآن | কুরআন | قرآن |
| `tile.dhikr` | Dhikr & Du’a | الأذكار والدعاء | যিকির ও দোয়া | ذکر اور دعا |
| `tile.hadith` | Hadith | الحديث | হাদিস | حدیث |
| `tile.noor` | Today’s NOOR | نور اليوم | আজকের নূর | آج کا نور |
| `tile.calendar` | Islamic Calendar | التقويم الإسلامي | ইসলামি ক্যালেন্ডার | اسلامی کیلنڈر |
| `tile.knowledge` | Knowledge | المعرفة | জ্ঞান | علم |
| `tile.academy` | Wasia Academy | أكاديمية وصية | ওয়াসিয়া একাডেমি | وصیہ اکیڈمی |
| `tile.journey` | My Journey | رحلتي | আমার যাত্রা | میرا سفر |
| `ui.qibla` | Qibla | القبلة | কিবলা | قبلہ |
| `ui.settings` | Settings | الإعدادات | সেটিংস | ترتیبات |
| `ui.next` | Next | التالي | পরবর্তী | اگلا |
| `ui.skip` | Skip | تخطَّ | এড়িয়ে যান | چھوڑیں |
| `ui.continue` | Continue | متابعة | চালিয়ে যান | جاری رکھیں |
| `ui.begin` | Begin | ابدأ | শুরু করুন | شروع کریں |
| `ui.search` | Search | بحث | অনুসন্ধান | تلاش |
| `ui.back` | Back | رجوع | পিছনে | واپس |
| `ui.language` | Language | اللغة | ভাষা | زبان |
| `ui.about` | About | حول التطبيق | পরিচিতি | تعارف |
| `ui.sources` | Our Sources | مصادرنا | আমাদের সূত্র | ہمارے ذرائع |
| `onb.question` | What brings you here? | ما الذي جاء بك إلى هنا؟ | আপনি এখানে কেন এসেছেন? | آپ یہاں کیوں آئے ہیں؟ |
| `onb.learn` | Learning about Islam | تعلّم الإسلام | ইসলাম সম্পর্কে শেখা | اسلام کے بارے میں سیکھنا |
| `onb.peace` | Peace for my heart | سكينة لقلبي | মনের শান্তি | دل کا سکون |
| `onb.children` | Teaching my children | تعليم أطفالي | আমার সন্তানদের শেখানো | اپنے بچوں کو سکھانا |
| `onb.pray` | Praying on time | الصلاة في وقتها | সময়মতো নামাজ | وقت پر نماز |
| `onb.new` | New to Islam or just curious | جديد على الإسلام أو فضولي فقط | ইসলামে নতুন বা শুধু কৌতূহলী | اسلام میں نیا یا صرف متجسس |
| `onb.community` | A community | مجتمع | একটি সম্প্রদায় | ایک کمیونٹی |

## Other machine-written text already in the app (not part of this task)

`lib/app/core/i18n/app_locale.dart` holds Language & Voice labels for Urdu, Arabic and Indonesian, and prayer-name words for eight languages. They predate this review and need the same check.
