import 'package:ar_rayaan/features/zakat/domain/zakat_calculation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crawl audit: odd things people type into the zakat amount fields.
void main() {
  double p(String s) => ZakatCalculation.parseAmount(s);
  String? problem(String s) => ZakatCalculation.amountProblem(s);

  test('scientific notation is read as the number it says', () {
    expect(p('1e12'), 1e12);
    expect(p('2.5E3'), 2500);
  });

  test('huge numbers are capped, and print without an exponent', () {
    expect(p('1e23'), ZakatCalculation.maxAmount);
    expect(p('9' * 40), ZakatCalculation.maxAmount);
    expect(ZakatCalculation.formatAmount(p('1e23')).contains('e'), isFalse);
    expect(problem('1e23'), 'That number is too large');
  });

  test('digit groups that are not thousands are not glued together', () {
    expect(p('1000 5000'), 0);
    expect(problem('1000 5000'), isNotNull);
  });

  test('real thousands groups still parse', () {
    expect(p('1 234 567'), 1234567);
    expect(p('1,234,567.50'), 1234567.5);
    expect(problem('1 234 567'), isNull);
  });

  test('negative and non-numeric input is flagged', () {
    expect(problem('-500'), contains('negative'));
    expect(problem('abc'), 'Enter the amount as a number');
  });

  test('empty and ordinary input are fine', () {
    expect(problem(''), isNull);
    expect(problem('   '), isNull);
    expect(problem('12500.50'), isNull);
    expect(p('12500.50'), 12500.5);
  });
}
