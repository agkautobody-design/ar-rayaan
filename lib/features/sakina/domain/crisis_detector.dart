/// Crisis detection — the one shared safety net for every place a person can
/// type their pain into the app (Hādi today; anything else later).
///
/// It runs BEFORE any answer provider — the offline shelf and every live AI
/// alike — and when it fires the provider is never called at all: the person
/// gets a fixed, compassionate reply with real help lines for their country,
/// and what they wrote stays on the device.
///
/// Design rules (locked):
/// - Whole-word / whole-phrase matching on normalised text. Never substring:
///   "breakfast" contains "fast", "business" contains "sin" — those must not
///   fire anything.
/// - When in doubt about a self-harm phrase, fire. A gentle card shown
///   needlessly costs a second; a missed crisis costs far more.
/// - Idioms and religious phrasing that are clearly not about self-harm
///   ("I want to die upon Islam", "Suicide Squad", "it hit me that…") are
///   excluded explicitly, and each exclusion is pinned by a test.
/// - No number is ever invented. Lines come only from [HelpResources].
library;

import 'crisis_near_words.dart';
import 'sakina_content.dart';

/// What kind of moment the message is.
enum CrisisKind {
  /// The person may be thinking of ending their life or hurting themselves
  /// (or is writing about someone who is).
  selfHarm,

  /// A question about suicide itself ("is suicide haram?", "will he be
  /// forgiven?") with no sign the person is describing their own plan. The
  /// answer is compassion first, honesty second, help lines always.
  suicideQuestion,

  /// Someone is hurting, threatening or forcing the person (domestic
  /// violence, child abuse, sexual assault).
  abuse,

  /// A child or young person is being pressured, groomed, blackmailed or
  /// touched by someone (online or in person), or is being told to keep a
  /// secret about it.
  childSafety,

  /// Starving, purging, bingeing or punishing the body through food.
  eatingDisorder,

  /// First-person intent to join or serve a violent group, or to hurt people
  /// for their religion.
  extremism,
}

/// One phrase to look for, with optional guards against known false alarms.
class _Pat {
  const _Pat(
    this.phrase, {
    this.notAfter = const <String>[],
    this.notFollowedBy = const <String>[],
    this.needsPrevious = false,
    this.mustEnd = false,
  });

  /// Normalised, space-separated words.
  final String phrase;

  /// The word just before the phrase must not be one of these.
  final List<String> notAfter;

  /// The words just after the phrase must not start with any of these
  /// phrases.
  final List<String> notFollowedBy;

  /// The phrase must have at least one word before it (stops "beats me!"
  /// as a lone idiom from reading as an accusation).
  final bool needsPrevious;

  /// The phrase must be the last words of the message ("I can't go on."
  /// fires; "I can't go on Friday" does not).
  final bool mustEnd;
}

abstract final class CrisisDetector {
  /// Lowercases, drops apostrophes ("don't" -> "dont") and soft hyphens,
  /// turns every other punctuation mark into a space, folds a few Arabic/Persian letter forms
  /// and diacritics, and squeezes letters repeated three or more times
  /// ("diiiie" -> "die"). Words are joined by single spaces.
  static String normalize(String input) {
    final StringBuffer out = StringBuffer();
    bool lastWasSpace = true;
    for (final int original in input.toLowerCase().runes) {
      int c = original;
      // Apostrophes and quote-like marks inside words vanish.
      if (c == 0x27 || c == 0x2018 || c == 0x2019 || c == 0x60 || c == 0xB4) {
        continue;
      }
      // A soft hyphen is invisible: it never splits a word.
      if (c == 0xAD) continue;
      // Arabic harakat, tatweel and dagger alef vanish.
      if ((c >= 0x064B && c <= 0x065F) ||
          c == 0x0640 ||
          c == 0x0670 ||
          c == 0x0307) {
        continue; // harakat, tatweel, dagger alef, combining dot above
      }
      // Fold letter variants so typing style does not matter.
      if (c == 0x0623 || c == 0x0625 || c == 0x0622) c = 0x0627; // alef forms
      if (c == 0x0649 || c == 0x06CC) c = 0x064A; // alef maqsura / farsi yeh
      if (c == 0x06A9) c = 0x0643; // keheh -> kaf
      if (c == 0x06C1 || c == 0x06BE) c = 0x0647; // urdu heh -> heh
      final bool ascii = (c >= 0x61 && c <= 0x7A) || (c >= 0x30 && c <= 0x39);
      final bool separatorSymbol = (c >= 0x80 && c <= 0xBF) ||
          (c >= 0x2000 && c <= 0x206F) ||
          (c >= 0x3000 && c <= 0x303F) ||
          (c >= 0xFF00 && c <= 0xFF0F) ||
          c == 0x060C ||
          c == 0x061B ||
          c == 0x061F ||
          c == 0x06D4 ||
          c == 0x0964 ||
          c == 0x0965 ||
          c == 0xD7;
      final bool keep = ascii || (c > 0x7F && !separatorSymbol);
      if (keep) {
        out.writeCharCode(c);
        lastWasSpace = false;
      } else {
        if (!lastWasSpace) {
          out.write(' ');
          lastWasSpace = true;
        }
      }
    }
    return _squeeze(out.toString().trim());
  }

  /// Collapses any letter repeated three or more times to one
  /// ("diiiie" -> "die", "pleeease" -> "pleease" stays harmless).
  static String _squeeze(String s) {
    final List<int> runes = s.runes.toList();
    final StringBuffer b = StringBuffer();
    int i = 0;
    while (i < runes.length) {
      int j = i;
      while (j < runes.length && runes[j] == runes[i]) {
        j++;
      }
      final int count = j - i;
      final int copies = count >= 3 ? 1 : count;
      for (int k = 0; k < copies; k++) {
        b.writeCharCode(runes[i]);
      }
      i = j;
    }
    return b.toString();
  }

  // ── Self-harm: explicit phrases ──────────────────────────────────────

  static const List<String> _religiousDeathContinuations = <String>[
    'as a martyr',
    'as a shaheed',
    'as shaheed',
    'as a muslim',
    'as a good muslim',
    'as a believer',
    'as muslim',
    'upon',
    'with iman',
    'with la ilaha',
    'on iman',
    'on islam',
    'on the deen',
    'on the straight path',
    'in madinah',
    'in medina',
    'in makkah',
    'in mecca',
    'in the path',
    'for the sake',
    'for allah',
    'laughing',
  ];

  /// "tired of living in a flat" is about a place, not about life.
  static const List<String> _placeContinuations = <String>[
    'in',
    'on',
    'at',
    'with',
    'under',
    'near',
    'far',
    'abroad',
    'here',
    'there',
  ];

  static final List<_Pat> _selfHarm = <_Pat>[
    // Wanting to be dead
    const _Pat('want to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wants to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wanted to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wanna die'),
    const _Pat('want to be dead'),
    const _Pat('wish i was dead'),
    const _Pat('wish i were dead'),
    const _Pat('wish i could die'),
    const _Pat('wish i would die'),
    const _Pat('wish i was never born'),
    const _Pat('wish i were never born'),
    const _Pat('wish i had never been born'),
    const _Pat('wish i never existed'),
    const _Pat('wish i didnt exist'),
    const _Pat('wish i could disappear'),
    const _Pat('wish i could just disappear'),
    const _Pat('wish i would not wake up'),
    const _Pat('wish i wouldnt wake up'),
    const _Pat('dont want to wake up'),
    const _Pat('dont want to be alive'),
    const _Pat('dont want to be here anymore'),
    const _Pat('dont want to live'),
    const _Pat('dont wanna live'),
    const _Pat('dont want to exist'),
    const _Pat('do not want to live'),
    const _Pat('do not want to be alive'),
    const _Pat('do not want to exist'),
    const _Pat('no longer want to live'),
    const _Pat('no longer want to be alive'),
    const _Pat('better off dead'),
    const _Pat('better off without me'),
    const _Pat('better off if i was gone'),
    const _Pat('better off if i were gone'),
    const _Pat('better off if i were dead'),
    const _Pat('better off if i died'),
    const _Pat('rather be dead'),
    const _Pat('rather die'),
    // Life not worth living
    const _Pat('not worth living'),
    const _Pat('isnt worth living'),
    const _Pat('wasnt worth living'),
    const _Pat('nobody would miss me'),
    const _Pat('no one would miss me'),
    const _Pat('nobody would care if i died'),
    const _Pat('no one would care if i died'),
    const _Pat('if i were dead'),
    const _Pat('if i was dead'),
    const _Pat('no reason to live'),
    const _Pat('no reason to go on'),
    const _Pat('no reason to be alive'),
    const _Pat('nothing to live for'),
    const _Pat('no point in living'),
    const _Pat('no point living'),
    const _Pat('no point in life'),
    const _Pat('no point in going on'),
    const _Pat('whats the point of living'),
    const _Pat('whats the point of life'),
    const _Pat('what is the point of living'),
    const _Pat('tired of living', notFollowedBy: _placeContinuations),
    const _Pat('tired of life'),
    const _Pat('tired of being alive'),
    const _Pat('sick of living', notFollowedBy: _placeContinuations),
    const _Pat('sick of life'),
    const _Pat('sick of being alive'),
    const _Pat('done with life'),
    const _Pat('done with living', notFollowedBy: _placeContinuations),
    const _Pat('give up on life'),
    const _Pat('giving up on life'),
    const _Pat('cant go on', mustEnd: true),
    const _Pat('cant go on living'),
    const _Pat('cant go on like this'),
    const _Pat('cant go on anymore'),
    const _Pat('cant go on any longer'),
    const _Pat('cant go on any more'),
    const _Pat('cant go on much longer'),
    const _Pat('cant live like this'),
    const _Pat('no will to live'),
    // Ending it
    const _Pat('end it all'),
    const _Pat('ending it all'),
    const _Pat('end my life'),
    const _Pat('end my own life'),
    const _Pat('ending my life'),
    const _Pat('end his life'),
    const _Pat('end her life'),
    const _Pat('end their lives'),
    const _Pat('take my life'),
    const _Pat('take my own life'),
    const _Pat('taking my own life'),
    const _Pat('take his own life'),
    const _Pat('take her own life'),
    const _Pat('take their own lives'),
    const _Pat('taking his own life'),
    const _Pat('taking her own life'),
    // Killing / hurting oneself
    const _Pat('kill myself'),
    const _Pat('killing myself'),
    const _Pat('killed myself'),
    const _Pat('kill my self'),
    const _Pat('kill himself'),
    const _Pat('kill herself'),
    const _Pat('kill themselves'),
    const _Pat('killing himself'),
    const _Pat('killing herself'),
    const _Pat('hurt myself'),
    const _Pat('hurting myself'),
    const _Pat('hurt my self'),
    const _Pat('harm myself'),
    const _Pat('harming myself'),
    const _Pat('harm my self'),
    const _Pat('hurt himself'),
    const _Pat('hurt herself'),
    const _Pat('harm himself'),
    const _Pat('harm herself'),
    const _Pat('hurting himself'),
    const _Pat('hurting herself'),
    const _Pat('self harm'),
    const _Pat('selfharm'),
    const _Pat('self harming'),
    const _Pat('self harmed'),
    const _Pat('cut myself'),
    const _Pat('cutting myself'),
    const _Pat('cut himself'),
    const _Pat('cut herself'),
    const _Pat('cut my wrists'),
    const _Pat('cut my wrist'),
    const _Pat('slit my wrists'),
    const _Pat('slit my wrist'),
    const _Pat('slit my throat'),
    const _Pat('hang myself'),
    const _Pat('hanging myself'),
    const _Pat('shoot myself'),
    const _Pat('poison myself'),
    const _Pat('drown myself'),
    const _Pat('throw myself off'),
    const _Pat('throw myself in front'),
    const _Pat('jump off a bridge'),
    const _Pat('jump off a building'),
    const _Pat('jump off a roof'),
    const _Pat('jump from a building'),
    const _Pat('jump in front of a train'),
    const _Pat('overdose on'),
    const _Pat('overdose myself'),
    const _Pat('overdosed'),
    const _Pat('overdosing'),
    const _Pat('take an overdose'),
    const _Pat('took an overdose'),
    const _Pat('take too many pills'),
    const _Pat('took too many pills'),
    const _Pat('swallow all my pills'),
    const _Pat('swallow all the pills'),
    const _Pat('take all my pills'),
    const _Pat('take all the pills'),
    // Suicidal, suicide attempts
    const _Pat('suicidal'),
    const _Pat('attempt suicide'),
    const _Pat('attempted suicide'),
    const _Pat('attempting suicide'),
    const _Pat('suicide attempt'),
    const _Pat('suicide note'),
    const _Pat('sucide'),
    const _Pat('sucidal'),
    const _Pat('suiciddal'),
    const _Pat('suicidel'),
    const _Pat('suicidial'),
    const _Pat('suicde'),
    const _Pat('suiside'),
    // Arabic
    const _Pat('اريد ان اموت'),
    const _Pat('ابغي اموت'),
    const _Pat('ابي اموت'),
    const _Pat('اريد الموت'),
    const _Pat('اتمني الموت'),
    const _Pat('اتمني ان اموت'),
    const _Pat('اقتل نفسي'),
    const _Pat('سانتحر'),
    const _Pat('اريد الانتحار'),
    const _Pat('افكر في الانتحار'),
    const _Pat('انهي حياتي'),
    const _Pat('اريد ان انهي حياتي'),
    const _Pat('تعبت من الحياه'),
    const _Pat('لا اريد ان اعيش'),
    const _Pat('لا اريد العيش'),
    // Urdu (script and Roman)
    const _Pat('مرنا چاهتا هوں'),
    const _Pat('مرنا چاهتي هوں'),
    const _Pat('مرنا چاهتا هون'),
    const _Pat('مرنا چاهتي هون'),
    const _Pat('marna chahta hoon'),
    const _Pat('marna chahti hoon'),
    const _Pat('marna chahta hun'),
    const _Pat('marna chahti hun'),
    const _Pat('jaan de dunga'),
    const _Pat('jaan de dungi'),
    const _Pat('zindagi khatam karna'),
    // Malay / Indonesian
    const _Pat('mau mati'),
    const _Pat('nak mati'),
    const _Pat('mahu mati'),
    const _Pat('ingin mati'),
    const _Pat('pengen mati'),
    // Turkish, Spanish
    const _Pat('ölmek istiyorum'),
    const _Pat('quiero morir'),
    const _Pat('quiero morirme'),
    // Slang and indirect English
    const _Pat('unalive myself'),
    const _Pat('unalive me'),
    const _Pat('unaliving myself'),
    const _Pat('unalive'),
    const _Pat('gonna kms'),
    const _Pat('going to kms'),
    const _Pat('wanna kms'),
    const _Pat('want to kms'),
    const _Pat('just kms'),
    const _Pat('should kms'),
    const _Pat('ima kms'),
    const _Pat('ill kms'),
    const _Pat('time to kms'),
    const _Pat('to sleep forever'),
    const _Pat('just sleep forever'),
    const _Pat('and sleep forever'),
    const _Pat('sleep and never wake up'),
    const _Pat('wish i would never wake up'),
    const _Pat('wish i never woke up'),
    const _Pat('never want to wake up'),
    const _Pat('wish i wasnt alive'),
    const _Pat('wish i was not alive'),
    const _Pat('wish i werent alive'),
    const _Pat('wish i wasnt here'),
    const _Pat('wish i was not here'),
    const _Pat('dont want to be here'),
    const _Pat('do not want to be here'),
    const _Pat('world would be better without me'),
    const _Pat('world is better without me'),
    const _Pat('better without me'),
    const _Pat('im a burden'),
    const _Pat('i am a burden'),
    const _Pat('im just a burden'),
    const _Pat('i am just a burden'),
    const _Pat('burden to everyone'),
    const _Pat('burden on everyone'),
    const _Pat('want to disappear'),
    const _Pat('wanna disappear'),
    const _Pat('disappear forever'),
    const _Pat('ready to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('giving up on living'),
    const _Pat('give up on living'),
    const _Pat('cant take it anymore'),
    const _Pat('cant take this anymore'),
    const _Pat('cant do this anymore'),
    const _Pat('see no way out'),
    const _Pat('there is no way out'),
    const _Pat('theres no way out'),
    const _Pat('end myself'),
    const _Pat('off myself'),
    const _Pat('offing myself'),
    const _Pat('hanged myself'),
    const _Pat('self injury'),
    const _Pat('self injure'),
    const _Pat('self injuring'),
    const _Pat('burn myself on purpose'),
    const _Pat('burning myself on purpose'),
    const _Pat('burned myself on purpose'),
    const _Pat('burn myself with a cigarette'),
    const _Pat('ways to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('way to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('how to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('how do i die'),
    const _Pat('pills to die'),
    const _Pat('swallow pills to die'),
    // Religious framing of wanting death
    const _Pat('wish allah would take me'),
    const _Pat('wish allah would take my life'),
    const _Pat('wish allah would take my soul'),
    const _Pat('wish god would take me'),
    const _Pat('wish god would take my life'),
    const _Pat('ask allah to take my life'),
    const _Pat('ask allah to take me'),
    const _Pat('ask allah for death'),
    const _Pat('pray for death'),
    const _Pat('praying for death'),
    const _Pat('praying to die'),
    const _Pat('prayed to die'),
    const _Pat('prayed for death'),
    const _Pat('pray to die'),
    const _Pat('pray that i die'),
    // Arabic additions (ta marbuta spelling, Gulf and Levantine forms)
    const _Pat('تعبت من الحياة'),
    const _Pat('مليت من الحياة'),
    const _Pat('زهقت من الحياة'),
    const _Pat('كرهت حياتي'),
    const _Pat('اكره حياتي'),
    const _Pat('لا اريد الحياة'),
    const _Pat('ليتني مت'),
    const _Pat('ليتني كنت ميتا'),
    const _Pat('اتمني لو مت'),
    const _Pat('لا فائدة من الحياة'),
    const _Pat('ساقتل نفسي'),
    const _Pat('اريد ان اقتل نفسي'),
    const _Pat('اريد ان ارتاح من الحياة'),
    const _Pat('مش عايز اعيش'),
    const _Pat('مش عاوز اعيش'),
    const _Pat('عايز اموت'),
    const _Pat('عاوز اموت'),
    // Urdu script and Roman Urdu additions
    const _Pat('مر جانا چاہتا ہوں'),
    const _Pat('مر جانا چاہتی ہوں'),
    const _Pat('جینا نہیں چاہتا'),
    const _Pat('جینا نہیں چاہتی'),
    const _Pat('زندگی ختم کرنا چاہتا ہوں'),
    const _Pat('زندگی ختم کرنا چاہتی ہوں'),
    const _Pat('خود کو مارنا چاہتا ہوں'),
    const _Pat('خود کو مارنا چاہتی ہوں'),
    const _Pat('mar jana chahta hoon'),
    const _Pat('mar jana chahti hoon'),
    const _Pat('mar jana chahta hun'),
    const _Pat('mar jana chahti hun'),
    const _Pat('jeena nahi chahta'),
    const _Pat('jeena nahi chahti'),
    const _Pat('jeene ka mann nahi'),
    const _Pat('zindagi se tang aa gaya'),
    const _Pat('zindagi se tang aa gayi'),
    const _Pat('maut chahta hoon'),
    const _Pat('maut chahti hoon'),
    const _Pat('khud ko khatam'),
    // Hindi
    const _Pat('मरना चाहता हूं'),
    const _Pat('मरना चाहता हूँ'),
    const _Pat('मरना चाहती हूं'),
    const _Pat('मरना चाहती हूँ'),
    const _Pat('जीना नहीं चाहता'),
    const _Pat('जीना नहीं चाहती'),
    const _Pat('जीने का मन नहीं'),
    const _Pat('खुद को खत्म'),
    // Bengali
    const _Pat('মরে যেতে চাই'),
    const _Pat('মরতে চাই'),
    const _Pat('বাঁচতে চাই না'),
    // Turkish
    const _Pat('intihar etmek istiyorum'),
    const _Pat('yaşamak istemiyorum'),
    const _Pat('kendimi öldürmek'),
    const _Pat('kendimi öldüreceğim'),
    const _Pat('hayatıma son vermek'),
    // French
    const _Pat('je veux mourir'),
    const _Pat('jai envie de mourir'),
    const _Pat('envie de mourir'),
    const _Pat('je veux me tuer'),
    const _Pat('je vais me tuer'),
    const _Pat('me suicider'),
    const _Pat('je veux en finir'),
    const _Pat('en finir avec la vie'),
    const _Pat('je ne veux plus vivre'),
    const _Pat('je nai plus envie de vivre'),
    const _Pat('plus envie de vivre'),
    const _Pat('je veux disparaître'),
    // Spanish
    const _Pat('me quiero morir'),
    const _Pat('quiero matarme'),
    const _Pat('quiero suicidarme'),
    const _Pat('no quiero vivir'),
    const _Pat('no quiero seguir viviendo'),
    const _Pat('voy a matarme'),
    const _Pat('acabar con mi vida'),
    const _Pat('quitarme la vida'),
    // Indonesian / Malay
    const _Pat('tidak mau hidup'),
    const _Pat('tidak ingin hidup'),
    const _Pat('tak nak hidup'),
    const _Pat('tak mahu hidup'),
    const _Pat('capek hidup'),
    const _Pat('penat hidup'),
    // Persian
    const _Pat('می خواهم بمیرم'),
    const _Pat('میخواهم بمیرم'),
    const _Pat('می خوام بمیرم'),
    const _Pat('میخوام بمیرم'),
    const _Pat('دلم می خواهد بمیرم'),
    const _Pat('نمی خواهم زندگی کنم'),
    const _Pat('نمی خوام زندگی کنم'),
    const _Pat('از زندگی خسته شدم'),
  ];

  /// Words that, alone, mean the subject of suicide has come up. Whether
  /// that is a person in danger or a person asking a religious question is
  /// decided afterwards.
  static final List<_Pat> _suicideConcept = <_Pat>[
    const _Pat(
      'suicide',
      notFollowedBy: <String>[
        'squad',
        'bomber',
        'bombers',
        'bombing',
        'bombings',
        'attack',
        'attacks',
        'mission',
        'missions',
        'vest',
        'vests',
        'terrorist',
        'terrorists',
        'door',
        'doors',
        'jockey',
      ],
    ),
    const _Pat('suicides'),
    const _Pat('commit suicide'),
    const _Pat('committed suicide'),
    const _Pat('committing suicide'),
    const _Pat('commits suicide'),
    const _Pat('kill yourself'),
    const _Pat('killing yourself'),
    const _Pat('harm yourself'),
    const _Pat('take your own life'),
    const _Pat('end your life'),
    const _Pat('انتحار'),
    const _Pat('الانتحار'),
    const _Pat('انتحر'),
    const _Pat('خودکشی'),
    const _Pat('خود کشی'),
    const _Pat('khudkushi'),
    const _Pat('khud kushi'),
    const _Pat('bunuh diri'),
    const _Pat('intihar'),
    const _Pat('आत्महत्या'),
    const _Pat('আত্মহত্যা'),
    const _Pat('suicidio'),
    const _Pat('suicidarme'),
  ];

  /// Words that make a suicide mention a question about the topic rather
  /// than a disclosure.
  static const List<String> _questionMarkers = <String>[
    'haram',
    'halal',
    'sin',
    'sinful',
    'allowed',
    'permissible',
    'forgive',
    'forgiven',
    'forgives',
    'hell',
    'jannah',
    'paradise',
    'punishment',
    'punished',
    'kafir',
    'janazah',
    'janaza',
    'funeral',
    'buried',
    'ruling',
    'islam',
    'islamic',
    'quran',
    'hadith',
    'scholars',
    'does allah',
    'will allah',
    'what happens',
    'is it',
    'can i pray',
    'pray for',
    'حرام',
    'حلال',
    'هل',
    'ما حكم',
    'جائز',
  ];

  /// Words that say the person is speaking about themselves, even inside a
  /// question. These override the "just a question" reading.
  static const List<String> _personalMarkers = <String>[
    'i want',
    'i wanna',
    'i am thinking',
    'im thinking',
    'i have been thinking',
    'ive been thinking',
    'i keep thinking',
    'i think about',
    'thinking about suicide',
    'thinking of suicide',
    'thoughts of suicide',
    'suicidal thoughts',
    'i feel like',
    'i might',
    'i am going to',
    'im going to',
    'i will',
    'i plan',
    'i planned',
    'i tried',
    'i have tried',
    'ive tried',
    'i cant',
    'i am so',
    'im so',
  ];

  // ── Abuse ────────────────────────────────────────────────────────────

  static const List<String> _idiomPrevious = <String>[
    'it',
    'that',
    'this',
    'which',
    'what',
    'reality',
    'thought',
    'idea',
    'realization',
    'then',
    'suddenly',
  ];

  /// "my dad hits the gym" is not about violence at home.
  static const List<String> _benignHits = <String>['the', 'a', 'an'];

  /// "my dad beats me at chess" is not about violence at home.
  static const List<String> _benignBeats = <String>[
    'me at',
    'me in',
    'us at',
    'the',
    'a',
    'an',
  ];

  /// "he beats me at chess" is a game, not violence. Only games and sports
  /// are listed: "beats me at night" must still be caught.
  static const List<String> _benignBeatsMe = <String>[
    'at chess',
    'at cards',
    'at ludo',
    'at games',
    'at a game',
    'at the game',
    'at football',
    'at soccer',
    'at cricket',
    'at tennis',
    'at pool',
    'at scrabble',
    'at monopoly',
    'at fifa',
    'at video games',
    'at every game',
    'to it',
    'to the punch',
  ];

  static final List<_Pat> _abuse = <_Pat>[
    const _Pat(
      'beats me',
      needsPrevious: true,
      notAfter: _idiomPrevious,
      notFollowedBy: _benignBeatsMe,
    ),
    const _Pat('beating me'),
    const _Pat('beat me'),
    const _Pat('beaten me'),
    const _Pat('beaten by my'),
    const _Pat('beaten by him'),
    const _Pat('beaten by her'),
    const _Pat('beaten up by my'),
    const _Pat('hit by my husband'),
    const _Pat('hit by my father'),
    const _Pat('hit by my dad'),
    const _Pat('hit by my mother'),
    const _Pat('hit by my brother'),
    const _Pat('beats me up'),
    const _Pat('beat me up'),
    const _Pat('hits me', notAfter: _idiomPrevious, notFollowedBy: <String>['up']),
    const _Pat('hitting me'),
    const _Pat('hit me', notAfter: _idiomPrevious, notFollowedBy: <String>['up', 'with the']),
    const _Pat('slaps me'),
    const _Pat('slapped me'),
    const _Pat('slapping me'),
    const _Pat('punches me'),
    const _Pat('punched me'),
    const _Pat('kicks me'),
    const _Pat('kicked me'),
    const _Pat('chokes me'),
    const _Pat('choked me'),
    const _Pat('strangled me'),
    const _Pat('strangles me'),
    const _Pat('husband beats', notFollowedBy: <String>['his wife']),
    const _Pat('husband hits', notFollowedBy: <String>['his wife']),
    const _Pat('husband beat', notFollowedBy: <String>['his wife']),
    const _Pat('husband hit', notFollowedBy: <String>['his wife']),
    const _Pat('wife beats', notFollowedBy: <String>['her husband']),
    const _Pat('father beats', notFollowedBy: _benignBeats),
    const _Pat('father hits', notFollowedBy: _benignHits),
    const _Pat('dad beats', notFollowedBy: _benignBeats),
    const _Pat('dad hits', notFollowedBy: _benignHits),
    const _Pat('mother beats', notFollowedBy: _benignBeats),
    const _Pat('mother hits', notFollowedBy: _benignHits),
    const _Pat('mom beats', notFollowedBy: _benignBeats),
    const _Pat('mom hits', notFollowedBy: _benignHits),
    const _Pat('mum beats', notFollowedBy: _benignBeats),
    const _Pat('mum hits', notFollowedBy: _benignHits),
    const _Pat('brother beats', notFollowedBy: _benignBeats),
    const _Pat('brother hits', notFollowedBy: _benignHits),
    const _Pat('parents beat'),
    const _Pat('parents hit'),
    const _Pat('abuses me'),
    const _Pat('abused me'),
    const _Pat('abusing me'),
    const _Pat('being abused'),
    const _Pat('i am abused'),
    const _Pat('i was abused'),
    const _Pat('abused as a child'),
    const _Pat('abusive husband'),
    const _Pat('abusive wife'),
    const _Pat('abusive father'),
    const _Pat('abusive mother'),
    const _Pat('abusive parents'),
    const _Pat('abusive marriage'),
    const _Pat('abusive relationship'),
    const _Pat('abusive home'),
    const _Pat('abusive boyfriend'),
    const _Pat('abusive family'),
    const _Pat('child abuse'),
    const _Pat('domestic violence'),
    const _Pat('domestic abuse'),
    const _Pat('family violence'),
    const _Pat('physically abused'),
    const _Pat('emotionally abused'),
    const _Pat('emotional abuse'),
    const _Pat('sexually abused'),
    const _Pat('sexual abuse'),
    const _Pat('sexually assaulted'),
    const _Pat('sexual assault'),
    const _Pat('raped'),
    const _Pat('raped me'),
    const _Pat('rapes me'),
    const _Pat('molested'),
    const _Pat('touched me inappropriately'),
    const _Pat('touches me inappropriately'),
    const _Pat('forced me to have sex'),
    const _Pat('forces me to have sex'),
    const _Pat('forced himself on me'),
    const _Pat('forces himself on me'),
    const _Pat('forced me to sleep with'),
    const _Pat('forces me to sleep with'),
    const _Pat('afraid of my husband'),
    const _Pat('scared of my husband'),
    const _Pat('afraid of my father'),
    const _Pat('scared of my father'),
    const _Pat('afraid of my dad'),
    const _Pat('scared of my dad'),
    const _Pat('afraid of my brother'),
    const _Pat('scared of my brother'),
    const _Pat('afraid of my mother'),
    const _Pat('scared of my mother'),
    const _Pat('afraid to go home'),
    const _Pat('scared to go home'),
    const _Pat('afraid for my life'),
    const _Pat('scared for my life'),
    const _Pat('fear for my life'),
    const _Pat('fear for my safety'),
    const _Pat('not safe at home'),
    const _Pat('unsafe at home'),
    const _Pat('dont feel safe at home'),
    const _Pat('dont feel safe with him'),
    const _Pat('threatened to kill me'),
    const _Pat('threatens to kill me'),
    const _Pat('threatening to kill me'),
    const _Pat('tried to kill me'),
    const _Pat('trying to kill me'),
    const _Pat('wants to kill me'),
    const _Pat('locked me in'),
    const _Pat('locks me in'),
    const _Pat('زوجي يضربني'),
    const _Pat('يضربني'),
    const _Pat('ابي يضربني'),
    const _Pat('العنف الاسري'),
  ];

  // ── Child safety: grooming, sextortion, secrecy ────────────────────

  static final List<_Pat> _childSafety = <_Pat>[
    const _Pat('asked me to send pictures'),
    const _Pat('asked me to send photos'),
    const _Pat('asked me to send nudes'),
    const _Pat('asked me for nudes'),
    const _Pat('asking me for nudes'),
    const _Pat('asking me for pictures of my body'),
    const _Pat('asking me to send pictures'),
    const _Pat('asking me to send photos'),
    const _Pat('asks me to send pictures'),
    const _Pat('asks me to send photos'),
    const _Pat('wants me to send pictures'),
    const _Pat('wants me to send photos'),
    const _Pat('wants nudes'),
    const _Pat('nude pictures of me'),
    const _Pat('nude photos of me'),
    const _Pat('groomed me'),
    const _Pat('grooming me'),
    const _Pat('being groomed'),
    const _Pat('online groomer'),
    const _Pat('told me not to tell'),
    const _Pat('tells me not to tell'),
    const _Pat('told me to keep it secret'),
    const _Pat('told me to keep it a secret'),
    const _Pat('keep it a secret from my parents'),
    const _Pat('keep it secret from my parents'),
    const _Pat('dont tell your parents'),
    const _Pat('do not tell your parents'),
    const _Pat('older man online'),
    const _Pat('older guy online'),
    const _Pat('older boy online'),
    const _Pat('adult online asked'),
    const _Pat('stranger online asked'),
    const _Pat('touched my private parts'),
    const _Pat('touched me there'),
    const _Pat('made me touch'),
    const _Pat('showed me porn'),
    const _Pat('showed me inappropriate videos'),
    const _Pat('sextortion'),
    const _Pat('blackmailing me with my pictures'),
    const _Pat('blackmailing me with my photos'),
    const _Pat('threatened to share my pictures'),
    const _Pat('threatened to share my photos'),
    const _Pat('threatens to leak my photos'),
    const _Pat('threatens to leak my pictures'),
    const _Pat('threatened to leak my photos'),
  ];

  // ── Eating disorders ───────────────────────────────────────────────

  static final List<_Pat> _eating = <_Pat>[
    const _Pat('starving myself'),
    const _Pat('starve myself'),
    const _Pat('starved myself'),
    const _Pat('not eating for days'),
    const _Pat('havent eaten in days'),
    const _Pat('havent eaten for days'),
    const _Pat('stopped eating completely'),
    const _Pat('stopped eating altogether'),
    const _Pat('make myself throw up'),
    const _Pat('making myself throw up'),
    const _Pat('make myself vomit'),
    const _Pat('making myself vomit'),
    const _Pat('made myself throw up'),
    const _Pat('made myself vomit'),
    const _Pat('binge and purge'),
    const _Pat('purge after eating'),
    const _Pat('purging after'),
    const _Pat('i purge'),
    const _Pat('i binge', notFollowedBy: <String>['watch', 'watched', 'watching', 'read', 'reading', 'listen']),
    const _Pat('anorexia'),
    const _Pat('anorexic'),
    const _Pat('bulimia'),
    const _Pat('bulimic'),
    const _Pat('eating disorder'),
    const _Pat('punish myself by not eating'),
    const _Pat('punish myself with fasting'),
    const _Pat('dont deserve to eat'),
    const _Pat('do not deserve to eat'),
    const _Pat('dont deserve food'),
    const _Pat('taking laxatives to lose weight'),
    const _Pat('laxatives to lose weight'),
    const _Pat('اجوع نفسي'),
    const _Pat('اتقيا عمدا'),
    const _Pat('khud ko bhooka rakhta'),
    const _Pat('khud ko bhooka rakhti'),
  ];

  // ── Extremism: first-person intent only ────────────────────────────

  static final List<_Pat> _extremism = <_Pat>[
    const _Pat('i want to join isis'),
    const _Pat('i want to join daesh'),
    const _Pat('i want to join al qaeda'),
    const _Pat('i want to join al shabaab'),
    const _Pat('i want to join a terrorist group'),
    const _Pat('i want to join the terrorists'),
    const _Pat('how do i join isis'),
    const _Pat('how can i join isis'),
    const _Pat('how to join isis'),
    const _Pat('how do i join daesh'),
    const _Pat('how can i join daesh'),
    const _Pat('how to join daesh'),
    const _Pat('how to join al qaeda'),
    const _Pat('how do i join al qaeda'),
    const _Pat('how to join a terrorist group'),
    const _Pat('i want to kill kafirs'),
    const _Pat('i want to kill non muslims'),
    const _Pat('i want to kill all non muslims'),
    const _Pat('i want to kill the kuffar'),
    const _Pat('i want to kill all the kuffar'),
    const _Pat('i want to kill christians'),
    const _Pat('i want to kill jews'),
    const _Pat('i want to kill shia'),
    const _Pat('i want to become a suicide bomber'),
    const _Pat('i want to be a suicide bomber'),
    const _Pat('i want to blow myself up'),
    const _Pat('how to make a bomb'),
    const _Pat('how to build a bomb'),
    const _Pat('i am planning an attack'),
    const _Pat('im planning an attack'),
    const _Pat('انضم الى داعش'),
    const _Pat('اريد الانضمام الى داعش'),
    const _Pat('اريد ان انضم الى داعش'),
  ];

  /// Pattern lists normalised the plain way (what [detect] always tried).
  static final _Lists _plain = _Lists(normalize);

  /// The same lists normalised after folding look-alike letters, accents and
  /// invisible characters, for text that is folded the same way.
  static final _Lists _folded = _Lists(_normalizeFolded);

  static List<_Pat> _normalizeAll(
    List<_Pat> pats,
    String Function(String) norm,
  ) =>
      <_Pat>[
        for (final _Pat p in pats)
          _Pat(
            norm(p.phrase),
            notAfter: <String>[for (final String w in p.notAfter) norm(w)],
            notFollowedBy: <String>[
              for (final String w in p.notFollowedBy) norm(w),
            ],
            needsPrevious: p.needsPrevious,
            mustEnd: p.mustEnd,
          ),
      ];

  // ── Folding: obfuscation the plain normaliser cannot see ─────────────

  /// Characters that draw nothing: soft hyphen, zero-width space, joiners,
  /// directional marks, word joiner, invisible operators, the byte-order
  /// mark, variation selectors and tag characters.
  static bool _isInvisible(int c) =>
      c == 0xAD ||
      c == 0x34F ||
      c == 0x61C ||
      c == 0x6DD ||
      c == 0x70F ||
      c == 0x115F ||
      c == 0x1160 ||
      c == 0x17B4 ||
      c == 0x17B5 ||
      (c >= 0x180B && c <= 0x180E) ||
      (c >= 0x200B && c <= 0x200F) ||
      (c >= 0x202A && c <= 0x202E) ||
      (c >= 0x2060 && c <= 0x206F) ||
      c == 0x3164 ||
      (c >= 0xFE00 && c <= 0xFE0F) ||
      c == 0xFEFF ||
      c == 0xFFA0 ||
      (c >= 0xE0000 && c <= 0xE007F);

  /// Letters from other alphabets that are drawn like a Latin letter
  /// (Cyrillic and Greek mostly), lower case, and Latin letters with marks.
  static const Map<int, String> _lookAlike = <int, String>{
    // Cyrillic
    0x0430: 'a', 0x0432: 'b', 0x0441: 'c', 0x0435: 'e', 0x0451: 'e', //
    0x043D: 'h', 0x0456: 'i', 0x0457: 'i', 0x0458: 'j', 0x043A: 'k', //
    0x043C: 'm', 0x043E: 'o', 0x0440: 'p', 0x0455: 's', 0x0442: 't', //
    0x0443: 'y', 0x0445: 'x', 0x0501: 'd', 0x051B: 'q', 0x051D: 'w', //
    0x04CF: 'l', 0x04BB: 'h', 0x0475: 'v', //
    // Greek
    0x03B1: 'a', 0x03B2: 'b', 0x03B3: 'y', 0x03B5: 'e', 0x03B7: 'n', //
    0x03B9: 'i', 0x03BA: 'k', 0x03BD: 'v', 0x03BF: 'o', 0x03C1: 'p', //
    0x03C4: 't', 0x03C5: 'u', 0x03C7: 'x', 0x03C9: 'w', 0x03BC: 'u', //
    0x03C3: 'o', //
    // Latin letters with marks, and dotless i
    0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a', //
    0x101: 'a', 0x103: 'a', 0x105: 'a', 0xE7: 'c', 0x107: 'c', 0x10D: 'c', //
    0x10F: 'd', 0x111: 'd', 0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e', //
    0x113: 'e', 0x117: 'e', 0x119: 'e', 0x11B: 'e', 0x11F: 'g', //
    0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i', 0x12B: 'i', 0x12F: 'i', //
    0x131: 'i', 0x142: 'l', 0xF1: 'n', 0x144: 'n', 0x148: 'n', //
    0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', 0xF8: 'o', //
    0x14D: 'o', 0x151: 'o', 0x15B: 's', 0x161: 's', 0x15F: 's', //
    0x219: 's', 0xDF: 'ss', 0x165: 't', 0x163: 't', 0xF9: 'u', 0xFA: 'u', //
    0xFB: 'u', 0xFC: 'u', 0x16B: 'u', 0x16F: 'u', 0x171: 'u', //
    0xFD: 'y', 0xFF: 'y', 0x17A: 'z', 0x17C: 'z', 0x17E: 'z', //
    0xE6: 'ae', 0x153: 'oe', //
  };

  /// Digits and symbols typed in place of letters.
  static const Map<int, String> _leetMap = <int, String>{
    0x30: 'o', 0x33: 'e', 0x34: 'a', 0x35: 's', 0x37: 't', 0x38: 'b', //
    0x40: 'a', 0x24: 's', 0x2B: 't', 0x21: 'i', 0x7C: 'i', //
  };

  static bool _isLatinLetter(int c) => c >= 0x61 && c <= 0x7A;

  /// Folds fullwidth forms, look-alike letters and accents to plain Latin
  /// and, when [joinInvisible] is true, drops invisible characters so they
  /// cannot split a word. With [leet] set, digits and symbols that sit next
  /// to a letter become the letter they stand for; [leet] is what the digit
  /// 1 becomes ("i" or "l"), or null to leave digits alone.
  static String _foldText(
    String input, {
    required bool joinInvisible,
    String? leet,
  }) {
    final List<int> raw = <int>[];
    for (final int original in input.toLowerCase().runes) {
      int c = original;
      if (c >= 0xFF01 && c <= 0xFF5E) c -= 0xFEE0; // fullwidth ASCII
      if (c == 0x3000) c = 0x20;
      if (c >= 0x300 && c <= 0x36F) continue; // combining marks
      if (_isInvisible(c)) {
        // A soft hyphen never splits a word, whatever the setting.
        if (!joinInvisible && c != 0xAD) raw.add(0x20);
        continue;
      }
      final String? look = _lookAlike[c];
      if (look != null) {
        raw.addAll(look.codeUnits);
      } else {
        raw.add(c);
      }
    }
    if (leet == null) return String.fromCharCodes(raw);
    // Digits and symbols typed for letters, read as letters only inside a
    // run of characters that already holds a letter, so a bare number such
    // as "13" is left alone.
    final StringBuffer out = StringBuffer();
    // A message that mixes digits into words is typed in "leet": then even
    // a short run of digits on its own ("44" for "aa") is read as letters.
    bool leetStyle = false;
    {
      bool letter = false;
      bool digit = false;
      for (final int c in <int>[...raw, 0x20]) {
        if (c <= 0x20) {
          if (letter && digit) leetStyle = true;
          letter = false;
          digit = false;
        } else if (_isLatinLetter(c)) {
          letter = true;
        } else if (c >= 0x30 && c <= 0x39) {
          digit = true;
        }
      }
    }
    int i = 0;
    while (i < raw.length) {
      if (raw[i] <= 0x20) {
        out.writeCharCode(raw[i]);
        i++;
        continue;
      }
      int j = i;
      bool hasLetter = false;
      while (j < raw.length && raw[j] > 0x20) {
        if (_isLatinLetter(raw[j])) hasLetter = true;
        j++;
      }
      for (int k = i; k < j; k++) {
        final int c = raw[k];
        // A lone digit ("4" for "a") is read as a letter too.
        final bool readable = hasLetter ||
            (c >= 0x30 && c <= 0x39 && (j - i == 1 || leetStyle && j - i <= 3));
        String? mapped = readable ? _leetMap[c] : null;
        if (readable && c == 0x31) mapped = leet;
        if (mapped != null && _leetSymbols.contains(c)) {
          // A symbol counts only between two letters ("d!e"), or at the
          // start of a word before a letter ("@ll").
          final bool before = k > i && _isLatinLetter(raw[k - 1]);
          final bool after = k + 1 < j && _isLatinLetter(raw[k + 1]);
          if (!(after && (before || k == i && (c == 0x40 || c == 0x24))) &&
              !(before && after)) {
            mapped = null;
          }
        }
        if (mapped != null) {
          out.write(mapped);
        } else {
          out.writeCharCode(c);
        }
      }
      i = j;
    }
    return out.toString();
  }

  static const Set<int> _leetSymbols = <int>{0x40, 0x24, 0x2B, 0x21, 0x7C};

  static String _normalizeFolded(String input) =>
      normalize(_foldText(input, joinInvisible: true));

  static final RegExp _leetChars = RegExp(r'[0-9@$+!|]');

  // ── Typo tolerance ───────────────────────────────────────────────────

  static bool _isAsciiLetters(String s) {
    if (s.isEmpty) return false;
    for (int i = 0; i < s.length; i++) {
      if (!_isLatinLetter(s.codeUnitAt(i))) return false;
    }
    return true;
  }

  /// True when [a] and [b] differ by exactly one slip: a wrong letter, a
  /// missing letter, an extra letter, or two neighbouring letters swapped.
  static bool _oneSlip(String a, String b) {
    final int la = a.length;
    final int lb = b.length;
    if (a == b || (la - lb).abs() > 1) return false;
    if (la == lb) {
      int first = -1;
      int diffs = 0;
      for (int i = 0; i < la; i++) {
        if (a[i] != b[i]) {
          if (diffs == 0) first = i;
          diffs++;
          if (diffs > 2) return false;
        }
      }
      if (diffs == 1) return true;
      return diffs == 2 &&
          first + 1 < la &&
          a[first] == b[first + 1] &&
          a[first + 1] == b[first];
    }
    final String shorter = la < lb ? a : b;
    final String longer = la < lb ? b : a;
    int i = 0;
    while (i < shorter.length && shorter[i] == longer[i]) {
      i++;
    }
    return shorter.substring(i) == longer.substring(i + 1);
  }

  /// For each word of the message that is not itself a word the crisis
  /// phrases use, the phrase words it could be a typing slip of. A word is
  /// only believed to be a slip when it starts with the same letter, is not
  /// a real word (see [kCrisisNearWords]), and the phrase word has four or
  /// more letters.
  static Map<String, Set<String>> _nearMap(List<String> tokens, _Lists lists) {
    final Map<String, Set<String>> out = <String, Set<String>>{};
    final Set<String> seen = <String>{};
    for (final String t in tokens) {
      if (t.length < 3 || !seen.add(t)) continue;
      if (!_isAsciiLetters(t)) continue;
      if (lists.words.contains(t) || kCrisisNearWords.contains(t)) continue;
      final List<String>? bucket = lists.byFirst[t[0]];
      if (bucket == null) continue;
      for (final String w in bucket) {
        if ((w.length - t.length).abs() <= 1 && _oneSlip(t, w)) {
          (out[t] ??= <String>{}).add(w);
        }
      }
    }
    return out;
  }

  static bool _matches(
    List<String> tokens,
    _Pat p, [
    Map<String, Set<String>>? near,
  ]) {
    final List<String> pt = p.phrase.split(' ');
    if (pt.isEmpty || p.phrase.isEmpty) return false;
    // A one-word phrase is only matched through a slip when it is long.
    final bool slipsAllowed = near != null && (pt.length > 1 || p.phrase.length >= 7);
    for (int i = 0; i + pt.length <= tokens.length; i++) {
      bool same = true;
      int slips = 0;
      for (int j = 0; j < pt.length; j++) {
        final String t = tokens[i + j];
        if (t == pt[j]) continue;
        if (slipsAllowed && slips == 0 && (near[t]?.contains(pt[j]) ?? false)) {
          slips++;
          continue;
        }
        same = false;
        break;
      }
      if (!same) continue;
      if (p.needsPrevious && i == 0) continue;
      if (p.mustEnd && i + pt.length != tokens.length) continue;
      if (i > 0 && p.notAfter.contains(tokens[i - 1])) continue;
      if (p.notFollowedBy.isNotEmpty) {
        final String rest = '${tokens.sublist(i + pt.length).join(' ')} ';
        bool excluded = false;
        for (final String f in p.notFollowedBy) {
          if (rest.startsWith('$f ')) {
            excluded = true;
            break;
          }
        }
        if (excluded) continue;
      }
      return true;
    }
    return false;
  }

  static bool _anyMatch(
    List<String> tokens,
    List<_Pat> pats, [
    Map<String, Set<String>>? near,
  ]) {
    for (final _Pat p in pats) {
      if (_matches(tokens, p, near)) return true;
    }
    return false;
  }

  static bool _containsPhrase(String padded, String phrase) =>
      padded.contains(' $phrase ');

  /// Classifies one normalised message against one set of lists. With
  /// [near] set, a phrase may match through one typing slip.
  static CrisisKind? _classify(
    _Lists lists,
    String norm, {
    Map<String, Set<String>>? near,
  }) {
    if (norm.isEmpty) return null;
    final List<String> tokens = norm.split(' ');
    final String padded = ' $norm ';

    if (_anyMatch(tokens, lists.selfHarm, near)) return CrisisKind.selfHarm;

    if (_anyMatch(tokens, lists.concept, near)) {
      bool personal = false;
      for (final String m in lists.personal) {
        if (_containsPhrase(padded, m)) {
          personal = true;
          break;
        }
      }
      if (personal) return CrisisKind.selfHarm;
      bool question = false;
      for (final String m in lists.question) {
        if (_containsPhrase(padded, m)) {
          question = true;
          break;
        }
      }
      return question ? CrisisKind.suicideQuestion : CrisisKind.selfHarm;
    }

    if (_anyMatch(tokens, lists.child, near)) return CrisisKind.childSafety;
    if (_anyMatch(tokens, lists.abuse, near)) return CrisisKind.abuse;
    if (_anyMatch(tokens, lists.eating, near)) return CrisisKind.eatingDisorder;
    if (_anyMatch(tokens, lists.extremism, near)) return CrisisKind.extremism;
    return null;
  }

  /// The first pass of [detect] alone: the exact phrases on the normalised
  /// text, with no folding and no typo allowance. Tests use it to show that
  /// the later passes add nothing on ordinary text.
  static CrisisKind? detectExact(String text) =>
      _classify(_plain, normalize(text));

  /// Returns the kind of crisis in [text], or null when there is none.
  ///
  /// Three passes, each only run when the one before found nothing, so the
  /// plain pass (what this method always did) can never lose a detection:
  ///  1. the plain normalised text;
  ///  2. the text with look-alike letters, fullwidth forms, accents and
  ///     invisible characters folded away, and with digits typed for
  ///     letters read as letters;
  ///  3. the same texts again, allowing ONE typing slip in ONE word of a
  ///     phrase (a swapped, missing, extra or wrong letter).
  static CrisisKind? detect(String text) {
    final String norm = normalize(text);
    final CrisisKind? plain = _classify(_plain, norm);
    if (plain != null) return plain;

    final List<String> variants = <String>[];
    void addVariant(String v) {
      if (v.isNotEmpty && !variants.contains(v)) variants.add(v);
    }

    addVariant(_normalizeFolded(text));
    addVariant(normalize(_foldText(text, joinInvisible: false)));
    if (_leetChars.hasMatch(text)) {
      addVariant(normalize(_foldText(text, joinInvisible: true, leet: 'i')));
      addVariant(normalize(_foldText(text, joinInvisible: true, leet: 'l')));
    }
    for (final String v in variants) {
      final CrisisKind? k = _classify(_folded, v);
      if (k != null) return k;
    }

    final CrisisKind? slipPlain = _classify(
      _plain,
      norm,
      near: _nearMap(norm.isEmpty ? const <String>[] : norm.split(' '), _plain),
    );
    if (slipPlain != null) return slipPlain;
    for (final String v in variants) {
      final CrisisKind? k = _classify(
        _folded,
        v,
        near: _nearMap(v.split(' '), _folded),
      );
      if (k != null) return k;
    }
    return null;
  }
}

/// One set of crisis phrase lists, all normalised the same way.
class _Lists {
  _Lists(String Function(String) norm)
      : selfHarm = CrisisDetector._normalizeAll(CrisisDetector._selfHarm, norm),
        concept =
            CrisisDetector._normalizeAll(CrisisDetector._suicideConcept, norm),
        abuse = CrisisDetector._normalizeAll(CrisisDetector._abuse, norm),
        child = CrisisDetector._normalizeAll(CrisisDetector._childSafety, norm),
        eating = CrisisDetector._normalizeAll(CrisisDetector._eating, norm),
        extremism =
            CrisisDetector._normalizeAll(CrisisDetector._extremism, norm),
        question = <String>[
          for (final String m in CrisisDetector._questionMarkers) norm(m),
        ],
        personal = <String>[
          for (final String m in CrisisDetector._personalMarkers) norm(m),
        ] {
    final List<List<_Pat>> all = <List<_Pat>>[
      selfHarm,
      concept,
      abuse,
      child,
      eating,
      extremism,
    ];
    for (final List<_Pat> list in all) {
      for (final _Pat p in list) {
        for (final String w in p.phrase.split(' ')) {
          if (w.isEmpty) continue;
          words.add(w);
          if (w.length >= 4 && CrisisDetector._isAsciiLetters(w)) {
            final List<String> bucket =
                byFirst.putIfAbsent(w[0], () => <String>[]);
            if (!bucket.contains(w)) bucket.add(w);
          }
        }
      }
    }
  }

  final List<_Pat> selfHarm;
  final List<_Pat> concept;
  final List<_Pat> abuse;
  final List<_Pat> child;
  final List<_Pat> eating;
  final List<_Pat> extremism;
  final List<String> question;
  final List<String> personal;

  /// Every word the phrases use.
  final Set<String> words = <String>{};

  /// The longer ASCII words the phrases use, by first letter.
  final Map<String, List<String>> byFirst = <String, List<String>>{};
}

/// The fixed replies. Compassion first; real help second; never a lecture;
/// never a pointer to a feature that does not exist.
abstract final class CrisisResponses {
  static const String _quran3953 =
      'Allah says: “Say, O My servants who have transgressed against '
      'themselves [by sinning], do not despair of the mercy of Allah. '
      'Indeed, Allah forgives all sins. Indeed, it is He who is the '
      'Forgiving, the Merciful.” (Qur’an 39:53)';

  /// Which help rows serve each kind of moment.
  static Set<HelpKind> kindsFor(CrisisKind kind) {
    switch (kind) {
      case CrisisKind.selfHarm:
      case CrisisKind.suicideQuestion:
        return const <HelpKind>{
          HelpKind.suicide,
          HelpKind.emergency,
          HelpKind.muslim,
        };
      case CrisisKind.abuse:
        return const <HelpKind>{HelpKind.abuse, HelpKind.emergency};
      case CrisisKind.childSafety:
        return const <HelpKind>{
          HelpKind.child,
          HelpKind.abuse,
          HelpKind.emergency,
        };
      case CrisisKind.eatingDisorder:
        return const <HelpKind>{
          HelpKind.eating,
          HelpKind.suicide,
          HelpKind.emergency,
        };
      case CrisisKind.extremism:
        return const <HelpKind>{HelpKind.emergency};
    }
  }

  /// The tappable rows for [kind] in [countryCode] (null = unknown).
  static List<HelpResource> resourcesFor(
    CrisisKind kind,
    String? countryCode,
  ) {
    return HelpResources.forCountry(countryCode, kinds: kindsFor(kind));
  }

  static String _lines(List<HelpResource> rows, {int max = 5}) {
    final StringBuffer b = StringBuffer();
    int n = 0;
    for (final HelpResource r in rows) {
      if (n >= max) break;
      if (r.dial == null && r.url == null) continue;
      b.writeln('• ${r.name} (${r.region}): ${r.contact}');
      n++;
    }
    return b.toString().trimRight();
  }

  /// The full reply text for [kind]. Includes the help lines as plain text
  /// so that it still works when read aloud, copied, or shown without the
  /// tappable panel.
  static String textFor(CrisisKind kind, {String? countryCode}) {
    final String lines = _lines(resourcesFor(kind, countryCode));
    switch (kind) {
      case CrisisKind.selfHarm:
        return 'I am really glad you told me. What you are carrying sounds '
            'very heavy, and I will not answer it with a lecture.\n\n'
            'Please reach a real person right now. If you might act on '
            'these thoughts, or you have already hurt yourself, call your '
            'local emergency number now, move away from anything you could '
            'use to hurt yourself, and go to someone you trust.\n\n'
            '$lines\n\n'
            'If you are worried about someone else, stay with them, and '
            'call the emergency number if they are in danger.\n\n'
            '$_quran3953\n\n'
            'You are not a burden, and this pain does not get the last '
            'word. I am an app, not a person, so the people behind these '
            'lines matter more than anything I can say. I am still here.';
      case CrisisKind.suicideQuestion:
        return 'I hear the weight behind that question, and I will answer '
            'it honestly, but first: if you are asking because you are in '
            'pain yourself, or because you lost someone this way, you are '
            'not being judged here.\n\n'
            'The Qur’an says: “And do not kill yourselves [or one '
            'another]. Indeed, Allah is to you ever Merciful.” (Qur’an '
            '4:29). That is never the first thing a hurting person needs to '
            'hear, and it is not the whole of what Islam says about you. '
            'Judgement of any person belongs to Allah alone. For a ruling '
            'about someone you lost, please ask a qualified scholar in '
            'person.\n\n'
            '$_quran3953\n\n'
            'If any part of this is about you, please talk to a real '
            'person now:\n\n'
            '$lines\n\n'
            'If you might act on these thoughts, call your local emergency '
            'number now.';
      case CrisisKind.abuse:
        return 'I am sorry. What you describe is not okay, and it is not '
            'your fault. Nothing, not marriage, not family, not honour, '
            'makes it acceptable for someone to hurt, threaten or force '
            'you. Your safety comes first, and you do not have to decide '
            'anything tonight.\n\n'
            'If you are in danger right now, call your local emergency '
            'number. If you can leave safely, go to someone you trust. '
            'These lines are for people in your situation:\n\n'
            '$lines\n\n'
            'If you are asking for someone else, the same lines can advise '
            'you. A trusted imam or scholar can help too, and a good one '
            'will put your safety first. If you want to talk it through '
            'here, I am listening, and I will keep this conversation on '
            'your device.';
      case CrisisKind.childSafety:
        return 'I am glad you told me. Someone who asks for pictures, '
            'tells you to keep a secret from your parents, or touches you '
            'in a way that feels wrong is doing something wrong. It is not '
            'your fault and you are not in trouble.\n\n'
            'Please do three things: stop answering them (keep the '
            'messages, they can help), tell a parent or another adult you '
            'trust today, and if you are in danger right now call your '
            'local emergency number.\n\n'
            '$lines\n\n'
            'These lines are for young people. If it feels too hard to say '
            'it at home, a teacher, an imam you trust, or one of these '
            'lines can help you find the words. I am an app, not a person, '
            'so the people behind these lines matter more than anything I '
            'can say.';
      case CrisisKind.eatingDisorder:
        return 'Thank you for telling me. Starving, purging or punishing '
            'your body with food is a real struggle, not a failure of '
            'faith or of character, and a doctor can help. You deserve '
            'care.\n\n'
            'The Qur’an, speaking about fasting, says: “Allah intends for '
            'you ease and does not intend for you hardship.” (Qur’an '
            '2:185) If fasting has become a way to punish or control '
            'yourself, please talk to a doctor, and ask a qualified scholar '
            'about your fasts. Your health comes first.\n\n'
            '$lines\n\n'
            'If you feel faint, have chest pain, or have thoughts of '
            'ending your life, call your local emergency number now. I am '
            'an app, not a doctor.';
      case CrisisKind.extremism:
        return 'I cannot help with that, and I will not. I am also not '
            'going to lecture you. If something is pulling you toward '
            'violence (anger at what you have seen, a group that wants '
            'you, a voice telling you it is your duty), please talk to a '
            'person you trust before you do anything: a local imam, a '
            'teacher, a family member.\n\n'
            'The Qur’an says: “…whoever kills a soul unless for a soul or '
            'for corruption [done] in the land - it is as if he had slain '
            'mankind entirely. And whoever saves one - it is as if he had '
            'saved mankind entirely.” (Qur’an 5:32, a decree upon the '
            'Children of Israel)\n\n'
            'If you or anyone else is in danger right now, call your local '
            'emergency number:\n\n'
            '$lines';
    }
  }

  /// A short reminder appended to a normal answer when a crisis card was
  /// already shown a moment ago (so a follow-up question is not blocked,
  /// but help stays in view).
  static String reminderFor(CrisisKind kind) {
    switch (kind) {
      case CrisisKind.abuse:
        return 'If you are in danger, please call your local emergency '
            'number. The help lines above are still there for you.';
      case CrisisKind.childSafety:
        return 'If someone is hurting or pressuring you, tell a trusted '
            'adult today. The lines above are for young people.';
      case CrisisKind.eatingDisorder:
        return 'A doctor can help with this. The lines above are still '
            'there for you.';
      case CrisisKind.extremism:
        return 'If anyone is in danger, call your local emergency number.';
      case CrisisKind.selfHarm:
      case CrisisKind.suicideQuestion:
        return 'If any part of this is about you, the help lines above are '
            'still there, and your local emergency number is always an '
            'option.';
    }
  }

  /// A short fixed follow-up when the same moment continues. Never goes to
  /// a live provider.
  static String followUpFor(CrisisKind kind) {
    switch (kind) {
      case CrisisKind.abuse:
        return 'I am here. Your safety comes first. If you are in danger '
            'right now, call your local emergency number. The lines above '
            'are for people in your situation, and I will keep this '
            'conversation on your device.';
      case CrisisKind.childSafety:
        return 'You did the right thing by telling someone. Please also '
            'tell a parent or another adult you trust today, and keep the '
            'messages. The lines above are for young people.';
      case CrisisKind.eatingDisorder:
        return 'I hear you. This is worth telling a doctor, and the lines '
            'above can help you find support. You do not have to fix it '
            'alone or tonight.';
      case CrisisKind.extremism:
        return 'I will not help with that. Please talk to a person you '
            'trust, such as a local imam, before you do anything. If anyone '
            'is in danger, call your local emergency number.';
      case CrisisKind.selfHarm:
      case CrisisKind.suicideQuestion:
        return reminderFor(kind);
    }
  }
}
