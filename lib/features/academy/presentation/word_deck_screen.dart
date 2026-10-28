import '../../../app/core/scholar_review.dart';
import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/word_gloss.dart';

/// A card in the plain flashcard viewer (the spaced-repetition deck lives in
/// domain/word_deck.dart and is practised at /academy/review).
class WordPackCard {
  final String arabic, gloss;
  final String? glossSource;
  final int occurrences, frequencyRank;
  final List<int> sourceAyah;
  const WordPackCard({required this.arabic, required this.gloss,
      this.glossSource,
      required this.occurrences, required this.frequencyRank,
      required this.sourceAyah});

  /// False for pack cards whose meaning has not been verified (empty gloss)
  /// or that still carry a truncated verse snippet from an older pack.
  bool get hasMeaning =>
      gloss.trim().isNotEmpty &&
      !gloss.contains('(in context)') &&
      (glossSource?.trim().isNotEmpty ?? false);

  /// The card with its meaning from the separate glosses file (the pack
  /// itself is checksum-pinned and carries none).
  WordPackCard withGloss(Map<String, WordGloss> glosses) {
    final WordGloss? g = glosses['${sourceAyah[0]}:${sourceAyah[1]}:$arabic'];
    if (g == null || hasMeaning) return this;
    return WordPackCard(
        arabic: arabic,
        gloss: g.gloss,
        glossSource: kWordGlossSource,
        occurrences: occurrences,
        frequencyRank: frequencyRank,
        sourceAyah: sourceAyah);
  }

  factory WordPackCard.fromJson(Map<String, dynamic> j) => WordPackCard(
        arabic: j['arabic'] as String,
        gloss: j['gloss'] as String,
        glossSource: j['glossSource'] as String?,
        occurrences: (j['occurrences'] as num).toInt(),
        frequencyRank: (j['frequencyRank'] as num).toInt(),
        sourceAyah: (j['sourceAyah'] as List<dynamic>).cast<int>(),
      );
}

final wordPackProvider = FutureProvider<List<WordPackCard>>((ref) async {
  final raw = await rootBundle.loadString('assets/academy/word_pack.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  Map<String, WordGloss> glosses = <String, WordGloss>{};
  try {
    glosses = parseWordGlosses(
        await rootBundle.loadString('assets/academy/word_glosses.json'));
  } catch (_) {
    // No meanings file: the cards show no meaning rather than an invented one.
  }
  return (d['cards'] as List<dynamic>)
      .map((e) => WordPackCard.fromJson(e as Map<String, dynamic>)
          .withGloss(glosses))
      .toList();
});

/// The Qur'anic Arabic school — the 300 most frequent words of the Qur'an,
/// as a flashcard deck. Frequency order: learn the words you will meet most.
class WordDeckScreen extends ConsumerStatefulWidget {
  const WordDeckScreen({super.key});

  @override
  ConsumerState<WordDeckScreen> createState() => _WordDeckScreenState();
}

class _WordDeckScreenState extends ConsumerState<WordDeckScreen> {
  int _i = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(wordPackProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: deck.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load the word deck.', style: AppText.bodyMuted)),
        data: (cards) {
          final c = cards[_i];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Qur\u2019anic Arabic', close: true),
              const ScholarReviewNote(
                reviewKey: 'gloss',
                padding: const EdgeInsets.only(bottom: 8),
              ),
              Text('العَرَبِيَّةُ القُرْآنِيَّة',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 24,
                      color: Color(0xFFEAD9A8))),
              const SizedBox(height: 4),
              Center(child: Text('THE 300-WORD CORE \u00b7 MOST FREQUENT FIRST',
                  style: AppText.eyebrow)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [
                    Text(c.arabic,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 58,
                            height: 1.6, color: Color(0xFFEAD9A8))),
                    if (_flipped) ...[
                      const SizedBox(height: 14),
                      if (c.hasMeaning)
                        Text(c.gloss,
                            style: AppText.titleMedium.copyWith(fontSize: 22))
                      else
                        Text(
                          'Meaning not verified yet \u2014 read it in its verse.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyMuted,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'appears ${c.occurrences} times \u00b7 rank #${c.frequencyRank} \u00b7 '
                        'first in ${c.sourceAyah[0]}:${c.sourceAyah[1]}',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text('tap to reveal the meaning',
                          style: AppText.bodyMuted.copyWith(fontSize: 12)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _i > 0
                        ? () => setState(() { _i--; _flipped = false; })
                        : null,
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 13, color: AppColors.gold),
                    label: Text('Previous', style: AppText.bodyMuted),
                  ),
                  Text('${_i + 1} / ${cards.length}', style: AppText.eyebrow),
                  TextButton.icon(
                    onPressed: _i < cards.length - 1
                        ? () => setState(() { _i++; _flipped = false; })
                        : null,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppColors.gold),
                    label: Text('Next', style: AppText.bodyMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/academy/review'),
                  child: Text('Practise with spaced repetition \u2192',
                      style: AppText.bodyMuted.copyWith(color: AppColors.gold)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'The 300 most frequent words of the Qur\u2019an, most common first. '
                  'Meanings are written for this app from the Qur\u2019an\u2019s own verses and have not yet been reviewed by a scholar of Arabic.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(height: 1.55),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
