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


## Added in the flows round (all machine-style, none reviewed)

These cover the Home screen, the first-run screens, the Menu and common buttons. Same instructions as above. Long prose, Settings and Profile text, Terms, Privacy and every religious text remain English on purpose.

| Key | English | Arabic | Bangla | Urdu |
|---|---|---|---|---|
| `onb.hello` | AS-SALAAMU ALAIKUM | السلام عليكم | আস-সালামু আলাইকুম | السلام علیکم |
| `onb.title` | Welcome to Ar-Rayaan | مرحبًا بك في الريان | আর-রাইয়ানে স্বাগতম | الریان میں خوش آمدید |
| `onb.choose` | Choose one — it only sets your first door. Or press Begin to go straight Home. | اختر واحدًا — فهو يحدد بابك الأول فقط. أو اضغط «ابدأ» للذهاب إلى الرئيسية مباشرة. | একটি বেছে নিন — এটি শুধু আপনার প্রথম দরজা ঠিক করে। অথবা সরাসরি হোমে যেতে «শুরু করুন» চাপুন। | ایک چنیں — یہ صرف آپ کا پہلا دروازہ طے کرتا ہے۔ یا سیدھا ہوم جانے کے لیے «شروع کریں» دبائیں۔ |
| `onb.body` | Prayer times, the Qur’an, stories, a school for your children, and Hādi, a guide you can ask in plain words. You do not need to be Muslim to look around. | مواقيت الصلاة، والقرآن، والقصص، ومدرسة لأطفالك، وهادي، دليل تسأله بكلمات بسيطة. لا يلزم أن تكون مسلمًا لتتجول فيه. | নামাজের সময়, কুরআন, গল্প, আপনার সন্তানদের জন্য একটি স্কুল, আর হাদী, এমন একজন সঙ্গী যাকে আপনি সহজ ভাষায় প্রশ্ন করতে পারেন। চারপাশ ঘুরে দেখতে মুসলিম হওয়ার প্রয়োজন নেই। | نماز کے اوقات، قرآن، کہانیاں، آپ کے بچوں کے لیے ایک مدرسہ، اور ہادی، ایک رہنما جس سے آپ سادہ الفاظ میں پوچھ سکتے ہیں۔ آس پاس دیکھنے کے لیے مسلمان ہونا ضروری نہیں۔ |
| `onb.trust` | Free today. No sign-up needed. Nothing asks for a card. | مجاني اليوم. لا حاجة للتسجيل. لا شيء يطلب بطاقة. | আজ বিনামূল্যে। সাইন-আপ লাগবে না। কিছুই কার্ড চায় না। | آج مفت۔ سائن اپ کی ضرورت نہیں۔ کوئی چیز کارڈ نہیں مانگتی۔ |
| `onb.langNote` | Menus and titles change. Lessons, stories and answers stay in English for now. | تتغير القوائم والعناوين. تبقى الدروس والقصص والأجوبة بالإنجليزية حاليًا. | মেনু ও শিরোনাম বদলায়। পাঠ, গল্প ও উত্তর আপাতত ইংরেজিতেই থাকে। | مینو اور عنوان بدل جاتے ہیں۔ اسباق، کہانیاں اور جوابات فی الحال انگریزی میں رہتے ہیں۔ |
| `onb.elder1` | Easier to read? Turn on Elder Mode | قراءة أسهل؟ شغّل وضع كبار السن | পড়তে সহজ চান? প্রবীণ মোড চালু করুন | پڑھنے میں آسانی چاہتے ہیں؟ بزرگ موڈ آن کریں |
| `onb.elder2` | Big words, big buttons and a simple home. You can turn it off in Settings. | خط كبير وأزرار كبيرة وصفحة رئيسية بسيطة. يمكنك إيقافه من الإعدادات. | বড় অক্ষর, বড় বোতাম ও সহজ হোম। সেটিংসে গিয়ে বন্ধ করতে পারবেন। | بڑے حروف، بڑے بٹن اور سادہ ہوم۔ آپ اسے ترتیبات میں بند کر سکتے ہیں۔ |
| `onb.learn.sub` | Stories, Friday talks (khutbahs), and knowledge | قصص وخطب الجمعة وعلم | গল্প, জুমার খুতবা ও জ্ঞান | کہانیاں، جمعہ کے خطبے اور علم |
| `onb.peace.sub` | Du’as and comfort for heavy days | أدعية وسلوى للأيام الثقيلة | ভারী দিনের জন্য দোয়া ও সান্ত্বনা | بھاری دنوں کے لیے دعائیں اور تسلی |
| `onb.children.sub` | Wasia’s letters school and Family Wing | مدرسة الحروف مع وصية وجناح الأسرة | ওয়াসিয়ার অক্ষর শেখা ও পরিবার অংশ | وصیہ کا حروف کا مدرسہ اور فیملی ونگ |
| `onb.pray.sub` | Prayer times, qibla, and adhkar | مواقيت الصلاة والقبلة والأذكار | নামাজের সময়, কিবলা ও যিকির | نماز کے اوقات، قبلہ اور اذکار |
| `onb.new.sub` | A gentle 30-day road, one step at a time. Everyone is welcome | طريق لطيف من 30 يومًا، خطوة خطوة. الجميع مرحّب به | ৩০ দিনের নরম পথ, এক ধাপ করে। সবাই স্বাগত | 30 دن کا نرم راستہ، ایک ایک قدم۔ سب کا خیرمقدم ہے |
| `onb.community.sub` | Finding a masjid near you and its Friday time | العثور على مسجد قريب منك ووقت صلاة الجمعة فيه | আপনার কাছের মসজিদ ও তার জুমার সময় খুঁজে পাওয়া | اپنے قریب مسجد اور اس کا جمعہ کا وقت تلاش کرنا |
| `home.greeting` | As-Salaamu Alaikum, | السلام عليكم، | আসসালামু আলাইকুম, | السلام علیکم، |
| `home.welcome` | Welcome Home | أهلًا بك | স্বাগতম | خوش آمدید |
| `home.blessing` | May Allah make this a source of\nbarakah in your day! | نسأل الله أن يجعل هذا\nسببًا للبركة في يومك! | আল্লাহ এটিকে আপনার দিনের\nবরকতের উৎস করুন! | اللہ اسے آپ کے دن کی\nبرکت کا ذریعہ بنائے! |
| `home.quick` | Quick Access | وصول سريع | দ্রুত প্রবেশ | فوری رسائی |
| `home.quickSub` | Academy · Naats · Games · Elder Care · Therapy · Duas | الأكاديمية · الأناشيد · الألعاب · رعاية كبار السن · الدعم النفسي · الأدعية | একাডেমি · নাত · খেলা · প্রবীণ সেবা · মানসিক সহায়তা · দোয়া | اکیڈمی · نعتیں · کھیل · بزرگوں کی دیکھ بھال · ذہنی معاونت · دعائیں |
| `home.elder` | ELDER MODE | وضع كبار السن | প্রবীণ মোড | بزرگ موڈ |
| `home.elderSub` | Big words. Three doors. Nothing else. | خط كبير. ثلاثة أبواب. لا شيء غير ذلك. | বড় অক্ষর। তিনটি দরজা। আর কিছু নয়। | بڑے حروف۔ تین دروازے۔ اور کچھ نہیں۔ |
| `home.elderSubLong` | One tap — the app opens here for them every time. Big words. Three doors. Nothing else. | لمسة واحدة — يفتح التطبيق هنا لهم في كل مرة. خط كبير. ثلاثة أبواب. لا شيء غير ذلك. | এক ট্যাপ — প্রতিবার অ্যাপ তাদের জন্য এখানে খুলবে। বড় অক্ষর। তিনটি দরজা। আর কিছু নয়। | ایک ٹیپ — ایپ ہر بار ان کے لیے یہیں کھلے گی۔ بڑے حروف۔ تین دروازے۔ اور کچھ نہیں۔ |
| `home.also` | Also: | وأيضًا: | আরও: | مزید: |
| `home.nasheeds` | Nasheeds | الأناشيد | নাশিদ | نشید |
| `home.forChildren` | For children | للأطفال | শিশুদের জন্য | بچوں کے لیے |
| `home.mosques` | Mosques & halal food | المساجد والطعام الحلال | মসজিদ ও হালাল খাবার | مساجد اور حلال کھانا |
| `home.names99` | 99 Names of Allah | أسماء الله الحسنى | আল্লাহর ৯৯ নাম | اللہ کے 99 نام |
| `home.today` | Today for You | لك اليوم | আজ আপনার জন্য | آج آپ کے لیے |
| `home.viewAll` | View All | عرض الكل | সব দেখুন | سب دیکھیں |
| `home.nextStep` | YOUR NEXT STEP | خطوتك التالية | আপনার পরবর্তী ধাপ | آپ کا اگلا قدم |
| `home.soon` | Soon | قريبًا | শীঘ্রই | جلد |
| `home.remaining` | remaining | المتبقي | বাকি | باقی |
| `tile.stories` | Stories | القصص | গল্প | کہانیاں |
| `tile.games` | Games | الألعاب | খেলা | کھیل |
| `sub.hadith` | The Forty Hadith · An-Nawawi | الأربعون النووية | চল্লিশ হাদিস · ইমাম নববী | چالیس احادیث · امام نووی |
| `sub.noor` | A fresh light for your heart | نور جديد لقلبك | আপনার হৃদয়ের জন্য নতুন আলো | آپ کے دل کے لیے نئی روشنی |
| `sub.hadi` | Ask anything · Get guidance | اسأل أي شيء · احصل على إرشاد | যেকোনো প্রশ্ন করুন · দিকনির্দেশনা পান | کچھ بھی پوچھیں · رہنمائی پائیں |
| `sub.calendar` | Hijri date, converter & events | التاريخ الهجري والمحوّل والمناسبات | হিজরি তারিখ, রূপান্তর ও ঘটনা | ہجری تاریخ، کنورٹر اور تقریبات |
| `sub.stories` | Stories, khutbahs & duas | قصص وخطب وأدعية | গল্প, খুতবা ও দোয়া | کہانیاں، خطبے اور دعائیں |
| `sub.academy` | Letters school & Family Wing | مدرسة الحروف وجناح الأسرة | অক্ষর শেখা ও পরিবার অংশ | حروف کا مدرسہ اور فیملی ونگ |
| `sub.games` | Quizzes, Ludo & Shatranj | اختبارات ولودو وشطرنج | কুইজ, লুডো ও দাবা | کوئز، لوڈو اور شطرنج |
| `sub.journey` | Track, Reflect & Grow | تابع وتأمّل وانمُ | অনুসরণ, চিন্তা ও বেড়ে ওঠা | ٹریک کریں، غور کریں اور آگے بڑھیں |
| `sub.setLocation` | Set your location | حدّد موقعك | আপনার অবস্থান নির্ধারণ করুন | اپنا مقام منتخب کریں |
| `sub.loadingTimes` | Loading times… | جارٍ تحميل المواقيت… | সময় লোড হচ্ছে… | اوقات لوڈ ہو رہے ہیں… |
| `sub.timesUnavailable` | Times unavailable | المواقيت غير متاحة | সময় পাওয়া যায়নি | اوقات دستیاب نہیں |
| `sub.beginReading` | Begin Reading · Al-Fatihah | ابدأ القراءة · الفاتحة | পড়া শুরু করুন · আল-ফাতিহা | پڑھنا شروع کریں · الفاتحہ |
| `sub.continueReading` | Continue Reading | تابع القراءة | পড়া চালিয়ে যান | پڑھنا جاری رکھیں |
| `sub.morningAdhkar` | Morning Adhkar | أذكار الصباح | সকালের যিকির | صبح کے اذکار |
| `menu.title` | Menu | القائمة | মেনু | مینو |
| `menu.faith` | Faith & Worship | الإيمان والعبادة | ঈমান ও ইবাদত | ایمان اور عبادت |
| `menu.healing` | Healing & Guidance | الشفاء والإرشاد | আরোগ্য ও দিকনির্দেশনা | شفا اور رہنمائی |
| `menu.family` | Family & Community | الأسرة والمجتمع | পরিবার ও সমাজ | خاندان اور برادری |
| `menu.tools` | Tools & Resources | أدوات وموارد | সরঞ্জাম ও সম্পদ | اوزار اور وسائل |
| `menu.qibla` | Qibla Finder | تحديد القبلة | কিবলা নির্ণয় | قبلہ تلاش |
| `menu.zakat` | Zakat Calculator | حاسبة الزكاة | যাকাত ক্যালকুলেটর | زکوٰۃ کیلکولیٹر |
| `menu.courses` | Islamic Courses | الدورات الإسلامية | ইসলামি কোর্স | اسلامی کورسز |
| `menu.marriage` | Marriage & Family Life | الزواج وحياة الأسرة | বিবাহ ও পারিবারিক জীবন | نکاح اور خاندانی زندگی |
| `menu.familyWing` | Family Wing · for parents | جناح الأسرة · للوالدين | পরিবার অংশ · অভিভাবকদের জন্য | فیملی ونگ · والدین کے لیے |
| `menu.community` | Community | المجتمع | সম্প্রদায় | کمیونٹی |
| `menu.elderCare` | Elder Care | رعاية كبار السن | প্রবীণ সেবা | بزرگوں کی دیکھ بھال |
| `menu.library` | Library | المكتبة | লাইব্রেরি | لائبریری |
| `menu.notes` | Notes & Bookmarks | الملاحظات والعلامات | নোট ও বুকমার্ক | نوٹس اور بک مارکس |
| `menu.downloads` | Downloads | التنزيلات | ডাউনলোড | ڈاؤن لوڈز |
| `menu.logout` | Log Out | تسجيل الخروج | লগ আউট | لاگ آؤٹ |
| `menu.signin` | Sign in | تسجيل الدخول | সাইন ইন | سائن ان |
| `sub.needsInternet` | Needs internet the first time | يحتاج إلى الإنترنت في المرة الأولى | প্রথমবার ইন্টারনেট লাগবে | پہلی بار انٹرنیٹ درکار ہے |
| `ui.retry` | Try again | حاول مرة أخرى | আবার চেষ্টা করুন | دوبارہ کوشش کریں |
| `ui.close` | Close | إغلاق | বন্ধ করুন | بند کریں |
| `ui.cancel` | Cancel | إلغاء | বাতিল | منسوخ کریں |
