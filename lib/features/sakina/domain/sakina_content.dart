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
  });

  final String id;
  final String name;
  final String subtitle;

  /// What the user reads when the room opens (the crisis shell).
  final String doorLine;
  final String emoji;
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
    ),
    SakinaRoom(
      id: 'loss',
      name: 'The Empty Chair',
      subtitle: 'Grief & loss',
      emoji: '🕯️',
      doorLine:
          'The Prophet ﷺ wept at the grave of his son and said: "The eye '
          'weeps, the heart grieves, and we say only what pleases our '
          'Lord." Your tears are not weak faith. They are love with '
          'nowhere to go — and Allah gathers every one of them.',
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

/// A human-help resource — always visible, never buried.
class HelpResource {
  const HelpResource({
    required this.name,
    required this.detail,
    required this.contact,
    required this.region,
  });

  final String name;
  final String detail;
  final String contact;
  final String region;
}

abstract final class HelpResources {
  static const List<HelpResource> all = <HelpResource>[
    HelpResource(
      name: 'Naseeha Muslim Helpline',
      detail: 'Confidential, faith-sensitive listening, 7 days a week.',
      contact: '1-866-627-3342 (1-866-NASEEHA)',
      region: 'North America',
    ),
    HelpResource(
      name: 'Khalil Center',
      detail: 'Islamically-integrated professional therapy (TIIP model).',
      contact: 'khalilcenter.com',
      region: 'North America & online',
    ),
    HelpResource(
      name: '988 Suicide & Crisis Lifeline',
      detail: 'If you are thinking of harming yourself — call or text now. Free, 24/7.',
      contact: 'Call or text 988',
      region: 'United States',
    ),
    HelpResource(
      name: 'Talk Suicide Canada',
      detail: 'If you are in crisis — call or text, 24/7.',
      contact: 'Call or text 9-8-8',
      region: 'Canada',
    ),
    HelpResource(
      name: 'Emergency Services',
      detail: 'If you or someone near you is in immediate danger.',
      contact: '911 (US/CA) · 112 (EU) · 999 (UK)',
      region: 'Worldwide',
    ),
  ];
}
