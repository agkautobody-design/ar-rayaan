/// Review session — one card at a time, dignity-first.
///
/// Front: the word as it appears in the Quran + its ayah context.
/// Tap anywhere to flip: gloss, root, occurrences. Self-grade with
/// Again / Good / Easy — wrong-feeling taps reteach gently, nothing
/// is timed, nothing is red (Simplicity Charter).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/academy_strings.dart';
import '../application/sfx_provider.dart';
import '../application/word_deck_provider.dart';
import '../domain/sfx.dart';
import '../domain/spaced_repetition.dart';
import '../domain/word_deck.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState
    extends ConsumerState<ReviewSessionScreen> {
  int _index = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final List<WordCard> session = ref.watch(todaySessionProvider);

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: session.isEmpty
            ? _EmptyState(onDone: () => Navigator.of(context).maybePop())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  ScreenHeader(
                    title: AcademyStrings.get('academy.title'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_index + 1} / ${session.length}',
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _ReviewCardView(
                    card: session[_index.clamp(0, session.length - 1)],
                    flipped: _flipped,
                    onFlip: () => setState(() => _flipped = !_flipped),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      for (final (ReviewGrade g, String label, IconData ic)
                          in <(ReviewGrade, String, IconData)>[
                        (ReviewGrade.again, 'Again', Icons.refresh),
                        (ReviewGrade.good, 'Good', Icons.check),
                        (ReviewGrade.easy, 'Easy', Icons.auto_awesome),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _GradeButton(
                              label: label,
                              icon: ic,
                              onPressed: () => _grade(g),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _grade(ReviewGrade g) async {
    final List<WordCard> session = ref.read(todaySessionProvider);
    if (session.isEmpty) return;
    await SfxPlayer.play(Sfx.wordGraded, ref.read(soundSettingsProvider).tier);
    await ref
        .read(wordDeckProvider.notifier)
        .grade(session[_index].key, g);
    setState(() {
      _flipped = false;
      _index++;
    });
  }
}

class _ReviewCardView extends StatelessWidget {
  const _ReviewCardView({
    required this.card,
    required this.flipped,
    required this.onFlip,
  });

  final WordCard card;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: GlassCard(
        strong: true,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: Column(
            children: <Widget>[
              SelectableText(
                card.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 44,
                  height: 1.4,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 10),
              if (card.sourceAyah != null)
                Text(
                  'Qur’an ${card.sourceAyah!.surah}:${card.sourceAyah!.ayah}',
                  style: AppText.caption,
                ),
              if (flipped) ...<Widget>[
                const Divider(height: 24),
                Text(card.gloss,
                    style: AppText.titleMedium, textAlign: TextAlign.center),
                if (card.root != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Root: ${card.root}',
                      style: AppText.bodyMuted, textAlign: TextAlign.center),
                ],
                Text(
                  card.occurrences > 1
                      ? 'Appears ${card.occurrences} times in the Qur’an'
                      : 'Unique in the Qur’an',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ] else ...<Widget>[
                const SizedBox(height: 12),
                Text('Tap to reveal meaning',
                    style: AppText.caption, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          strong: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.auto_awesome,
                  color: AppColors.gold, size: 36),
              const SizedBox(height: 12),
              Text('All caught up', style: AppText.titleMedium),
              const SizedBox(height: 6),
              Text(
                'No words due today. Every step counts — no matter how small.',
                style: AppText.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onDone, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}
