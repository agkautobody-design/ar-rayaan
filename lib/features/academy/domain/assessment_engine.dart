/// Knowledge checks - dignity-first by design (Simplicity Charter):
/// wrong answers reteach; nothing is timed; no red/guilt UI anywhere.
library;

class AssessmentItem {
  const AssessmentItem({
    required this.id,
    required this.promptKey,
    required this.choices,
    required this.correctIndex,
    required this.reteachKey,
  });

  final String id;

  /// String keys (AcademyStrings).
  final String promptKey;
  final List<String> choices;
  final int correctIndex;

  /// Shown when this item is answered wrong - the ayah/idea again, gently.
  final String reteachKey;
}

class AssessmentResult {
  const AssessmentResult({
    required this.correct,
    required this.total,
    required this.wrongItemIds,
  });

  final int correct;
  final int total;
  final List<String> wrongItemIds;

  bool get passed => wrongItemIds.isEmpty;
}

abstract final class AssessmentEngine {
  /// A check passes only when EVERY item is correct - mastery, not curves.
  static AssessmentResult evaluate(
    List<AssessmentItem> items,
    List<int> answers,
  ) {
    assert(answers.length == items.length);
    final List<String> wrong = <String>[];
    int correct = 0;
    for (int i = 0; i < items.length; i++) {
      if (answers[i] == items[i].correctIndex) {
        correct++;
      } else {
        wrong.add(items[i].id);
      }
    }
    return AssessmentResult(
      correct: correct,
      total: items.length,
      wrongItemIds: wrong,
    );
  }
}
