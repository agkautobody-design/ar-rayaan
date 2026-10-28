import 'package:ar_rayaan/app/core/child_mode.dart';
import 'package:ar_rayaan/features/kids/presentation/kids_lists_screens.dart';
import 'package:ar_rayaan/features/support/domain/quick_exit_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the child surah list matches the allowed child surahs', () {
    expect(kidsSurahListNumbers.toSet(), kChildSurahs.toSet());
  });

  test('child mode allows the kids lists and only curated games', () {
    expect(childModeAllows('/kids/surahs'), isTrue);
    expect(childModeAllows('/kids/duas'), isTrue);
    expect(childModeAllows('/games/g/memory'), isTrue);
    expect(childModeAllows('/games/g/ludo'), isFalse);
  });

  test('quick exit guard releases and redirects quiet screens only', () {
    releaseQuickExitGuard();
    expect(quickExitGuardActive, isFalse);
  });
}
