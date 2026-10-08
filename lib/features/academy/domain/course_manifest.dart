/// The Academy course manifest - curricula as *references* to content
/// owned by other modules plus Academy-authored lessons.
///
/// Wave 1 seeds: The Path units 0-1 (welcome + purification) with real
/// steps; the four schools as honest "coming soon" cards.
library;

import 'academy_models.dart';
import 'assessment_engine.dart';

/// Embed refs -> app routes. Content stays with its owning module.
const Map<String, String> kEmbedRoutes = <String, String>{
  'prayer.times': '/prayer',
  'zakat.guided': '/zakat',
  'quran.reader': '/quran',
  'adhkar.morning': '/adhkar',
  'hadith.daily': '/hadith',
};

/// The Path - zero-to-practicing curriculum. Units 2-9 land in Wave 2
/// with their authored content; the structure is fixed now.
final List<AcademyCourse> kAcademyCourses = <AcademyCourse>[
  const AcademyCourse(
    id: 'the-path',
    titleKey: 'path.title',
    subtitleKey: 'path.subtitle',
    units: <AcademyUnit>[
      AcademyUnit(
        id: 'path.u0',
        courseId: 'the-path',
        titleKey: 'path.u0.title',
        subtitleKey: 'path.u0.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u0.l1',
            unitId: 'path.u0',
            courseId: 'the-path',
            titleKey: 'path.u0.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u0.s1.title',
                bodyKey: 'path.u0.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u0.s2.title',
                bodyKey: 'path.u0.s2.body',
              ),
              AcademyStep(
                kind: AcademyStepKind.action,
                titleKey: 'path.u0.s3.title',
                bodyKey: 'path.u0.s3.body',
                route: '/hadi',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u0.s4.title',
                bodyKey: 'path.u0.s4.body',
                honestyLabel: '[Established]',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u1',
        courseId: 'the-path',
        titleKey: 'path.u1.title',
        subtitleKey: 'path.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u1.l1',
            unitId: 'path.u1',
            courseId: 'the-path',
            titleKey: 'path.u1.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u1.s1.title',
                bodyKey: 'path.u1.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u1.s2.title',
                bodyKey: 'path.u1.s2.body',
                ref: 'prayer.times',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u1.s3.title',
                bodyKey: 'path.u1.s3.body',
              ),
              AcademyStep(
                kind: AcademyStepKind.check,
                titleKey: 'path.u1.check.title',
                assessmentId: 'wudu.basics',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u2',
        courseId: 'the-path',
        titleKey: 'path.u2.title',
        subtitleKey: 'path.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u2.l1',
            unitId: 'path.u2',
            courseId: 'the-path',
            titleKey: 'path.u2.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u2.s1.title',
                bodyKey: 'path.u2.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u2.s2.title',
                bodyKey: 'path.u2.s2.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u2.s3.title',
                bodyKey: 'path.u2.s3.body',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u3',
        courseId: 'the-path',
        titleKey: 'path.u3.title',
        subtitleKey: 'path.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u3.l1',
            unitId: 'path.u3',
            courseId: 'the-path',
            titleKey: 'path.u3.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u3.s1.title',
                bodyKey: 'path.u3.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u3.s2.title',
                bodyKey: 'path.u3.s2.body',
                ref: 'quran.reader',
              ),
              AcademyStep(
                kind: AcademyStepKind.check,
                titleKey: 'path.u3.check.title',
                assessmentId: 'fatihah.meaning',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u4',
        courseId: 'the-path',
        titleKey: 'path.u4.title',
        subtitleKey: 'path.u4.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u4.l1',
            unitId: 'path.u4',
            courseId: 'the-path',
            titleKey: 'path.u4.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u4.s1.title',
                bodyKey: 'path.u4.s1.body',
                ref: 'prayer.times',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u4.s2.title',
                bodyKey: 'path.u4.s2.body',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u4.s3.title',
                bodyKey: 'path.u4.s3.body',
                honestyLabel: '[Interpretive]',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u5',
        courseId: 'the-path',
        titleKey: 'path.u5.title',
        subtitleKey: 'path.u5.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u5.l1',
            unitId: 'path.u5',
            courseId: 'the-path',
            titleKey: 'path.u5.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u5.s1.title',
                bodyKey: 'path.u5.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u5.s2.title',
                bodyKey: 'path.u5.s2.body',
                ref: 'adhkar.morning',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u6',
        courseId: 'the-path',
        titleKey: 'path.u6.title',
        subtitleKey: 'path.u6.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u6.l1',
            unitId: 'path.u6',
            courseId: 'the-path',
            titleKey: 'path.u6.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u6.s1.title',
                bodyKey: 'path.u6.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u6.s2.title',
                bodyKey: 'path.u6.s2.body',
                ref: 'zakat.guided',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u7',
        courseId: 'the-path',
        titleKey: 'path.u7.title',
        subtitleKey: 'path.u7.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u7.l1',
            unitId: 'path.u7',
            courseId: 'the-path',
            titleKey: 'path.u7.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.embed,
                titleKey: 'path.u7.s1.title',
                bodyKey: 'path.u7.s1.body',
                ref: 'adhkar.morning',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u7.s2.title',
                bodyKey: 'path.u7.s2.body',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u8',
        courseId: 'the-path',
        titleKey: 'path.u8.title',
        subtitleKey: 'path.u8.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u8.l1',
            unitId: 'path.u8',
            courseId: 'the-path',
            titleKey: 'path.u8.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u8.s1.title',
                bodyKey: 'path.u8.s1.body',
                honestyLabel: '[Established]',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u8.s2.title',
                bodyKey: 'path.u8.s2.body',
              ),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'path.u9',
        courseId: 'the-path',
        titleKey: 'path.u9.title',
        subtitleKey: 'path.u9.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'path.u9.l1',
            unitId: 'path.u9',
            courseId: 'the-path',
            titleKey: 'path.u9.l1.title',
            steps: <AcademyStep>[
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u9.s1.title',
                bodyKey: 'path.u9.s1.body',
              ),
              AcademyStep(
                kind: AcademyStepKind.text,
                titleKey: 'path.u9.s2.title',
                bodyKey: 'path.u9.s2.body',
                honestyLabel: '[Established]',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  const AcademyCourse(
    id: 'letters',
    titleKey: 'school.letters.title',
    subtitleKey: 'school.letters.subtitle',
    available: false,
    units: <AcademyUnit>[],
  ),
  const AcademyCourse(
    id: 'recitation',
    titleKey: 'school.recitation.title',
    subtitleKey: 'school.recitation.subtitle',
    available: false,
    units: <AcademyUnit>[],
  ),
  const AcademyCourse(
    id: 'quranic-arabic',
    titleKey: 'school.arabic.title',
    subtitleKey: 'school.arabic.subtitle',
    available: false,
    units: <AcademyUnit>[],
  ),
  const AcademyCourse(
    id: 'understanding',
    titleKey: 'school.understanding.title',
    subtitleKey: 'school.understanding.subtitle',
    available: false,
    units: <AcademyUnit>[],
  ),
];

/// Assessment catalog (knowledge checks referenced by `check` steps).
final Map<String, List<AssessmentItem>> kAssessments =
    <String, List<AssessmentItem>>{
  'fatihah.meaning': <AssessmentItem>[
    const AssessmentItem(
      id: 'fatihah.meaning.1',
      promptKey: 'check.fatihah.q1',
      choices: <String>[
        'check.fatihah.q1.a',
        'check.fatihah.q1.b',
        'check.fatihah.q1.c',
      ],
      correctIndex: 0,
      reteachKey: 'check.fatihah.q1.reteach',
    ),
  ],
  'wudu.basics': <AssessmentItem>[
    const AssessmentItem(
      id: 'wudu.basics.1',
      promptKey: 'check.wudu.q1',
      choices: <String>['check.wudu.q1.a', 'check.wudu.q1.b', 'check.wudu.q1.c'],
      correctIndex: 0,
      reteachKey: 'check.wudu.q1.reteach',
    ),
    const AssessmentItem(
      id: 'wudu.basics.2',
      promptKey: 'check.wudu.q2',
      choices: <String>['check.wudu.q1.a', 'check.wudu.q1.b', 'check.wudu.q1.c'],
      correctIndex: 1,
      reteachKey: 'check.wudu.q2.reteach',
    ),
  ],
};

/// Find a lesson by ids, or null.
AcademyLesson? findLesson(String courseId, String unitId, String lessonId) {
  for (final AcademyCourse c in kAcademyCourses) {
    if (c.id != courseId) continue;
    for (final AcademyUnit u in c.units) {
      if (u.id != unitId) continue;
      for (final AcademyLesson l in u.lessons) {
        if (l.id == lessonId) return l;
      }
    }
  }
  return null;
}
