/// Health & Ruqyah school — the body as an amanah: halal food, sleep,
/// the evil eye and its cure, and the Qur\u2019an as medicine. Built on
/// the huda guides and the Sakina comfort content.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _HlLesson {
  const _HlLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _HlUnit {
  const _HlUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_HlLesson> lessons;
}

const List<_HlUnit> kHealthUnits = <_HlUnit>[
  _HlUnit(
    title: 'The Body as an Amanah',
    frame: 'Your body is a trust — you did not build it, you were lent it. The Prophet \ufdfa said: your body has a right over you (Bukhari 1839).',
    lessons: <_HlLesson>[
      _HlLesson(
        title: 'Eat of the Good Things',
        body: 'O people, eat from the earth what is lawful and good, and do not follow the footsteps of Shaytan (2:168). The halal plate is not a restriction list — it is an invitation to eat well, eat clean, and eat with gratitude.',
        practice: 'Audit one meal this week: is it halal, wholesome, and eaten with His name? Start there.',
      ),
      _HlLesson(
        title: 'The Third of the Stomach',
        body: 'The Prophet \ufdfa said: the son of Adam does not fill any vessel worse than his stomach — a few morsels for his back to stand straight; if he must fill it, then a third for food, a third for drink, a third for breath (Tirmidhi 2380). The oldest diet advice in history, from the one who knew the body\u2019s design.',
        practice: 'Stop eating at two-thirds full for one meal this week. Notice how the afternoon changes.',
      ),
      _HlLesson(
        title: 'Sleep Is Worship\u2019s Fuel',
        body: 'The Prophet \ufdfa said: when one of you goes to bed, let him brush his hand over his bed — for he does not know what came upon it after him — then say: in Your name, my Lord, I lay down my side (Bukhari 6320). Sleep entered the sunna; the night is not a waste, it is the deposit of the morning\u2019s prayer.',
        practice: 'Adopt the bedtime sunna tonight — bismillah, the dua, the side. Sleep as a deposit, not a collapse.',
      ),
      _HlLesson(
        title: 'Moderation in All Things',
        body: 'The Prophet \ufdfa said: the religion is ease (Bukhari 39). And he fasted but did not fast continuously; he prayed but he slept; he worked but he rested. Extremism in worship is not devotion — it is a debt the body will collect.',
        practice: 'Choose one act of worship this week and do it at a sustainable level — then keep it. Consistency is the miracle.',
      ),
    ],
  ),
  _HlUnit(
    title: 'Ruqyah — the Qur\u2019an as Medicine',
    frame: 'And We send down of the Qur\u2019an that which is healing and mercy for the believers (17:82). The verses are medicine; the reciter is the patient.',
    lessons: <_HlLesson>[
      _HlLesson(
        title: 'The Prophet\u2019s Own Ruqyah',
        body: 'When any of his family fell ill, the Prophet \ufdfa would recite: in the name of Allah — I seek refuge in Allah\u2019s might and power from the evil of what I feel and fear (Muslim 2202). Seven times, blowing lightly over the body. The cure begins with refuge, not with the symptom.',
        practice: 'Memorize the ruqyah this week — seven recitations, over your own chest or a loved one\u2019s.',
      ),
      _HlLesson(
        title: 'The Evil Eye Is Real — and Curable',
        body: 'The Prophet \ufdfa said: the evil eye is real, and if anything were to overtake the divine decree, it would be the evil eye (Muslim 2188). And he taught the cure: the mu\u2019awwidhat (the last three surahs) recited over the afflicted. The protection is not paranoia; it is a sunna carried lightly.',
        practice: 'When you admire something — your child, your home, your health — say mashallah, la quwwata illa billah. Guard the blessing by naming its Owner.',
      ),
      _HlLesson(
        title: 'When Medicine and Faith Meet',
        body: 'The Prophet \ufdfa said: Allah did not send down a disease without sending down its cure (Bukhari 5678). Use the medicine — the ruqyah does not cancel the doctor; the doctor does not cancel the ruqyah. Seeking treatment is not weak faith; it is the sunna.',
        practice: 'If you or someone you love is ill: book the appointment AND recite the ruqyah. Both are tawakkul.',
      ),
    ],
  ),
  _HlUnit(
    title: 'The Heart\u2019s Health',
    frame: 'The body\u2019s final organ is the heart — and it has diseases with cures the Qur\u2019an names.',
    lessons: <_HlLesson>[
      _HlLesson(
        title: 'The Day of the Heart\u2019s Surgery',
        body: 'The day when neither wealth nor children will avail, except one who comes to Allah with a sound heart (26:88-89). Every practice in this school — food, sleep, ruqyah, moderation — is finally aimed here. The sound heart is the only luggage that boards.',
        practice: 'Tonight before sleep, ask: what would my heart need to be sound — and what is one thing I could release this week to move toward it?',
      ),
      _HlLesson(
        title: 'Dhikr Is the Heart\u2019s Food',
        body: 'Those who remember Allah standing, sitting, and on their sides (3:191). The heart without dhikr is the body without food — it does not die loudly; it just grows numb. The morning and evening adhkar are the three meals of the soul.',
        practice: 'Attach one dhikr to one daily action this week — the door, the car, the kettle. Let the habit carry the heart.',
      ),
    ],
  ),
];

class HealthSchoolScreen extends StatelessWidget {
  const HealthSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Health & Ruqyah', close: true),
              Text('الصحة',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The body as an amanah — halal food, sleep, the Quran as medicine, the heart\u2019s health',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _HlUnit unit in kHealthUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _HlLesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.title, style: AppText.titleMedium),
                          const SizedBox(height: 6),
                          Text(l.body, style: AppText.body.copyWith(height: 1.65, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: Text('Practice: ${l.practice}',
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, height: 1.5, color: AppColors.gold)),
                          ),
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
