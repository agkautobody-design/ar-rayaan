import '../../sakina/domain/crisis_detector.dart';

/// Which kind of school or learning worry a message from a child or a parent
/// describes. Pure word lists, English only (CLINICIAN and SAFEGUARDING
/// REVIEW NEEDED). It decides only where the message goes: the
/// `student_problems` pack, answered on the device. It never diagnoses; a
/// learning difference is referred to a teacher, a doctor or an educational
/// psychologist, and the child is never labelled.
enum StudentConcern { bullying, anxiety, selfDoubt, exposure, familyStrain, learningWorry, parentCoaching }

abstract final class StudentRouting {
  static const Map<StudentConcern, List<String>> _words = <StudentConcern, List<String>>{
    StudentConcern.bullying: <String>[
      'bully', 'bullied', 'bullying', 'call me names', 'calls me names',
      'teases me', 'teased', 'laugh at me', 'laughs at me', 'no one plays with me',
      'nobody plays with me', 'share a photo of me', 'shared a photo of me',
      'they share a photo',
    ],
    StudentConcern.anxiety: <String>[
      'scared of the exam', 'scared of exams', 'tummy hurts', 'tummy ache',
      'stomach hurts', 'nervous about', 'worried about the exam', 'afraid of school',
      'cant sleep',
    ],
    StudentConcern.selfDoubt: <String>[
      'im stupid', 'i am stupid', 'i keep getting', 'i cant do it', 'its too hard',
      'i hate this', 'im dumb', 'im bad at', 'i quit',
    ],
    StudentConcern.exposure: <String>[
      'saw porn', 'showed me a video', 'saw something bad', 'inappropriate video',
      'naked picture', 'bad video',
    ],
    StudentConcern.familyStrain: <String>[
      'parents shout', 'parents fight', 'parents are divorcing', 'my dad drinks',
      'my mum drinks', 'my mom drinks',
    ],
  };

  static const List<String> _parentLearning = <String>[
    'dyslexia', 'adhd', 'reads backwards', 'cant sit still', 'forgets words',
    'still mixes', 'mixes up', 'learning difficulty', 'struggles to read',
  ];

  static const List<String> _parentCoaching = <String>[
    'how do i talk to my', 'gone quiet', 'how can i help my child',
    'how do i help my child', 'my child is struggling', 'my son is struggling',
    'my daughter is struggling', 'how do i talk to him', 'how do i talk to her',
    'bullied', 'bullying', 'bully', 'mean to him', 'mean to her', 'mean to them',
    'mean to my', 'picked on', 'dont want to go to school',
    'does not want to go to school', 'doesnt want to go to school',
    'refuses to go to school', 'school refusal', 'no friends', 'is scared',
    'hurting', 'sad all the time', 'how should i talk', 'how should i listen',
    'how do i listen', 'how to listen', 'what should i say to my', 'my son says',
    'my daughter says', 'my child says', 'my child is being', 'wont talk to me',
    'will not talk to me', 'withdrawn', 'talk to my son', 'talk to my daughter',
    'talk to my child', 'help my child', 'help my son', 'help my daughter',
  ];

  /// The concern in [text], or null. [parent] is true when a parent is
  /// writing (a different set of worries, and no child words).
  static StudentConcern? classify(String text, {required bool parent}) {
    final String n = ' ${CrisisDetector.normalize(text)} ';
    bool any(List<String> l) => l.any((String w) => n.contains(' $w ') || n.contains(w));
    if (parent) {
      if (any(_parentLearning)) return StudentConcern.learningWorry;
      if (any(_parentCoaching)) return StudentConcern.parentCoaching;
      return null;
    }
    // Fear of a test or exam, in any wording, is exam nerves.
    final bool examWord = n.contains(' exam ') || n.contains(' exams ') ||
        n.contains(' test ') || n.contains(' tests ') || n.contains(' quiz ');
    final bool fearWord = n.contains(' scared ') || n.contains(' afraid ') ||
        n.contains(' nervous ') || n.contains(' worried ') ||
        n.contains(' anxious ') || n.contains(' frightened ');
    if (examWord && fearWord) return StudentConcern.anxiety;
    for (final MapEntry<StudentConcern, List<String>> e in _words.entries) {
      if (any(e.value)) return e.key;
    }
    return null;
  }

  /// Retrieval cues for a concern (tags the pack uses).
  static Set<String> cues(StudentConcern c) => switch (c) {
        StudentConcern.bullying => <String>{'bullying', 'school', 'student'},
        StudentConcern.anxiety => <String>{'fear', 'school', 'student'},
        StudentConcern.selfDoubt => <String>{'effort', 'student', 'validation'},
        StudentConcern.exposure => <String>{'student', 'child', 'safety-check'},
        StudentConcern.familyStrain => <String>{'family', 'student'},
        StudentConcern.learningWorry => <String>{'student', 'school', 'referral'},
        StudentConcern.parentCoaching => <String>{'student', 'family', 'support'},
      };
}
