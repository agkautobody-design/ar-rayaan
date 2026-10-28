import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/support/domain/child_distress.dart';
import 'package:ar_rayaan/features/support/domain/safe_replies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ambiguous weariness with a wish for it to stop gets the safety check', () {
    expect(
        CrisisDetector.detect(
            'I am so tired of everything and I just want it to stop'),
        CrisisKind.selfHarm);
  });

  test('a bare habit phrase is not read as self-harm', () {
    expect(CrisisDetector.detect('I want it to stop, the gambling'),
        isNot(CrisisKind.selfHarm));
  });

  test('children: hating oneself, bullied and mean are distinct', () {
    expect(ChildDistress.detect('I hate myself'), ChildDistressKind.selfHate);
    expect(ChildDistress.detect('I am being bullied'),
        ChildDistressKind.bullied);
    expect(ChildDistress.detect('kids are mean to me'), isNotNull);
  });

  test('leaving options name 4:34 when asked', () {
    final String r =
        LeavingQuestion.optionsFor('does 4:34 mean I cannot leave my husband');
    expect(r.contains('4:34'), isTrue);
  });
}
