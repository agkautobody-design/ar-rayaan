/// Sakina — the soul of the app. Crisis shell content (Wave A4).
///
/// The crisis constitution (locked):
/// - Sakina never diagnoses, never lectures, never shames.
/// - Shame is the engine of the cycle; guilt is the door of tawbah. We
///   speak to the wound, never at the failure.
/// - Human help is always one tap away and always on screen.
/// - Full pathways ship only after clinician + scholar review. Until then
///   the rooms open gently, not empty-handed: comfort cards, sourced words,
///   and doors to real people.
library;

/// A room of Sakina — a dedicated space for one kind of pain.
class SakinaRoom {
  const SakinaRoom({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.doorLine,
    required this.emoji,
    this.safetyLine,
    this.helpKinds = const <HelpKind>{},
  });

  final String id;
  final String name;
  final String subtitle;

  /// What the user reads when the room opens (the crisis shell).
  final String doorLine;
  final String emoji;

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
          'after every fall is not weakness — it is the proof of your iman. '
          'Allah does not count your falls; He counts your returns.',
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
          'The best of homes had hard days too. The Prophet ﷺ was called '
          'the best of husbands — and his house still knew tears, silence, '
          'and reconciliation. Your marriage is not failing because it '
          'struggles; it is alive because you are still here.',
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
          'was betrayed by his own brothers — and years later said: "No '
          'reproach upon you today." Healing here is not pretending it '
          'didn’t hurt. It is deciding the hurt stops with you.',
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
          'The Prophet ﷺ wept when his son Ibrahim died and said: "The eye '
          'weeps, the heart grieves, and we say only what pleases our '
          'Lord." Your tears are not weak faith. They are love with '
          'nowhere to go — and Allah gathers every one of them.',
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
          'You were taught to carry, not to speak. The Prophet ﷺ cried '
          'openly, leaned on his companions, and said "I am only a man." '
          'Strength was never silence. Put it down here — no one is '
          'watching, and Allah already knows.',
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
          'The companions asked the Prophet ﷺ about the whispers that '
          'disturbed them, and he said: "That is clear faith." The whisper '
          'that torments you is not a sign of a sick heart — it is the '
          'sign of a heart Shaytan is angry with. You are not what you '
          'think. You are what you choose.',
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
class ComfortCard {
  const ComfortCard({required this.text, required this.source});

  final String text;
  final String source;
}

/// The comfort deck (first 20 of 40; the rest ship with the pathways after
/// clinician + scholar review). Every card is sourced; none is a lecture.
abstract final class ComfortCards {
  static const List<ComfortCard> deck = <ComfortCard>[
    ComfortCard(text: 'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives ALL sins.', source: 'Quran 39:53 — excerpt'),
    ComfortCard(text: 'And never despair of the relief of Allah. Indeed, no one despairs of Allah’s relief except the disbelieving people.', source: 'Quran 12:87'),
    ComfortCard(text: 'Allah is happier with the repentance of His servant than a man who lost his camel in the desert — carrying all his food and water — and then finds it again.', source: 'Sahih Muslim 2747 — excerpt'),
    ComfortCard(text: 'By the One in Whose hand is my soul, if you did not sin, Allah would remove you and bring a people who sin and seek forgiveness — and He would forgive them.', source: 'Sahih Muslim 2749'),
    ComfortCard(text: 'Every son of Adam sins, and the best of those who sin are those who repent.', source: 'Jamiʿ at-Tirmidhi 2499 — hasan'),
    ComfortCard(text: 'A man killed ninety-nine people, then asked if repentance was open to him — and it was. Nothing you have done has closed a door Allah keeps open.', source: 'Sahih Muslim 2766 — the hundred-souls hadith, excerpt'),
    ComfortCard(text: 'Allah accepts the repentance of His servant until the soul reaches the throat.', source: 'Jamiʿ at-Tirmidhi 3537 — hasan'),
    ComfortCard(text: 'Indeed, with hardship comes ease. Indeed, with hardship comes ease.', source: 'Quran 94:5–6'),
    ComfortCard(text: 'No fatigue, illness, anxiety, sorrow or grief touches a Muslim — not even the prick of a thorn — but that Allah expiates some of his sins by it.', source: 'Sahih al-Bukhari 5641 — excerpt'),
    ComfortCard(text: 'Verily, in the remembrance of Allah do hearts find rest.', source: 'Quran 13:28'),
    ComfortCard(text: 'And He is with you wherever you are.', source: 'Quran 57:4 — excerpt'),
    ComfortCard(text: 'Allah says: I am as My servant thinks of Me, and I am with him when he remembers Me.', source: 'Sahih al-Bukhari 7405 (Hadith Qudsi) — excerpt'),
    ComfortCard(text: 'None of you should die except thinking well of Allah.', source: 'Sahih Muslim 2877'),
    ComfortCard(text: 'Your Lord has written mercy upon Himself.', source: 'Quran 6:54 — excerpt'),
    ComfortCard(text: 'O My servants who believe — indeed, My earth is spacious, and My mercy encompasses all things.', source: 'Quran 29:56 · 7:156 — excerpts'),
    ComfortCard(text: 'The dua of Yunus from inside the whale: La ilaha illa anta, subhanaka, inni kuntu minaz-zalimin — and Allah answered him. He answers you too.', source: 'Quran 21:87–88'),
    ComfortCard(text: 'Ya’qub عليه السلام lost his sight from grief and said only: I complain of my sorrow and grief to Allah.', source: 'Quran 12:86 — excerpt'),
    ComfortCard(text: 'The Prophet ﷺ, in his hardest year, was told: Your Lord has neither forsaken you nor does He hate you. And the Hereafter is better for you than the first.', source: 'Quran 93:3–4'),
    ComfortCard(text: 'Fear not — I am with you both; I hear and I see.', source: 'Quran 20:46 — Allah to Musa and Harun'),
    ComfortCard(text: 'Whoever comes to Me walking, I come to him running.', source: 'Sahih al-Bukhari 7405 (Hadith Qudsi) — excerpt'),
  ];
}

/// What a help line is for. Used to pick the right rows for a moment
/// (a suicidal message needs a different set from a domestic-violence one).
enum HelpKind { suicide, emergency, abuse, addiction, muslim, general }

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
}

/// Human-help lines, by country.
///
/// HOW THESE WERE CHECKED (20 Oct 2026): every service below was confirmed to
/// exist through public web search results naming the service and (where the
/// result title or URL showed it) its number. The full organisation pages
/// could not be fetched from the build sandbox, so a human must re-confirm
/// each number against the operator's own page before every release — see
/// docs in the fix report. Numbers that could not be corroborated at all
/// are deliberately NOT here; the global directory row (findahelpline.com)
/// covers those countries instead. Never add a number from memory.
abstract final class HelpResources {
  static const Set<HelpKind> _suicide = <HelpKind>{
    HelpKind.suicide,
    HelpKind.general,
  };
  static const Set<HelpKind> _emergency = <HelpKind>{HelpKind.emergency};
  static const Set<HelpKind> _abuse = <HelpKind>{HelpKind.abuse};

  static const List<HelpResource> all = <HelpResource>[
    // ── North America ────────────────────────────────────────────────
    HelpResource(
      name: '988 Suicide & Crisis Lifeline',
      detail: 'If you are thinking of harming yourself — call or text now. '
          'Free, 24/7.',
      contact: 'Call or text 988',
      region: 'United States',
      dial: '988',
      countries: <String>['US'],
      kinds: _suicide,
    ),
    HelpResource(
      name: '9-8-8 Suicide Crisis Helpline',
      detail: 'If you are in crisis — call or text, 24/7.',
      contact: 'Call or text 9-8-8',
      region: 'Canada',
      dial: '988',
      countries: <String>['CA'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '911',
      region: 'United States & Canada',
      dial: '911',
      countries: <String>['US', 'CA'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'National Domestic Violence Hotline',
      detail: 'Confidential support if someone at home hurts or frightens '
          'you.',
      contact: '1-800-799-7233 (1-800-799-SAFE)',
      region: 'United States',
      dial: '18007997233',
      countries: <String>['US'],
      kinds: _abuse,
    ),
    HelpResource(
      name: 'SAMHSA National Helpline',
      detail: 'Free, confidential help with addiction and mental health, '
          'in English and Spanish.',
      contact: '1-800-662-4357 (1-800-662-HELP)',
      region: 'United States',
      dial: '18006624357',
      countries: <String>['US'],
      kinds: <HelpKind>{HelpKind.addiction},
    ),
    HelpResource(
      name: 'Naseeha Muslim Helpline',
      detail: 'Confidential, faith-sensitive listening. Hours are limited — '
          'check naseeha.org for when it is open.',
      contact: '1-866-627-3342 (1-866-NASEEHA)',
      region: 'North America',
      dial: '18666273342',
      countries: <String>['US', 'CA'],
      kinds: <HelpKind>{HelpKind.muslim, HelpKind.general},
    ),
    HelpResource(
      name: 'Khalil Center',
      detail: 'Islamically-integrated professional therapy (TIIP model).',
      contact: 'khalilcenter.com',
      region: 'North America & online',
      url: 'https://khalilcenter.com',
      countries: <String>['US', 'CA'],
      kinds: <HelpKind>{HelpKind.muslim, HelpKind.general},
    ),

    // ── United Kingdom & Ireland ────────────────────────────────────
    HelpResource(
      name: 'Samaritans',
      detail: 'Free to call, any time, day or night. You do not have to be '
          'suicidal to call.',
      contact: '116 123',
      region: 'United Kingdom',
      dial: '116123',
      countries: <String>['GB'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Samaritans Ireland',
      detail: 'Free to call, any time, day or night.',
      contact: '116 123',
      region: 'Ireland',
      dial: '116123',
      countries: <String>['IE'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Muslim Youth Helpline',
      detail: 'Faith-sensitive support, 7 days a week, 4pm to 10pm.',
      contact: '0808 808 2008',
      region: 'United Kingdom',
      dial: '08088082008',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.muslim, HelpKind.general},
    ),
    HelpResource(
      name: 'National Domestic Abuse Helpline',
      detail: 'Free, confidential support if someone at home hurts or '
          'frightens you.',
      contact: '0808 2000 247',
      region: 'United Kingdom',
      dial: '08082000247',
      countries: <String>['GB'],
      kinds: _abuse,
    ),
    HelpResource(
      name: 'FRANK',
      detail: 'Confidential advice about drugs and addiction.',
      contact: '0300 123 6600',
      region: 'United Kingdom',
      dial: '03001236600',
      countries: <String>['GB'],
      kinds: <HelpKind>{HelpKind.addiction},
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'United Kingdom',
      dial: '999',
      countries: <String>['GB'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112 or 999',
      region: 'Ireland',
      dial: '112',
      countries: <String>['IE'],
      kinds: _emergency,
    ),

    // ── Australia ────────────────────────────────────────────────────
    HelpResource(
      name: 'Lifeline Australia',
      detail: 'Crisis support and suicide prevention, 24 hours.',
      contact: '13 11 14',
      region: 'Australia',
      dial: '131114',
      countries: <String>['AU'],
      kinds: _suicide,
    ),
    HelpResource(
      name: '1800RESPECT',
      detail: 'Confidential support for domestic, family and sexual '
          'violence.',
      contact: '1800 737 732',
      region: 'Australia',
      dial: '1800737732',
      countries: <String>['AU'],
      kinds: _abuse,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '000',
      region: 'Australia',
      dial: '000',
      countries: <String>['AU'],
      kinds: _emergency,
    ),

    // ── South Asia ───────────────────────────────────────────────────
    HelpResource(
      name: 'Umang Pakistan',
      detail: 'Mental health helpline for people in distress.',
      contact: '0311-7786264',
      region: 'Pakistan',
      dial: '03117786264',
      countries: <String>['PK'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'Police 15. Rescue 1122 where it operates.',
      contact: '15 (police) · 1122 (rescue)',
      region: 'Pakistan',
      dial: '15',
      countries: <String>['PK'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Tele-MANAS',
      detail: 'Government mental health support line, free, 24/7.',
      contact: '14416',
      region: 'India',
      dial: '14416',
      countries: <String>['IN'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '112',
      region: 'India',
      dial: '112',
      countries: <String>['IN'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'National Helpline Centre',
      detail: 'Support for women and children facing violence.',
      contact: '109',
      region: 'Bangladesh',
      dial: '109',
      countries: <String>['BD'],
      kinds: _abuse,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Bangladesh',
      dial: '999',
      countries: <String>['BD'],
      kinds: _emergency,
    ),

    // ── Gulf & Middle East ──────────────────────────────────────────
    HelpResource(
      name: 'National Mental Health Support Line',
      detail: 'Free mental health support line.',
      contact: '800 HOPE (800 4673)',
      region: 'United Arab Emirates',
      dial: '8004673',
      countries: <String>['AE'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'United Arab Emirates',
      dial: '999',
      countries: <String>['AE'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Ministry of Health 937',
      detail: 'The national health line; ask for mental health support.',
      contact: '937',
      region: 'Saudi Arabia',
      dial: '937',
      countries: <String>['SA'],
      kinds: _suicide,
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
      name: 'National Mental Health Helpline',
      detail: 'Run by Hamad Medical Corporation.',
      contact: '16000',
      region: 'Qatar',
      dial: '16000',
      countries: <String>['QA'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Qatar',
      dial: '999',
      countries: <String>['QA'],
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
      name: 'ALO 183 Social Support Line',
      detail: 'Government line for people facing violence at home.',
      contact: '183',
      region: 'Türkiye',
      dial: '183',
      countries: <String>['TR'],
      kinds: _abuse,
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

    // ── Southeast Asia ──────────────────────────────────────────────
    HelpResource(
      name: 'Befrienders Kuala Lumpur',
      detail: 'Emotional support for anyone in distress.',
      contact: '03-7627 2929',
      region: 'Malaysia',
      dial: '0376272929',
      countries: <String>['MY'],
      kinds: _suicide,
    ),
    HelpResource(
      name: 'Talian Kasih',
      detail: 'Government line for abuse, domestic violence and welfare '
          'help.',
      contact: '15999',
      region: 'Malaysia',
      dial: '15999',
      countries: <String>['MY'],
      kinds: _abuse,
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '999',
      region: 'Malaysia',
      dial: '999',
      countries: <String>['MY'],
      kinds: _emergency,
    ),
    HelpResource(
      name: 'Samaritans of Singapore (SOS)',
      detail: '24-hour crisis line.',
      contact: '1767',
      region: 'Singapore',
      dial: '1767',
      countries: <String>['SG'],
      kinds: _suicide,
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

    // ── Everywhere ──────────────────────────────────────────────────
    HelpResource(
      name: 'Find a Helpline',
      detail: 'A directory of free, confidential helplines in almost every '
          'country. Choose your country and the topic.',
      contact: 'findahelpline.com',
      region: 'Worldwide',
      url: 'https://findahelpline.com',
      kinds: <HelpKind>{
        HelpKind.suicide,
        HelpKind.abuse,
        HelpKind.addiction,
        HelpKind.general,
      },
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
      },
    ),
  ];

  /// Rows for [countryCode] first, then the worldwide rows. When
  /// [kinds] is given, only rows that serve one of those purposes. An
  /// unknown or missing country gets the worldwide rows alone — never a
  /// number that would only work somewhere else.
  static List<HelpResource> forCountry(
    String? countryCode, {
    Set<HelpKind>? kinds,
  }) {
    final String? cc = countryCode?.trim().toUpperCase();
    bool wanted(HelpResource r) =>
        kinds == null || r.kinds.any(kinds.contains);
    final List<HelpResource> local = <HelpResource>[
      for (final HelpResource r in all)
        if (cc != null && r.countries.contains(cc) && wanted(r)) r,
    ];
    final List<HelpResource> worldwide = <HelpResource>[
      for (final HelpResource r in all)
        if (r.countries.isEmpty && wanted(r)) r,
    ];
    return <HelpResource>[...local, ...worldwide];
  }

  /// Every country code that has at least one specific row.
  static Set<String> get coveredCountries => <String>{
        for (final HelpResource r in all) ...r.countries,
      };
}
