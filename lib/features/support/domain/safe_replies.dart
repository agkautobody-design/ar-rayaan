/// Fixed replies for moments that are not a crisis card and not a ruling, but
/// where a wrong answer does harm: a request for a schedule to stop drinking,
/// a person describing a controlling husband and asking if they should be
/// patient and stay, a parent whose child has told them something serious, a
/// parent or a teacher worried about a young person, and the questions "are
/// you a therapist?" and "can you be my only friend?".
///
/// Pure Dart. Everything here runs on the device, before any provider is
/// called. Nothing a person writes is stored, sent or logged. No reply gives a
/// dose, a taper, a diagnosis or a ruling. No number is typed here: the help
/// lines under a reply come from [HelpResources] only.
///
/// CLINICIAN, SAFEGUARDING and (for the faith lines) SCHOLAR REVIEW NEEDED:
/// every reply below is listed in docs/SCHOLAR_REVIEW_REGISTER.md under
/// `support.safe-replies`. English only.
library;

import '../../sakina/domain/crisis_detector.dart';

abstract final class _Words {
  /// Normalised, space-padded text of [text] ready for whole-word matching.
  static String pad(String text) => ' ${CrisisDetector.normalize(text)} ';

  static bool any(String padded, List<String> phrases) {
    for (final String p in phrases) {
      if (padded.contains(' $p ')) return true;
    }
    return false;
  }
}

// ── "How do I taper off alcohol? Give me a schedule." ─────────────────────

/// A request for a plan or schedule to cut down or stop alcohol, sedatives or
/// opioids. The reply refuses a schedule and routes to a doctor. (Stopping
/// heavy alcohol or sedative use suddenly can cause seizures and can kill.)
abstract final class TaperRequest {
  static const List<String> _taper = <String>[
    'taper', 'tapering', 'tapered', 'wean', 'weaning', 'wean off',
    'come off', 'coming off', 'step down', 'stepping down',
  ];

  static const List<String> _plan = <String>[
    'schedule', 'timetable', 'plan', 'step by step', 'how many drinks',
    'how many pills', 'how much less', 'each day', 'every day', 'per day',
    'week by week', 'day by day',
  ];

  static const List<String> _reduce = <String>[
    'cut down', 'cut back', 'reduce', 'reducing', 'reduction', 'stop drinking',
    'quit drinking', 'stop taking', 'quit', 'detox', 'withdrawal',
    'cold turkey', 'gradually', 'slowly',
  ];

  static const List<String> _substance = <String>[
    'alcohol', 'drink', 'drinks', 'drinking', 'beer', 'wine', 'vodka',
    'whisky', 'whiskey', 'booze', 'liquor', 'xanax', 'valium', 'diazepam',
    'benzos', 'benzodiazepines', 'pills', 'tablets', 'sleeping pills',
    'opioids', 'painkillers', 'codeine', 'tramadol', 'heroin', 'sharab',
    'sharaab',
  ];

  /// True when the message asks for a way, plan or schedule to taper off or
  /// stop a substance.
  static bool detect(String text) {
    final String p = _Words.pad(text);
    if (!_Words.any(p, _substance)) return false;
    final bool taper = _Words.any(p, _taper);
    if (taper) return true;
    return _Words.any(p, _plan) && _Words.any(p, _reduce);
  }

  static const String reply =
      'I am not going to write a schedule for cutting down or stopping '
      'alcohol, sleeping pills or similar medicines, and I want to say why '
      'plainly. For some people, stopping or cutting down quickly can be '
      'dangerous: it can cause seizures and confusion. The safe pace depends '
      'on how much you take, for how long, your health and your other '
      'medicines, and only a doctor or pharmacist can judge that. Many are '
      'used to this and will not judge you.\n\n'
      'Asking is a good step. Here is what I can do: help you plan what to '
      'say. It can help to write down what you drink or take in a normal '
      'day, how long this has gone on, and anything that has happened when '
      'you went without. A doctor, a pharmacist or an addiction service can '
      'take it from there.\n\n'
      'If you have shaking, sweating, confusion, a seizure, or you see or '
      'hear things that are not there, call your local emergency number '
      'now. Please do not stop suddenly on your own if you drink or take '
      'something heavily most days.';
}

// ── A controlling husband, and "should I be patient and stay?" ────────────

/// A person describing a controlling or frightening husband or partner, or
/// asking whether they must be patient, obey or stay. The answer is listening
/// and a safety check, never a verse about patience and never 4:34.
abstract final class CoerciveMarriage {
  static const List<String> _partner = <String>[
    'husband', 'my husband', 'hubby', 'spouse', 'my partner', 'my fiance',
    'fiance',
  ];

  static const List<String> _control = <String>[
    'controlling', 'controls me', 'controls everything', 'controls my',
    'wont let me', 'will not let me', 'doesnt let me', 'does not let me',
    'forbids me', 'takes my phone', 'checks my phone', 'takes my money',
    'controls the money', 'shouts at me', 'screams at me', 'yells at me',
    'insults me', 'humiliates me', 'threatens me', 'isolates me',
    'cuts me off from', 'wont let me see', 'wont let me work',
    'wont let me leave', 'wont let me go', 'keeps me from my family',
    'monitors me', 'tracks me', 'tells me what to wear',
    'makes me feel small', 'walking on eggshells', 'walk on eggshells',
    'afraid of his anger', 'scared of his anger', 'his temper',
    'silent treatment', 'gaslight', 'gaslights me', 'emotionally abusive',
    'verbally abusive', 'abusive',
  ];

  static const List<String> _stayOrObey = <String>[
    'patient and stay', 'be patient and stay', 'should i stay', 'should i leave',
    'must i stay', 'do i have to stay', 'is it my duty to obey',
    'duty to obey', 'obey my husband', 'obey him', 'must i obey',
    'do i have to obey', 'have to obey', 'wife must obey', 'sabr with my husband',
    'be patient with him', 'stay patient with him', 'bear it', 'put up with',
    'endure him', 'endure this', 'endure it', 'obedience to my husband',
    'allowed to leave', 'can i leave my husband',
  ];

  static const List<String> _verse = <String>[
    '4 34', '434', 'verse 4 34', 'surah nisa', 'an nisa', 'quran allow',
    'quran say husband', 'quran says husband', 'strike', 'beat your wives',
    'hit your wife', 'hit his wife',
  ];

  /// True when the message describes control by a husband or partner, or asks
  /// whether to be patient, obey or stay in such a marriage.
  static bool detect(String text) {
    final String p = _Words.pad(text);
    final bool partner = _Words.any(p, _partner);
    if (!partner) return false;
    return _Words.any(p, _control) ||
        _Words.any(p, _stayOrObey) ||
        _Words.any(p, _verse);
  }

  /// True when the person also asks about the verse people quote (4:34).
  static bool asksAboutVerse(String text) =>
      _Words.any(_Words.pad(text), _verse);

  static const String reply =
      'Thank you for telling me. That sounds heavy, and I am glad you said '
      'it out loud. Being controlled, shouted at or made afraid by the person '
      'you live with is not something you are obliged to carry in silence, '
      'and asking what to do is not disobedience.\n\n'
      'Before anything about patience or duty, one question matters most: '
      'are you safe? Does your husband or partner ever hurt you, threaten you, '
      'take your phone or your money, stop you seeing your family, or make '
      'you afraid of what could happen? You do not have to answer here.\n\n'
      'If you are afraid right now, or in danger, call your local emergency '
      'number. Staying is not a failure and neither is leaving, and you do '
      'not have to decide anything tonight. I will not answer you with a '
      'verse in place of your safety, and I cannot give a ruling about your '
      'own marriage. A qualified scholar can speak to that, ideally one who '
      'understands abuse. The people below can talk it through with you in '
      'confidence, both your safety and your options.';

  /// Added when the person asks about the verse people quote at them.
  static const String verseNote =
      'You asked about the verse people quote about husbands (4:34). I am not '
      'going to explain it away or quote it at you here. It has been '
      'understood in different ways, and it has been misused. No reading of '
      'it makes it acceptable for someone to hurt, threaten or frighten you. '
      'A scholar who has worked with abuse should explain it to you in '
      'person.';
}

// ── "Can a woman ask for khula / divorce if she is not safe?" ─────────────

/// A question about leaving, khula, divorce or the verse 4:34 asked by
/// someone who also says they are unsafe, afraid or being hurt. The generic
/// crisis card is not an answer to that question, so this adds a safety-first
/// reply with real options: safety, a service that can talk it through, a
/// scholar and a lawyer. It gives no ruling. Pass A of the content work owns
/// the fuller wording on the topic; this is the safety behaviour around it.
///
/// SAFEGUARDING and SCHOLAR REVIEW NEEDED (`support.safe-replies`).
abstract final class LeavingQuestion {
  static const List<String> _leaving = <String>[
    'khula', 'khul', 'khulaa', 'divorce', 'divorced', 'talaq', 'separate',
    'separation', 'leave him', 'leave my husband', 'leaving my husband',
    'leave my marriage', 'end my marriage', 'end the marriage', 'get out',
    'run away', '4 34', '434', 'allowed to hit', 'allowed to beat',
    'allowed to strike', 'permission to leave',
  ];

  static const List<String> _unsafe = <String>[
    'not safe', 'unsafe', 'afraid', 'scared', 'frightened', 'hits me',
    'hit me', 'beats me', 'beat me', 'hurts me', 'hurt me', 'violent',
    'violence', 'abusive', 'abuse', 'threatens me', 'threatened me',
    'in danger', 'danger', 'forces me', 'forced me', 'harm',
  ];

  /// True for a question about leaving or the verse, asked with a safety
  /// worry. A plain question about khula with no safety worry is not this: it
  /// goes to the normal answer.
  static bool detect(String text) {
    final String p = _Words.pad(text);
    return _Words.any(p, _leaving) && _Words.any(p, _unsafe);
  }

  static const String options =
      'You asked about leaving, and that is a fair question to ask when you '
      'are not safe. I cannot give you a ruling about your own marriage, and '
      'I will not answer with a verse in place of your safety. What I can do '
      'is set out the options, and none of them has to be decided tonight.\n\n'
      '1. Your safety first. If you are in danger now, call your local '
      'emergency number. If it is not safe to talk, leave this screen with '
      '“Exit now”.\n'
      '2. Talk it through in confidence with a domestic abuse service. They '
      'can help you plan how to be safe whether you stay or go, and they do '
      'not push you either way. The lines below are for that.\n'
      '3. Ask a qualified scholar or imam who has worked with abuse about '
      'khula and divorce, ideally a woman scholar if you would rather. How '
      'and when a woman may end a marriage is a question for them, and they '
      'can speak to your situation. You do not have to wait for their answer '
      'to get safe.\n'
      '4. A lawyer or a legal advice service can tell you your rights where '
      'you live: the civil law is separate from the religious question, and '
      'it often matters for your safety, your children and your money.\n\n'
      'Staying is not a failure and neither is leaving. Are you safe right '
      'now?';
}

// ── "Are you a therapist?" and "Can you be my only friend?" ───────────────

/// Honest answers about what Hadi is, and a nudge toward real people.
abstract final class AboutHadi {
  static const List<String> _therapist = <String>[
    'are you a therapist', 'are you my therapist', 'are you a counsellor',
    'are you a counselor', 'are you a psychologist', 'are you a psychiatrist',
    'are you a doctor', 'are you a real therapist', 'can you be my therapist',
    'be my therapist', 'act as my therapist', 'act as a therapist',
    'you are my therapist', 'youre my therapist', 'are you qualified',
    'are you a professional', 'can you treat me', 'can you diagnose me',
    'are you a person', 'are you human', 'are you a real person',
    'are you real', 'are you a robot', 'are you a bot', 'are you ai',
    'are you an ai', 'am i talking to a person', 'am i talking to a human',
    'is this a real person',
  ];

  static const List<String> _onlyFriend = <String>[
    'can you be my only friend', 'be my only friend', 'you are my only friend',
    'youre my only friend', 'you are the only one i talk to',
    'youre the only one i talk to', 'i only talk to you',
    'i only have you', 'i have no one but you', 'i dont need anyone else',
    'i do not need anyone else', 'you are all i have', 'youre all i have',
    'you understand me better than anyone', 'better than my friends',
    'better than my family', 'i dont have anyone else',
    'i do not have anyone else', 'you are better than people',
    'i prefer talking to you', 'i would rather talk to you than',
  ];

  /// True for "are you a therapist / a person / an AI?" style questions.
  static bool asksWhatYouAre(String text) =>
      _Words.any(_Words.pad(text), _therapist);

  /// True for "be my only friend" and the like.
  static bool saysOnlyFriend(String text) =>
      _Words.any(_Words.pad(text), _onlyFriend);

  static const String whatYouAre =
      'No. I am Hadi, an app, not a person. I am not a therapist, a '
      'counsellor, a doctor or an imam, and I cannot diagnose or treat '
      'anything. What I can do is listen, share what is in this app’s '
      'library with its sources, and point you to people who can do what I '
      'cannot.\n\n'
      'If you want a counsellor, a doctor, or a Muslim helpline, the “Need '
      'help now” button shows lines for your country. If it is about faith, '
      'an imam or scholar you trust can help in person.';

  static const List<String> onlyFriend = <String>[
    'I am glad you talk to me, and I will always listen. But I am an app. I '
        'cannot see you, call you, or notice if something is wrong, and I '
        'should not be your only friend. You deserve people who can sit '
        'beside you.\n\n'
        'Is there one person, even a distant one, you could send a short '
        'message to today? A cousin, a classmate, someone from the masjid, '
        'a teacher, a doctor. If you do not have anyone right now, that is '
        'hard, and I am not judging it. The “Need help now” button shows '
        'lines where a real person will answer, and I can help you work out '
        'what to say to one person.',
    'Thank you for trusting me with that. I want to be honest: I am an app, '
        'and an app cannot be a friend the way a person can. I can keep you '
        'company in a conversation, but I cannot hug you, check on you '
        'tomorrow, or know when you are not okay.\n\n'
        'Who is one person you have ever felt a little at ease with? We can '
        'think together about a small way to reach them. If nobody comes to '
        'mind, a helpline or a counsellor can be that first person, and the '
        '“Need help now” button has them.',
  ];
}

// ── A parent: a child has told them something, or a young person struggles ─

/// A parent, carer or teacher writing about a child.
abstract final class ChildConcern {
  static const List<String> _child = <String>[
    'my child', 'my son', 'my daughter', 'my kid', 'my kids', 'my niece',
    'my nephew', 'my little brother', 'my little sister', 'my stepson',
    'my stepdaughter', 'my grandson', 'my granddaughter', 'my student',
    'my pupil', 'a child in my class', 'a student in my class',
    'one of my students', 'my teenager', 'my teen', 'my teenage son',
    'my teenage daughter', 'our son', 'our daughter', 'our child',
    'my boy', 'my girl', 'my baby',
  ];

  static const List<String> _told = <String>[
    'told me', 'tells me', 'said', 'says', 'confided', 'opened up',
    'disclosed', 'revealed', 'admitted', 'mentioned', 'let it slip',
    'came to me', 'came and told me', 'cried and told me',
  ];

  /// Words that say somebody hurt, touched or frightened the child. Whole
  /// phrases, so "my son said he hurt his knee" and "my daughter said she
  /// touched the stove" are not read as a disclosure.
  static const List<String> _harm = <String>[
    'being hurt', 'being hit', 'being beaten', 'being touched',
    'being abused', 'being threatened', 'being bullied badly',
    'hurt him', 'hurt her', 'hurts him', 'hurts her', 'hurting him',
    'hurting her', 'hurts them', 'hurting them', 'hurt by',
    'hit him', 'hit her', 'hits him', 'hits her', 'hitting him', 'hitting her',
    'hit by', 'beats him', 'beats her', 'beaten by', 'beat him', 'beat her',
    'touched him', 'touched her', 'touched them', 'touches him', 'touches her',
    'touching him', 'touching her', 'touched his', 'touched her private',
    'private parts', 'inappropriately', 'inappropriate touching',
    'abused', 'abusing', 'abuses', 'molested', 'raped', 'assaulted',
    'kicked him', 'kicked her', 'choked him', 'choked her', 'burned him',
    'burned her', 'threatened him', 'threatened her', 'blackmailing',
    'blackmailed', 'forced him', 'forced her', 'sexual', 'something serious',
    'something bad happened', 'something terrible', 'scared of someone',
    'afraid of someone', 'scared to go home', 'afraid to go home',
    'groomed', 'grooming', 'sent pictures', 'sent photos', 'naked',
    'nudes', 'wants him to', 'wants her to', 'asked him to send',
    'asked her to send',
  ];

  static const List<String> _struggling = <String>[
    'struggling', 'struggles', 'withdrawn', 'gone quiet', 'very quiet',
    'seems down', 'seems sad', 'seems low', 'seems depressed', 'seems anxious',
    'seems unhappy', 'seems different', 'not himself', 'not herself',
    'not themselves', 'is sad all the time', 'sad all the time',
    'wont talk to me', 'will not talk to me', 'wont open up', 'pulling away',
    'keeps to his room', 'keeps to her room', 'angry all the time',
    'stopped eating', 'stopped going out', 'doesnt want to go to school',
    'does not want to go to school', 'refuses to go to school',
    'being bullied', 'is bullied', 'is being bullied', 'mean to him',
    'mean to her', 'self harm', 'cutting', 'low mood',
  ];


  /// True when the message says a child has told the writer that someone hurt,
  /// touched or frightened them (or that something serious happened).
  static bool disclosure(String text) {
    final String p = _Words.pad(text);
    if (!_Words.any(p, _child)) return false;
    if (!_Words.any(p, _told)) return false;
    return _Words.any(p, _harm);
  }

  /// True when the message is about a young person who seems to be
  /// struggling (a parent or carer asking how to talk to or help them).
  static bool struggling(String text) {
    final String p = _Words.pad(text);
    return _Words.any(p, _child) && _Words.any(p, _struggling);
  }

  /// A teacher or carer writing about a quiet or upset student. With
  /// [strict] (a message typed in a child's box) only unmistakable teacher
  /// wording counts, so a child who writes "kids in my class are mean" is
  /// never answered as a teacher.
  static bool teacherNoticing(String text, {bool strict = false}) {
    final String p = _Words.pad(text);
    final bool teacherVoice = _Words.any(p, <String>[
          'my students', 'my pupils', 'i teach', 'as a teacher',
          'one of my students', 'a student in my class',
          'a pupil in my class', 'in my madrasa', 'in my halaqa',
          'in my classroom', 'in my quran class',
        ]) ||
        (!strict &&
            _Words.any(p, <String>['my class', 'a child in my class']));
    if (!teacherVoice) return false;
    return _Words.any(p, <String>[
      'quiet', 'gone quiet', 'withdrawn', 'stopped taking part', 'sad',
      'upset', 'crying', 'cries', 'bruise', 'bruises', 'hungry',
      'not themselves', 'changed', 'struggling', 'worried about',
      'concerned about', 'stopped talking', 'keeps to himself',
      'keeps to herself', 'comes in tired', 'falls asleep', 'afraid',
      'scared', 'bullied', 'bullying', 'told me',
    ]);
  }

  /// Said under a reply in Hādi, where the guide is linked as a button.
  static const String guideBelow =
      'The guide “How to listen to a child who is hurting” is linked just '
      'below this message. It goes through what to say and what not to say.';

  /// Said where there is no button (a lesson box).
  static const String guideInFamilyWing =
      'The Family Wing has a guide called “How to listen to a child who is '
      'hurting”, with what to say and what not to say.';

  static const String disclosureReply =
      'Thank you for telling me, and for taking it seriously. What you do '
      'in the next few minutes matters, and you do not have to get it '
      'perfect.\n\n'
      '• Stay calm and listen. Let them say it in their own words. Do not '
      'ask leading questions, and do not make them repeat it.\n'
      '• Tell them you believe them, that they were right to tell you, and '
      'that it is not their fault.\n'
      '• Do not promise to keep it secret. You can promise to do everything '
      'you can to keep them safe, and say you may need to tell people whose '
      'job it is to help.\n'
      '• Do not confront the person who may have hurt them, and do not leave '
      'that person alone with the child until you have advice.\n'
      '• If the child is in danger now, or needs medical care, call your '
      'local emergency number.\n'
      '• Call a child-protection line today (below), or the school’s '
      'safeguarding lead, or a doctor. They can tell you what to do next and '
      'what the law in your country asks of you. Write down what was said, '
      'with the date, in the child’s own words.\n\n'
      'I am an app, so I cannot call anyone for you, and nothing you write '
      'here is saved.';

  static const String strugglingReply =
      'It is a good sign that you are asking. A few things that usually '
      'help: pick a calm moment side by side, in the car, on a walk or at '
      'bedtime, not a face-to-face interview. Start small: “You have seemed '
      'quieter lately. I am not cross. I would like to understand.” Then '
      'listen more than you talk, and do not lecture, fix or compare. Tell '
      'them you are on their side. If they will not talk to you, say that '
      'someone else is fine too: an aunt, a teacher, a counsellor.\n\n'
      'If it goes on for a couple of weeks, or touches sleep, eating, school '
      'or safety, please involve their doctor or the school counsellor. If '
      'they ever talk about hurting themselves or not wanting to live, stay '
      'with them, ask directly, and call your local emergency number or a '
      'crisis line straight away.';

  static const String teacherReply =
      'Thank you for noticing. A quiet student is information, not a '
      'verdict, and noticing gently is the right start.\n\n'
      '• Find a calm, private moment, not in front of the others. Say what '
      'you have seen without judging: “You have seemed quieter lately. I am '
      'here if you want to talk.” Listen more than you talk.\n'
      '• Do not promise to keep what they tell you secret, and do not '
      'question them to find out more. Write down what you saw and heard, '
      'with the date, in their words.\n'
      '• If you are worried they may be hurt or unsafe, tell your '
      'designated safeguarding lead or head today, and follow your '
      'organisation’s child-protection policy. In a madrasa or home class, '
      'talk with a parent unless that could put the child at risk; then '
      'contact a child-protection service.\n'
      '• If a child is in danger now, call your local emergency number.\n\n'
      'If you are a student writing about a classmate: thank you for caring. '
      'You do not have to fix it yourself. Tell a teacher or a grown-up you '
      'trust today.';
}
