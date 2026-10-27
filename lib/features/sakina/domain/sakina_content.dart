/// Sakina — the soul of the app. Crisis shell content (Wave A4).
///
/// The crisis constitution (locked):
/// - Sakina never diagnoses, never lectures, never shames.
/// - Shame is the engine of the cycle; guilt is the door of tawbah. We
///   speak to the wound, never at the failure.
/// - Human help is always one tap away and always on screen.
/// - Full pathways ship only after clinician + scholar review. Until then
///   the rooms open gently, not empty-handed: comfort cards, sourced words,
///   and doors to real people. Nothing here has yet been reviewed by a named
///   clinician or a named scholar, and the screens say so.
///
/// Religious-content standard (Qur'an quoted only from the bundled text,
/// hadith cited by collection and number with the grade and who gave it
/// where the collection is not Bukhari or Muslim) is enforced by
/// test/sakina_test.dart.
library;

/// A room of Sakina — a dedicated space for one kind of pain.
class SakinaRoom {
  const SakinaRoom({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.doorLine,
    required this.emoji,
    this.sources = '',
    this.safetyLine,
    this.helpKinds = const <HelpKind>{},
  });

  final String id;
  final String name;
  final String subtitle;

  /// What the user reads when the room opens (the crisis shell). It is a
  /// reflection written for this app; the quotations inside it are named in
  /// [sources].
  final String doorLine;
  final String emoji;

  /// The Qur'an verses and hadith quoted in [doorLine], for display.
  final String sources;

  /// A plain safety statement shown under the door line, for rooms where
  /// the person may be in danger rather than only in pain.
  final String? safetyLine;

  /// Which kinds of human help this room puts in front of the person.
  final Set<HelpKind> helpKinds;
}

abstract final class SakinaRooms {
  static const List<SakinaRoom> all = <SakinaRoom>[
    SakinaRoom(
      id: 'quiet-war',
      name: 'The Quiet War',
      subtitle: 'Addiction & compulsive habits',
      emoji: '🛡️',
      doorLine:
          'You are not your struggle. The fact that you are still fighting '
          'after every fall is not weakness. Every return matters. Allah '
          'says: “O My servants who have transgressed against themselves '
          '[by sinning], do not despair of the mercy of Allah. Indeed, '
          'Allah forgives all sins.” (Qur’an 39:53)',
      sources: 'Qur’an 39:53',
      safetyLine:
          'If you are in danger of overdose or withdrawal, or you are '
          'thinking of ending your life, call your local emergency number '
          'now. A doctor or an addiction service can walk this road with '
          'you; you do not have to do it on willpower alone.',
      helpKinds: <HelpKind>{HelpKind.addiction, HelpKind.suicide},
    ),
    SakinaRoom(
      id: 'marriage',
      name: 'Between Two Hearts',
      subtitle: 'Marriage & relationships',
      emoji: '💞',
      doorLine:
          'Hard days do not mean a failed home. The Prophet ﷺ taught that '
          'the best of you is the best to his wives '
          '(Jamiʿ at-Tirmidhi 3895, hasan per Darussalam; sahih per '
          'al-Albani). Your '
          'marriage is not failing because it struggles; it is alive '
          'because you are still here.',
      sources: 'Jamiʿ at-Tirmidhi 3895 (hasan per Darussalam; sahih per al-Albani)',
      safetyLine:
          'If you are ever afraid in your own home, hurt, threatened or '
          'forced, that is not a hard patch to endure quietly. Your safety '
          'comes first, and you do not have to decide anything tonight. '
          'Confidential help is one tap away below.',
      helpKinds: <HelpKind>{HelpKind.abuse, HelpKind.emergency},
    ),
    SakinaRoom(
      id: 'family',
      name: 'The House We Grew In',
      subtitle: 'Family wounds',
      emoji: '🏠',
      doorLine:
          'Some wounds come from the hands that raised us. Yusuf عليه السلام '
          'was wronged by his own brothers, and when he met them again he '
          'said: “No blame will there be upon you today.” (Qur’an 12:92) '
          'Healing here is not pretending it didn’t hurt. It is deciding '
          'the hurt stops with you.',
      sources: 'Qur’an 12:92',
      safetyLine:
          'If someone in your family hurts or threatens you, or you are '
          'afraid to go home, you are allowed to ask for help and to put '
          'your safety first. Confidential help is one tap away below.',
      helpKinds: <HelpKind>{HelpKind.abuse, HelpKind.emergency},
    ),
    SakinaRoom(
      id: 'loss',
      name: 'The Empty Chair',
      subtitle: 'Grief & loss',
      emoji: '🕯️',
      doorLine:
          'The Prophet ﷺ wept as his son Ibrahim was dying and said: “The '
          'eyes are shedding tears and the heart is grieved, and we will '
          'not say except what pleases our Lord.” (Sahih al-Bukhari 1303) '
          'Your tears are not weak faith. They are love with nowhere to go.',
      sources: 'Sahih al-Bukhari 1303',
      safetyLine:
          'Grief can become too heavy to carry alone. If you are thinking '
          'of ending your life, please call a crisis line or your local '
          'emergency number now.',
      helpKinds: <HelpKind>{HelpKind.suicide},
    ),
    SakinaRoom(
      id: 'son-father-husband',
      name: 'The Son, The Father, The Husband',
      subtitle: 'A space for men who carry quietly',
      emoji: '🌑',
      doorLine:
          'You were taught to carry, not to speak. The Prophet ﷺ wept '
          'openly as his son Ibrahim was dying (Sahih al-Bukhari 1303), and '
          'Allah tells him to say: “I am only a man like you.” (Qur’an '
          '18:110) Strength was never silence. Put it down here; Allah '
          'already knows.',
      sources: 'Sahih al-Bukhari 1303 · Qur’an 18:110',
      safetyLine:
          'If you are thinking of ending your life, please call a crisis '
          'line or your local emergency number now. Needing to say it out '
          'loud to a real person is not weakness.',
      helpKinds: <HelpKind>{HelpKind.suicide},
    ),
    SakinaRoom(
      id: 'whisper',
      name: 'The Whisper',
      subtitle: 'Waswas, doubt & scrupulosity',
      emoji: '🍃',
      doorLine:
          'The whisper that torments you is not proof of a sick heart. '
          'The Qur’an says what to do when an evil suggestion comes: '
          '“And if there comes to you from Satan an evil suggestion, then '
          'seek refuge in Allah. Indeed, He is the Hearing, the Knowing.” '
          '(Qur’an 41:36) You are not what you think. You are what you '
          'choose.',
      sources: 'Qur’an 41:36',
      safetyLine:
          'If the whispers take over your days — washing, checking, '
          'repeating, or fear that will not leave — it can help to speak to '
          'a doctor or counsellor as well as a scholar. Needing both is not '
          'a failure of faith.',
      helpKinds: <HelpKind>{HelpKind.suicide},
    ),
  ];
}

/// A comfort card — one sourced word of mercy for a hard day.
///
/// Qur'an cards hold verbatim excerpts of the app's bundled translation
/// (test/sakina_test.dart compares them with assets/quran/quran.json).
/// Hadith cards are summaries or short excerpts of the cited narration;
/// [source] names the collection and number, plus the grade and grader for
/// anything outside Bukhari and Muslim.
class ComfortCard {
  const ComfortCard({
    required this.text,
    required this.source,
    this.meaning = false,
  });

  final String text;
  final String source;

  /// A "meaning of hardship" card (for example, that hardship expiates
  /// sins). It can be heard as "your pain is deserved" by someone in acute
  /// distress, so it is never offered as the word of the day.
  final bool meaning;
}

/// The comfort deck (first 20 of 40; the rest ship with the pathways after
/// clinician + scholar review). Every card is sourced; none is a lecture.
abstract final class ComfortCards {
  static const List<ComfortCard> deck = <ComfortCard>[
    ComfortCard(
      text: 'Say, “O My servants who have transgressed against themselves '
          '[by sinning], do not despair of the mercy of Allah. Indeed, Allah '
          'forgives all sins.”',
      source: 'Quran 39:53 — excerpt',
    ),
    ComfortCard(
      text: '…despair not of relief from Allah…',
      source: 'Quran 12:87 — excerpt',
    ),
    ComfortCard(
      text: 'Allah is more pleased with the repentance of His servant than '
          'a traveller who finds his lost camel again.',
      source: 'Sahih Muslim 2747 — summary',
    ),
    ComfortCard(
      text: 'If you did not sin, Allah would replace you with a people who '
          'sin, seek forgiveness, and are forgiven.',
      source: 'Sahih Muslim 2749 — summary',
    ),
    ComfortCard(
      text: '…indeed I am near. I respond to the invocation of the '
          'supplicant when he calls upon Me…',
      source: 'Quran 2:186 — excerpt',
    ),
    ComfortCard(
      text: 'A man who had killed ninety-nine people asked whether he could '
          'still repent, and the hadith tells us the door was open to him. '
          'Nothing you have done has closed a door Allah keeps open.',
      source: 'Sahih Muslim 2766 — the hundred-souls hadith, summary',
    ),
    ComfortCard(
      text: 'Allah accepts the repentance of His servant until the soul '
          'reaches the throat.',
      source: 'Jamiʿ at-Tirmidhi 3537 — hasan (Darussalam)',
    ),
    ComfortCard(
      text: 'For indeed, with hardship [will be] ease. Indeed, with '
          'hardship [will be] ease.',
      source: 'Quran 94:5–6',
    ),
    ComfortCard(
      text: 'No fatigue, illness, worry, grief, harm or distress touches a '
          'Muslim, even a thorn’s prick, but Allah expiates some of his '
          'sins for it.',
      source: 'Sahih al-Bukhari 5641 — summary',
      meaning: true,
    ),
    ComfortCard(
      text: 'Unquestionably, by the remembrance of Allah hearts are '
          'assured.',
      source: 'Quran 13:28 — excerpt',
    ),
    ComfortCard(
      text: '…He is with you wherever you are…',
      source: 'Quran 57:4 — excerpt',
    ),
    ComfortCard(
      text: 'Allah says: I am just as My servant thinks I am.',
      source: 'Sahih al-Bukhari 7405 (Hadith Qudsi) — excerpt',
    ),
    ComfortCard(
      text: 'None of you should die except while thinking well of Allah.',
      source: 'Sahih Muslim 2877',
      meaning: true,
    ),
    ComfortCard(
      text: '…Your Lord has decreed upon Himself mercy…',
      source: 'Quran 6:54 — excerpt',
    ),
    ComfortCard(
      text: '…My mercy encompasses all things…',
      source: 'Quran 7:156 — excerpt',
    ),
    ComfortCard(
      text: '…He called out within the darknesses, “There is no deity '
          'except You; exalted are You. Indeed, I have been of the '
          'wrongdoers.” So We responded to him and saved him from the '
          'distress…',
      source: 'Quran 21:87–88 — excerpt',
    ),
    ComfortCard(
      text: '…“I only complain of my suffering and my grief to Allah, and I '
          'know from Allah that which you do not know.”',
      source: 'Quran 12:86 — Yaʿqub عليه السلام, excerpt',
    ),
    ComfortCard(
      text: 'Your Lord has not taken leave of you, [O Muhammad], nor has He '
          'detested [you]. And the Hereafter is better for you than the '
          'first [life].',
      source: 'Quran 93:3–4',
    ),
    ComfortCard(
      text: '…Fear not. Indeed, I am with you both; I hear and I see.',
      source: 'Quran 20:46 — Allah to Musa and Harun, excerpt',
    ),
    ComfortCard(
      text: 'If he comes to Me walking, I go to him running.',
      source: 'Sahih al-Bukhari 7405 (Hadith Qudsi) — excerpt',
    ),
  ];

  /// Cards that may be the word of the day: the deck without the
  /// "meaning of hardship" cards.
  static List<ComfortCard> get daily => <ComfortCard>[
        for (final ComfortCard c in deck)
          if (!c.meaning) c,
      ];

  /// Cards taken out of the deck, kept here (not deleted) with the reason.
  /// Not shown anywhere.
  static const List<ComfortCard> withheld = <ComfortCard>[
    ComfortCard(
      text: 'Every son of Adam sins, and the best of those who sin are those '
          'who repent.',
      // Checked on sunnah.com on 2026-10-20: Jami' at-Tirmidhi 2499 is
      // graded da'if (weak) by Darussalam. The card called it hasan.
      source: 'Jamiʿ at-Tirmidhi 2499 — da‘if (Darussalam); withheld',
    ),
  ];
}

/// What a help line is for. Used to pick the right rows for a moment
/// (a suicidal message needs a different set from a domestic-violence one).
enum HelpKind {
  suicide,
  emergency,
  abuse,
  addiction,
  muslim,
  general,

  /// Ongoing counselling or listening that is not a crisis service (limited
  /// hours, appointment based, or volunteer led). Never offered first in a
  /// crisis reply.
  counselling,

  /// Lines for children and young people.
  child,

  /// Eating-disorder support.
  eating,
}

/// A human-help resource — always visible, never buried.
class HelpResource {
  const HelpResource({
    required this.name,
    required this.detail,
    required this.contact,
    required this.region,
    this.dial,
    this.url,
    this.countries = const <String>[],
    this.kinds = const <HelpKind>{HelpKind.general},
    this.verifiedOn,
    this.source,
  });

  final String name;
  final String detail;
  final String contact;
  final String region;

  /// Number to dial when tapped (digits only), when the row is a phone line.
  final String? dial;

  /// Web address to open when tapped, when the row is a website.
  final String? url;

  /// ISO 3166-1 alpha-2 codes this row is specifically for. Empty means it
  /// is useful anywhere (a global directory, a near-universal emergency
  /// number).
  final List<String> countries;

  /// What this line is for.
  final Set<HelpKind> kinds;

  /// The day (YYYY-MM-DD) a person read this number on the operator's own
  /// page, and that page's address. Both null means "not re-checked on an
  /// official page"; the screen then says so.
  final String? verifiedOn;
  final String? source;

  bool get verified => verifiedOn != null && source != null;
}

/// Human-help lines, by country.
///
/// HOW THESE WERE CHECKED (20 Oct 2026): each row with a [HelpResource.source]
/// was read on the operator's own page on 2026-10-20 (the page is named in
/// `source`; what the page said, including hours, is what `detail` says).
/// Rows without a source are national emergency numbers that were not
/// re-read on an official page that day; the screen labels them "not
/// re-checked". Numbers that could not be corroborated at all are not shown:
/// they sit in [unverified] with the reason. Never add a number from memory.
/// test/help_resources_test.dart fails when a verified row is older than nine
/// months, so the list is re-read at least that often.
abstract final class HelpResources {
  /// The day this list was last read against the operators' pages.
  static const String checked = '2026-10-27';

  static const Set<HelpKind> _suicide = <HelpKind>{
    HelpKind.suicide,
    HelpKind.general,
  };
  static const Set<HelpKind> _emergency = <HelpKind>{HelpKind.emergency};
  static const Set<HelpKind> _abuse = <HelpKind>{HelpKind.abuse};
  static const Set<HelpKind> _child = <HelpKind>{
    HelpKind.child,
    HelpKind.abuse,
  };

  static const List<HelpResource> all = <HelpResource>[
    // ── North America ────────────────────────────────────────────────
    HelpResource(
      name: '988 Suicide & Crisis Lifeline',
      detail: 'Free and confidential. Call, text or chat (chat.988lifeline.org). '
          'Available 24/7/365.',
      contact: 'Call or text 988',
      region: 'United States',
      dial: '988',
      countries: <String>['US'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://988lifeline.org/',
    ),
    HelpResource(
      name: '9-8-8 Suicide Crisis Helpline',
      detail: 'Call or text, 24 hours a day, every day of the year.',
      contact: 'Call or text 9-8-8',
      region: 'Canada',
      dial: '988',
      countries: <String>['CA'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://988.ca/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '911',
      region: 'United States',
      dial: '911',
      countries: <String>['US'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://www.911.gov/calling-911/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If your safety is at risk, call 9-1-1 right away.',
      contact: '911',
      region: 'Canada',
      dial: '911',
      countries: <String>['CA'],
      kinds: _emergency,
      verifiedOn: checked,
      source: 'https://988.ca/',
    ),
    HelpResource(
      name: 'National Domestic Violence Hotline',
      detail: 'Free, confidential support 24/7 if someone at home hurts or '
          'frightens you. Text START to 88788, or chat live on the site.',
      contact: '1-800-799-7233 (1-800-799-SAFE)',
      region: 'United States',
      dial: '18007997233',
      countries: <String>['US'],
      kinds: _abuse,
      verifiedOn: checked,
      source: 'https://www.thehotline.org/get-help/',
    ),
    HelpResource(
      name: 'RAINN National Sexual Assault Hotline',
      detail: 'Free, confidential, 24/7 in English and Spanish. Chat at '
          'rainn.org/hotline, or text HOPE to 64673.',
      contact: '1-800-656-4673 (1-800-656-HOPE)',
      region: 'United States',
      dial: '18006564673',
      countries: <String>['US'],
      kinds: _abuse,
      verifiedOn: checked,
      source: 'https://rainn.org/',
    ),
    HelpResource(
      name: 'Childhelp National Child Abuse Hotline',
      detail: 'For children, and for adults worried about a child. Call, '
          'text GO to 800.422.4453, or chat on the site.',
      contact: '1-800-422-4453',
      region: 'United States',
      dial: '18004224453',
      countries: <String>['US'],
      kinds: _child,
      verifiedOn: checked,
      source: 'https://www.childhelphotline.org/',
    ),
    HelpResource(
      name: 'Kids Help Phone',
      detail: 'For all young people in Canada. Call 24/7 in multiple '
          'languages, or text CONNECT to 686868. Live chat 7pm to midnight '
          'ET.',
      contact: '1-800-668-6868',
      region: 'Canada',
      dial: '18006686868',
      countries: <String>['CA'],
      kinds: _child,
      verifiedOn: checked,
      source: 'https://kidshelpphone.ca/',
    ),
    HelpResource(
      name: 'SAMHSA National Helpline',
      detail: 'Free, confidential treatment referral and information, 24/7, '
          'in English and Spanish, for mental and substance use disorders.',
      contact: '1-800-662-4357 (1-800-662-HELP)',
      region: 'United States',
      dial: '18006624357',
      countries: <String>['US'],
      kinds: <HelpKind>{HelpKind.addiction},
      verifiedOn: checked,
      source: 'https://www.samhsa.gov/find-help/national-helpline',
    ),
    HelpResource(
      name: 'ANAD Eating Disorders Helpline',
      detail: 'Monday to Friday, 9am to 9pm Central. Not a crisis line: if '
          'you are in danger, call 988 or 911.',
      contact: '1-888-375-7767',
      region: 'United States',
      dial: '18883757767',
      countries: <String>['US'],
      kinds: <HelpKind>{HelpKind.eating},
      verifiedOn: checked,
      source: 'https://anad.org/get-help/',
    ),
    HelpResource(
      name: 'Naseeha Muslim Helpline',
      detail: 'Faith-sensitive support from a Muslim helpline. Call or text '
          'any time, 24/7 (the site says “Call or text any time”). A live '
          'chat link is on naseeha.org; its hours are not stated there.',
      contact: '1-866-627-3342 (1-866-NASEEHA)',
      region: 'North America',
      dial: '18666273342',
      countries: <String>['US', 'CA'],
      kinds: <HelpKind>{HelpKind.muslim, HelpKind.general},
      verifiedOn: checked,
      source: 'https://naseeha.org',
    ),
    HelpResource(
      name: 'Khalil Center',
      detail: 'Islamically-integrated therapy by appointment. Not a crisis '
          'service: it lists no crisis line.',
      contact: 'khalilcenter.com',
      region: 'North America',
      url: 'https://khalilcenter.com',
      countries: <String>['US', 'CA'],
      kinds: <HelpKind>{HelpKind.counselling},
      verifiedOn: checked,
      source: 'https://khalilcenter.com',
    ),

    // ── United Kingdom & Ireland ────────────────────────────────────
    HelpResource(
      name: 'Samaritans',
      detail: 'Free from any phone, open 24 hours a day, 365 days a year. '
          'You do not have to be suicidal to call.',
      contact: '116 123',
      region: 'United Kingdom',
      dial: '116123',
      countries: <String>['GB'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://www.samaritans.org/how-we-can-help/contact-samaritan/',
    ),
    HelpResource(
      name: 'Samaritans Ireland',
      detail: 'Call free, day or night, 365 days a year.',
      contact: '116 123',
      region: 'Ireland',
      dial: '116123',
      countries: <String>['IE'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://www.samaritans.org/ireland/samaritans-ireland/',
    ),
    HelpResource(
      name: 'Muslim Youth Helpline',
      detail: 'For young British Muslims. Phone 7 days a week, 4pm to 10pm; '
          'web chat on the site.',
      contact: '0808 808 2008',
      region: 'United Kingdom',
      dial: '08088082008',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.muslim, HelpKind.general},
      verifiedOn: checked,
      source: 'https://myh.org.uk',
    ),
    HelpResource(
      name: 'Muslim Community Helpline',
      detail: 'A volunteer listening line (English, Arabic, Gujarati, '
          'Punjabi, Urdu/Hindi). Monday to Thursday 10am to 1pm, Friday '
          '10am to 4pm. Not a crisis service.',
      contact: '020 8904 8193 · 020 8908 6715',
      region: 'United Kingdom',
      dial: '02089048193',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.counselling},
      verifiedOn: checked,
      source: 'https://www.muslimcommunityhelpline.org.uk',
    ),
    HelpResource(
      name: 'National Domestic Abuse Helpline',
      detail: 'Free and confidential, 24 hours a day. Live chat on the '
          'site. In an emergency call 999.',
      contact: '0808 2000 247',
      region: 'United Kingdom',
      dial: '08082000247',
      countries: <String>['GB'],
      kinds: _abuse,
      verifiedOn: checked,
      source: 'https://www.nationaldahelpline.org.uk/',
    ),
    HelpResource(
      name: 'Childline',
      detail: 'Free, 24 hours a day, 7 days a week, for young people. '
          'Online 1-2-1 chat with a counsellor on the site.',
      contact: '0800 1111',
      region: 'United Kingdom',
      dial: '08001111',
      countries: <String>['GB'],
      kinds: _child,
      verifiedOn: checked,
      source: 'https://www.childline.org.uk/get-support/contacting-childline/',
    ),
    HelpResource(
      name: 'FRANK',
      detail: 'Confidential advice about drugs, 24 hours a day. Text '
          '82111. For urgent help after taking drugs, call 999.',
      contact: '0300 123 6600',
      region: 'United Kingdom',
      dial: '03001236600',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.addiction},
      verifiedOn: checked,
      source: 'https://www.talktofrank.com/contact-frank',
    ),
    HelpResource(
      name: 'Beat Eating Disorders',
      detail: 'Helpline for people in England (0808 801 0677); Scotland, '
          'Wales and Northern Ireland have their own numbers on the site. '
          '3pm to 8pm, Monday to Friday. Not a crisis service: call 999 in '
          'danger, or Samaritans on 116 123.',
      contact: '0808 801 0677 (England)',
      region: 'United Kingdom',
      dial: '08088010677',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.eating},
      verifiedOn: checked,
      source: 'https://www.beateatingdisorders.org.uk/get-information-and-'
          'support/get-help-for-myself/i-need-support-now/helplines/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: '999 is for life-threatening emergencies.',
      contact: '999',
      region: 'United Kingdom',
      dial: '999',
      countries: <String>['GB'],
      kinds: _emergency,
      verifiedOn: checked,
      source: 'https://www.nhs.uk/nhs-services/urgent-and-emergency-care-'
          'services/when-to-call-999/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112 or 999',
      region: 'Ireland',
      dial: '112',
      countries: <String>['IE'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://www.gov.ie/en/department-of-the-taoiseach/services/how-to-contact-emergency-services-in-ireland/',
    ),

    // ── Australia ────────────────────────────────────────────────────
    HelpResource(
      name: 'Lifeline Australia',
      detail: 'Crisis support. Call 13 11 14, text 0477 13 11 14, or chat '
          'on the site (chat is available 24/7).',
      contact: '13 11 14',
      region: 'Australia',
      dial: '131114',
      countries: <String>['AU'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://www.lifeline.org.au/',
    ),
    HelpResource(
      name: '1800RESPECT',
      detail: 'Support for domestic, family and sexual violence, 24 hours a '
          'day, 7 days a week. Text 0458 737 732.',
      contact: '1800 737 732',
      region: 'Australia',
      dial: '1800737732',
      countries: <String>['AU'],
      kinds: _abuse,
      verifiedOn: checked,
      source: 'https://www.1800respect.org.au/',
    ),
    HelpResource(
      name: 'Kids Helpline',
      detail: 'For young people aged 5 to 25, 24/7, by phone or web chat.',
      contact: '1800 55 1800',
      region: 'Australia',
      dial: '1800551800',
      countries: <String>['AU'],
      kinds: _child,
      verifiedOn: checked,
      source: 'https://www.kidshelpline.com.au/',
    ),
    HelpResource(
      name: 'Butterfly Foundation Helpline',
      detail: 'Eating disorders. 8am to midnight Eastern time, 7 days, '
          'closed on national public holidays. “Not a crisis line”: call '
          '000 or Lifeline on 13 11 14 in a crisis.',
      contact: '1800 33 4673 (1800 ED HOPE)',
      region: 'Australia',
      dial: '1800334673',
      countries: <String>['AU'],
      kinds: <HelpKind>{HelpKind.eating},
      verifiedOn: checked,
      source: 'https://butterfly.org.au/get-support/helpline/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If life is in danger, call Triple Zero (000).',
      contact: '000',
      region: 'Australia',
      dial: '000',
      countries: <String>['AU'],
      kinds: _emergency,
      verifiedOn: checked,
      source: 'https://www.lifeline.org.au/',
    ),

    // ── South Asia ───────────────────────────────────────────────────
    HelpResource(
      name: 'Rozan Counselling Helpline',
      detail: 'Counselling and psychosocial support; Rozan works against '
          'violence against women and children. Hours are not stated on '
          'the site, so it may not answer at night. Not a 24-hour crisis '
          'line.',
      contact: '0304-111-1741',
      region: 'Pakistan',
      dial: '03041111741',
      countries: <String>['PK'],
      kinds: <HelpKind>{HelpKind.counselling, HelpKind.abuse},
      verifiedOn: checked,
      source: 'https://rozan.org/',
    ),
    HelpResource(
      name: 'Rescue 1122',
      detail: 'The emergency number of the Punjab Emergency Service (its '
          'site is Government of the Punjab). Other provinces: call police '
          'on 15.',
      contact: '1122',
      region: 'Pakistan (Punjab)',
      dial: '1122',
      countries: <String>['PK'],
      kinds: _emergency,
      verifiedOn: checked,
      source: 'https://www.rescue.gov.pk/',
    ),
    HelpResource(
      name: 'Tele-MANAS',
      detail: 'Government of India tele-mental-health service: a toll-free '
          'helpline, 24x7, tele-counselling in 20 Indian languages.',
      contact: '14416',
      region: 'India',
      dial: '14416',
      countries: <String>['IN'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://static.pib.gov.in/WriteReadData/specificdocs/'
          'documents/2024/oct/doc20241013415701.pdf',
    ),
    HelpResource(
      name: 'CHILDLINE 1098',
      detail: 'For children in need of care and protection. Its site does '
          'not state its hours.',
      contact: '1098',
      region: 'India',
      dial: '1098',
      countries: <String>['IN'],
      kinds: _child,
      verifiedOn: checked,
      source: 'https://www.childlineindia.org/',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'The pan-India single emergency number.',
      contact: '112',
      region: 'India',
      dial: '112',
      countries: <String>['IN'],
      kinds: _emergency,
      verifiedOn: checked,
      source: 'https://112.gov.in/',
    ),
    HelpResource(
      name: 'National Helpline Centre',
      detail: 'Support for women and children facing violence.',
      contact: '109',
      region: 'Bangladesh',
      dial: '109',
      countries: <String>['BD'],
      kinds: _abuse,
      verifiedOn: '2026-10-27',
      source: 'https://bangladesh.gov.bd/pages/static-pages/69a55ba386514399668e4e89',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Bangladesh',
      dial: '999',
      countries: <String>['BD'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://bangladesh.gov.bd/pages/static-pages/69a55ba386514399668e4e89',
    ),

    // ── Gulf & Middle East ──────────────────────────────────────────
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'United Arab Emirates',
      dial: '999',
      countries: <String>['AE'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://u.ae/en/information-and-services/justice-safety-and-the-law/Safety/handling-emergencies',
    ),
    HelpResource(
      name: 'Ministry of Health 937',
      detail: 'The Ministry of Health call centre, open 24/7, with medical '
          'consultation by doctors. Its page does not mention mental '
          'health, so ask for a doctor and say what you need.',
      contact: '937',
      region: 'Saudi Arabia',
      dial: '937',
      countries: <String>['SA'],
      kinds: <HelpKind>{HelpKind.general},
      verifiedOn: checked,
      source: 'https://www.moh.gov.sa/en/Ministry/MediaCenter/News/Pages/'
          'News-2020-10-15-001.aspx',
    ),
    HelpResource(
      name: 'National Mental Health Helpline',
      detail: 'Run by Hamad Medical Corporation. Call 16000 and choose '
          'option 4 for Mental Health. Open 8am to 6pm, Saturday to '
          'Thursday only; outside those hours call 999.',
      contact: '16000 (option 4)',
      region: 'Qatar',
      dial: '16000',
      countries: <String>['QA'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://hamad.qa/EN/news/2026/April/Pages/'
          'National-Mental-Health-Helpline-marks-six-years-of-supporting-'
          'Qatar’s-population.aspx',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Qatar',
      dial: '999',
      countries: <String>['QA'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://portal.moi.gov.qa/UNCCPCJDoha/English/Emergency_Services.html',
    ),
    HelpResource(
      name: 'ALO 183 Social Support Line',
      detail: 'Ministry of Family line for reports and guidance on '
          'violence, abuse and neglect (women, children, elderly, '
          'families), reachable 24/7. The page found for this check is a '
          'May 2020 ministry announcement.',
      contact: '183',
      region: 'Türkiye',
      dial: '183',
      countries: <String>['TR'],
      kinds: <HelpKind>{HelpKind.abuse, HelpKind.child},
      verifiedOn: checked,
      source: 'https://aile.gov.tr/bolu/haberler/'
          'bakan-selcuk-alo-183-whatsapp-ihbar-hatti-vatandaslarimizin-'
          'hizmetinde/',
    ),

    // ── Southeast Asia ──────────────────────────────────────────────
    HelpResource(
      name: 'Befrienders Kuala Lumpur',
      detail: 'Emotional support, 24 hours, free and confidential.',
      contact: '03-7627 2929',
      region: 'Malaysia',
      dial: '0376272929',
      countries: <String>['MY'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://www.befrienders.org.my/',
    ),
    HelpResource(
      name: 'Talian Kasih',
      detail: 'A 24/7 government helpline (run by the Welfare Department) '
          'for abuse, neglect, harassment and family crises. WhatsApp '
          '019-261 5999.',
      contact: '15999',
      region: 'Malaysia',
      dial: '15999',
      countries: <String>['MY'],
      kinds: <HelpKind>{HelpKind.abuse, HelpKind.child},
      verifiedOn: checked,
      source: 'https://www.malaysia.gov.my/en/topics/talian-kasih-15999',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Malaysia',
      dial: '999',
      countries: <String>['MY'],
      kinds: _emergency,
      verifiedOn: '2026-10-27',
      source: 'https://www.malaysia.gov.my/en/categories/safety-and-community/public-safety/mers-999-emergency-line',
    ),
    HelpResource(
      name: 'Samaritans of Singapore (SOS)',
      detail: '24-hour hotline for emotional support or crisis. CareText '
          'on WhatsApp: 9151 1767.',
      contact: '1767',
      region: 'Singapore',
      dial: '1767',
      countries: <String>['SG'],
      kinds: _suicide,
      verifiedOn: checked,
      source: 'https://www.sos.org.sg/',
    ),

    // ── Everywhere ──────────────────────────────────────────────────
    HelpResource(
      name: 'Find a Helpline',
      detail: 'A free directory of verified helplines run by ThroughLine. '
          'Choose your country and the topic. It lists phone, text and '
          'chat lines.',
      contact: 'findahelpline.com',
      region: 'Worldwide',
      url: 'https://findahelpline.com',
      kinds: <HelpKind>{
        HelpKind.suicide,
        HelpKind.emergency,
        HelpKind.abuse,
        HelpKind.addiction,
        HelpKind.general,
        HelpKind.child,
        HelpKind.eating,
      },
      verifiedOn: checked,
      source: 'https://findahelpline.com/',
    ),
  ];

  /// Lines that were in the list before 2026-10-20 and could NOT be
  /// confirmed on the operator's own page. Kept here with the reason, not
  /// deleted, and shown nowhere. Do not move a row back to [all] without a
  /// `verifiedOn` and `source`.
  static const List<HelpResource> unverified = <HelpResource>[
    // Emergency numbers moved here on 2026-10-27: not confirmed on an operator
    // or official page in assets/support/helplines.json, so not shown.
    HelpResource(
      name: 'Police',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '15',
      region: 'Pakistan',
      dial: '15',
      countries: <String>['PK'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'Ambulance 997. Police 999.',
      contact: '997 (ambulance) · 999 (police)',
      region: 'Saudi Arabia',
      dial: '997',
      countries: <String>['SA'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112',
      region: 'Kuwait',
      dial: '112',
      countries: <String>['KW'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'Police 122. Ambulance 123.',
      contact: '123 (ambulance) · 122 (police)',
      region: 'Egypt',
      dial: '123',
      countries: <String>['EG'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112',
      region: 'Türkiye',
      dial: '112',
      countries: <String>['TR'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'Police 999. Ambulance 995.',
      contact: '999 (police) · 995 (ambulance)',
      region: 'Singapore',
      dial: '995',
      countries: <String>['SG'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112',
      region: 'Indonesia',
      dial: '112',
      countries: <String>['ID'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger. 112 '
          'connects from most mobile phones in Europe and many other '
          'countries; if it does not, dial your local emergency number.',
      contact: '112',
      region: 'Many countries (check yours)',
      dial: '112',
      kinds: <HelpKind>{
        HelpKind.emergency,
        HelpKind.suicide,
        HelpKind.abuse,
        HelpKind.child,
      },
    ),
    HelpResource(
      name: 'Umang Pakistan',
      // umang.com.pk was read on 2026-10-20: the page lists no phone number,
      // so 0311-7786264 cannot be confirmed there, and the page describes
      // phone therapy sessions with clinical psychologists ("1st session
      // free"), not a crisis line.
      detail: 'Mental health helpline for people in distress.',
      contact: '0311-7786264',
      region: 'Pakistan',
      dial: '03117786264',
      countries: <String>['PK'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'National Mental Health Support Line (800 HOPE)',
      // Not found on an operator page on 2026-10-20 (emiratesfoundation.ae
      // page returned no content about it; u.ae blocked automated reads).
      detail: 'Free mental health support line.',
      contact: '800 HOPE (800 4673)',
      region: 'United Arab Emirates',
      dial: '8004673',
      countries: <String>['AE'],
      kinds: _suicide,
    ),
  ];

  /// Rows for [countryCode] first, then the worldwide rows. When
  /// [kinds] is given, only rows that serve one of those purposes. An
  /// unknown or missing country gets the worldwide rows alone — never a
  /// number that would only work somewhere else.
  /// Verified rows read from assets/support/helplines.json at start-up (see
  /// `HelplinesLoader`). Empty until loaded, and in tests. Only rows with a
  /// verified-on date and a source are ever put here.
  static List<HelpResource> extra = <HelpResource>[];

  /// Every row that may be shown: the verified rows of [all] plus [extra]
  /// whose number is not already listed.
  /// Two rows are the same line when they dial the same digits (or open the
  /// same page) in the same countries, however the contact text is written.
  static String _rowKey(HelpResource r) =>
      '${r.countries.join(',')}|${r.dial ?? r.url ?? r.contact.replaceAll(RegExp(r'[^0-9A-Za-z]'), '')}';

  static List<HelpResource> get shown {
    final Set<String> have = <String>{for (final HelpResource r in all) _rowKey(r)};
    return <HelpResource>[
      ...all,
      for (final HelpResource r in extra)
        if (r.verified && have.add(_rowKey(r))) r,
    ];
  }

  static List<HelpResource> forCountry(
    String? countryCode, {
    Set<HelpKind>? kinds,
  }) {
    final String? cc = countryCode?.trim().toUpperCase();
    bool wanted(HelpResource r) =>
        kinds == null || r.kinds.any(kinds.contains);
    final List<HelpResource> local = <HelpResource>[
      for (final HelpResource r in shown)
        if (cc != null && r.countries.contains(cc) && wanted(r)) r,
    ];
    final List<HelpResource> worldwide = <HelpResource>[
      for (final HelpResource r in shown)
        if (r.countries.isEmpty && wanted(r)) r,
    ];
    final Set<String> seen = <String>{};
    return <HelpResource>[
      for (final HelpResource r in <HelpResource>[...local, ...worldwide])
        if (seen.add('${r.dial ?? r.url ?? r.contact}')) r,
    ];
  }

  /// Every country code that has at least one specific row.
  static Set<String> get coveredCountries => <String>{
        for (final HelpResource r in shown) ...r.countries,
      };
}
