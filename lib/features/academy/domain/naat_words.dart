/// The words of naats and poems of praise and prayer, so a person can read
/// them, say them, and learn their meaning in their own language.
///
/// Only texts whose copyright has expired or that are traditional (anonymous
/// and over a thousand years old) are held here. The recordings in the
/// player belong to their artists and labels; their lyrics are not copied
/// into the app. Every original line was checked against published text of
/// the poem (see [NaatWork.source]); the transliteration follows it; the
/// translations are drafts written for this app and are marked as such.
library;

/// One couplet or verse: the original, how to say it, and what it means.
class NaatLine {
  const NaatLine({
    required this.original,
    required this.sounds,
    required this.meaning,
    this.devanagari,
  });

  /// The original text. Two halves of a couplet are separated by a newline.
  final String original;

  /// The original written in Latin letters (a reading aid; left to right).
  final String sounds;

  /// The original written in Hindi script (Devanagari), for works whose
  /// original is Urdu; null when not provided. A reading aid, a draft.
  final String? devanagari;

  /// The meaning by language code: `en`, `ur`, `ar`, `bn`. The original's own
  /// language is not repeated here.
  final Map<String, String> meaning;
}

class NaatWork {
  const NaatWork({
    required this.id,
    required this.title,
    required this.titleOriginal,
    required this.poet,
    required this.kind,
    required this.originalLang,
    required this.about,
    required this.source,
    required this.lines,
  });

  final String id;
  final String title;
  final String titleOriginal;
  final String poet;

  /// "Welcome poem", "Praise of the Prophet", "A child's prayer", ...
  final String kind;

  /// `ar` or `ur`.
  final String originalLang;

  /// A few honest sentences about it, in English.
  final String about;

  /// Where the original wording was checked.
  final String source;

  final List<NaatLine> lines;

  /// Languages a reader can learn this in, original first.
  List<String> get languages => <String>[
    originalLang,
    ...kNaatLanguages.keys.where((String l) => l != originalLang),
  ];
}

/// The languages offered for meaning, with the name written in that language.
const Map<String, String> kNaatLanguages = <String, String>{
  'en': 'English',
  'ur': 'اردو',
  'ar': 'العربية',
  'bn': 'বাংলা',
  'hi': 'हिन्दी',
};

const String kNaatDraftNote =
    'The original words were checked against published text. The '
    'transliteration and the translations (English, Urdu, Hindi, Arabic, Bangla) are '
    'drafts written for this app: a native speaker and a scholar still have '
    'to check them. Other languages are not available yet.';

const List<NaatWork> kNaatWorks = <NaatWork>[
  NaatWork(
    id: 'tala-al-badru',
    title: 'Ṭalaʿa al-Badru ʿAlaynā',
    titleOriginal: 'طلع البدر علينا',
    poet: 'Traditional, poet unknown',
    kind: 'Welcome poem',
    originalLang: 'ar',
    about:
        'A short Arabic welcome poem sung for the Prophet ﷺ. It is often said '
        'that the people of Madinah sang it when he arrived, but scholars '
        'point out that the report is weakly narrated, so it is shared here as '
        'a loved traditional poem, not as a proven event. Several versions '
        'exist; this is the shortest common one.',
    source:
        'Wording as printed in the Wikipedia article "Talaʿ al-Badru ʿAlayna" '
        'and in Arabic and English scholarly notes on how it is narrated.',
    lines: <NaatLine>[
      NaatLine(
        original: 'طلع البدر علينا\nمن ثنيات الوداع',
        sounds: "ṭalaʿa l-badru ʿalaynā\nmin thaniyyāti l-wadāʿ",
        meaning: <String, String>{
          'hi': 'पूर्णिमा का चाँद हम पर निकला, वदा की घाटियों की ओर से।',
          'en':
              'The full moon has risen over us, from the valleys of Wadāʿ.',
          'ur': 'ہم پر چودھویں کا چاند طلوع ہوا، ثنیات الوداع کی گھاٹیوں سے۔',
          'bn':
              'আমাদের ওপর পূর্ণিমার চাঁদ উদিত হয়েছে, সানিয়্যাতুল ওয়াদা‘র ঘাঁটি থেকে।',
        },
      ),
      NaatLine(
        original: 'وجب الشكر علينا\nما دعا لله داع',
        sounds: "wajaba sh-shukru ʿalaynā\nmā daʿā li-llāhi dāʿ",
        meaning: <String, String>{
          'hi': 'हम पर शुक्र वाजिब है, जब तक कोई अल्लाह की ओर बुलाने वाला बुलाता रहे।',
          'en':
              'Gratitude is owed by us, for as long as anyone calls to Allah.',
          'ur':
              'ہم پر شکر واجب ہے، جب تک کوئی اللہ کی طرف بلانے والا بلاتا رہے۔',
          'bn':
              'আমাদের ওপর কৃতজ্ঞতা ওয়াজিব, যতদিন কোনো আহ্বানকারী আল্লাহর দিকে আহ্বান করে।',
        },
      ),
      NaatLine(
        original: 'أيها المبعوث فينا\nجئت بالأمر المطاع',
        sounds: "ayyuha l-mabʿūthu fīnā\njiʾta bi-l-amri l-muṭāʿ",
        meaning: <String, String>{
          'hi': 'ऐ हमारे बीच भेजे गए, आप ऐसा हुक्म लेकर आए जिसे माना जाए।',
          'en':
              'O you who were sent among us, you came with a command to be obeyed.',
          'ur':
              'اے ہمارے درمیان بھیجے گئے! آپ ایسا حکم لے کر آئے جس کی اطاعت کی جاتی ہے۔',
          'bn':
              'হে আমাদের মাঝে প্রেরিত! আপনি এসেছেন এমন নির্দেশ নিয়ে যা মান্য করার যোগ্য।',
        },
      ),
    ],
  ),
  NaatWork(
    id: 'burda-opening',
    title: 'The Burda · the opening',
    titleOriginal: 'البردة · المطلع',
    poet: 'Imam al-Būṣīrī (d. about 1295 CE)',
    kind: 'Praise of the Prophet ﷺ',
    originalLang: 'ar',
    about:
        'Qaṣīdat al-Burda, “The Poem of the Mantle”, is among the most '
        'recited poems of praise of the Prophet ﷺ, 160 verses long. These are '
        'its first six verses. They open in the old Arabic way, with longing '
        'and tears, before the poem turns to praise. The famous story that '
        'the Prophet ﷺ wrapped the poet in his mantle is a popular tradition, '
        'not a proven report.',
    source:
        'Verses 1–6 as printed in the published text of the Burda (Arabic '
        'poetry collections of al-Būṣīrī).',
    lines: <NaatLine>[
      NaatLine(
        original: 'أَمِنْ تَذَكُّرِ جِيرانٍ بِذِي سَلَمٍ\nمَزَجْتَ دَمْعاً جَرَى مِنْ مُقْلَةٍ بِدَمِ',
        sounds:
            "a-min tadhakkuri jīrānin bi-dhī salamin\nmazajta damʿan jarā min muqlatin bi-damī",
        meaning: <String, String>{
          'hi': 'क्या पड़ोसियों "ज़ी सलम" की याद ने तेरी आँख से बहते आँसुओं में ख़ून मिला दिया?',
          'en':
              'Is it the memory of neighbours at Dhū Salam that made you mix tears flowing from your eye with blood?',
          'ur':
              'کیا ذی سلم کے پڑوسیوں کی یاد نے تیری آنکھ سے بہتے آنسوؤں میں خون ملا دیا؟',
          'bn':
              'যি-সালামের প্রতিবেশীদের স্মরণেই কি তুমি চোখ থেকে ঝরা অশ্রুর সঙ্গে রক্ত মিশিয়ে ফেললে?',
        },
      ),
      NaatLine(
        original: 'أَمْ هَبَّتِ الرِّيحُ مِنْ تِلْقاءِ كاظِمَةٍ\nوَأَوْمَضَ الْبَرْقُ فِي الظَّلْماءِ مِنْ إِضَمِ',
        sounds:
            "am habbati r-rīḥu min tilqāʾi kāẓimatin\nwa-awmaḍa l-barqu fi ẓ-ẓalmāʾi min iḍami",
        meaning: <String, String>{
          'hi': 'या कज़िमा की ओर से हवा चली, और इज़म की अँधेरी रात में बिजली चमकी?',
          'en':
              'Or did the wind blow from the direction of Kāẓima, and lightning flash in the dark from Iḍam?',
          'ur':
              'یا کاظمہ کی طرف سے ہوا چلی اور اضم کی جانب اندھیرے میں بجلی چمکی؟',
          'bn':
              'নাকি কাজিমার দিক থেকে বাতাস বইল, আর ইদামের দিকে অন্ধকারে বিদ্যুৎ ঝলকাল?',
        },
      ),
      NaatLine(
        original: 'فَما لِعَيْنَيْكَ إِنْ قُلْتَ اكْفُفا هَمَتا\nوَما لِقَلْبِكَ إِنْ قُلْتَ اسْتَفِقْ يَهِمِ',
        sounds:
            "fa-mā li-ʿaynayka in qulta kfufā hamatā\nwa-mā li-qalbika in qulta stafiq yahimī",
        meaning: <String, String>{
          'hi': 'तेरी आँखों को क्या हुआ कि तू रुकने को कहे तो और बरसती हैं, और तेरे दिल को क्या हुआ कि तू सँभलने को कहे तो और बेचैन होता है?',
          'en':
              'What is wrong with your eyes, that they stream when you tell them “stop”, and your heart, that it wanders when you tell it “come to yourself”?',
          'ur':
              'تیری آنکھوں کو کیا ہوا کہ تو “رک جاؤ” کہتا ہے تب بھی بہتی رہتی ہیں، اور دل کو کیا ہوا کہ “ہوش میں آ” کہتا ہے تب بھی بھٹکتا ہے؟',
          'bn':
              'তোমার চোখের কী হলো যে “থামো” বললেও ঝরতেই থাকে, আর হৃদয়ের কী হলো যে “সুস্থ হও” বললেও দিশেহারা হয়?',
        },
      ),
      NaatLine(
        original: 'أَيَحْسَبُ الصَّبُّ أَنَّ الْحُبَّ مُنْكَتِمٌ\nما بَيْنَ مُنْسَجِمٍ مِنْهُ وَمُضْطَرِمِ',
        sounds:
            "a-yaḥsabu ṣ-ṣabbu anna l-ḥubba munkatimun\nmā bayna munsajimin minhu wa-muḍṭarimī",
        meaning: <String, String>{
          'hi': 'क्या आशिक़ समझता है कि उसका प्रेम छिपा रह जाएगा, जबकि वह बहते आँसू और भड़कती आग के बीच है?',
          'en':
              'Does the lover think his love can stay hidden, between tears pouring and a heart on fire?',
          'ur':
              'کیا عاشق سمجھتا ہے کہ اس کا عشق چھپا رہے گا، جب آنسو بہہ رہے ہوں اور دل میں آگ بھڑک رہی ہو؟',
          'bn':
              'প্রেমিক কি মনে করে তার ভালোবাসা গোপন থাকবে, যখন অশ্রু ঝরছে আর অন্তর জ্বলছে?',
        },
      ),
      NaatLine(
        original: 'لَوْلا الْهَوَى لَمْ تُرِقْ دَمْعاً عَلَى طَلَلٍ\nوَلا أَرِقْتَ لِذِكْرِ الْبانِ وَالْعَلَمِ',
        sounds:
            "lawlā l-hawā lam turiq damʿan ʿalā ṭalalin\nwa-lā ariqta li-dhikri l-bāni wa-l-ʿalami",
        meaning: <String, String>{
          'hi': 'अगर प्रेम न होता तो तू खंडहर पर आँसू न बहाता, और बान के पेड़ और पर्वत की याद में रातें न जागता।',
          'en':
              'Were it not for love you would not shed tears over a ruin, nor lie sleepless remembering the ban trees and the mountain.',
          'ur':
              'اگر محبت نہ ہوتی تو تُو کھنڈر پر آنسو نہ بہاتا، اور بان کے درختوں اور پہاڑی کی یاد میں جاگتا نہ رہتا۔',
          'bn':
              'ভালোবাসা না থাকলে তুমি ধ্বংসাবশেষের ওপর অশ্রু ঝরাতে না, আর বান গাছ ও পাহাড়ের কথা মনে করে জেগে থাকতে না।',
        },
      ),
      NaatLine(
        original: 'فَكَيْفَ تُنْكِرُ حُبّاً بَعْدَ ما شَهِدَتْ\nبِهِ عَلَيْكَ عُدُولُ الدَّمْعِ وَالسَّقَمِ',
        sounds:
            "fa-kayfa tunkiru ḥubban baʿda mā shahidat\nbihī ʿalayka ʿudūlu d-damʿi wa-s-saqami",
        meaning: <String, String>{
          'hi': 'फिर तू प्रेम से कैसे इनकार करता है, जबकि तेरे आँसू और तेरी बीमारी के दो न्यायप्रिय गवाह तेरे विरुद्ध गवाही दे चुके?',
          'en':
              'How then can you deny love, after the honest witnesses of tears and sickness have testified to it against you?',
          'ur':
              'تو پھر تُو محبت سے کیسے انکار کرے گا، جب آنسو اور بیماری کے دیانت دار گواہ تیرے خلاف گواہی دے چکے؟',
          'bn':
              'তাহলে ভালোবাসাকে কীভাবে অস্বীকার করবে, যখন অশ্রু ও রোগের ন্যায়পরায়ণ সাক্ষীরা তোমার বিরুদ্ধে সাক্ষ্য দিয়েছে?',
        },
      ),
    ],
  ),
  NaatWork(
    id: 'lab-pe-aati-hai-dua',
    title: 'Lab pe aati hai dua',
    titleOriginal: 'لب پہ آتی ہے دعا',
    poet: 'Allama Muhammad Iqbal (1877–1938)',
    kind: 'A child’s prayer',
    originalLang: 'ur',
    about:
        'Also called “Bachche ki dua”, a child’s prayer, written by Iqbal in '
        '1902. Generations of children in South Asia have learned it by '
        'heart: a prayer to be a light, to love knowledge, and to help the '
        'poor and the weak. The poet died in 1938, so the poem is in the '
        'public domain.',
    source:
        'Roman Urdu and Urdu as published on Rekhta (Bachche ki dua), and '
        'cross-checked against the Wikipedia article “Lab Pe Aati Hai Dua”.',
    lines: <NaatLine>[
      NaatLine(
        original: 'لب پہ آتی ہے دعا بن کے تمنا میری\nزندگی شمع کی صورت ہو خدایا میری',
        sounds:
            "lab pe aati hai dua ban ke tamanna meri\nzindagi shama ki surat ho Khudaya meri",
        devanagari: 'लब पे आती है दुआ बन के तमन्ना मेरी\nज़िन्दगी शम्अ की सूरत हो ख़ुदाया मेरी',
        meaning: <String, String>{
          'hi': 'मेरी तमन्ना दुआ बनकर मेरे होंठों पर आती है: ऐ ख़ुदा, मेरी ज़िंदगी शम्अ जैसी हो।',
          'en':
              'My longing comes to my lips as a prayer: O God, may my life be like a candle.',
          'ar':
              'تأتي أمنيتي إلى شفتيّ دعاءً: يا ربّ، ليكن عمري كالشمعة.',
          'bn':
              'আমার আকাঙ্ক্ষা দোয়া হয়ে ঠোঁটে আসে: হে খোদা, আমার জীবন যেন মোমবাতির মতো হয়।',
        },
      ),
      NaatLine(
        original: 'دور دنیا کا مرے دم سے اندھیرا ہو جائے\nہر جگہ میرے چمکنے سے اجالا ہو جائے',
        sounds:
            "dur duniya ka mere dam se andhera ho jae\nhar jagah mere chamakne se ujala ho jae",
        devanagari: 'दूर दुनिया का मेरे दम से अँधेरा हो जाए\nहर जगह मेरे चमकने से उजाला हो जाए',
        meaning: <String, String>{
          'hi': 'मेरे दम से दुनिया का अँधेरा दूर हो जाए; मेरे चमकने से हर जगह उजाला हो जाए।',
          'en':
              'May the darkness of the world be gone because of me; may every place be bright because I shine.',
          'ar':
              'ليزل ظلام الدنيا بسببي، وليعمّ النور كل مكان بإشراقي.',
          'bn':
              'আমার জন্য দুনিয়ার অন্ধকার দূর হোক; আমি যেখানে জ্বলি সেখানে আলো ছড়াক।',
        },
      ),
      NaatLine(
        original: 'ہو مرے دم سے یونہی میرے وطن کی زینت\nجس طرح پھول سے ہوتی ہے چمن کی زینت',
        sounds:
            "ho mere dam se yunhi mere watan ki zinat\njis tarah phul se hoti hai chaman ki zinat",
        devanagari: 'हो मेरे दम से यूँ ही मेरे वतन की ज़ीनत\nजिस तरह फूल से होती है चमन की ज़ीनत',
        meaning: <String, String>{
          'hi': 'मेरे दम से मेरे वतन की शोभा ऐसे हो, जैसे फूल से बाग़ की शोभा होती है।',
          'en':
              'May my homeland be adorned through me, as a garden is adorned by a flower.',
          'ar':
              'ليكن وطني بي في زينة، كما تتزيّن الحديقة بالزهرة.',
          'bn':
              'আমার মাধ্যমে আমার দেশ শোভিত হোক, যেমন ফুলে বাগান শোভিত হয়।',
        },
      ),
      NaatLine(
        original: 'زندگی ہو مری پروانے کی صورت یا رب\nعلم کی شمع سے ہو مجھ کو محبت یا رب',
        sounds:
            "zindagi ho meri parwane ki surat ya Rab\nilm ki shama se ho mujh ko muhabbat ya Rab",
        devanagari: 'ज़िन्दगी हो मेरी परवाने की सूरत या रब\nइल्म की शम्अ से हो मुझ को मुहब्बत या रब',
        meaning: <String, String>{
          'hi': 'ऐ मेरे रब, मेरी ज़िंदगी परवाने जैसी हो; इल्म की शम्अ से मुझे मुहब्बत हो।',
          'en':
              'May my life be like the moth’s, my Lord; may I love the candle of knowledge, my Lord.',
          'ar':
              'ليكن عمري كالفراشة يا ربّ، وليكن حبّي لشمعة العلم يا ربّ.',
          'bn':
              'হে রব, আমার জীবন হোক পতঙ্গের মতো; জ্ঞানের প্রদীপের প্রতি আমার ভালোবাসা থাকুক।',
        },
      ),
      NaatLine(
        original: 'ہو مرا کام غریبوں کی حمایت کرنا\nدردمندوں سے ضعیفوں سے محبت کرنا',
        sounds:
            "ho mera kaam gharibon ki himayat karna\ndardmandon se zaifon se muhabbat karna",
        devanagari: 'हो मेरा काम ग़रीबों की हिमायत करना\nदर्दमंदों से ज़ईफ़ों से मुहब्बत करना',
        meaning: <String, String>{
          'hi': 'मेरा काम ग़रीबों की मदद करना हो; दर्दमंदों और कमज़ोरों से मुहब्बत करना हो।',
          'en':
              'May my work be to stand up for the poor, and to love the suffering and the weak.',
          'ar':
              'ليكن عملي نصرة الفقراء، ومحبة أصحاب الألم والضعفاء.',
          'bn':
              'আমার কাজ হোক দরিদ্রদের পাশে দাঁড়ানো, ব্যথিত ও দুর্বলদের ভালোবাসা।',
        },
      ),
      NaatLine(
        original: 'مرے اللہ! برائی سے بچانا مجھ کو\nنیک جو راہ ہو اس رہ پہ چلانا مجھ کو',
        sounds:
            "mere Allah! burai se bachana mujh ko\nnek jo rah ho us rah pe chalana mujh ko",
        devanagari: 'मेरे अल्लाह! बुराई से बचाना मुझ को\nनेक जो राह हो उस रह पे चलाना मुझ को',
        meaning: <String, String>{
          'hi': 'ऐ मेरे अल्लाह, मुझे बुराई से बचाना; जो राह नेक हो उसी पर मुझे चलाना।',
          'en':
              'My Allah, keep me from evil, and walk me on every path that is good.',
          'ar':
              'يا الله، احفظني من الشرّ، وسِر بي على كل طريق صالح.',
          'bn':
              'হে আমার আল্লাহ, আমাকে মন্দ থেকে বাঁচাও; যে পথ ভালো সেই পথে আমাকে চালাও।',
        },
      ),
    ],
  ),
  NaatWork(
    id: 'mustafa-jan-e-rahmat',
    title: 'Mustafa Jaan-e-Rahmat · the first lines',
    titleOriginal: 'مصطفیٰ جانِ رحمت پہ لاکھوں سلام',
    poet: 'Imam Ahmad Raza Khan (1856–1921)',
    kind: 'Salam to the Prophet ﷺ',
    originalLang: 'ur',
    about:
        'The best loved Urdu salam, sung in gatherings across South Asia, '
        'from the collection Hadāʾiq-i Bakhshish (1907). It is long; only the '
        'opening couplet and the couplet in praise of Abū Bakr are here, '
        'because those are the lines whose wording was checked. The poet died '
        'in 1921, so the poem is in the public domain.',
    source:
        'Wording as quoted from the salam by musjidulhaq.com (the opening '
        'couplet) and dawateislami.net (the couplet on Abū Bakr). Published '
        'text of Hadāʾiq-i Bakhshish still has to be checked line by line.',
    lines: <NaatLine>[
      NaatLine(
        original: 'مصطفےٰ جانِ رحمت پہ لاکھوں سلام\nشمعِ بزمِ ہدایت پہ لاکھوں سلام',
        sounds:
            "Mustafā jān-e-raḥmat pe lākhon salām\nshamʿ-e-bazm-e-hidāyat pe lākhon salām",
        devanagari:
            'मुस्तफ़ा जान-ए-रहमत पे लाखों सलाम\nशम्अ-ए-बज़्म-ए-हिदायत पे लाखों सलाम',
        meaning: <String, String>{
          'hi':
              'मुस्तफ़ा ﷺ पर, जो रहमत की जान हैं, लाखों सलाम; हिदायत की महफ़िल की शम्अ पर लाखों सलाम।',
          'en':
              'Millions of salutations on Mustafa ﷺ, the soul of mercy; millions on the lamp of the gathering of guidance.',
          'ar':
              'ألف ألف سلام على المصطفى ﷺ روح الرحمة، وعلى شمعة مجلس الهداية.',
          'bn':
              'মুস্তফা ﷺ-এর ওপর, যিনি রহমতের প্রাণ, লক্ষ লক্ষ সালাম; হিদায়াতের মজলিসের প্রদীপের ওপর লক্ষ লক্ষ সালাম।',
        },
      ),
      NaatLine(
        original: 'عزّ و نازِ خلافت پہ لاکھوں سلام\nثانیَ اثنینِ ہجرت پہ لاکھوں سلام',
        sounds:
            "ʿizz-o-nāz-e-khilāfat pe lākhon salām\nsānī-e-ithnain-e-hijrat pe lākhon salām",
        devanagari:
            'इज़्ज़-ओ-नाज़-ए-ख़िलाफ़त पे लाखों सलाम\nसानी-ए-इसनैन-ए-हिजरत पे लाखों सलाम',
        meaning: <String, String>{
          'hi':
              'ख़िलाफ़त की शान और नाज़ पर लाखों सलाम; हिजरत में "दो में से दूसरे" (अबू बक्र रज़ियल्लाहु अन्हु) पर लाखों सलाम।',
          'en':
              'Millions of salutations on the honour and pride of the caliphate, and on the "second of the two" on the migration (Abū Bakr, may Allah be pleased with him).',
          'ar':
              'ألف ألف سلام على عزّ الخلافة وفخرها، وعلى «ثاني اثنين» في الهجرة (أبي بكر رضي الله عنه).',
          'bn':
              'খিলাফতের মর্যাদা ও গৌরবের ওপর লক্ষ লক্ষ সালাম; হিজরতের "দুজনের দ্বিতীয়জন" (আবু বকর রাদিয়াল্লাহু আনহু)-এর ওপর লক্ষ লক্ষ সালাম।',
        },
      ),
    ],
  ),
];

NaatWork? naatWorkById(String id) {
  for (final NaatWork w in kNaatWorks) {
    if (w.id == id) return w;
  }
  return null;
}
