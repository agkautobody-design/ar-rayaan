import 'package:ar_rayaan/app/theme/widgets/whole_word_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round 8: the settings switch rows showed a wrapped subtitle cut to its
/// first line with an ellipsis ("Private log for Qur'an reading, ...").
/// The cause was an ellipsis overflow on a text with no line limit.
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
      );

  testWidgets('without a line limit the text wraps and is never ellipsised',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(const WholeWordText(
        'Totals and a calendar for Qur’an reading, dhikr and lessons, kept on '
        'this device only.',
      )),
    );
    final Text t = tester.widget<Text>(find.byType(Text));
    expect(t.maxLines, isNull);
    expect(t.overflow, isNot(TextOverflow.ellipsis));
    final RenderParagraph p =
        tester.renderObject<RenderParagraph>(find.byType(RichText));
    expect(p.didExceedMaxLines, isFalse);
  });

  testWidgets('with a line limit the ellipsis is kept',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(const WholeWordText(
        'A long title that cannot fit on one line of this narrow box',
        maxLines: 1,
      )),
    );
    final Text t = tester.widget<Text>(find.byType(Text));
    expect(t.overflow, TextOverflow.ellipsis);
  });
}
