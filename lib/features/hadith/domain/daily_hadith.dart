/// Daily Hadith + Feeling Check-in — content pack (Wave A3).
///
/// - 60 one-sentence hadiths (sahih/hasan, brief, sourced) — one per day,
///   selected deterministically by day-of-year.
/// - The mood map: 10 feelings, each matched to curated, sourced comfort —
///   per the Content Expansion authoring bible §2.
///
/// Authenticity rules (locked): every entry carries its source; weak or
/// fabricated reports are never included; where a wording is a verified
/// excerpt rather than the full hadith, the text says so.
library;

/// A short daily hadith.
class DailyHadith {
  const DailyHadith({
    required this.text,
    required this.narrator,
    required this.source,
  });

  final String text;
  final String narrator;
  final String source;
}

/// A feeling on the check-in wheel.
class Feeling {
  const Feeling({
    required this.id,
    required this.label,
    required this.emoji,
    required this.responses,
  });

  final String id;
  final String label;
  final String emoji;

  /// Curated responses for this feeling (cycled by day). Always sourced.
  final List<FeelingResponse> responses;
}

/// One sourced response to a feeling — an ayah, a hadith, a dua, or a door.
class FeelingResponse {
  const FeelingResponse({
    required this.kind,
    required this.text,
    required this.source,
    this.note,
  });

  /// 'Quran' · 'Hadith' · 'Dua' · 'Door'
  final String kind;
  final String text;
  final String source;

  /// Optional gentle pointer (e.g. to a Sakina room).
  final String? note;
}

/// The 60 one-sentence hadiths — the daily rotation.
abstract final class DailyHadiths {
  static const List<DailyHadith> all = <DailyHadith>[
    DailyHadith(text: 'Actions are but by intentions, and every person shall have only what he intended.', narrator: 'Umar ibn al-Khattab (RA)', source: 'Sahih al-Bukhari 1'),
    DailyHadith(text: 'The best of you are those who learn the Quran and teach it.', narrator: 'Uthman ibn Affan (RA)', source: 'Sahih al-Bukhari 5027'),
    DailyHadith(text: 'Your smile in your brother’s face is charity.', narrator: 'Abu Dharr (RA)', source: 'Jamiʿ at-Tirmidhi 1956 — hasan'),
    DailyHadith(text: 'The strong is not the one who wrestles; the strong is the one who controls himself when angry.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 6114'),
    DailyHadith(text: 'None of you truly believes until he loves for his brother what he loves for himself.', narrator: 'Anas ibn Malik (RA)', source: 'Sahih al-Bukhari 13'),
    DailyHadith(text: 'Whoever believes in Allah and the Last Day, let him speak good or remain silent.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 6018'),
    DailyHadith(text: 'Allah is Gentle and loves gentleness in all things.', narrator: 'Aisha (RA)', source: 'Sahih al-Bukhari 6927'),
    DailyHadith(text: 'The most beloved deeds to Allah are the most consistent, even if small.', narrator: 'Aisha (RA)', source: 'Sahih al-Bukhari 6464'),
    DailyHadith(text: 'Cleanliness is half of faith.', narrator: 'Abu Malik al-Ash’ari (RA)', source: 'Sahih Muslim 223'),
    DailyHadith(text: 'Whoever conceals the fault of a Muslim, Allah will conceal his faults in this world and the Hereafter.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2699'),
    DailyHadith(text: 'The upper hand is better than the lower hand.', narrator: 'Abdullah ibn Umar (RA)', source: 'Sahih al-Bukhari 1427'),
    DailyHadith(text: 'Make things easy and do not make them difficult; give glad tidings and do not repel people.', narrator: 'Anas ibn Malik (RA)', source: 'Sahih al-Bukhari 69'),
    DailyHadith(text: 'The best charity is that given when you are healthy and holding back, fearing poverty.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 1419'),
    DailyHadith(text: 'Whoever does not show mercy will not be shown mercy.', narrator: 'Jarir ibn Abdullah (RA)', source: 'Sahih al-Bukhari 6013'),
    DailyHadith(text: 'Kindness is never present in anything but it beautifies it.', narrator: 'Aisha (RA)', source: 'Sahih Muslim 2594'),
    DailyHadith(text: 'Removing something harmful from the road is charity.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 2989'),
    DailyHadith(text: 'A good word is charity.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 2989'),
    DailyHadith(text: 'Two words, light on the tongue, heavy on the Scale, beloved to the Most Merciful: SubhanAllahi wa bihamdihi, SubhanAllahil-Adheem.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 6406'),
    DailyHadith(text: 'Whoever believes in Allah and the Last Day, let him honor his guest.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 6019'),
    DailyHadith(text: 'The most complete believers in faith are the best of them in character.', narrator: 'Abu Hurayrah (RA)', source: 'Jamiʿ at-Tirmidhi 1162 — sahih'),
    DailyHadith(text: 'Fear Allah wherever you are, follow a bad deed with a good one and it will erase it, and treat people with good character.', narrator: 'Abu Dharr & Mu’adh (RA)', source: 'Jamiʿ at-Tirmidhi 1987 — hasan sahih'),
    DailyHadith(text: 'Allah does not look at your appearances or your wealth, but He looks at your hearts and your deeds.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2564'),
    DailyHadith(text: 'Leave that which makes you doubt for that which does not make you doubt.', narrator: 'al-Hasan ibn Ali (RA)', source: 'Jamiʿ at-Tirmidhi 2518 — hasan sahih'),
    DailyHadith(text: 'Part of a person’s good Islam is leaving what does not concern him.', narrator: 'Abu Hurayrah (RA)', source: 'Jamiʿ at-Tirmidhi 2317 — hasan'),
    DailyHadith(text: 'Do not envy one another, do not hate one another, do not turn away from one another — and be, O servants of Allah, brothers.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2559 — excerpt'),
    DailyHadith(text: 'A Muslim is the brother of a Muslim: he does not wrong him, nor forsake him, nor despise him.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2564'),
    DailyHadith(text: 'Whoever relieves a believer’s distress, Allah will relieve his distress on the Day of Resurrection.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2699 — excerpt'),
    DailyHadith(text: 'Be in this world as if you were a stranger or a traveler.', narrator: 'Abdullah ibn Umar (RA)', source: 'Sahih al-Bukhari 6416'),
    DailyHadith(text: 'If you were to rely upon Allah with true reliance, He would provide for you as He provides for the birds.', narrator: 'Umar ibn al-Khattab (RA)', source: 'Jamiʿ at-Tirmidhi 2344 — hasan sahih'),
    DailyHadith(text: 'Take advantage of five before five: your youth before your old age, your health before your sickness, your wealth before your poverty, your free time before your busyness, and your life before your death.', narrator: 'Abdullah ibn Abbas (RA)', source: 'al-Hakim — sahih'),
    DailyHadith(text: 'The best among you are those who are best to their families, and I am the best of you to my family.', narrator: 'Aisha (RA)', source: 'Jamiʿ at-Tirmidhi 3895 — sahih'),
    DailyHadith(text: 'He is not of us who does not show mercy to our young and honor our elderly.', narrator: 'Abdullah ibn Amr (RA)', source: 'Jamiʿ at-Tirmidhi 1919 — sahih'),
    DailyHadith(text: 'The Merciful are shown mercy by the Most Merciful; be merciful to those on earth and the One above the heavens will be merciful to you.', narrator: 'Abdullah ibn Amr (RA)', source: 'Sunan Abi Dawud 4941 — sahih'),
    DailyHadith(text: 'Whoever does not thank people has not thanked Allah.', narrator: 'Abu Hurayrah (RA)', source: 'Sunan Abi Dawud 4811 — sahih'),
    DailyHadith(text: 'Two blessings many people lose: health and free time.', narrator: 'Abdullah ibn Abbas (RA)', source: 'Sahih al-Bukhari 6412'),
    DailyHadith(text: 'Richness is not having many possessions; richness is contentment of the soul.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 6446'),
    DailyHadith(text: 'The most beloved people to Allah are those most beneficial to people.', narrator: 'Ibn Umar (RA)', source: 'al-Mu’jam al-Awsat — hasan'),
    DailyHadith(text: 'Allah makes the way to Paradise easy for whoever travels a path seeking knowledge.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2699 — excerpt'),
    DailyHadith(text: 'When a man dies, his deeds end except three: ongoing charity, beneficial knowledge, or a righteous child who prays for him.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 1631'),
    DailyHadith(text: 'The best of you in this world are those who, when they are reminded of Allah, their eyes overflow with tears.', narrator: 'Abdullah ibn Mas’ud (RA)', source: 'Musnad Ahmad — meaning, graded hasan'),
    DailyHadith(text: 'Whoever fasts Ramadan out of faith and hope for reward, his previous sins are forgiven.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 38'),
    DailyHadith(text: 'Whoever prays the two cool hours (Fajr and Asr) will enter Paradise.', narrator: 'Abu Musa al-Ash’ari (RA)', source: 'Sahih al-Bukhari 574'),
    DailyHadith(text: 'The closest a servant is to his Lord is while he is prostrating — so make much dua.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 482'),
    DailyHadith(text: 'Allah descends in the last third of the night and says: Who calls upon Me that I may answer him?', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 1145 — excerpt'),
    DailyHadith(text: 'Purity of speech and feeding others and praying at night while people sleep — enter Paradise in peace.', narrator: 'Abdullah ibn Salam (RA)', source: 'Jamiʿ at-Tirmidhi 2485 — sahih, excerpt'),
    DailyHadith(text: 'The seven whom Allah will shade on the day there is no shade but His… (among them) a person whose eyes shed tears in private out of reverence for Allah.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 660 — excerpt'),
    DailyHadith(text: 'Whoever says SubhanAllah one hundred times, a thousand good deeds are recorded for him.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2698'),
    DailyHadith(text: 'Indeed Allah and His angels send blessings upon the Prophet; O you who believe, send blessings and peace upon him.', narrator: 'The Quran itself commands it', source: 'Quran 33:56'),
    DailyHadith(text: 'Whoever sends one blessing upon me, Allah sends ten blessings upon him.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 407'),
    DailyHadith(text: 'There is a gate in Paradise called Ar-Rayyan through which those who fasted will enter, and none will enter through it except them.', narrator: 'Sahl ibn Sa’d (RA)', source: 'Sahih al-Bukhari 1896'),
    DailyHadith(text: 'Allah accepts the repentance of His servant so long as the death-rattle has not reached his throat.', narrator: 'Abdullah ibn Umar (RA)', source: 'Jamiʿ at-Tirmidhi 3537 — hasan'),
    DailyHadith(text: 'By the One in Whose hand is my soul, if you did not sin, Allah would replace you with people who would sin and seek forgiveness — and He would forgive them.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih Muslim 2749'),
    DailyHadith(text: 'Every son of Adam sins, and the best of those who sin are those who repent.', narrator: 'Anas ibn Malik (RA)', source: 'Jamiʿ at-Tirmidhi 2499 — hasan'),
    DailyHadith(text: 'Allah is happier with the repentance of His servant than one of you who finds his lost camel in the desert.', narrator: 'Anas ibn Malik (RA)', source: 'Sahih Muslim 2747 — excerpt'),
    DailyHadith(text: 'None of you should die except thinking well of Allah.', narrator: 'Jabir ibn Abdullah (RA)', source: 'Sahih Muslim 2877'),
    DailyHadith(text: 'Amazing is the affair of the believer — all of it is good for him: gratitude in ease, patience in hardship.', narrator: 'Suhayb ar-Rumi (RA)', source: 'Sahih Muslim 2999 — excerpt'),
    DailyHadith(text: 'No fatigue, illness, worry or grief touches a Muslim, even the prick of a thorn, but that Allah expiates some of his sins by it.', narrator: 'Abu Hurayrah (RA)', source: 'Sahih al-Bukhari 5641 — excerpt'),
    DailyHadith(text: 'To Allah belongs what He took and what He gave, and everything with Him has an appointed term — so be patient and seek reward.', narrator: 'Usamah ibn Zayd (RA)', source: 'Sahih al-Bukhari 1284 — excerpt'),
    DailyHadith(text: 'Supplication is worship itself.', narrator: 'an-Nu’man ibn Bashir (RA)', source: 'Jamiʿ at-Tirmidhi 2969 — sahih'),
    DailyHadith(text: 'The dua of the distressed: O Allah, Your mercy I hope for — do not leave me to myself even for the blink of an eye.', narrator: 'Asma bint Umays (RA)', source: 'Sunan Abi Dawud 5090 — sahih'),
  ];

  /// Today's hadith — deterministic by day-of-year, so every user on Earth
  /// reads the same one the same day.
  static DailyHadith forDate(DateTime date) {
    return all[dayOfYear(date) % all.length];
  }
}

/// Days since Jan 1 of [d]'s year (0-based), kept dependency-free.
int dayOfYear(DateTime d) => d.difference(DateTime(d.year, 1, 1)).inDays;

/// The ten feelings on the check-in wheel, each with sourced responses.
abstract final class MoodMap {
  static const List<Feeling> feelings = <Feeling>[
    Feeling(id: 'peace', label: 'At peace', emoji: '🕊️', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Verily, in the remembrance of Allah do hearts find rest.', source: 'Quran 13:28'),
      FeelingResponse(kind: 'Hadith', text: 'Amazing is the affair of the believer — all of it is good for him: if ease reaches him he is grateful, and if hardship strikes him he is patient.', source: 'Sahih Muslim 2999 — excerpt'),
      FeelingResponse(kind: 'Dua', text: 'O Allah, I ask You for contentment after decree, and well-being in this world and the Hereafter.', source: 'Taught by the Prophet ﷺ — Sunan Ibn Majah 3871 — sahih, excerpt'),
    ]),
    Feeling(id: 'grateful', label: 'Grateful', emoji: '🌷', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Hadith', text: 'Whoever does not thank people has not thanked Allah.', source: 'Sunan Abi Dawud 4811 — sahih'),
      FeelingResponse(kind: 'Hadith', text: 'Two blessings many people lose: health and free time.', source: 'Sahih al-Bukhari 6412'),
      FeelingResponse(kind: 'Door', text: 'Sujud al-shukr — the prostration of gratitude. When a blessing reaches you, fall into prostration.', source: 'The practice of the Prophet ﷺ — Sunan Abi Dawud 2774 — sahih'),
    ]),
    Feeling(id: 'anxious', label: 'Anxious', emoji: '🌊', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Verily, in the remembrance of Allah do hearts find rest.', source: 'Quran 13:28'),
      FeelingResponse(kind: 'Dua', text: 'O Allah, Your mercy I hope for; do not leave me to myself even for the blink of an eye, and set right all my affairs. There is no god but You.', source: 'Sunan Abi Dawud 5090 — sahih'),
      FeelingResponse(kind: 'Hadith', text: 'If you were to rely upon Allah with true reliance, He would provide for you as He provides for the birds: they leave hungry in the morning and return full.', source: 'Jamiʿ at-Tirmidhi 2344 — hasan sahih'),
    ]),
    Feeling(id: 'sad', label: 'Sad', emoji: '🌧️', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Indeed, with hardship comes ease. Indeed, with hardship comes ease.', source: 'Quran 94:5–6'),
      FeelingResponse(kind: 'Hadith', text: 'No fatigue, illness, anxiety, sorrow or grief touches a Muslim — not even a thorn — but that Allah expiates some of his sins by it.', source: 'Sahih al-Bukhari 5641 — excerpt'),
      FeelingResponse(kind: 'Dua', text: 'La ilaha illa anta, subhanaka, inni kuntu minaz-zalimin — the dua of Yunus in the three darknesses.', source: 'Quran 21:87 · Jamiʿ at-Tirmidhi 3505'),
    ]),
    Feeling(id: 'angry', label: 'Angry', emoji: '🔥', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Hadith', text: 'The strong is not the one who wrestles; the strong is the one who controls himself when angry.', source: 'Sahih al-Bukhari 6114'),
      FeelingResponse(kind: 'Hadith', text: 'When one of you becomes angry, let him say: A’udhu billahi minash-shaytanir-rajim.', source: 'Sahih al-Bukhari 6115 — meaning'),
      FeelingResponse(kind: 'Hadith', text: 'Anger comes from Shaytan, and Shaytan was created from fire — and fire is extinguished with water. So when one of you becomes angry, let him make wudu.', source: 'Sunan Abi Dawud 4784 — sahih'),
    ]),
    Feeling(id: 'lonely', label: 'Lonely', emoji: '🌙', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'And He is with you wherever you are.', source: 'Quran 57:4 — excerpt'),
      FeelingResponse(kind: 'Hadith', text: 'Allah says: I am as My servant thinks of Me, and I am with him when he remembers Me.', source: 'Sahih al-Bukhari 7405 (Hadith Qudsi) — excerpt'),
      FeelingResponse(kind: 'Hadith', text: 'The Quran will come as an intercessor for its companions on the Day of Resurrection.', source: 'Sahih Muslim 804 — meaning'),
    ]),
    Feeling(id: 'overwhelmed', label: 'Overwhelmed', emoji: '⛰️', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Allah does not burden a soul beyond what it can bear.', source: 'Quran 2:286 — excerpt'),
      FeelingResponse(kind: 'Hadith', text: 'The most beloved deeds to Allah are the most consistent, even if small.', source: 'Sahih al-Bukhari 6464'),
      FeelingResponse(kind: 'Door', text: 'One row at a time. The deen was revealed over 23 years — you do not have to carry it all tonight.', source: 'The principle of gradualism — Quran 25:32'),
    ]),
    Feeling(id: 'hopeful', label: 'Hopeful', emoji: '🌅', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Hadith', text: 'None of you should die except thinking well of Allah.', source: 'Sahih Muslim 2877'),
      FeelingResponse(kind: 'Hadith', text: 'Allah is happier with the repentance of His servant than a man who lost his camel in the desert — with his food and water on it — and then finds it.', source: 'Sahih Muslim 2747 — excerpt'),
      FeelingResponse(kind: 'Quran', text: 'And never despair of the relief of Allah. Indeed, no one despairs of Allah’s relief except the disbelieving people.', source: 'Quran 12:87'),
    ]),
    Feeling(id: 'grieving', label: 'Grieving', emoji: '🕯️', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Who, when disaster strikes them, say: Indeed we belong to Allah, and indeed to Him we will return. Those are the ones upon whom are blessings and mercy from their Lord, and those are the guided.', source: 'Quran 2:155–157 — excerpt'),
      FeelingResponse(kind: 'Hadith', text: 'To Allah belongs what He took and what He gave, and everything with Him has an appointed term — so be patient and seek reward.', source: 'Sahih al-Bukhari 1284 — excerpt'),
      FeelingResponse(kind: 'Door', text: 'The Prophet ﷺ wept at the grave of his son Ibrahim and said: "The eye weeps and the heart grieves, and we say only what pleases our Lord."', source: 'Sahih al-Bukhari 1303 — excerpt'),
    ]),
    Feeling(id: 'sin', label: 'Struggling with sin', emoji: '🌱', responses: <FeelingResponse>[
      FeelingResponse(kind: 'Quran', text: 'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins.', source: 'Quran 39:53 — excerpt'),
      FeelingResponse(kind: 'Hadith', text: 'Every son of Adam sins, and the best of those who sin are those who repent.', source: 'Jamiʿ at-Tirmidhi 2499 — hasan'),
      FeelingResponse(kind: 'Hadith', text: 'A man killed ninety-nine souls, then sought repentance — and Allah forgave him. No one stands between you and repentance but despair.', source: 'Sahih Muslim 2766 — the hundred-souls hadith, excerpt'),
    ]),
  ];

  static Feeling byId(String id) =>
      feelings.firstWhere((Feeling f) => f.id == id, orElse: () => feelings.first);

  /// Today's response for a feeling (cycles through its responses by day).
  static FeelingResponse responseFor(String feelingId, DateTime date) {
    final Feeling f = byId(feelingId);
    return f.responses[dayOfYear(date) % f.responses.length];
  }
}
