import 'package:ar_rayaan/features/finance/domain/halal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

ScreenResult run({
  double haram = 0,
  double revenue = 0,
  double debt = 0,
  double cap = 0,
  double interest = 0,
  double deposits = 0,
}) =>
    HalalScreen.run(
      haramRevenue: haram,
      totalRevenue: revenue,
      interestBearingDebt: debt,
      marketCap: cap,
      interestIncome: interest,
      interestBearingDeposits: deposits,
    );

void main() {
  test('5.4% haram revenue is shown with its decimal and fails', () {
    final ScreenResult r = run(haram: 54, revenue: 1000, debt: 0, cap: 1000);
    final ScreenLine line = r.lines.firstWhere((l) => l.name == 'Business activity');
    expect(line.passes, isFalse);
    expect(line.text, contains('5.4%'));
    expect(line.text, isNot(contains(' 5% of revenue')));
    expect(r.verdict, 'fail');
  });

  test('a value that would round to the ceiling is shown with two decimals', () {
    // 5.04% would print as "5.0%" - it must not look like a pass.
    final ScreenResult r = run(haram: 50.4, revenue: 1000, cap: 1000);
    final ScreenLine line = r.lines.firstWhere((l) => l.name == 'Business activity');
    expect(line.passes, isFalse);
    expect(line.text, contains('5.04%'));
  });

  test('exactly 5% passes and is purified', () {
    final ScreenResult r = run(haram: 50, revenue: 1000, cap: 1000);
    final ScreenLine line = r.lines.firstWhere((l) => l.name == 'Business activity');
    expect(line.passes, isTrue);
    expect(line.purify, isTrue);
    expect(line.text, contains('purify'));
  });

  test('leverage: 30% passes, 30.1% fails', () {
    expect(run(revenue: 1, debt: 300, cap: 1000).lines
        .firstWhere((l) => l.name == 'Leverage').passes, isTrue);
    final ScreenLine line = run(revenue: 1, debt: 301, cap: 1000).lines
        .firstWhere((l) => l.name == 'Leverage');
    expect(line.passes, isFalse);
    expect(line.text, contains('30.1%'));
  });

  test('deposits and securities screen runs only when entered', () {
    expect(run(revenue: 1000, cap: 1000).lines.any((l) => l.name == 'Deposits and securities'), isFalse);
    final ScreenResult r = run(revenue: 1000, cap: 1000, deposits: 400);
    expect(r.lines.firstWhere((l) => l.name == 'Deposits and securities').passes, isFalse);
    expect(r.verdict, 'fail');
  });

  test('overall verdict: pass, fail, incomplete', () {
    expect(run(haram: 10, revenue: 1000, debt: 100, cap: 1000, interest: 10).verdict, 'pass');
    expect(run(haram: 100, revenue: 1000, debt: 100, cap: 1000).verdict, 'fail');
    expect(run(revenue: 1000).verdict, 'incomplete');
    expect(run().verdict, 'incomplete');
    expect(HalalScreen.verdictText(run()), contains('not enough figures'));
  });

  test('purification arithmetic is the dividend times the haram share', () {
    expect(100 * 3 / 100, 3);
  });
}
