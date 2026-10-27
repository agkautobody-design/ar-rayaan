import 'package:ar_rayaan/features/hadi/grounding/answer_verifier.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/passage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hadi_eval/corpus_fixture.dart';
import 'hadi_eval/hadi_eval.dart';

void main() {
  final HadiCorpus corpus = loadRealCorpus();

  group('corpus integrity', () {
    test('every Qur\'an entry resolves to real text', () {
      final Map<String, dynamic> raw = readCorpusJson();
      final List<dynamic> entries = raw['quran'] as List<dynamic>;
      expect(entries, isNotEmpty);
      for (final dynamic e in entries) {
        final String ref = (e as Map<String, dynamic>)['ref'] as String;
        final Passage? p = corpus.resolve('q:$ref');
        expect(p, isNotNull, reason: 'q:$ref does not resolve');
        expect(p!.arabic, isNotEmpty);
        expect(p.english, isNotEmpty);
        expect((e['topics'] as List<dynamic>), isNotEmpty, reason: ref);
      }
    });

    test('every hadith has provenance: number, grade, grader, date, source', () {
      final Map<String, dynamic> raw = readCorpusJson();
      final List<dynamic> entries = raw['hadith'] as List<dynamic>;
      expect(entries, isNotEmpty);
      for (final dynamic e in entries) {
        final Map<String, dynamic> h = e as Map<String, dynamic>;
        final String id = h['id'] as String;
        for (final String k in <String>[
          'collection',
          'number',
          'english',
          'grade',
          'grader',
          'verifiedOn',
          'verifiedAt',
          'textKind',
        ]) {
          expect((h[k] as String?)?.trim().isNotEmpty ?? false, isTrue,
              reason: '$id is missing $k');
        }
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(h['verifiedOn'] as String),
            isTrue,
            reason: id);
        expect((h['verifiedAt'] as String).startsWith('https://sunnah.com/'),
            isTrue,
            reason: id);
        expect(<String>['summary', 'excerpt'].contains(h['textKind']), isTrue,
            reason: id);
        expect(corpus.resolve(id), isNotNull, reason: id);
      }
    });

    test('Tirmidhi 2499 (weak) and unread pages are not in the corpus', () {
      expect(corpus.hadithByRef('Tirmidhi', '2499'), isNull);
      expect(corpus.hadithByRef('Muslim', '132'), isNull);
      // Bukhari 5999 (the mother and her child) is now a checked card.
      expect(corpus.hadithByRef('Bukhari', '5999'), isNotNull);
    });

    test('Qur\'an text is the bundled text, with ranges and limits', () {
      final Passage? one = corpus.resolve('q:94:5');
      expect(one, isNotNull);
      expect(one!.english, contains('ease'));
      final Passage? range = corpus.resolve('q:94:5-6');
      expect(range, isNotNull);
      expect(range!.english, contains('(94:5)'));
      expect(corpus.resolve('q:94:99'), isNull);
      expect(corpus.resolve('q:115:1'), isNull);
      expect(corpus.resolve('q:2:1-30'), isNull, reason: 'longer than max');
      expect(corpus.resolve('x:1:1'), isNull);
    });

    test('book names fold to one key', () {
      expect(HadiCorpus.bookKey('Sahih al-Bukhari'), HadiCorpus.bookKey('Bukhari'));
      expect(HadiCorpus.bookKey('Sahih Muslim'), HadiCorpus.bookKey('muslim'));
      expect(HadiCorpus.bookKey('Jamiʿ at-Tirmidhi'),
          HadiCorpus.bookKey('Tirmidhi'));
      expect(corpus.hadithByRef('Sahih Muslim', '2749'), isNotNull);
    });
  });

  group('retrieval', () {
    test('finds passages for common human questions', () {
      expect(corpus.retrieve('I feel anxious and full of worry'), isNotEmpty);
      expect(corpus.retrieve('I keep sinning and feel guilty'), isNotEmpty);
      expect(corpus.retrieve('my mother passed away'), isNotEmpty);
    });

    test('offers nothing when the library has nothing', () {
      expect(corpus.retrieve('who will win the football match'), isEmpty);
      expect(corpus.retrieve(''), isEmpty);
    });

    test('is deterministic', () {
      final List<String> a =
          corpus.retrieve('I am worried about money', limit: 4).map((p) => p.id).toList();
      final List<String> b =
          corpus.retrieve('I am worried about money', limit: 4).map((p) => p.id).toList();
      expect(a, b);
    });

    test('what the model is told carries an ID and no more than a short text', () {
      for (final Passage p in corpus.retrieve('anxiety worry', limit: 4)) {
        final String d = HadiCorpus.describeForModel(p);
        expect(d.startsWith('[[src:${p.id}]]'), isTrue);
        expect(d.length, lessThan(400));
      }
    });
  });

  group('answer verifier', () {
    test('a real token becomes a source and disappears from the text', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'That is heavy, and ease comes with hardship. [[src:q:94:5-6]]',
        corpus,
      );
      expect(v.sourceIds, <String>['q:94:5-6']);
      expect(v.text.contains('[['), isFalse);
      expect(v.changed, isFalse);
    });

    test('an unknown token is dropped and counted', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'See this. [[src:h:bukhari-424242]]',
        corpus,
      );
      expect(v.sourceIds, isEmpty);
      expect(v.droppedIds, 1);
      expect(v.changed, isTrue);
    });

    test('a free-typed corpus hadith reference is kept and shown', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'It is in Sahih Muslim 2749.',
        corpus,
      );
      expect(v.sourceIds, contains('h:muslim-2749'));
      expect(v.removedReferences, 0);
    });

    test('a free-typed Qur\'an reference that exists is kept and shown', () {
      final VerifiedAnswer v = AnswerVerifier.verify(
        'Allah says so in Quran 94:6.',
        corpus,
      );
      expect(v.sourceIds, contains('q:94:6'));
    });

    test('a quotation that is inside a shown passage is allowed', () {
      final Passage p = corpus.resolve('q:94:5')!;
      final String inside = p.english.replaceAll(RegExp(r'^\(\d+:\d+\)\s*'), '');
      final VerifiedAnswer v = AnswerVerifier.verify(
        'The verse says "$inside" [[src:q:94:5]]',
        corpus,
      );
      expect(v.removedQuotes, 0, reason: inside);
    });

    test('grades are not allowed without a hadith from the library', () {
      final VerifiedAnswer a = AnswerVerifier.verify(
        'This hadith is graded sahih by scholars.',
        corpus,
      );
      expect(a.unsupportedGrade, isTrue);
      final VerifiedAnswer b = AnswerVerifier.verify(
        'This hadith is graded hasan. [[src:h:tirmidhi-3537]]',
        corpus,
      );
      expect(b.unsupportedGrade, isFalse);
    });

    group('the reader\'s own script', () {
      const String prose = 'آپ نماز اور روزہ کے بارے میں پوچھ رہے ہیں';
      const String vowelled = 'إِنَّ مَعَ الْعُسْرِ يُسْرًا';

      test('is stripped by default, as before', () {
        final VerifiedAnswer v = AnswerVerifier.verify(prose, corpus);
        expect(v.text.contains('نماز'), isFalse);
        expect(v.removedArabic, isTrue);
      });

      test('plain Urdu or Arabic prose is kept for an Urdu or Arabic reader',
          () {
        final VerifiedAnswer v =
            AnswerVerifier.verify(prose, corpus, keepUserScript: true);
        expect(v.text, contains('نماز'));
        expect(v.removedArabic, isFalse);
      });

      test('typed scripture and quoted Arabic are still removed', () {
        final VerifiedAnswer a = AnswerVerifier.verify(
            'Here it is: $vowelled', corpus,
            keepUserScript: true);
        expect(a.text.contains('الْعُسْرِ'), isFalse);
        expect(a.removedArabic, isTrue);
        final VerifiedAnswer b = AnswerVerifier.verify(
            'Allah says “$prose”', corpus,
            keepUserScript: true);
        expect(b.text.contains('نماز'), isFalse);
        expect(b.removedArabic, isTrue);
      });
    });

    for (final HostileCase h in kHostile) {
      test('hostile output neutralised: ${h.id}', () {
        final VerifiedAnswer v = AnswerVerifier.verify(h.raw, corpus);
        for (final String s in h.mustNotContain) {
          expect(v.text.contains(s), isFalse,
              reason: '${h.id}: "$s" survived in "${v.text}"');
        }
        expect(v.changed, isTrue, reason: h.id);
      });
    }
  });
}
