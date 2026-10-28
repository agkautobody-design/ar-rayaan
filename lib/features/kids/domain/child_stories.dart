/// Child-level retellings of the seven stories child mode opens, one short
/// paragraph for each chapter of the story (same order and count as the
/// chapters in assets/stories). They keep to what the Qur'an states, add no
/// detail of their own, and leave out the adult commentary and citations: the
/// sources stay at the foot of each story page. A child reads these in place
/// of the long chapter text.
///
/// Reviewed in the scholar register (child-mode stories, child retellings).
const Map<String, List<String>> kChildStoryText = <String, List<String>>{
  'prophet-adam': <String>[
    'Allah told the angels that He would put a person on the earth. Allah '
        'taught Adam the names of things, and the angels saw how much Adam '
        'could learn.',
    'Allah told the angels to bow to Adam, to show respect. They all did, '
        'except Iblis. He said no, because he thought he was better than '
        'Adam. Being proud like that was wrong.',
    'Adam and his wife lived in the Garden. Allah told them not to go near '
        'one tree. Shaytan whispered to them, and they ate from it. They were '
        'sorry and asked Allah to forgive them, and Allah forgave them.',
    'Allah sent Adam and his wife down to live on the earth. He promised to '
        'send them guidance. Whoever follows Allah’s guidance will not '
        'be afraid or sad.',
  ],
  'prophet-nuh': <String>[
    'Nuh told his people to worship only Allah. He called them for a very '
        'long time, by night and by day, but only a few of them listened.',
    'Allah told Nuh to build a ship. Some of his people laughed at him. Nuh '
        'kept trusting Allah and kept building.',
    'Then the flood came. Nuh took the believers and pairs of animals on '
        'the ship. He called to his son to come aboard, but his son did not '
        'listen.',
    'Then Allah told the water to go down, and the ship came to rest on a '
        'mountain. Nuh and the people with him were safe.',
    'Nuh was patient for a very long time. Allah tells us that the best end '
        'is for those who are patient and try to do right.',
  ],
  'prophet-yunus': <String>[
    'Yunus was a messenger of Allah. He left his people because he was upset '
        'with them, and he left before Allah had allowed it.',
    'A big fish swallowed him, and he was in the dark. Yunus said: there is '
        'no god but You, glory to You, I was in the wrong. Allah heard him '
        'and saved him.',
    'Allah put Yunus safely on the shore and made a plant grow over him. '
        'Later, his people believed in Allah.',
  ],
  'prophet-ayyub': <String>[
    'Ayyub was very unwell and in hardship. He stayed patient, and he called '
        'out to Allah: I am in trouble, and You are the kindest of all those '
        'who are kind.',
    'Allah answered him. He told Ayyub to stamp his foot, and a spring of '
        'cool water came out. Ayyub washed and drank, and what was hurting '
        'him was taken away.',
    'Allah gave Ayyub his family back, and more like them, as a mercy from '
        'Him. Ayyub is a good example of patience.',
  ],
  'prophet-sulayman': <String>[
    'Sulayman was a prophet and a king, the son of Dawud. He asked Allah to '
        'forgive him, and Allah gave him a great kingdom.',
    'Allah let Sulayman understand the speech of the birds. One day an ant '
        'told the other ants to go into their homes, so that they would not '
        'be crushed. Sulayman smiled and thanked Allah.',
    'A bird called the hoopoe told Sulayman about a queen and her people. '
        'Sulayman sent her a letter that began: in the name of Allah, the '
        'Kind, the Merciful.',
    'Allah asked Sulayman’s family to be thankful. Sulayman thanked '
        'Allah for all that he had been given.',
  ],
  'tale-cave-people': <String>[
    'Some young people believed in Allah when most of the people around them '
        'did not. They were brave, and Allah made them stronger in their '
        'faith.',
    'They went into a cave, and Allah put them to sleep for a very, very '
        'long time. The Qur’an says they stayed there three hundred '
        'years, and nine more.',
    'When they woke up, they thought they had slept for only a day. Allah '
        'knows best how long it was. The story reminds us that Allah’s '
        'promise is true.',
  ],
  'tale-two-gardens': <String>[
    'A man had two beautiful gardens, with grapes, date palms and a river. '
        'He was proud, and he said that he thought they would never be '
        'lost.',
    'His friend told him to be thankful to Allah and not proud of what he '
        'had. The man did not listen.',
    'Then his gardens were ruined. He was sad, and he wished he had not been '
        'proud. We should always thank Allah for what we have.',
  ],
};

/// The child's retelling of chapter [index] of story [storyId], or null when
/// there is none (the chapter text is then used).
String? childStoryChapter(String storyId, int index) {
  final List<String>? parts = kChildStoryText[storyId];
  if (parts == null || index < 0 || index >= parts.length) return null;
  return parts[index];
}
