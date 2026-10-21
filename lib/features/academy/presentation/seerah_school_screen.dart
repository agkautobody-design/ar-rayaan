/// Seerah school — the life of the Prophet \ufdfa era by era, each era
/// a row of chapters that open the existing seerah story collection in
/// reading order. Makkah · Madinah · The Farewell — the whole life in
/// one school.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _SeerahEra {
  const _SeerahEra({
    required this.title,
    required this.frame,
    required this.stories,
  });

  final String title;
  final String frame;
  final List<_SeerahStory> stories;
}

class _SeerahStory {
  const _SeerahStory({required this.id, required this.title, required this.note});

  final String id;
  final String title;
  final String note;
}

/// Chapter lists reference assets/stories/seerah.json by id — the school's
/// curriculum IS the collection, walked in order.
const List<_SeerahEra> kSeerahEras = <_SeerahEra>[
  _SeerahEra(
    title: 'Makkah — The Formation',
    frame:
        'Born in the Year of the Elephant, raised an orphan, trusted before he was believed: the Makkan era forms the man. Read these chapters in order — each one stands alone, together they are a life.',
    stories: <_SeerahStory>[
      _SeerahStory(id: 'seerah-01', title: 'The Year of the Elephant', note: 'The hour of birth, and the army that could not enter Makkah.'),
      _SeerahStory(id: 'seerah-02', title: 'The Orphan of Makkah', note: 'Father gone before birth, mother at six, grandfather at eight — and yet al-Amin, the trustworthy.'),
      _SeerahStory(id: 'seerah-03', title: 'Al-Amin, The Trustworthy', note: 'The title Makkah gave him before revelation — character precedes the call.'),
      _SeerahStory(id: 'seerah-04', title: 'The Cave of Hira', note: 'Forty years old, seeking quiet — and the first word is Iqra.'),
      _SeerahStory(id: 'seerah-31', title: 'Iqra — The First Word', note: 'Read, in the name of your Lord. The first revelation chose knowledge.'),
      _SeerahStory(id: 'seerah-05', title: 'Three Years of Whispers', note: 'Secret teaching, then open call — patience measured in years.'),
      _SeerahStory(id: 'seerah-06', title: 'Bilal and the Heavy Sand', note: 'One word — Ahad — heavier than the mountain of sand on his chest.'),
      _SeerahStory(id: 'seerah-07', title: 'The Night of the Journey', note: 'From the Haram to Jerusalem to the seven heavens in one night.'),
      _SeerahStory(id: 'seerah-08', title: 'The Boycott', note: 'Three years of siege in the valley — and the believers stayed.'),
      _SeerahStory(id: 'seerah-09', title: 'The First Hijrah', note: 'To Abyssinia, where a just king protected the weak — Musab carried the message.'),
      _SeerahStory(id: 'seerah-10', title: 'The Conversion of Umar', note: 'The man who came to kill left proclaiming — strength that found its direction.'),
      _SeerahStory(id: 'seerah-11', title: 'Taif', note: 'Stoned and bleeding, and he prayed for the grandchildren of the people who stoned him.'),
      _SeerahStory(id: 'seerah-12', title: 'The Pledges of Aqabah', note: 'The people of Yathrib reach for the Prophet — a city will be renamed after him.'),
    ],
  ),
  _SeerahEra(
    title: 'Madinah — The Building',
    frame:
        'The Hijrah turns a persecuted group into a community with a charter, a qibla, and a future. Madinah is where the message learns to build: law, mercy, and the hardest tests of leadership.',
    stories: <_SeerahStory>[
      _SeerahStory(id: 'seerah-13', title: 'The Hijrah', note: 'The cave where a spider\u2019s web and a dove\u2019s nest turned back an empire.'),
      _SeerahStory(id: 'seerah-14', title: 'The Arrival in Madinah', note: 'The camel stopped at the place of the masjid — Quba, then the date-palm land.'),
      _SeerahStory(id: 'seerah-15', title: 'The Charter of Madinah', note: 'One document binding Muslims, Jews, and pagans of the city — the first pluralist charter.'),
      _SeerahStory(id: 'seerah-16', title: 'The Qibla Changes', note: 'From Jerusalem to Makkah — the direction turns, the meaning deepens.'),
      _SeerahStory(id: 'seerah-17', title: 'Badr: The Two Armies Meet', note: '313 against a thousand — and Allah\u2019s help came with discipline, not numbers.'),
      _SeerahStory(id: 'seerah-18', title: 'Badr: The Prisoners', note: 'The Prophet ﷺ ransomed literate prisoners by teaching — the captor became a school.'),
      _SeerahStory(id: 'seerah-19', title: 'Uhud: The Day the Line Broke', note: 'Fifty archers told to hold a hill — and the lesson of obedience cost seventy lives.'),
      _SeerahStory(id: 'seerah-20', title: 'Uhud: Hamza and the Women', note: 'The uncle of the Prophet fell; the women of Uhud did not — Safiyya on the battlefield.'),
      _SeerahStory(id: 'seerah-21', title: 'The Trench', note: 'A city defended with a ditch and words — Salman\u2019s idea, thirty days of digging.'),
      _SeerahStory(id: 'seerah-22', title: 'Hudaybiyyah', note: 'The treaty everyone hated became the conquest of Arabia — Allah named it a clear victory (48:1).'),
      _SeerahStory(id: 'seerah-23', title: 'Khaybar', note: 'After the broken truce, the fortress fell — and the Prophet ate poisoned food that would carry to his final illness.'),
      _SeerahStory(id: 'seerah-25', title: 'Hunayn and the Return to Taif', note: 'Victory over ten thousand at Hunayn, and he went back to the city that stoned him — to call them again.'),
    ],
  ),
  _SeerahEra(
    title: 'The Farewell — The Completing',
    frame:
        'Makkah opens without blood, and the Prophet \ufdfa stands at Arafat delivering the sermon that still governs the ummah. The final chapters are the bequest.',
    stories: <_SeerahStory>[
      _SeerahStory(id: 'seerah-24', title: 'The Conquest of Makkah', note: 'Ten thousand entered the city of his birth — and he declared general amnesty.'),
      _SeerahStory(id: 'seerah-26', title: 'Tabuk', note: 'The hardest expedition — nine days\u2019 march in the heat, and the hypocrites exposed by their absence.'),
      _SeerahStory(id: 'seerah-27', title: 'The Farewell Sermon', note: 'No Arab has superiority over a non-Arab — blood and wealth and honor are sacred: the constitution of the ummah.'),
      _SeerahStory(id: 'seerah-28', title: 'The Passing of the Prophet \ufdfa', note: 'He died in Aisha\u2019s arms with his head on her lap, in the room beside the masjid — and the community learned to live without him.'),
      _SeerahStory(id: 'seerah-29', title: 'What He Left', note: 'No silver, no gold, no land — he left the Qur\u2019an and the example, and they have outlived every empire.'),
      _SeerahStory(id: 'seerah-30', title: 'Reflections: The Man Who Walked Beside Us', note: 'Aisha was asked about his character; she said: his character was the Qur\u2019an. Read this one last.'),
    ],
  ),
];

class SeerahSchoolScreen extends StatelessWidget {
  const SeerahSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Seerah', close: true),
              Text('السيرة',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The life of the Prophet \ufdfa — Makkah, Madinah, the Farewell — era by era',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _SeerahEra era in kSeerahEras) ...<Widget>[
                Text(era.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(era.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _SeerahStory st in era.stories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(st.title, style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                          const SizedBox(height: 4),
                          Text(st.note, style: AppText.bodyMuted.copyWith(
                              fontSize: 12, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
