import 'package:ar_rayaan/features/hadi/grounding/distress_signal.dart';
import 'package:ar_rayaan/features/support/domain/safe_replies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaithAndIdentity', () {
    test('a first-person disclosure with a faith worry is detected', () {
      expect(FaithAndIdentity.detect('I am gay and Muslim, will Allah hate me'),
          isTrue);
      expect(FaithAndIdentity.detect('i am a lesbian is it a sin'), isTrue);
    });

    test('a plain question about the ruling is not a disclosure', () {
      expect(FaithAndIdentity.detect('what does islam say about gay marriage'),
          isFalse);
      expect(FaithAndIdentity.detect('what is zakat'), isFalse);
    });

    test('the replies are warm, honest and do not rule on the person', () {
      for (int i = 0; i < FaithAndIdentity.replies.length; i++) {
        final String r = FaithAndIdentity.build(i);
        expect(r, contains('2751'));
        expect(r.toLowerCase(), contains('cannot rule'));
      }
      expect(FaithAndIdentity.build(0), isNot(FaithAndIdentity.build(1)));
    });
  });

  group('KillingQuestion', () {
    test('questions about who deserves to be killed are detected', () {
      expect(KillingQuestion.detect('Which people deserve to be killed in Islam'),
          isTrue);
      expect(KillingQuestion.detect('is it halal to kill non muslims'), isTrue);
    });

    test('ordinary questions are not', () {
      expect(KillingQuestion.detect('what is the ruling on halal meat'), isFalse);
      expect(KillingQuestion.detect('who was killed at uhud'), isFalse);
    });

    test('the reply states the sanctity of life and cites checked sources', () {
      expect(KillingQuestion.reply, contains('5:32'));
      expect(KillingQuestion.reply, contains('3166'));
      expect(KillingQuestion.reply.toLowerCase(), contains('not a fatwa'));
    });
  });

  group('DistressSignal', () {
    test('losing faith is heard, not answered with verse cards', () {
      expect(DistressSignal.packFor('I am losing my faith'), 'being_heard');
      expect(DistressSignal.themeFor('I am losing my faith'), 'far');
    });
  });
}
