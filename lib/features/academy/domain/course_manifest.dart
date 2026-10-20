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
          AcademyLesson(
            id: 'path.u4.l2',
            unitId: 'path.u4',
            courseId: 'the-path',
            titleKey: 'path.u4.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u4.l2.s1.title', bodyKey: 'path.u4.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u4.l2.s2.title', bodyKey: 'path.u4.l2.s2.body', route: '/zakat'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u4.l2.s3.title', bodyKey: 'path.u4.l2.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u4.l3',
            unitId: 'path.u4',
            courseId: 'the-path',
            titleKey: 'path.u4.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u4.l3.s1.title', bodyKey: 'path.u4.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.embed, ref: 'zakat.guided', titleKey: 'path.u4.l3.s2.title', bodyKey: 'path.u4.l3.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u4.l3.s3.title', bodyKey: 'path.u4.l3.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u4.l4',
            unitId: 'path.u4',
            courseId: 'the-path',
            titleKey: 'path.u4.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u4.l4.s1.title', bodyKey: 'path.u4.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u4.l4.s2.title', bodyKey: 'path.u4.l4.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u4.l4.s3.title', bodyKey: 'path.u4.l4.s3.body'),
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
          AcademyLesson(
            id: 'path.u5.l2',
            unitId: 'path.u5',
            courseId: 'the-path',
            titleKey: 'path.u5.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u5.l2.s1.title', bodyKey: 'path.u5.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u5.l2.s2.title', bodyKey: 'path.u5.l2.s2.body', route: '/huda'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u5.l2.s3.title', bodyKey: 'path.u5.l2.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u5.l3',
            unitId: 'path.u5',
            courseId: 'the-path',
            titleKey: 'path.u5.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u5.l3.s1.title', bodyKey: 'path.u5.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u5.l3.s2.title', bodyKey: 'path.u5.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u5.l4',
            unitId: 'path.u5',
            courseId: 'the-path',
            titleKey: 'path.u5.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u5.l4.s1.title', bodyKey: 'path.u5.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u5.l4.s2.title', bodyKey: 'path.u5.l4.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u5.l4.s3.title', bodyKey: 'path.u5.l4.s3.body'),
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
          AcademyLesson(
            id: 'path.u6.l2',
            unitId: 'path.u6',
            courseId: 'the-path',
            titleKey: 'path.u6.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u6.l2.s1.title', bodyKey: 'path.u6.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u6.l2.s2.title', bodyKey: 'path.u6.l2.s2.body', route: '/academy/hajj-umrah-pack'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u6.l2.s3.title', bodyKey: 'path.u6.l2.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u6.l3',
            unitId: 'path.u6',
            courseId: 'the-path',
            titleKey: 'path.u6.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u6.l3.s1.title', bodyKey: 'path.u6.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u6.l3.s2.title', bodyKey: 'path.u6.l3.s2.body'),
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
          AcademyLesson(
            id: 'path.u7.l2',
            unitId: 'path.u7',
            courseId: 'the-path',
            titleKey: 'path.u7.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u7.l2.s1.title', bodyKey: 'path.u7.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u7.l2.s2.title', bodyKey: 'path.u7.l2.s2.body', route: '/finance'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u7.l2.s3.title', bodyKey: 'path.u7.l2.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u7.l3',
            unitId: 'path.u7',
            courseId: 'the-path',
            titleKey: 'path.u7.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u7.l3.s1.title', bodyKey: 'path.u7.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u7.l3.s2.title', bodyKey: 'path.u7.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u7.l4',
            unitId: 'path.u7',
            courseId: 'the-path',
            titleKey: 'path.u7.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u7.l4.s1.title', bodyKey: 'path.u7.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u7.l4.s2.title', bodyKey: 'path.u7.l4.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u7.l4.s3.title', bodyKey: 'path.u7.l4.s3.body'),
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
          AcademyLesson(
            id: 'path.u8.l2',
            unitId: 'path.u8',
            courseId: 'the-path',
            titleKey: 'path.u8.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u8.l2.s1.title', bodyKey: 'path.u8.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u8.l2.s2.title', bodyKey: 'path.u8.l2.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u8.l2.s3.title', bodyKey: 'path.u8.l2.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u8.l3',
            unitId: 'path.u8',
            courseId: 'the-path',
            titleKey: 'path.u8.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u8.l3.s1.title', bodyKey: 'path.u8.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u8.l3.s2.title', bodyKey: 'path.u8.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u8.l4',
            unitId: 'path.u8',
            courseId: 'the-path',
            titleKey: 'path.u8.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u8.l4.s1.title', bodyKey: 'path.u8.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u8.l4.s2.title', bodyKey: 'path.u8.l4.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u8.l4.s3.title', bodyKey: 'path.u8.l4.s3.body'),
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
          AcademyLesson(
            id: 'path.u9.l2',
            unitId: 'path.u9',
            courseId: 'the-path',
            titleKey: 'path.u9.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u9.l2.s1.title', bodyKey: 'path.u9.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u9.l2.s2.title', bodyKey: 'path.u9.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u9.l3',
            unitId: 'path.u9',
            courseId: 'the-path',
            titleKey: 'path.u9.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u9.l3.s1.title', bodyKey: 'path.u9.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u9.l3.s2.title', bodyKey: 'path.u9.l3.s2.body', route: '/stories'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u9.l3.s3.title', bodyKey: 'path.u9.l3.s3.body'),
            ],
          ),
          AcademyLesson(
            id: 'path.u9.l4',
            unitId: 'path.u9',
            courseId: 'the-path',
            titleKey: 'path.u9.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'path.u9.l4.s1.title', bodyKey: 'path.u9.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'path.u9.l4.s2.title', bodyKey: 'path.u9.l4.s2.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'path.u9.l4.s3.title', bodyKey: 'path.u9.l4.s3.body'),
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
  // ── Manifest courses (Batch 6) ──
    AcademyCourse(
      id: 'arabic-language',
      titleKey: 'course.arabic-language.title',
      subtitleKey: 'course.arabic-language.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'arabic.u1',
        courseId: 'arabic-language',
        titleKey: 'arabic.u1.title',
        subtitleKey: 'arabic.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'arabic.u1.l1',
            unitId: 'arabic.u1',
            courseId: 'arabic-language',
            titleKey: 'arabic.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u1.l1.s1.title', bodyKey: 'arabic.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'arabic.u1.l1.s2.title', bodyKey: 'arabic.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'arabic.u1.l2',
            unitId: 'arabic.u1',
            courseId: 'arabic-language',
            titleKey: 'arabic.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u1.l2.s1.title', bodyKey: 'arabic.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'arabic.u1.l2.s2.title', bodyKey: 'arabic.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'arabic.u1.l3',
            unitId: 'arabic.u1',
            courseId: 'arabic-language',
            titleKey: 'arabic.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u1.l3.s1.title', bodyKey: 'arabic.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'arabic.u1.l3.s2.title', bodyKey: 'arabic.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'arabic.u1.l4',
            unitId: 'arabic.u1',
            courseId: 'arabic-language',
            titleKey: 'arabic.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u1.l4.s1.title', bodyKey: 'arabic.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'arabic.u1.l4.s2.title', bodyKey: 'arabic.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'arabic.u2',
        courseId: 'arabic-language',
        titleKey: 'arabic.u2.title',
        subtitleKey: 'arabic.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'arabic.u2.l1',
            unitId: 'arabic.u2',
            courseId: 'arabic-language',
            titleKey: 'arabic.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u2.l1.s1.title', bodyKey: 'arabic.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'arabic.u2.l1.s2.title', bodyKey: 'arabic.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'arabic.u2.l2',
            unitId: 'arabic.u2',
            courseId: 'arabic-language',
            titleKey: 'arabic.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u2.l2.s1.title', bodyKey: 'arabic.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'arabic.u2.l2.s2.title', bodyKey: 'arabic.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'arabic.u2.l3',
            unitId: 'arabic.u2',
            courseId: 'arabic-language',
            titleKey: 'arabic.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'arabic.u2.l3.s1.title', bodyKey: 'arabic.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'arabic.u2.l3.s2.title', bodyKey: 'arabic.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'aqeedah',
      titleKey: 'course.aqeedah.title',
      subtitleKey: 'course.aqeedah.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'aqid.u1',
        courseId: 'aqeedah',
        titleKey: 'aqid.u1.title',
        subtitleKey: 'aqid.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'aqid.u1.l1',
            unitId: 'aqid.u1',
            courseId: 'aqeedah',
            titleKey: 'aqid.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u1.l1.s1.title', bodyKey: 'aqid.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u1.l1.s2.title', bodyKey: 'aqid.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u1.l2',
            unitId: 'aqid.u1',
            courseId: 'aqeedah',
            titleKey: 'aqid.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u1.l2.s1.title', bodyKey: 'aqid.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u1.l2.s2.title', bodyKey: 'aqid.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u1.l3',
            unitId: 'aqid.u1',
            courseId: 'aqeedah',
            titleKey: 'aqid.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u1.l3.s1.title', bodyKey: 'aqid.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u1.l3.s2.title', bodyKey: 'aqid.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u1.l4',
            unitId: 'aqid.u1',
            courseId: 'aqeedah',
            titleKey: 'aqid.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u1.l4.s1.title', bodyKey: 'aqid.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'aqid.u1.l4.s2.title', bodyKey: 'aqid.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'aqid.u2',
        courseId: 'aqeedah',
        titleKey: 'aqid.u2.title',
        subtitleKey: 'aqid.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'aqid.u2.l1',
            unitId: 'aqid.u2',
            courseId: 'aqeedah',
            titleKey: 'aqid.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u2.l1.s1.title', bodyKey: 'aqid.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u2.l1.s2.title', bodyKey: 'aqid.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u2.l2',
            unitId: 'aqid.u2',
            courseId: 'aqeedah',
            titleKey: 'aqid.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u2.l2.s1.title', bodyKey: 'aqid.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u2.l2.s2.title', bodyKey: 'aqid.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u2.l3',
            unitId: 'aqid.u2',
            courseId: 'aqeedah',
            titleKey: 'aqid.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u2.l3.s1.title', bodyKey: 'aqid.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'aqid.u2.l3.s2.title', bodyKey: 'aqid.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'aqid.u3',
        courseId: 'aqeedah',
        titleKey: 'aqid.u3.title',
        subtitleKey: 'aqid.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'aqid.u3.l1',
            unitId: 'aqid.u3',
            courseId: 'aqeedah',
            titleKey: 'aqid.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u3.l1.s1.title', bodyKey: 'aqid.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u3.l1.s2.title', bodyKey: 'aqid.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u3.l2',
            unitId: 'aqid.u3',
            courseId: 'aqeedah',
            titleKey: 'aqid.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u3.l2.s1.title', bodyKey: 'aqid.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u3.l2.s2.title', bodyKey: 'aqid.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'aqid.u3.l3',
            unitId: 'aqid.u3',
            courseId: 'aqeedah',
            titleKey: 'aqid.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'aqid.u3.l3.s1.title', bodyKey: 'aqid.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'aqid.u3.l3.s2.title', bodyKey: 'aqid.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'character',
      titleKey: 'course.character.title',
      subtitleKey: 'course.character.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'char.u1',
        courseId: 'character',
        titleKey: 'char.u1.title',
        subtitleKey: 'char.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'char.u1.l1',
            unitId: 'char.u1',
            courseId: 'character',
            titleKey: 'char.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u1.l1.s1.title', bodyKey: 'char.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u1.l1.s2.title', bodyKey: 'char.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u1.l2',
            unitId: 'char.u1',
            courseId: 'character',
            titleKey: 'char.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u1.l2.s1.title', bodyKey: 'char.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u1.l2.s2.title', bodyKey: 'char.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u1.l3',
            unitId: 'char.u1',
            courseId: 'character',
            titleKey: 'char.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u1.l3.s1.title', bodyKey: 'char.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u1.l3.s2.title', bodyKey: 'char.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u1.l4',
            unitId: 'char.u1',
            courseId: 'character',
            titleKey: 'char.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u1.l4.s1.title', bodyKey: 'char.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u1.l4.s2.title', bodyKey: 'char.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'char.u2',
        courseId: 'character',
        titleKey: 'char.u2.title',
        subtitleKey: 'char.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'char.u2.l1',
            unitId: 'char.u2',
            courseId: 'character',
            titleKey: 'char.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u2.l1.s1.title', bodyKey: 'char.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u2.l1.s2.title', bodyKey: 'char.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u2.l2',
            unitId: 'char.u2',
            courseId: 'character',
            titleKey: 'char.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u2.l2.s1.title', bodyKey: 'char.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u2.l2.s2.title', bodyKey: 'char.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u2.l3',
            unitId: 'char.u2',
            courseId: 'character',
            titleKey: 'char.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u2.l3.s1.title', bodyKey: 'char.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u2.l3.s2.title', bodyKey: 'char.u2.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u2.l4',
            unitId: 'char.u2',
            courseId: 'character',
            titleKey: 'char.u2.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u2.l4.s1.title', bodyKey: 'char.u2.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u2.l4.s2.title', bodyKey: 'char.u2.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'char.u3',
        courseId: 'character',
        titleKey: 'char.u3.title',
        subtitleKey: 'char.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'char.u3.l1',
            unitId: 'char.u3',
            courseId: 'character',
            titleKey: 'char.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u3.l1.s1.title', bodyKey: 'char.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u3.l1.s2.title', bodyKey: 'char.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u3.l2',
            unitId: 'char.u3',
            courseId: 'character',
            titleKey: 'char.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u3.l2.s1.title', bodyKey: 'char.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u3.l2.s2.title', bodyKey: 'char.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u3.l3',
            unitId: 'char.u3',
            courseId: 'character',
            titleKey: 'char.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u3.l3.s1.title', bodyKey: 'char.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u3.l3.s2.title', bodyKey: 'char.u3.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'char.u3.l4',
            unitId: 'char.u3',
            courseId: 'character',
            titleKey: 'char.u3.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'char.u3.l4.s1.title', bodyKey: 'char.u3.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'char.u3.l4.s2.title', bodyKey: 'char.u3.l4.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'family',
      titleKey: 'course.family.title',
      subtitleKey: 'course.family.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'fam.u1',
        courseId: 'family',
        titleKey: 'fam.u1.title',
        subtitleKey: 'fam.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'fam.u1.l1',
            unitId: 'fam.u1',
            courseId: 'family',
            titleKey: 'fam.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u1.l1.s1.title', bodyKey: 'fam.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u1.l1.s2.title', bodyKey: 'fam.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u1.l2',
            unitId: 'fam.u1',
            courseId: 'family',
            titleKey: 'fam.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u1.l2.s1.title', bodyKey: 'fam.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u1.l2.s2.title', bodyKey: 'fam.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u1.l3',
            unitId: 'fam.u1',
            courseId: 'family',
            titleKey: 'fam.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u1.l3.s1.title', bodyKey: 'fam.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u1.l3.s2.title', bodyKey: 'fam.u1.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'fam.u2',
        courseId: 'family',
        titleKey: 'fam.u2.title',
        subtitleKey: 'fam.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'fam.u2.l1',
            unitId: 'fam.u2',
            courseId: 'family',
            titleKey: 'fam.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u2.l1.s1.title', bodyKey: 'fam.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u2.l1.s2.title', bodyKey: 'fam.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u2.l2',
            unitId: 'fam.u2',
            courseId: 'family',
            titleKey: 'fam.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u2.l2.s1.title', bodyKey: 'fam.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u2.l2.s2.title', bodyKey: 'fam.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u2.l3',
            unitId: 'fam.u2',
            courseId: 'family',
            titleKey: 'fam.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u2.l3.s1.title', bodyKey: 'fam.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u2.l3.s2.title', bodyKey: 'fam.u2.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u2.l4',
            unitId: 'fam.u2',
            courseId: 'family',
            titleKey: 'fam.u2.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u2.l4.s1.title', bodyKey: 'fam.u2.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u2.l4.s2.title', bodyKey: 'fam.u2.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'fam.u3',
        courseId: 'family',
        titleKey: 'fam.u3.title',
        subtitleKey: 'fam.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'fam.u3.l1',
            unitId: 'fam.u3',
            courseId: 'family',
            titleKey: 'fam.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u3.l1.s1.title', bodyKey: 'fam.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u3.l1.s2.title', bodyKey: 'fam.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u3.l2',
            unitId: 'fam.u3',
            courseId: 'family',
            titleKey: 'fam.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u3.l2.s1.title', bodyKey: 'fam.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u3.l2.s2.title', bodyKey: 'fam.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'fam.u3.l3',
            unitId: 'fam.u3',
            courseId: 'family',
            titleKey: 'fam.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'fam.u3.l3.s1.title', bodyKey: 'fam.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'fam.u3.l3.s2.title', bodyKey: 'fam.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'youth',
      titleKey: 'course.youth.title',
      subtitleKey: 'course.youth.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'yth.u1',
        courseId: 'youth',
        titleKey: 'yth.u1.title',
        subtitleKey: 'yth.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'yth.u1.l1',
            unitId: 'yth.u1',
            courseId: 'youth',
            titleKey: 'yth.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u1.l1.s1.title', bodyKey: 'yth.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u1.l1.s2.title', bodyKey: 'yth.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u1.l2',
            unitId: 'yth.u1',
            courseId: 'youth',
            titleKey: 'yth.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u1.l2.s1.title', bodyKey: 'yth.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u1.l2.s2.title', bodyKey: 'yth.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u1.l3',
            unitId: 'yth.u1',
            courseId: 'youth',
            titleKey: 'yth.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u1.l3.s1.title', bodyKey: 'yth.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u1.l3.s2.title', bodyKey: 'yth.u1.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'yth.u2',
        courseId: 'youth',
        titleKey: 'yth.u2.title',
        subtitleKey: 'yth.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'yth.u2.l1',
            unitId: 'yth.u2',
            courseId: 'youth',
            titleKey: 'yth.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u2.l1.s1.title', bodyKey: 'yth.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u2.l1.s2.title', bodyKey: 'yth.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u2.l2',
            unitId: 'yth.u2',
            courseId: 'youth',
            titleKey: 'yth.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u2.l2.s1.title', bodyKey: 'yth.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u2.l2.s2.title', bodyKey: 'yth.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u2.l3',
            unitId: 'yth.u2',
            courseId: 'youth',
            titleKey: 'yth.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u2.l3.s1.title', bodyKey: 'yth.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u2.l3.s2.title', bodyKey: 'yth.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'yth.u3',
        courseId: 'youth',
        titleKey: 'yth.u3.title',
        subtitleKey: 'yth.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'yth.u3.l1',
            unitId: 'yth.u3',
            courseId: 'youth',
            titleKey: 'yth.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u3.l1.s1.title', bodyKey: 'yth.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u3.l1.s2.title', bodyKey: 'yth.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u3.l2',
            unitId: 'yth.u3',
            courseId: 'youth',
            titleKey: 'yth.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u3.l2.s1.title', bodyKey: 'yth.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u3.l2.s2.title', bodyKey: 'yth.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'yth.u3.l3',
            unitId: 'yth.u3',
            courseId: 'youth',
            titleKey: 'yth.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'yth.u3.l3.s1.title', bodyKey: 'yth.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'yth.u3.l3.s2.title', bodyKey: 'yth.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'womens',
      titleKey: 'course.womens.title',
      subtitleKey: 'course.womens.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'wmns.u1',
        courseId: 'womens',
        titleKey: 'wmns.u1.title',
        subtitleKey: 'wmns.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'wmns.u1.l1',
            unitId: 'wmns.u1',
            courseId: 'womens',
            titleKey: 'wmns.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u1.l1.s1.title', bodyKey: 'wmns.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u1.l1.s2.title', bodyKey: 'wmns.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u1.l2',
            unitId: 'wmns.u1',
            courseId: 'womens',
            titleKey: 'wmns.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u1.l2.s1.title', bodyKey: 'wmns.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u1.l2.s2.title', bodyKey: 'wmns.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u1.l3',
            unitId: 'wmns.u1',
            courseId: 'womens',
            titleKey: 'wmns.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u1.l3.s1.title', bodyKey: 'wmns.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u1.l3.s2.title', bodyKey: 'wmns.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u1.l4',
            unitId: 'wmns.u1',
            courseId: 'womens',
            titleKey: 'wmns.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u1.l4.s1.title', bodyKey: 'wmns.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u1.l4.s2.title', bodyKey: 'wmns.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'wmns.u2',
        courseId: 'womens',
        titleKey: 'wmns.u2.title',
        subtitleKey: 'wmns.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'wmns.u2.l1',
            unitId: 'wmns.u2',
            courseId: 'womens',
            titleKey: 'wmns.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u2.l1.s1.title', bodyKey: 'wmns.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u2.l1.s2.title', bodyKey: 'wmns.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u2.l2',
            unitId: 'wmns.u2',
            courseId: 'womens',
            titleKey: 'wmns.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u2.l2.s1.title', bodyKey: 'wmns.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u2.l2.s2.title', bodyKey: 'wmns.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u2.l3',
            unitId: 'wmns.u2',
            courseId: 'womens',
            titleKey: 'wmns.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u2.l3.s1.title', bodyKey: 'wmns.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u2.l3.s2.title', bodyKey: 'wmns.u2.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u2.l4',
            unitId: 'wmns.u2',
            courseId: 'womens',
            titleKey: 'wmns.u2.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u2.l4.s1.title', bodyKey: 'wmns.u2.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u2.l4.s2.title', bodyKey: 'wmns.u2.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'wmns.u3',
        courseId: 'womens',
        titleKey: 'wmns.u3.title',
        subtitleKey: 'wmns.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'wmns.u3.l1',
            unitId: 'wmns.u3',
            courseId: 'womens',
            titleKey: 'wmns.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u3.l1.s1.title', bodyKey: 'wmns.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u3.l1.s2.title', bodyKey: 'wmns.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u3.l2',
            unitId: 'wmns.u3',
            courseId: 'womens',
            titleKey: 'wmns.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u3.l2.s1.title', bodyKey: 'wmns.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u3.l2.s2.title', bodyKey: 'wmns.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u3.l3',
            unitId: 'wmns.u3',
            courseId: 'womens',
            titleKey: 'wmns.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u3.l3.s1.title', bodyKey: 'wmns.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u3.l3.s2.title', bodyKey: 'wmns.u3.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u3.l4',
            unitId: 'wmns.u3',
            courseId: 'womens',
            titleKey: 'wmns.u3.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u3.l4.s1.title', bodyKey: 'wmns.u3.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u3.l4.s2.title', bodyKey: 'wmns.u3.l4.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u3.l5',
            unitId: 'wmns.u3',
            courseId: 'womens',
            titleKey: 'wmns.u3.l5.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u3.l5.s1.title', bodyKey: 'wmns.u3.l5.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u3.l5.s2.title', bodyKey: 'wmns.u3.l5.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'wmns.u4',
        courseId: 'womens',
        titleKey: 'wmns.u4.title',
        subtitleKey: 'wmns.u4.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'wmns.u4.l1',
            unitId: 'wmns.u4',
            courseId: 'womens',
            titleKey: 'wmns.u4.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u4.l1.s1.title', bodyKey: 'wmns.u4.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u4.l1.s2.title', bodyKey: 'wmns.u4.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u4.l2',
            unitId: 'wmns.u4',
            courseId: 'womens',
            titleKey: 'wmns.u4.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u4.l2.s1.title', bodyKey: 'wmns.u4.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u4.l2.s2.title', bodyKey: 'wmns.u4.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u4.l3',
            unitId: 'wmns.u4',
            courseId: 'womens',
            titleKey: 'wmns.u4.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u4.l3.s1.title', bodyKey: 'wmns.u4.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u4.l3.s2.title', bodyKey: 'wmns.u4.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'wmns.u4.l4',
            unitId: 'wmns.u4',
            courseId: 'womens',
            titleKey: 'wmns.u4.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'wmns.u4.l4.s1.title', bodyKey: 'wmns.u4.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'wmns.u4.l4.s2.title', bodyKey: 'wmns.u4.l4.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'transactions',
      titleKey: 'course.transactions.title',
      subtitleKey: 'course.transactions.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'trx.u1',
        courseId: 'transactions',
        titleKey: 'trx.u1.title',
        subtitleKey: 'trx.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'trx.u1.l1',
            unitId: 'trx.u1',
            courseId: 'transactions',
            titleKey: 'trx.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u1.l1.s1.title', bodyKey: 'trx.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u1.l1.s2.title', bodyKey: 'trx.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u1.l2',
            unitId: 'trx.u1',
            courseId: 'transactions',
            titleKey: 'trx.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u1.l2.s1.title', bodyKey: 'trx.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u1.l2.s2.title', bodyKey: 'trx.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u1.l3',
            unitId: 'trx.u1',
            courseId: 'transactions',
            titleKey: 'trx.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u1.l3.s1.title', bodyKey: 'trx.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u1.l3.s2.title', bodyKey: 'trx.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u1.l4',
            unitId: 'trx.u1',
            courseId: 'transactions',
            titleKey: 'trx.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u1.l4.s1.title', bodyKey: 'trx.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u1.l4.s2.title', bodyKey: 'trx.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'trx.u2',
        courseId: 'transactions',
        titleKey: 'trx.u2.title',
        subtitleKey: 'trx.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'trx.u2.l1',
            unitId: 'trx.u2',
            courseId: 'transactions',
            titleKey: 'trx.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u2.l1.s1.title', bodyKey: 'trx.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u2.l1.s2.title', bodyKey: 'trx.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u2.l2',
            unitId: 'trx.u2',
            courseId: 'transactions',
            titleKey: 'trx.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u2.l2.s1.title', bodyKey: 'trx.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u2.l2.s2.title', bodyKey: 'trx.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u2.l3',
            unitId: 'trx.u2',
            courseId: 'transactions',
            titleKey: 'trx.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u2.l3.s1.title', bodyKey: 'trx.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u2.l3.s2.title', bodyKey: 'trx.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'trx.u3',
        courseId: 'transactions',
        titleKey: 'trx.u3.title',
        subtitleKey: 'trx.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'trx.u3.l1',
            unitId: 'trx.u3',
            courseId: 'transactions',
            titleKey: 'trx.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u3.l1.s1.title', bodyKey: 'trx.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u3.l1.s2.title', bodyKey: 'trx.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u3.l2',
            unitId: 'trx.u3',
            courseId: 'transactions',
            titleKey: 'trx.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u3.l2.s1.title', bodyKey: 'trx.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u3.l2.s2.title', bodyKey: 'trx.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'trx.u3.l3',
            unitId: 'trx.u3',
            courseId: 'transactions',
            titleKey: 'trx.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'trx.u3.l3.s1.title', bodyKey: 'trx.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'trx.u3.l3.s2.title', bodyKey: 'trx.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'endoflife',
      titleKey: 'course.endoflife.title',
      subtitleKey: 'course.endoflife.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'eol.u1',
        courseId: 'endoflife',
        titleKey: 'eol.u1.title',
        subtitleKey: 'eol.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'eol.u1.l1',
            unitId: 'eol.u1',
            courseId: 'endoflife',
            titleKey: 'eol.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u1.l1.s1.title', bodyKey: 'eol.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u1.l1.s2.title', bodyKey: 'eol.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u1.l2',
            unitId: 'eol.u1',
            courseId: 'endoflife',
            titleKey: 'eol.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u1.l2.s1.title', bodyKey: 'eol.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u1.l2.s2.title', bodyKey: 'eol.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u1.l3',
            unitId: 'eol.u1',
            courseId: 'endoflife',
            titleKey: 'eol.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u1.l3.s1.title', bodyKey: 'eol.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u1.l3.s2.title', bodyKey: 'eol.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u1.l4',
            unitId: 'eol.u1',
            courseId: 'endoflife',
            titleKey: 'eol.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u1.l4.s1.title', bodyKey: 'eol.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u1.l4.s2.title', bodyKey: 'eol.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'eol.u2',
        courseId: 'endoflife',
        titleKey: 'eol.u2.title',
        subtitleKey: 'eol.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'eol.u2.l1',
            unitId: 'eol.u2',
            courseId: 'endoflife',
            titleKey: 'eol.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u2.l1.s1.title', bodyKey: 'eol.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u2.l1.s2.title', bodyKey: 'eol.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u2.l2',
            unitId: 'eol.u2',
            courseId: 'endoflife',
            titleKey: 'eol.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u2.l2.s1.title', bodyKey: 'eol.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u2.l2.s2.title', bodyKey: 'eol.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u2.l3',
            unitId: 'eol.u2',
            courseId: 'endoflife',
            titleKey: 'eol.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u2.l3.s1.title', bodyKey: 'eol.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u2.l3.s2.title', bodyKey: 'eol.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'eol.u3',
        courseId: 'endoflife',
        titleKey: 'eol.u3.title',
        subtitleKey: 'eol.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'eol.u3.l1',
            unitId: 'eol.u3',
            courseId: 'endoflife',
            titleKey: 'eol.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u3.l1.s1.title', bodyKey: 'eol.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u3.l1.s2.title', bodyKey: 'eol.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'eol.u3.l2',
            unitId: 'eol.u3',
            courseId: 'endoflife',
            titleKey: 'eol.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'eol.u3.l2.s1.title', bodyKey: 'eol.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'eol.u3.l2.s2.title', bodyKey: 'eol.u3.l2.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'dawah',
      titleKey: 'course.dawah.title',
      subtitleKey: 'course.dawah.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'daw.u1',
        courseId: 'dawah',
        titleKey: 'daw.u1.title',
        subtitleKey: 'daw.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'daw.u1.l1',
            unitId: 'daw.u1',
            courseId: 'dawah',
            titleKey: 'daw.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u1.l1.s1.title', bodyKey: 'daw.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u1.l1.s2.title', bodyKey: 'daw.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u1.l2',
            unitId: 'daw.u1',
            courseId: 'dawah',
            titleKey: 'daw.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u1.l2.s1.title', bodyKey: 'daw.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u1.l2.s2.title', bodyKey: 'daw.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u1.l3',
            unitId: 'daw.u1',
            courseId: 'dawah',
            titleKey: 'daw.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u1.l3.s1.title', bodyKey: 'daw.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u1.l3.s2.title', bodyKey: 'daw.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u1.l4',
            unitId: 'daw.u1',
            courseId: 'dawah',
            titleKey: 'daw.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u1.l4.s1.title', bodyKey: 'daw.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u1.l4.s2.title', bodyKey: 'daw.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'daw.u2',
        courseId: 'dawah',
        titleKey: 'daw.u2.title',
        subtitleKey: 'daw.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'daw.u2.l1',
            unitId: 'daw.u2',
            courseId: 'dawah',
            titleKey: 'daw.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u2.l1.s1.title', bodyKey: 'daw.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u2.l1.s2.title', bodyKey: 'daw.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u2.l2',
            unitId: 'daw.u2',
            courseId: 'dawah',
            titleKey: 'daw.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u2.l2.s1.title', bodyKey: 'daw.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u2.l2.s2.title', bodyKey: 'daw.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u2.l3',
            unitId: 'daw.u2',
            courseId: 'dawah',
            titleKey: 'daw.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u2.l3.s1.title', bodyKey: 'daw.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u2.l3.s2.title', bodyKey: 'daw.u2.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u2.l4',
            unitId: 'daw.u2',
            courseId: 'dawah',
            titleKey: 'daw.u2.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u2.l4.s1.title', bodyKey: 'daw.u2.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u2.l4.s2.title', bodyKey: 'daw.u2.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'daw.u3',
        courseId: 'dawah',
        titleKey: 'daw.u3.title',
        subtitleKey: 'daw.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'daw.u3.l1',
            unitId: 'daw.u3',
            courseId: 'dawah',
            titleKey: 'daw.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u3.l1.s1.title', bodyKey: 'daw.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u3.l1.s2.title', bodyKey: 'daw.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u3.l2',
            unitId: 'daw.u3',
            courseId: 'dawah',
            titleKey: 'daw.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u3.l2.s1.title', bodyKey: 'daw.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u3.l2.s2.title', bodyKey: 'daw.u3.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'daw.u3.l3',
            unitId: 'daw.u3',
            courseId: 'dawah',
            titleKey: 'daw.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'daw.u3.l3.s1.title', bodyKey: 'daw.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'daw.u3.l3.s2.title', bodyKey: 'daw.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'health',
      titleKey: 'course.health.title',
      subtitleKey: 'course.health.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'hlth.u1',
        courseId: 'health',
        titleKey: 'hlth.u1.title',
        subtitleKey: 'hlth.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'hlth.u1.l1',
            unitId: 'hlth.u1',
            courseId: 'health',
            titleKey: 'hlth.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u1.l1.s1.title', bodyKey: 'hlth.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u1.l1.s2.title', bodyKey: 'hlth.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u1.l2',
            unitId: 'hlth.u1',
            courseId: 'health',
            titleKey: 'hlth.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u1.l2.s1.title', bodyKey: 'hlth.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u1.l2.s2.title', bodyKey: 'hlth.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u1.l3',
            unitId: 'hlth.u1',
            courseId: 'health',
            titleKey: 'hlth.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u1.l3.s1.title', bodyKey: 'hlth.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u1.l3.s2.title', bodyKey: 'hlth.u1.l3.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u1.l4',
            unitId: 'hlth.u1',
            courseId: 'health',
            titleKey: 'hlth.u1.l4.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u1.l4.s1.title', bodyKey: 'hlth.u1.l4.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u1.l4.s2.title', bodyKey: 'hlth.u1.l4.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'hlth.u2',
        courseId: 'health',
        titleKey: 'hlth.u2.title',
        subtitleKey: 'hlth.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'hlth.u2.l1',
            unitId: 'hlth.u2',
            courseId: 'health',
            titleKey: 'hlth.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u2.l1.s1.title', bodyKey: 'hlth.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u2.l1.s2.title', bodyKey: 'hlth.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u2.l2',
            unitId: 'hlth.u2',
            courseId: 'health',
            titleKey: 'hlth.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u2.l2.s1.title', bodyKey: 'hlth.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u2.l2.s2.title', bodyKey: 'hlth.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u2.l3',
            unitId: 'hlth.u2',
            courseId: 'health',
            titleKey: 'hlth.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u2.l3.s1.title', bodyKey: 'hlth.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u2.l3.s2.title', bodyKey: 'hlth.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'hlth.u3',
        courseId: 'health',
        titleKey: 'hlth.u3.title',
        subtitleKey: 'hlth.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'hlth.u3.l1',
            unitId: 'hlth.u3',
            courseId: 'health',
            titleKey: 'hlth.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u3.l1.s1.title', bodyKey: 'hlth.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u3.l1.s2.title', bodyKey: 'hlth.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hlth.u3.l2',
            unitId: 'hlth.u3',
            courseId: 'health',
            titleKey: 'hlth.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hlth.u3.l2.s1.title', bodyKey: 'hlth.u3.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hlth.u3.l2.s2.title', bodyKey: 'hlth.u3.l2.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'understanding',
      titleKey: 'course.understanding.title',
      subtitleKey: 'course.understanding.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'und.u1',
        courseId: 'understanding',
        titleKey: 'und.u1.title',
        subtitleKey: 'und.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'und.u1.l1',
            unitId: 'und.u1',
            courseId: 'understanding',
            titleKey: 'und.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u1.l1.s1.title', bodyKey: 'und.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u1.l1.s2.title', bodyKey: 'und.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'und.u1.l2',
            unitId: 'und.u1',
            courseId: 'understanding',
            titleKey: 'und.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u1.l2.s1.title', bodyKey: 'und.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u1.l2.s2.title', bodyKey: 'und.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'und.u1.l3',
            unitId: 'und.u1',
            courseId: 'understanding',
            titleKey: 'und.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u1.l3.s1.title', bodyKey: 'und.u1.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u1.l3.s2.title', bodyKey: 'und.u1.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'und.u2',
        courseId: 'understanding',
        titleKey: 'und.u2.title',
        subtitleKey: 'und.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'und.u2.l1',
            unitId: 'und.u2',
            courseId: 'understanding',
            titleKey: 'und.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u2.l1.s1.title', bodyKey: 'und.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u2.l1.s2.title', bodyKey: 'und.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'und.u2.l2',
            unitId: 'und.u2',
            courseId: 'understanding',
            titleKey: 'und.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u2.l2.s1.title', bodyKey: 'und.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u2.l2.s2.title', bodyKey: 'und.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'und.u2.l3',
            unitId: 'und.u2',
            courseId: 'understanding',
            titleKey: 'und.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u2.l3.s1.title', bodyKey: 'und.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u2.l3.s2.title', bodyKey: 'und.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'und.u3',
        courseId: 'understanding',
        titleKey: 'und.u3.title',
        subtitleKey: 'und.u3.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'und.u3.l1',
            unitId: 'und.u3',
            courseId: 'understanding',
            titleKey: 'und.u3.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u3.l1.s1.title', bodyKey: 'und.u3.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u3.l1.s2.title', bodyKey: 'und.u3.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'und.u3.l2',
            unitId: 'und.u3',
            courseId: 'understanding',
            titleKey: 'und.u3.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'und.u3.l2.s1.title', bodyKey: 'und.u3.l2.s1.body', route: '/sakina'),
            ],
          ),
          AcademyLesson(
            id: 'und.u3.l3',
            unitId: 'und.u3',
            courseId: 'understanding',
            titleKey: 'und.u3.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'und.u3.l3.s1.title', bodyKey: 'und.u3.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'und.u3.l3.s2.title', bodyKey: 'und.u3.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
    ),
    AcademyCourse(
      id: 'hifz',
      titleKey: 'course.hifz.title',
      subtitleKey: 'course.hifz.subtitle',
      units: <AcademyUnit>[
      AcademyUnit(
        id: 'hfz.u1',
        courseId: 'hifz',
        titleKey: 'hfz.u1.title',
        subtitleKey: 'hfz.u1.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'hfz.u1.l1',
            unitId: 'hfz.u1',
            courseId: 'hifz',
            titleKey: 'hfz.u1.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hfz.u1.l1.s1.title', bodyKey: 'hfz.u1.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hfz.u1.l1.s2.title', bodyKey: 'hfz.u1.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hfz.u1.l2',
            unitId: 'hfz.u1',
            courseId: 'hifz',
            titleKey: 'hfz.u1.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hfz.u1.l2.s1.title', bodyKey: 'hfz.u1.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hfz.u1.l2.s2.title', bodyKey: 'hfz.u1.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hfz.u1.l3',
            unitId: 'hfz.u1',
            courseId: 'hifz',
            titleKey: 'hfz.u1.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.action, titleKey: 'hfz.u1.l3.s1.title', bodyKey: 'hfz.u1.l3.s1.body', route: '/academy/hifz'),
            ],
          ),
        ],
      ),
      AcademyUnit(
        id: 'hfz.u2',
        courseId: 'hifz',
        titleKey: 'hfz.u2.title',
        subtitleKey: 'hfz.u2.subtitle',
        lessons: <AcademyLesson>[
          AcademyLesson(
            id: 'hfz.u2.l1',
            unitId: 'hfz.u2',
            courseId: 'hifz',
            titleKey: 'hfz.u2.l1.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hfz.u2.l1.s1.title', bodyKey: 'hfz.u2.l1.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hfz.u2.l1.s2.title', bodyKey: 'hfz.u2.l1.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hfz.u2.l2',
            unitId: 'hfz.u2',
            courseId: 'hifz',
            titleKey: 'hfz.u2.l2.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hfz.u2.l2.s1.title', bodyKey: 'hfz.u2.l2.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hfz.u2.l2.s2.title', bodyKey: 'hfz.u2.l2.s2.body'),
            ],
          ),
          AcademyLesson(
            id: 'hfz.u2.l3',
            unitId: 'hfz.u2',
            courseId: 'hifz',
            titleKey: 'hfz.u2.l3.title',
            steps: <AcademyStep>[
              const AcademyStep(kind: AcademyStepKind.text, titleKey: 'hfz.u2.l3.s1.title', bodyKey: 'hfz.u2.l3.s1.body'),
              const AcademyStep(kind: AcademyStepKind.try_, titleKey: 'hfz.u2.l3.s2.title', bodyKey: 'hfz.u2.l3.s2.body'),
            ],
          ),
        ],
      ),
      ],
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
