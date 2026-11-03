/// Between Two Hearts — the two-way marriage tools of the Sakina room.
///
/// The Sakina constitution holds in this room: judgement-free,
/// trauma-informed, and grounded in the Qur'an and the authentic Sunnah.
/// Every tool runs in both directions — anything a husband may use to
/// reach his wife, a wife may use to reach her husband. A tool only one
/// spouse may use is not a tool; it is a leash.
///
/// Scripture rule: Qur'an is quoted byte-exact from the bundled
/// assets/quran/quran.json (test/sakina_test.dart re-reads the bundled
/// text and compares). Hadith are cited by collection and number; outside
/// Sahih al-Bukhari and Sahih Muslim the grade and its grader are named.
library;

/// One step inside a tool: a heading to hold on to, a body that explains
/// it gently, and — where the step rests on revelation — its source.
class MarriageStep {
  const MarriageStep({
    required this.heading,
    required this.body,
    this.source,
  });

  final String heading;
  final String body;
  final String? source;
}

/// A two-way marriage tool: a small practice a couple can walk through
/// together, or one spouse alone on a hard day.
class MarriageTool {
  const MarriageTool({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.steps,
  });

  /// Stable key, used in widget keys and tests.
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<MarriageStep> steps;
}

/// The content of the Between Two Hearts room.
abstract final class MarriageTools {
  /// The du'a of repair — surah Al-Furqan 25:74, byte-exact from the
  /// bundled Qur'an text. Never retype it by hand; the test suite compares
  /// it against assets/quran/quran.json.
  static const String repairDuaArabic = 'رَبَّنَا هَبۡ لَنَا مِنۡ أَزۡوَٰجِنَا وَذُرِّيَّـٰتِنَا قُرَّةَ أَعۡيُنٖ وَٱجۡعَلۡنَا لِلۡمُتَّقِينَ إِمَامًا';

  /// The bundled English rendering of 25:74.
  static const String repairDuaBody =
      'Our Lord, grant us from among our wives and offspring comfort to our '
      'eyes and make us an example for the righteous.';

  static const String repairDuaSource = "Qur'an 25:74";

  /// The five tools, in the order the room shows them. The safety card is
  /// always last, and on screen it is always open.
  static const List<MarriageTool> all = <MarriageTool>[
    MarriageTool(
      id: 'the-pause',
      title: 'The Sunnah Pause',
      subtitle: 'For the moment anger walks into the room',
      emoji: '🕊️',
      steps: <MarriageStep>[
        MarriageStep(
          heading: 'Stop at the gate of the tongue',
          body: 'The first victory over anger is silence. What you were '
              'about to say will keep for an hour; the wound it might leave '
              'could keep for years. The Prophet ﷺ said: whoever believes in '
              'Allah and the Last Day, let him speak good or remain silent.',
          source: 'Sahih al-Bukhari 6018',
        ),
        MarriageStep(
          heading: 'Change your posture',
          body: 'If you are standing, sit down. If you are sitting, lie '
              'down. The Prophet ﷺ taught this so the heat of anger leaves '
              'through the body before it reaches the tongue.',
          source: 'Sunan Abi Dawud 4782 (sahih, per al-Albani)',
        ),
        MarriageStep(
          heading: 'Water on the fire',
          body: 'Anger is from the fire, and water puts out fire. Make '
              'wudu — slowly, letting the coolness do its work — and only '
              'then decide whether the thing still needs saying.',
          source: 'Sunan Abi Dawud 4784 (sahih, per al-Albani)',
        ),
        MarriageStep(
          heading: 'Come back as the best of you',
          body: 'The pause is not the point; the return is. The most '
              'complete believers in faith are the best in character, and '
              'the best of them are the best to their women — and toward '
              'husbands, the same door of good character stands open.',
          source: "Jamiʿ at-Tirmidhi 1162 (hasan sahih, per al-Albani)",
        ),
      ],
    ),
    MarriageTool(
      id: 'say-it-gently',
      title: 'Say It Gently',
      subtitle: 'A hard conversation, opened the Prophetic way',
      emoji: '💬',
      steps: <MarriageStep>[
        MarriageStep(
          heading: 'Start with when',
          body: 'Not at the door, not at midnight, not in front of the '
              'children. Choose a moment when you are both fed, rested and '
              'unhurried. Half of a hard conversation is its timing.',
        ),
        MarriageStep(
          heading: 'Name your feeling, not their fault',
          body: '“I felt alone this week” opens a door; “you never listen” '
              'closes one. Speak about yourself and your need — that is '
              'honesty. Counting their faults is a courtroom, and a '
              'marriage is not one.',
        ),
        MarriageStep(
          heading: 'Ask for one small thing',
          body: 'One request, small enough to say yes to this week. “Could '
              'we walk after Maghrib on Friday?” moves a marriage further '
              'than a list of everything that is wrong with it.',
        ),
        MarriageStep(
          heading: 'Why this is worship, not technique',
          body: 'Allah says: "And tell My servants to say that which is '
              'best. Indeed, Satan induces [dissension] among them." '
              'Choosing the gentler word between two believers is '
              'obedience, not strategy.',
          source: "Qur'an 17:53",
        ),
      ],
    ),
    MarriageTool(
      id: 'the-daily-thank-you',
      title: 'The Daily Thank-You',
      subtitle: 'The smallest Sunnah with the longest shadow',
      emoji: '🌱',
      steps: <MarriageStep>[
        MarriageStep(
          heading: 'Catch one thing done right',
          body: 'Once a day, name one thing your spouse did well — out '
              'loud, in their presence, specific. “You handled his tears so '
              'gently.” “You noticed I was tired.” Small, true, daily.',
        ),
        MarriageStep(
          heading: 'Thanking them is thanking Him',
          body: 'The Prophet ﷺ said: whoever does not thank people has not '
              'thanked Allah. Gratitude to your spouse is part of gratitude '
              'to Allah — it is not flattery, it is worship.',
          source: 'Sunan Abi Dawud 4811 (sahih, per al-Albani)',
        ),
        MarriageStep(
          heading: 'Watch the one who served first',
          body: 'Asked what the Prophet ﷺ did at home, Aisha said: he was '
              'in the service of his family. The most honoured man in '
              'creation poured, mended and served. Neither spouse is '
              'beneath service; both are ennobled by it.',
          source: 'Sahih al-Bukhari 676',
        ),
      ],
    ),
    MarriageTool(
      id: 'rights-both-ways',
      title: 'Both Pans of the Scale',
      subtitle: 'Her due and his due, weighed together',
      emoji: '⚖️',
      steps: <MarriageStep>[
        MarriageStep(
          heading: 'Her due',
          body: 'Allah commands: "And live with them in kindness." '
              'Kindness toward a wife is not a husband’s generosity; it is '
              'her right, revealed.',
          source: "Qur'an 4:19",
        ),
        MarriageStep(
          heading: 'His due',
          body: 'And of wives Allah says: "due to the wives is similar to '
              'what is expected of them, according to what is reasonable." '
              'The scale has two pans; revelation put weight on both.',
          source: "Qur'an 2:228",
        ),
        MarriageStep(
          heading: 'The measure is the kitchen face',
          body: 'The best of you, the Prophet ﷺ said, are the best to '
              'their families — and he added: and I am the best of you to '
              'my family. The measure of a believer is not the mosque face '
              'but the kitchen face.',
          source: "Jamiʿ at-Tirmidhi 3895 (hasan per Darussalam, sahih per al-Albani)",
        ),
        MarriageStep(
          heading: 'Both pans or neither',
          body: 'Any list of rights that only one spouse may read is not '
              'from this room. If a sentence here is ever quoted to demand '
              'rather than to give, it has been quoted against its purpose.',
        ),
      ],
    ),
    MarriageTool(
      id: 'when-not-safe',
      title: 'When It Is Not Safe',
      subtitle: 'Some seasons need protection before they need patience',
      emoji: '🛡️',
      steps: <MarriageStep>[
        MarriageStep(
          heading: 'Name it without softening it',
          body: 'No harming and no reciprocating of harm, the Prophet ﷺ '
              'ruled. Blows are harm. Forced intimacy is harm. Threats, '
              'isolation, money withheld to control — harm. Patience is a '
              'virtue; enduring harm is not the patience revelation asks '
              'of you.',
          source: 'Sunan Ibn Majah 2341 (sahih, per al-Albani)',
        ),
        MarriageStep(
          heading: 'Safety comes before reconciliation',
          body: 'Get somewhere safe first. Reconciliation can wait a '
              'night, a week, a season — a body cannot. The pages behind '
              'the button below know the numbers and the next steps.',
        ),
        MarriageStep(
          heading: 'It runs both directions',
          body: 'Harm runs both directions. Wives harm husbands too, and a '
              'husband who is being harmed deserves the same protection, '
              'the same belief, and the same way out. This room does not '
              'ask which spouse you are.',
        ),
        MarriageStep(
          heading: 'Leaving the room is not leaving the faith',
          body: 'Stepping out of a dangerous house, or asking an outside '
              'hand to enter it, is not a betrayal of marriage. Protecting '
              'a life — yours or theirs — is part of the trust Allah '
              'placed in you.',
        ),
      ],
    ),
  ];
}
