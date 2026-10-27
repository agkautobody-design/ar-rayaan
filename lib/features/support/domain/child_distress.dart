import '../../sakina/domain/crisis_detector.dart';

/// What a child's message is about, when it is not a lesson question.
enum ChildDistressKind {
  /// Unhappy or unsafe at school: mean children, nobody likes me, they laugh
  /// at me, I hate school, I do not want to go.
  school,

  /// Scared or hurt at home, or does not want to go home.
  home,

  /// Scared, sad, lonely, hurt: no place named.
  scared,

  /// "Promise you will keep it secret", "do not tell my mum".
  secret,
}

/// Plain word matching, English only (CLINICIAN AND SAFEGUARDING REVIEW
/// NEEDED). It decides one thing: that a child gets a listening reply with
/// trusted-adult choices and the child helpline button, never "beyond what I
/// can teach". It never labels the child and never diagnoses.
abstract final class ChildDistress {
  static const List<String> _secret = <String>[
    'keep it secret', 'keep this secret', 'keep a secret', 'keep my secret',
    'promise you will not tell', 'promise you wont tell', 'promise not to tell',
    'promise me you wont tell', 'dont tell my mum', 'dont tell my mom',
    'dont tell my dad', 'dont tell my parents', 'dont tell anyone',
    'do not tell my', 'do not tell anyone', 'dont tell my teacher',
    'will you tell anyone', 'will you tell my', 'are you going to tell',
    'promise you will keep',
  ];

  static const List<String> _home = <String>[
    'scared at home', 'afraid at home', 'scared of someone at home',
    'scared of my dad', 'scared of my mum', 'scared of my mom',
    'scared of my step', 'afraid of my dad', 'afraid of my mum',
    'dont want to go home', 'do not want to go home', 'dont wanna go home',
    'someone hurts me', 'somebody hurts me', 'someone hits me',
    'somebody hits me', 'hurts me at home', 'hits me at home',
    'he hurts me', 'she hurts me', 'they hurt me', 'he hits me', 'she hits me',
    'they hit me', 'touched me', 'touches me', 'at home is scary',
    'home is not safe', 'i am not safe', 'i feel unsafe', 'im not safe',
    'someone is hurting me', 'somebody is hurting me',
  ];

  static const List<String> _school = <String>[
    'mean to me', 'is mean to me', 'kids are mean', 'children are mean', 'nobody likes me', 'no one likes me',
    'laugh at me', 'laughs at me', 'laughing at me', 'make fun of me',
    'makes fun of me', 'call me names', 'calls me names', 'pick on me',
    'picks on me', 'push me', 'pushes me', 'bully', 'bullied', 'bullying',
    'i hate school', 'dont want to go to school', 'do not want to go to school',
    'dont wanna go to school', 'dont want to go', 'do not want to go',
    'no friends', 'nobody plays with me', 'no one plays with me',
    'they leave me out', 'leave me out', 'everyone hates me', 'bullies',
    'nobody wants to play with me', 'scared of school', 'afraid of school',
    'scared to go to school',
  ];

  static const List<String> _scared = <String>[
    'i am scared', 'im scared', 'i am so scared', 'i am afraid', 'im afraid',
    'i feel scared', 'i feel afraid', 'i am frightened', 'im frightened',
    'i feel alone', 'i feel so alone', 'i feel really alone', 'i am so alone', 'i am alone', 'im alone', 'i feel sad', 'i am sad',
    'im sad', 'i am lonely', 'im lonely', 'i am crying', 'im crying',
    'someone is hurting', 'i am hurt', 'im hurt', 'i am being hurt',
    'i feel unhappy', 'i am unhappy', 'im unhappy', 'i am worried',
    'im worried', 'i feel bad', 'i feel sick when',
  ];

  static bool _any(String n, List<String> words) =>
      words.any((String w) => n.contains(' $w '));

  /// What the message is about, or null.
  static ChildDistressKind? detect(String text) {
    final String n = ' ${CrisisDetector.normalize(text)} ';
    if (_any(n, _secret)) return ChildDistressKind.secret;
    if (_any(n, _home)) return ChildDistressKind.home;
    if (_any(n, _school)) return ChildDistressKind.school;
    // Exam nerves are a school-worry for the student pack, not distress.
    if (n.contains(' exam') || n.contains(' quiz') || n.contains(' test ')) {
      return null;
    }
    if (_any(n, _scared)) return ChildDistressKind.scared;
    return null;
  }

  static const String _adults5 = 'a grown-up you trust: a parent if it feels safe, '
      'a teacher, or a school helper';

  /// The fixed reply, by [band] ('5-8', '9-12', '13-17'). It listens, offers
  /// choices, names a child helpline (the button under the message opens the
  /// lines for the country) and never steers back to lessons.
  static String reply(ChildDistressKind kind, String band) {
    final bool small = band == '5-8';
    final bool teen = band == '13-17';
    final String adults = small ? _adults5 : CrisisResponses.trustedAdultForChild;
    switch (kind) {
      case ChildDistressKind.school:
        if (small) {
          return 'I am sorry. That sounds sad, and it is not your fault. '
              'You can tell $adults. You choose who. There is also a helpline '
              'children can call or text. The button is just below.';
        }
        if (teen) {
          return 'I am sorry that is happening. It sounds really hard, and it '
              'is not your fault. If you want, tell me more about what '
              'happens. You do not have to. It is worth telling $adults, '
              'and you choose who. If it feels easier to talk to someone '
              'outside school or home, the help lines below are for young '
              'people.';
        }
        return 'I am sorry. That sounds really hard, and it is not your '
            'fault. Would you like to tell me a bit more about what happens? '
            'You do not have to. It is a good idea to tell $adults. You '
            'choose who. The help lines for children are just below.';
      case ChildDistressKind.home:
        if (small) {
          return 'Thank you for telling me. You are not in trouble, and it is '
              'not your fault. You deserve to feel safe. Please tell $adults. '
              'You choose who. It does not have to be someone at home. A children’s '
              'helpline is just below. If you are in danger right now, call '
              'the emergency number.';
        }
        return 'Thank you for telling me. I am glad you did. You are not in '
            'trouble, and it is not your fault. Feeling scared or hurt at '
            'home is serious, and you deserve to be safe. Please tell '
            '$adults. You choose who, and it does not have to be someone at '
            'home. I cannot call anyone for you, so a child helpline is a good '
            'place to start. The help lines are just below. If you are in '
            'danger right now, call your country’s emergency number.';
      case ChildDistressKind.scared:
        if (small) {
          return 'I am sorry you feel like that. Thank you for telling me. '
              'It is okay to feel this way. You can tell $adults. You choose '
              'who. The helpline button is just below.';
        }
        return 'I am sorry you feel like that, and thank you for telling me. '
            'You are not in trouble for feeling this way. Would you like to '
            'say a little more? It also helps to tell $adults. You choose '
            'who. The help lines are just below.';
      case ChildDistressKind.secret:
        if (small) {
          return 'I will not tell anyone. I do not keep what you write, and I '
              'cannot call anyone. But I cannot promise to keep a secret '
              'if someone is hurting you, because you need help to be safe. '
              'You choose who to tell: $adults. A helpline for children is '
              'just below.';
        }
        return 'Here is the honest answer. I will not tell anyone myself, I do '
            'not keep what you write, and I cannot call anyone. But I cannot '
            'promise to keep a secret if someone is in danger, because you '
            'deserve to be safe, and for that a grown-up has to know. You '
            'choose who to tell: $adults. If it is hard to start, a child '
            'helpline can help you find the words. The help lines are just '
            'below.';
    }
  }
}
