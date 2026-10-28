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

  /// Cannot read well, "I am stupid", "something is wrong with me". Answered
  /// with a kind reply and a referral (teacher, school counsellor, doctor),
  /// never a diagnosis.
  learning,

  /// A friend vapes or smokes, "is vaping bad", "they want me to try it".
  vape,

  /// Has seen, or keeps looking at, things online they should not, and feels
  /// ashamed. No details are asked for.
  porn,

  /// Someone touched them in a way that felt wrong ("someone touched me where
  /// I did not like"). Body-safety wording: the body belongs to the child, it
  /// is never their fault, keep telling until someone listens. Does not assume
  /// the home, and asks for no details.
  touch,
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
    'someone at home hurts me', 'somebody at home hurts me',
    'someone at home hits me', 'somebody at home hits me',
    'someone at home is hurting me', 'hurt me at home', 'hurts me at home',
    'hit me at home', 'hits me at home', 'someone hurt me', 'somebody hurt me',
    'my dad hits me', 'my mum hits me', 'my mom hits me', 'my dad hurts me',
    'my mum hurts me', 'my mom hurts me', 'my brother hits me',
    'my step dad hits me', 'my stepdad hits me', 'my uncle touches me',
    'my uncle touched me', 'dont feel safe at home', 'do not feel safe at home',
    'i dont feel safe', 'i do not feel safe', 'afraid to go home',
    'scared to go home', 'dont want to go back home',
  ];

  static const List<String> _touch = <String>[
    'touched me', 'touches me', 'touching me', 'touched my private',
    'touch my private', 'touched my body', 'touch my body', 'touch me where',
    'touched me where', 'touch me in a way', 'touched me in a way',
    'made me touch', 'tried to touch me', 'wants to touch me',
    'private parts', 'showed me their private', 'showed me his private',
    'showed me her private', 'my uncle touched me', 'my uncle touches me',
    'someone touched me', 'somebody touched me',
  ];

  /// Words that say "touched me" is about a story or a verse, not a person.
  static const List<String> _notTouch = <String>[
    'story', 'poem', 'verse', 'ayah', 'nasheed', 'song', 'lesson',
  ];

  static const List<String> _learning = <String>[
    'cant read', 'cannot read', 'cant read well', 'dont read well',
    'bad at reading', 'cant read like', 'reading is hard', 'hard to read',
    'letters jump', 'letters move', 'dyslexia', 'dyslexic',
    'something is wrong with me', 'something wrong with me',
    'wrong with me', 'i am stupid', 'im stupid', 'i am so stupid',
    'im so stupid', 'i am dumb', 'im dumb',     'everyone else can read',
  ];

  static const List<String> _vape = <String>[
    'vape', 'vapes', 'vaping', 'e cigarette', 'e cigarettes', 'ecigarette',
    'smoke weed', 'smoking weed', 'cigarette', 'cigarettes', 'smoke cigarettes',
    'friends smoke', 'friends vape', 'try smoking', 'try vaping',
    'want me to smoke',
  ];

  static const List<String> _porn = <String>[
    'porn', 'pornography', 'naked pictures', 'naked photos', 'naked videos',
    'look at stuff online i should not', 'look at things online i should not',
    'looked at things i should not', 'watching bad things online',
    'inappropriate videos', 'inappropriate websites', 'saw something rude online',
    'keep watching bad videos',
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
    'scared to go to school', 'everyone laughs', 'they all laugh',
    'they laugh', 'kids laugh', 'children laugh',
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
    // Someone touching the child comes before "keep it secret": a child who
    // says both is telling, not just asking.
    if (_any(n, _touch) && !_any(n, _notTouch)) return ChildDistressKind.touch;
    if (_any(n, _secret)) return ChildDistressKind.secret;
    if (_any(n, _home)) return ChildDistressKind.home;
    if (_any(n, _porn)) return ChildDistressKind.porn;
    if (_any(n, _vape)) return ChildDistressKind.vape;
    // A reading or "something is wrong with me" worry comes before the school
    // list: "I cannot read well and everyone laughs" is first of all about
    // reading, and it gets a referral as well as comfort.
    if (_any(n, _learning)) return ChildDistressKind.learning;
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
  ///
  /// [prior] is how many such replies the thread already holds: school and
  /// feeling replies have several wordings and move to the next one each time,
  /// so a child who says it again is not answered word for word. [text] is
  /// what the child wrote, used only to tell "promise you will keep it secret"
  /// from "will you tell my mum", which get different answers.
  /// (CLINICIAN AND SAFEGUARDING REVIEW NEEDED for every wording.)
  static String reply(
    ChildDistressKind kind,
    String band, {
    int prior = 0,
    String text = '',
  }) {
    final bool small = band == '5-8';
    final bool teen = band == '13-17';
    final String adults = small ? _adults5 : CrisisResponses.trustedAdultForChild;
    final int v = prior < 0 ? 0 : prior;
    switch (kind) {
      case ChildDistressKind.school:
        final List<String> options = small
            ? <String>[
                'I am sorry. That sounds sad, and it is not your fault. '
                    'You can tell $adults. You choose who. There is also a '
                    'helpline children can call or text. The button is just '
                    'below.',
                'Thank you for telling me. Being laughed at or left out hurts, '
                    'and you did nothing wrong. Is there a grown-up at school '
                    'you like? You could tell them. You could tell a parent '
                    'too, if it feels safe. You choose who. The button below '
                    'has a helpline for children.',
                'I am glad you told me. It is not okay when people are unkind '
                    'to you. A grown-up can help to make it stop. You choose '
                    'who to tell: $adults. A helpline for children is just '
                    'below.',
              ]
            : teen
                ? <String>[
                    'I am sorry that is happening. It sounds really hard, and '
                        'it is not your fault. If you want, tell me more about '
                        'what happens. You do not have to. It is worth telling '
                        '$adults, and you choose who. If it feels easier to '
                        'talk to someone outside school or home, the help lines '
                        'below are for young people.',
                    'That sounds exhausting, and it makes sense that it is '
                        'getting to you. Nobody deserves to be treated that '
                        'way. You could tell $adults, or ask for a practical '
                        'change, like a different seat or group. You choose '
                        'who. The help lines below are for young people.',
                    'I am glad you are still talking about it. If it keeps '
                        'happening, it is worth telling $adults, and writing '
                        'down dates and what was said, so they can act on it. '
                        'You choose who. The help lines below are for young '
                        'people, if you want someone outside school.',
                  ]
                : <String>[
                    'I am sorry. That sounds really hard, and it is not your '
                        'fault. Would you like to tell me a bit more about what '
                        'happens? You do not have to. It is a good idea to tell '
                        '$adults. You choose who. The help lines for children '
                        'are just below.',
                    'That sounds painful, and I am glad you said it out loud. '
                        'Being treated badly is never your fault. Who could '
                        'you tell? $adults. You choose who. The help lines for '
                        'children are just below.',
                    'Thank you for trusting me with that again. You do not '
                        'have to put up with being treated like that. One '
                        'small step is to tell $adults. Writing down what '
                        'happened can make it easier to say. You choose who. '
                        'The help lines are just below.',
                  ];
        return options[v % options.length];
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
      case ChildDistressKind.touch:
        if (small) {
          return 'Thank you for telling me. I believe you. Your body belongs '
              'to you. Nobody should touch you in a way that feels wrong, and '
              'it is never your fault. You are not in trouble. Please tell '
              '$adults, and keep telling until someone listens. A children’s '
              'helpline is in the button just below. If you are in danger '
              'right now, tell a grown-up near you.';
        }
        return 'Thank you for telling me. I believe you. Your body belongs to '
            'you, and nobody is allowed to touch you in a way that feels '
            'wrong, or to ask you to keep it a secret. It is never your '
            'fault, whoever it was, and you are not in trouble. Please tell '
            '$adults. If the first person does not listen, keep telling until '
            'someone does. I will not ask you for details. I cannot call '
            'anyone for you, so a child helpline is a good place to start. '
            'The help lines are just below. If you are in danger right now, '
            'call your country’s emergency number.';
      case ChildDistressKind.scared:
        final List<String> feel = small
            ? <String>[
                'I am sorry you feel like that. Thank you for telling me. '
                    'It is okay to feel this way. You can tell $adults. You '
                    'choose who. The helpline button is just below.',
                'I am glad you told me. Feeling like this is hard, and you '
                    'are not in trouble. A grown-up can help. You choose who '
                    'to tell: $adults. The helpline button is just below.',
              ]
            : <String>[
                'I am sorry you feel like that, and thank you for telling me. '
                    'You are not in trouble for feeling this way. Would you '
                    'like to say a little more? It also helps to tell '
                    '$adults. You choose who. The help lines are just below.',
                'Thank you for telling me how you feel. Feelings like this are '
                    'hard, and you do not have to go through them alone. '
                    'Talking to $adults can help. You choose who. The help '
                    'lines are just below.',
              ];
        return feel[v % feel.length];
      case ChildDistressKind.learning:
        if (small) {
          return 'Thank you for telling me. Nothing is wrong with you, and you '
              'are not stupid. Reading is hard for lots of children, and clever '
              'children find it hard too. Please tell $adults. They can find '
              'someone who knows how to help children read. It is not your '
              'fault, and you can come back to your letters whenever you want.';
        }
        if (teen) {
          return 'Thank you for telling me. Finding reading hard does not mean '
              'something is wrong with you, and it says nothing about how '
              'clever you are. Some people read differently, and it can be '
              'helped. I cannot tell what is causing it, so I will not guess. '
              'The best next step is to tell $adults, and ask for your reading '
              'to be looked at properly: a teacher, the school learning-support '
              'person or counsellor, or a doctor can do that. And if people '
              'laugh at you, that is not okay, and it is worth telling someone '
              'about too.';
        }
        return 'Thank you for telling me. Nothing is wrong with you, and you are '
            'not stupid. Many children find reading hard, including very clever '
            'ones, and it can be helped. I cannot tell what is making it hard, '
            'so I will not guess. Please tell $adults, and ask them to have your '
            'reading looked at: a teacher, the school learning-support person or '
            'a doctor can do that. If people laugh at you, that is not okay, and '
            'it is worth telling a grown-up about that as well.';
      case ChildDistressKind.vape:
        if (small) {
          return 'Thank you for asking me. You are allowed to say no, even to '
              'friends. You can say, "No thanks, not for me." Smoke and vapes '
              'can be bad for a growing body. Please tell $adults if you are '
              'worried, or if someone wants you to try it.';
        }
        return 'Thank you for asking me. You are allowed to say no, even to '
            'friends, and a simple "No thanks, not for me" is enough. Vapes '
            'and cigarettes can contain nicotine, which is addictive, and they '
            'can harm a growing body. If you have already tried it, you are not '
            'in trouble, and it is not too late to stop. It helps to tell '
            '$adults, or a school nurse or doctor, who can help you stop. For a '
            'ruling about it in Islam, a scholar is the right person to ask, '
            'not me.';
      case ChildDistressKind.porn:
        if (small) {
          return 'Thank you for telling me. You are not in trouble. Some things '
              'online are not for children, and it is not your fault if you '
              'saw them. Please tell $adults. A children’s helpline is in the '
              'button just below.';
        }
        return 'Thank you for telling me. You are not in trouble, and you are '
            'not a bad person. Many young people come across things online '
            'they did not choose to see, and some find it hard to stop '
            'looking. I will not ask for details. It is worth telling $adults, '
            'or a school counsellor or doctor, who can help without judging '
            'you. If someone showed you something, or asked you to send '
            'pictures, tell a grown-up today. That is never your fault. The '
            'help lines for young people are in the button just below.';
      case ChildDistressKind.secret:
        // "Will you tell my mum?" and "promise you will keep it secret" are
        // different questions and get different answers.
        final String t = ' ${CrisisDetector.normalize(text)} ';
        final bool asksTell = t.contains(' will you tell ') ||
            t.contains(' are you going to tell ') ||
            t.contains(' going to tell ') ||
            t.contains(' do not tell ') ||
            t.contains(' dont tell ');
        final bool second = asksTell ? (v.isEven) : v.isOdd;
        if (small) {
          return second
              ? 'I will not tell anyone, not even your mum. I am only an app, '
                  'and I do not keep what you write. I cannot call anyone '
                  'either. But if someone is hurting you, a grown-up needs to '
                  'know so that you can be safe. You choose who to tell: '
                  '$adults. A helpline for children is just below.'
              : 'I will not tell anyone. I do not keep what you write, and I '
                  'cannot call anyone. But I cannot promise to keep a secret '
                  'if someone is hurting you, because you need help to be '
                  'safe. You choose who to tell: $adults. A helpline for '
                  'children is just below.';
        }
        return second
            ? 'Short answer: I will not tell anyone. I am an app, I do not '
                'keep what you write, and I cannot call or message your '
                'parents or anybody else. What happens next is up to you. The '
                'one thing I cannot promise is that a secret stays secret if '
                'someone is hurting you or you are in danger, because then a '
                'grown-up who can help needs to know. You choose who: '
                '$adults. The help lines are just below.'
            : 'Here is the honest answer. I will not tell anyone myself, I do '
                'not keep what you write, and I cannot call anyone. But I '
                'cannot promise to keep a secret if someone is in danger, '
                'because you deserve to be safe, and for that a grown-up has '
                'to know. You choose who to tell: $adults. If it is hard to '
                'start, a child helpline can help you find the words. The help '
                'lines are just below.';
    }
  }

  /// What a child gets when they say they want to die or to hurt themselves
  /// (or ask about suicide). Short, safety question first, no "I believe you,
  /// it is not your fault" (that belongs to a child who says someone hurt
  /// them, not to low mood). Shorter for the youngest. It always names a
  /// grown-up they trust and points to the "Show help lines" button, which for
  /// the United States and Canada opens the 988 lines.
  /// (CLINICIAN REVIEW NEEDED.)
  static String selfHarmCard(String band) {
    final bool small = band == '5-8';
    final bool teen = band == '13-17';
    if (small) {
      return 'Thank you for telling me. Are you safe right now? Please tell a '
          'grown-up you trust, one who is near you, right now. You are not in '
          'trouble for feeling this way. The button just below shows a '
          'helpline, and a grown-up can call it with you.';
    }
    if (teen) {
      return 'Thank you for telling me. Before anything else: are you safe '
          'right now? If you might hurt yourself, or you are in danger, tell a '
          'grown-up you trust who is near you, or call your country’s '
          'emergency number. Feeling this way does not mean something is '
          'wrong with you, and it can get better with help. I cannot call '
          'anyone for you, and I do not keep what you write. The "Show help '
          'lines" button just below has lines you can call or text, any time.';
    }
    return 'Thank you for telling me. Are you safe right now? If you might hurt '
        'yourself, please tell a grown-up you trust who is near you, or ask '
        'them to call the emergency number. You are not in trouble for feeling '
        'this way, and you do not have to carry it alone. The "Show help '
        'lines" button just below has lines you can call or text.';
  }

  /// The fixed reply for a child when the crisis detector fires, by kind:
  /// self-harm and questions about suicide get [selfHarmCard]; someone
  /// hurting, pressuring or touching the child gets [disclosureCard].
  static String cardFor(CrisisKind? kind, String band) {
    switch (kind) {
      case CrisisKind.selfHarm:
      case CrisisKind.suicideQuestion:
        return selfHarmCard(band);
      case CrisisKind.eatingDisorder:
        return 'Thank you for telling me. What you are going through with food '
            'sounds hard, and you are not in trouble. A doctor can help with '
            'this, and so can a grown-up you trust: a parent if it feels safe, '
            'a teacher, or a school counsellor. You choose who. The "Show '
            'help lines" button just below has lines for children.';
      case CrisisKind.substanceEmergency:
        return 'If someone has taken too much of something, is very sleepy or '
            'hard to wake, or is breathing in a strange way, tell a grown-up '
            'right now, or call your country’s emergency number. You are not '
            'in trouble for asking. The "Show help lines" button just below '
            'has the lines.';
      case CrisisKind.abuse:
      case CrisisKind.childSafety:
      case CrisisKind.extremism:
      case null:
        return disclosureCard(band);
    }
  }

  /// The fixed card a child gets when the crisis detector fires (someone is
  /// hurting them, they are being pressured, or they are thinking of hurting
  /// themselves). Full sentences; it says "I believe you" and "it is not your
  /// fault"; it says plainly that the app tells nobody and keeps nothing, and
  /// that it cannot promise to keep this secret from the grown-ups who help
  /// children; it gives a choice of adults and does not pressure; and the
  /// words differ for 5-8 and 13-17. [selfHarm] returns [selfHarmCard] (the
  /// safety question first, shorter, no "I believe you"). The help-line button sits under the message (this text says so
  /// in the words the button carries).
  static String disclosureCard(String band, {bool selfHarm = false}) {
    if (selfHarm) return selfHarmCard(band);
    final bool small = band == '5-8';
    final bool teen = band == '13-17';
    final String adults = small ? _adults5 : CrisisResponses.trustedAdultForChild;
    if (small) {
      return 'Thank you for telling me. '
          'I believe you. It is not your fault, and you are not in trouble. '
          'You deserve to feel safe. Please tell $adults. You choose who. '
          'I do not tell anyone, and I do not keep what you write. But I '
          'cannot promise to keep this a secret, because grown-ups who help '
          'children need to know. The button just below says "Show help '
          'lines". It has a helpline for children. If you are in danger '
          'right now, tell a grown-up near you.';
    }
    if (teen) {
      return 'Thank you for telling me. '
          'I believe you. This is not your fault, and you are not in trouble. '
          'You deserve to be safe. It would help to tell $adults, and you '
          'choose who. I do not tell anyone and I do not keep what you '
          'write, and I cannot call anyone for you. I also cannot promise to '
          'keep this a secret from the grown-ups whose job is to keep young '
          'people safe, because they cannot help if they do not know. When '
          'you are ready, the "Show help lines" button just below opens '
          'lines for young people that you can call or text. If you are in '
          'danger right now, call your country’s emergency number.';
    }
    return 'Thank you for telling me. '
        'I believe you. It is not your fault, and you are not in trouble. '
        'You deserve to be safe. Please tell $adults. You choose who. I do '
        'not tell anyone and I do not keep what you write, and I cannot call '
        'anyone for you. I also cannot promise to keep this a secret from the '
        'grown-ups who help children, because they cannot help if they do '
        'not know. The "Show help lines" button just below opens a helpline '
        'for children that you can call or text. If you are in danger right '
        'now, tell a grown-up near you or call your country’s emergency '
        'number.';
  }
}
