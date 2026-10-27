/// The smallest honest string table for short interface labels.
///
/// Only labels a person needs to find their way (navigation, tile titles,
/// buttons, the first-run questions, the Home screen's own words and the Menu
/// rows) live here, in the three languages the
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
  'onb.hello': {
    'en': 'AS-SALAAMU ALAIKUM',
    'ar': 'السلام عليكم',
    'bn': 'আস-সালামু আলাইকুম',
    'ur': 'السلام علیکم',
  },
  'onb.title': {
    'en': 'Welcome to Ar-Rayaan',
    'ar': 'مرحبًا بك في الريان',
    'bn': 'আর-রাইয়ানে স্বাগতম',
    'ur': 'الریان میں خوش آمدید',
  },
  'onb.choose': {
    'en': 'Choose one — it only sets your first door. Or press Begin to go straight Home.',
    'ar': 'اختر واحدًا — فهو يحدد بابك الأول فقط. أو اضغط «ابدأ» للذهاب إلى الرئيسية مباشرة.',
    'bn': 'একটি বেছে নিন — এটি শুধু আপনার প্রথম দরজা ঠিক করে। অথবা সরাসরি হোমে যেতে «শুরু করুন» চাপুন।',
    'ur': 'ایک چنیں — یہ صرف آپ کا پہلا دروازہ طے کرتا ہے۔ یا سیدھا ہوم جانے کے لیے «شروع کریں» دبائیں۔',
  },
  'onb.body': {
    'en': 'Prayer times, the Qur’an, stories, a school for your children, and Hādi, a guide you can ask in plain words. You do not need to be Muslim to look around.',
    'ar': 'مواقيت الصلاة، والقرآن، والقصص، ومدرسة لأطفالك، وهادي، دليل تسأله بكلمات بسيطة. لا يلزم أن تكون مسلمًا لتتجول فيه.',
    'bn': 'নামাজের সময়, কুরআন, গল্প, আপনার সন্তানদের জন্য একটি স্কুল, আর হাদী, এমন একজন সঙ্গী যাকে আপনি সহজ ভাষায় প্রশ্ন করতে পারেন। চারপাশ ঘুরে দেখতে মুসলিম হওয়ার প্রয়োজন নেই।',
    'ur': 'نماز کے اوقات، قرآن، کہانیاں، آپ کے بچوں کے لیے ایک مدرسہ، اور ہادی، ایک رہنما جس سے آپ سادہ الفاظ میں پوچھ سکتے ہیں۔ آس پاس دیکھنے کے لیے مسلمان ہونا ضروری نہیں۔',
  },
  'onb.trust': {
    'en': 'Free today. No sign-up needed. Nothing asks for a card.',
    'ar': 'مجاني اليوم. لا حاجة للتسجيل. لا شيء يطلب بطاقة.',
    'bn': 'আজ বিনামূল্যে। সাইন-আপ লাগবে না। কিছুই কার্ড চায় না।',
    'ur': 'آج مفت۔ سائن اپ کی ضرورت نہیں۔ کوئی چیز کارڈ نہیں مانگتی۔',
  },
  'onb.langNote': {
    'en': 'Menus and titles change. Lessons, stories and answers stay in English for now.',
    'ar': 'تتغير القوائم والعناوين. تبقى الدروس والقصص والأجوبة بالإنجليزية حاليًا.',
    'bn': 'মেনু ও শিরোনাম বদলায়। পাঠ, গল্প ও উত্তর আপাতত ইংরেজিতেই থাকে।',
    'ur': 'مینو اور عنوان بدل جاتے ہیں۔ اسباق، کہانیاں اور جوابات فی الحال انگریزی میں رہتے ہیں۔',
  },
  'onb.elder1': {
    'en': 'Easier to read? Turn on Elder Mode',
    'ar': 'قراءة أسهل؟ شغّل وضع كبار السن',
    'bn': 'পড়তে সহজ চান? প্রবীণ মোড চালু করুন',
    'ur': 'پڑھنے میں آسانی چاہتے ہیں؟ بزرگ موڈ آن کریں',
  },
  'onb.elder2': {
    'en': 'Big words, big buttons and a simple home. You can turn it off in Settings.',
    'ar': 'خط كبير وأزرار كبيرة وصفحة رئيسية بسيطة. يمكنك إيقافه من الإعدادات.',
    'bn': 'বড় অক্ষর, বড় বোতাম ও সহজ হোম। সেটিংসে গিয়ে বন্ধ করতে পারবেন।',
    'ur': 'بڑے حروف، بڑے بٹن اور سادہ ہوم۔ آپ اسے ترتیبات میں بند کر سکتے ہیں۔',
  },
  'onb.learn.sub': {
    'en': 'Stories, Friday talks (khutbahs), and knowledge',
    'ar': 'قصص وخطب الجمعة وعلم',
    'bn': 'গল্প, জুমার খুতবা ও জ্ঞান',
    'ur': 'کہانیاں، جمعہ کے خطبے اور علم',
  },
  'onb.peace.sub': {
    'en': 'Du’as and comfort for heavy days',
    'ar': 'أدعية وسلوى للأيام الثقيلة',
    'bn': 'ভারী দিনের জন্য দোয়া ও সান্ত্বনা',
    'ur': 'بھاری دنوں کے لیے دعائیں اور تسلی',
  },
  'onb.children.sub': {
    'en': 'Wasia’s letters school and Family Wing',
    'ar': 'مدرسة الحروف مع وصية وجناح الأسرة',
    'bn': 'ওয়াসিয়ার অক্ষর শেখা ও পরিবার অংশ',
    'ur': 'وصیہ کا حروف کا مدرسہ اور فیملی ونگ',
  },
  'onb.pray.sub': {
    'en': 'Prayer times, qibla, and adhkar',
    'ar': 'مواقيت الصلاة والقبلة والأذكار',
    'bn': 'নামাজের সময়, কিবলা ও যিকির',
    'ur': 'نماز کے اوقات، قبلہ اور اذکار',
  },
  'onb.new.sub': {
    'en': 'A gentle 30-day road, one step at a time. Everyone is welcome',
    'ar': 'طريق لطيف من 30 يومًا، خطوة خطوة. الجميع مرحّب به',
    'bn': '৩০ দিনের নরম পথ, এক ধাপ করে। সবাই স্বাগত',
    'ur': '30 دن کا نرم راستہ، ایک ایک قدم۔ سب کا خیرمقدم ہے',
  },
  'onb.community.sub': {
    'en': 'Finding a masjid near you and its Friday time',
    'ar': 'العثور على مسجد قريب منك ووقت صلاة الجمعة فيه',
    'bn': 'আপনার কাছের মসজিদ ও তার জুমার সময় খুঁজে পাওয়া',
    'ur': 'اپنے قریب مسجد اور اس کا جمعہ کا وقت تلاش کرنا',
  },
  'home.greeting': {
    'en': 'As-Salaamu Alaikum,',
    'ar': 'السلام عليكم،',
    'bn': 'আসসালামু আলাইকুম,',
    'ur': 'السلام علیکم،',
  },
  'home.welcome': {
    'en': 'Welcome Home',
    'ar': 'أهلًا بك',
    'bn': 'স্বাগতম',
    'ur': 'خوش آمدید',
  },
  'home.blessing': {
    'en': 'May Allah make this a source of\nbarakah in your day!',
    'ar': 'نسأل الله أن يجعل هذا\nسببًا للبركة في يومك!',
    'bn': 'আল্লাহ এটিকে আপনার দিনের\nবরকতের উৎস করুন!',
    'ur': 'اللہ اسے آپ کے دن کی\nبرکت کا ذریعہ بنائے!',
  },
  'home.quick': {
    'en': 'Quick Access',
    'ar': 'وصول سريع',
    'bn': 'দ্রুত প্রবেশ',
    'ur': 'فوری رسائی',
  },
  'home.quickSub': {
    'en': 'Academy · Naats · Games · Elder Care · Therapy · Duas',
    'ar': 'الأكاديمية · الأناشيد · الألعاب · رعاية كبار السن · الدعم النفسي · الأدعية',
    'bn': 'একাডেমি · নাত · খেলা · প্রবীণ সেবা · মানসিক সহায়তা · দোয়া',
    'ur': 'اکیڈمی · نعتیں · کھیل · بزرگوں کی دیکھ بھال · ذہنی معاونت · دعائیں',
  },
  'home.elder': {
    'en': 'ELDER MODE',
    'ar': 'وضع كبار السن',
    'bn': 'প্রবীণ মোড',
    'ur': 'بزرگ موڈ',
  },
  'home.elderSub': {
    'en': 'Big words. A few simple doors. Nothing else.',
    'ar': 'خط كبير. أبواب بسيطة. لا شيء غير ذلك.',
    'bn': 'বড় অক্ষর। কয়েকটি সহজ দরজা। আর কিছু নয়।',
    'ur': 'بڑے حروف۔ چند سادہ دروازے۔ اور کچھ نہیں۔',
  },
  'home.elderSubLong': {
    'en': 'One tap — the app opens here for them every time. Big words. A few simple doors. Nothing else.',
    'ar': 'لمسة واحدة — يفتح التطبيق هنا لهم في كل مرة. خط كبير. أبواب بسيطة. لا شيء غير ذلك.',
    'bn': 'এক ট্যাপ — প্রতিবার অ্যাপ তাদের জন্য এখানে খুলবে। বড় অক্ষর। কয়েকটি সহজ দরজা। আর কিছু নয়।',
    'ur': 'ایک ٹیپ — ایپ ہر بار ان کے لیے یہیں کھلے گی۔ بڑے حروف۔ چند سادہ دروازے۔ اور کچھ نہیں۔',
  },
  'home.also': {
    'en': 'Also:',
    'ar': 'وأيضًا:',
    'bn': 'আরও:',
    'ur': 'مزید:',
  },
  'home.nasheeds': {
    'en': 'Nasheeds',
    'ar': 'الأناشيد',
    'bn': 'নাশিদ',
    'ur': 'نشید',
  },
  'home.forChildren': {
    'en': 'For children',
    'ar': 'للأطفال',
    'bn': 'শিশুদের জন্য',
    'ur': 'بچوں کے لیے',
  },
  'home.mosques': {
    'en': 'Mosques & halal food',
    'ar': 'المساجد والطعام الحلال',
    'bn': 'মসজিদ ও হালাল খাবার',
    'ur': 'مساجد اور حلال کھانا',
  },
  'home.names99': {
    'en': '99 Names of Allah',
    'ar': 'أسماء الله الحسنى',
    'bn': 'আল্লাহর ৯৯ নাম',
    'ur': 'اللہ کے 99 نام',
  },
  'home.today': {
    'en': 'Today for You',
    'ar': 'لك اليوم',
    'bn': 'আজ আপনার জন্য',
    'ur': 'آج آپ کے لیے',
  },
  'home.viewAll': {
    'en': 'View All',
    'ar': 'عرض الكل',
    'bn': 'সব দেখুন',
    'ur': 'سب دیکھیں',
  },
  'home.nextStep': {
    'en': 'YOUR NEXT STEP',
    'ar': 'خطوتك التالية',
    'bn': 'আপনার পরবর্তী ধাপ',
    'ur': 'آپ کا اگلا قدم',
  },
  'home.soon': {
    'en': 'Soon',
    'ar': 'قريبًا',
    'bn': 'শীঘ্রই',
    'ur': 'جلد',
  },
  'home.remaining': {
    'en': 'remaining',
    'ar': 'المتبقي',
    'bn': 'বাকি',
    'ur': 'باقی',
  },
  'tile.stories': {
    'en': 'Stories',
    'ar': 'القصص',
    'bn': 'গল্প',
    'ur': 'کہانیاں',
  },
  'tile.games': {
    'en': 'Games',
    'ar': 'الألعاب',
    'bn': 'খেলা',
    'ur': 'کھیل',
  },
  'sub.hadith': {
    'en': 'The Forty Hadith · An-Nawawi',
    'ar': 'الأربعون النووية',
    'bn': 'চল্লিশ হাদিস · ইমাম নববী',
    'ur': 'چالیس احادیث · امام نووی',
  },
  'sub.noor': {
    'en': 'A fresh light for your heart',
    'ar': 'نور جديد لقلبك',
    'bn': 'আপনার হৃদয়ের জন্য নতুন আলো',
    'ur': 'آپ کے دل کے لیے نئی روشنی',
  },
  'sub.hadi': {
    'en': 'Ask anything · Get guidance',
    'ar': 'اسأل أي شيء · احصل على إرشاد',
    'bn': 'যেকোনো প্রশ্ন করুন · দিকনির্দেশনা পান',
    'ur': 'کچھ بھی پوچھیں · رہنمائی پائیں',
  },
  'sub.calendar': {
    'en': 'Hijri date, converter & events',
    'ar': 'التاريخ الهجري والمحوّل والمناسبات',
    'bn': 'হিজরি তারিখ, রূপান্তর ও ঘটনা',
    'ur': 'ہجری تاریخ، کنورٹر اور تقریبات',
  },
  'sub.stories': {
    'en': 'Stories, khutbahs & duas',
    'ar': 'قصص وخطب وأدعية',
    'bn': 'গল্প, খুতবা ও দোয়া',
    'ur': 'کہانیاں، خطبے اور دعائیں',
  },
  'sub.academy': {
    'en': 'Letters school & Family Wing',
    'ar': 'مدرسة الحروف وجناح الأسرة',
    'bn': 'অক্ষর শেখা ও পরিবার অংশ',
    'ur': 'حروف کا مدرسہ اور فیملی ونگ',
  },
  'sub.games': {
    'en': 'Quizzes, Ludo & Shatranj',
    'ar': 'اختبارات ولودو وشطرنج',
    'bn': 'কুইজ, লুডো ও দাবা',
    'ur': 'کوئز، لوڈو اور شطرنج',
  },
  'sub.journey': {
    'en': 'Track, Reflect & Grow',
    'ar': 'تابع وتأمّل وانمُ',
    'bn': 'অনুসরণ, চিন্তা ও বেড়ে ওঠা',
    'ur': 'ٹریک کریں، غور کریں اور آگے بڑھیں',
  },
  'sub.setLocation': {
    'en': 'Set your location',
    'ar': 'حدّد موقعك',
    'bn': 'আপনার অবস্থান নির্ধারণ করুন',
    'ur': 'اپنا مقام منتخب کریں',
  },
  'sub.loadingTimes': {
    'en': 'Loading times…',
    'ar': 'جارٍ تحميل المواقيت…',
    'bn': 'সময় লোড হচ্ছে…',
    'ur': 'اوقات لوڈ ہو رہے ہیں…',
  },
  'sub.timesUnavailable': {
    'en': 'Times unavailable',
    'ar': 'المواقيت غير متاحة',
    'bn': 'সময় পাওয়া যায়নি',
    'ur': 'اوقات دستیاب نہیں',
  },
  'sub.beginReading': {
    'en': 'Begin Reading · Al-Fatihah',
    'ar': 'ابدأ القراءة · الفاتحة',
    'bn': 'পড়া শুরু করুন · আল-ফাতিহা',
    'ur': 'پڑھنا شروع کریں · الفاتحہ',
  },
  'sub.continueReading': {
    'en': 'Continue Reading',
    'ar': 'تابع القراءة',
    'bn': 'পড়া চালিয়ে যান',
    'ur': 'پڑھنا جاری رکھیں',
  },
  'sub.morningAdhkar': {
    'en': 'Morning Adhkar',
    'ar': 'أذكار الصباح',
    'bn': 'সকালের যিকির',
    'ur': 'صبح کے اذکار',
  },
  'menu.title': {
    'en': 'Menu',
    'ar': 'القائمة',
    'bn': 'মেনু',
    'ur': 'مینو',
  },
  'menu.faith': {
    'en': 'Faith & Worship',
    'ar': 'الإيمان والعبادة',
    'bn': 'ঈমান ও ইবাদত',
    'ur': 'ایمان اور عبادت',
  },
  'menu.healing': {
    'en': 'Healing & Guidance',
    'ar': 'الشفاء والإرشاد',
    'bn': 'আরোগ্য ও দিকনির্দেশনা',
    'ur': 'شفا اور رہنمائی',
  },
  'menu.family': {
    'en': 'Family & Community',
    'ar': 'الأسرة والمجتمع',
    'bn': 'পরিবার ও সমাজ',
    'ur': 'خاندان اور برادری',
  },
  'menu.tools': {
    'en': 'Tools & Resources',
    'ar': 'أدوات وموارد',
    'bn': 'সরঞ্জাম ও সম্পদ',
    'ur': 'اوزار اور وسائل',
  },
  'menu.qibla': {
    'en': 'Qibla Finder',
    'ar': 'تحديد القبلة',
    'bn': 'কিবলা নির্ণয়',
    'ur': 'قبلہ تلاش',
  },
  'menu.zakat': {
    'en': 'Zakat Calculator',
    'ar': 'حاسبة الزكاة',
    'bn': 'যাকাত ক্যালকুলেটর',
    'ur': 'زکوٰۃ کیلکولیٹر',
  },
  'menu.courses': {
    'en': 'Islamic Courses',
    'ar': 'الدورات الإسلامية',
    'bn': 'ইসলামি কোর্স',
    'ur': 'اسلامی کورسز',
  },
  'menu.marriage': {
    'en': 'Marriage & Family Life',
    'ar': 'الزواج وحياة الأسرة',
    'bn': 'বিবাহ ও পারিবারিক জীবন',
    'ur': 'نکاح اور خاندانی زندگی',
  },
  'menu.familyWing': {
    'en': 'Family Wing · for parents',
    'ar': 'جناح الأسرة · للوالدين',
    'bn': 'পরিবার অংশ · অভিভাবকদের জন্য',
    'ur': 'فیملی ونگ · والدین کے لیے',
  },
  'menu.community': {
    'en': 'Community',
    'ar': 'المجتمع',
    'bn': 'সম্প্রদায়',
    'ur': 'کمیونٹی',
  },
  'menu.elderCare': {
    'en': 'Elder Care',
    'ar': 'رعاية كبار السن',
    'bn': 'প্রবীণ সেবা',
    'ur': 'بزرگوں کی دیکھ بھال',
  },
  'menu.library': {
    'en': 'Library',
    'ar': 'المكتبة',
    'bn': 'লাইব্রেরি',
    'ur': 'لائبریری',
  },
  'menu.notes': {
    'en': 'Notes & Bookmarks',
    'ar': 'الملاحظات والعلامات',
    'bn': 'নোট ও বুকমার্ক',
    'ur': 'نوٹس اور بک مارکس',
  },
  'menu.downloads': {
    'en': 'Downloads',
    'ar': 'التنزيلات',
    'bn': 'ডাউনলোড',
    'ur': 'ڈاؤن لوڈز',
  },
  'menu.logout': {
    'en': 'Log Out',
    'ar': 'تسجيل الخروج',
    'bn': 'লগ আউট',
    'ur': 'لاگ آؤٹ',
  },
  'menu.signin': {
    'en': 'Sign in',
    'ar': 'تسجيل الدخول',
    'bn': 'সাইন ইন',
    'ur': 'سائن ان',
  },
  'sub.needsInternet': {
    'en': 'Needs internet the first time',
    'ar': 'يحتاج إلى الإنترنت في المرة الأولى',
    'bn': 'প্রথমবার ইন্টারনেট লাগবে',
    'ur': 'پہلی بار انٹرنیٹ درکار ہے',
  },
  'ui.retry': {
    'en': 'Try again',
    'ar': 'حاول مرة أخرى',
    'bn': 'আবার চেষ্টা করুন',
    'ur': 'دوبارہ کوشش کریں',
  },
  'ui.close': {
    'en': 'Close',
    'ar': 'إغلاق',
    'bn': 'বন্ধ করুন',
    'ur': 'بند کریں',
  },
  'ui.cancel': {
    'en': 'Cancel',
    'ar': 'إلغاء',
    'bn': 'বাতিল',
    'ur': 'منسوخ کریں',
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
