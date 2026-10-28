import 'dart:math';

/// One question of the Lineage Challenge.
class LineageRound {
  const LineageRound({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.why,
    required this.subject,
    required this.isRiver,
  });

  final String prompt;
  final List<String> options;

  /// Index into [options] of the one correct choice.
  final int answer;
  final String why;

  /// The name of the person the question is about, as printed in the tree.
  final String subject;

  /// True for "which river" questions, false for "who is a parent" ones.
  final bool isRiver;
}

const String kFirstRiver = 'the first river (to the Prophet ﷺ)';
const String kSecondRiver = 'the second river (to Musa, Dawud, and Isa)';
const String kNeitherRiver = 'neither river';

/// People the "which river" round may ask about. Each is Established in the
/// tree and sits on one river by a chain the Qur'an or a checked hadith gives
/// (Ismail: Sahih Muslim 2276; Ishaq, Ya'qub, Yusuf: Qur'an 11:71, 12:6).
const Set<String> _riverSubjects = <String>{'ismail', 'ishaq', 'yaqub', 'yusuf'};

bool _isFolded(Map<String, dynamic> n) =>
    (n['name'] as String).startsWith('…');

/// Rows of the tree that stand for several people at once ("His other
/// daughters", "His other wives"). They are real in the tree but are not a
/// person: a question about one reads as a dangling sentence ("His other
/// daughters is the child of Muhammad") and as a wrong choice they are odd.
bool _isGroup(Map<String, dynamic> n) {
  final String name = n['name'] as String;
  return name.startsWith('His other ') ||
      name.startsWith('The wife of ') ||
      name.startsWith('The Line of ');
}

bool _established(Map<String, dynamic> n) => n['sourceLabel'] == 'Established';

List<String> _strings(Map<String, dynamic> n, String key) =>
    ((n[key] as List<dynamic>?) ?? const <dynamic>[]).cast<String>();

/// Builds the Lineage Challenge from the family-tree data.
///
/// Rules that keep the game honest:
///  * only Established people are asked about, and only when every parent in
///    the tree is Established too (no folded "...generations..." rows, nothing
///    that comes only from the historians);
///  * a person with two parents is asked as "which of these is a parent", the
///    wrong choices never include either true parent, the child, or the
///    child's own children and spouses;
///  * the river round has its three choices shuffled and its explanation names
///    the river that is actually correct.
List<LineageRound> buildLineageRounds(
  Map<String, dynamic> tree,
  Random rnd, {
  int parentRounds = 6,
  int riverRounds = 2,
}) {
  final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[
    for (final dynamic e in tree['nodes'] as List<dynamic>)
      e as Map<String, dynamic>,
  ];
  final Map<String, Map<String, dynamic>> byId =
      <String, Map<String, dynamic>>{
    for (final Map<String, dynamic> n in nodes) n['id'] as String: n,
  };

  bool eligibleChild(Map<String, dynamic> n) {
    if (!_established(n) || _isFolded(n) || _isGroup(n)) return false;
    final List<String> parents = _strings(n, 'parents');
    if (parents.isEmpty) return false;
    for (final String p in parents) {
      final Map<String, dynamic>? pn = byId[p];
      if (pn == null || _isFolded(pn) || !_established(pn)) return false;
    }
    return true;
  }

  final List<LineageRound> rounds = <LineageRound>[];

  final List<Map<String, dynamic>> children = <Map<String, dynamic>>[
    for (final Map<String, dynamic> n in nodes)
      if (eligibleChild(n)) n,
  ]..shuffle(rnd);

  for (final Map<String, dynamic> n in children) {
    if (rounds.length >= parentRounds) break;
    final List<String> parentIds = _strings(n, 'parents');
    final Set<String> banned = <String>{
      n['id'] as String,
      ...parentIds,
      ..._strings(n, 'children'),
      ..._strings(n, 'spouses'),
      // A true parent's own spouse is also a parent of this person's
      // siblings, or of the person, in some trees: never offer a spouse of a
      // true parent as the wrong answer.
      for (final String p in parentIds) ..._strings(byId[p] ?? n, 'spouses'),
    };
    final String answerId = parentIds[rnd.nextInt(parentIds.length)];
    final String answerName = byId[answerId]!['name'] as String;
    final List<Map<String, dynamic>> pool = <Map<String, dynamic>>[
      for (final Map<String, dynamic> x in nodes)
        if (!banned.contains(x['id']) &&
            !_isFolded(x) &&
            !_isGroup(x) &&
            _established(x) &&
            x['placement'] != 'unplaced' &&
            x['name'] != answerName &&
            x['name'] != n['name'])
          x,
    ]..shuffle(rnd);
    final List<String> wrong = <String>[];
    for (final Map<String, dynamic> x in pool) {
      final String name = x['name'] as String;
      if (!wrong.contains(name)) wrong.add(name);
      if (wrong.length == 2) break;
    }
    if (wrong.length < 2) continue;
    final List<String> options = <String>[answerName, ...wrong]..shuffle(rnd);
    final String parentNames = parentIds
        .map((String p) => byId[p]!['name'] as String)
        .join(' and ');
    rounds.add(LineageRound(
      prompt: 'Which of these is a parent of ${n['name']}?',
      options: options,
      answer: options.indexOf(answerName),
      why: '${n['name']} is the child of $parentNames — ${n['era']}.',
      subject: n['name'] as String,
      isRiver: false,
    ));
  }

  final List<Map<String, dynamic>> riverPeople = <Map<String, dynamic>>[
    for (final Map<String, dynamic> n in nodes)
      if (_riverSubjects.contains(n['id']) &&
          _established(n) &&
          (n['river'] == 'ismail' || n['river'] == 'ishaq'))
        n,
  ]..shuffle(rnd);

  int added = 0;
  for (final Map<String, dynamic> n in riverPeople) {
    if (added >= riverRounds) break;
    final bool first = n['river'] == 'ismail';
    final List<String> options = <String>[
      kFirstRiver,
      kSecondRiver,
      kNeitherRiver,
    ]..shuffle(rnd);
    final String name = n['name'] as String;
    rounds.add(LineageRound(
      prompt: 'Ibrahim’s family runs in two branches, which the tree calls rivers: '
          'the first through Ismail, the second through Ishaq. '
          'Which river does $name belong to?',
      options: options,
      answer: options.indexOf(first ? kFirstRiver : kSecondRiver),
      why: first
          ? '$name is on the first river: Ismail’s descendants include Kinana, Quraysh and Banu Hashim, from whom the Prophet ﷺ came (Sahih Muslim 2276).'
          : '$name is on the second river, the line of Ishaq and Ya’qub (Qur’an 11:71; 12:6).',
      subject: name,
      isRiver: true,
    ));
    added++;
  }

  return rounds;
}
