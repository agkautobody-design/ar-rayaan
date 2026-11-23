import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../ui/games_theme.dart';
import 'games_screens.dart';
import 'puzzle_games.dart';

/// Flashcards: the Names of Allah, Arabic on the front, the Name and its
/// meaning on the back. Mark each card "I know it" or "Again"; "Again" cards
/// come back at the end until you know them all.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsState();
}

class _FlashcardsState extends ConsumerState<FlashcardsScreen> {
  List<Name99>? _queue;
  int _total = 0;
  int _known = 0;
  bool _flipped = false;

  void _start(List<Name99> all) {
    final List<Name99> q = List<Name99>.of(all)..shuffle(Random());
    _queue = q.take(10).toList();
    _total = _queue!.length;
  }

  void _answer(bool knew) {
    final List<Name99> q = _queue!;
    final Name99 c = q.removeAt(0);
    setState(() {
      if (knew) {
        _known++;
      } else {
        q.add(c);
      }
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Name99>> names = ref.watch(namesProvider);
    return names.when(
      loading: () => const PuzzleFrame(
        title: 'Flashcards',
        children: <Widget>[Center(child: CircularProgressIndicator())],
      ),
      error: (Object e, StackTrace s) => const PuzzleFrame(
        title: 'Flashcards',
        children: <Widget>[Text('The cards could not be loaded.')],
      ),
      data: (List<Name99> all) {
        if (_queue == null) _start(all);
        final List<Name99> q = _queue!;
        if (q.isEmpty) {
          return PuzzleFrame(
            title: 'Flashcards',
            children: <Widget>[
              const SizedBox(height: 12),
              puzzleDone(
                context,
                headline: 'All $_total cards known',
                detail: 'Come back for a fresh set of Names.',
              ),
            ],
          );
        }
        final Name99 c = q.first;
        return PuzzleFrame(
          title: 'Flashcards',
          tagline: 'Tap the card to turn it over',
          children: <Widget>[
            const SizedBox(height: 8),
            Text('$_known of $_total known', style: AppText.bodyMuted),
            const SizedBox(height: 12),
            GamePanel(
              semanticsLabel: _flipped
                  ? '${c.name}. ${c.meaning}'
                  : 'Card front. Tap to turn over',
              onTap: () => setState(() => _flipped = !_flipped),
              child: SizedBox(
                height: 220,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _flipped
                        ? Column(
                            key: const ValueKey<bool>(true),
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(c.name,
                                  textAlign: TextAlign.center,
                                  style: AppText.titleMedium),
                              const SizedBox(height: 10),
                              Text(c.meaning,
                                  textAlign: TextAlign.center,
                                  style:
                                      AppText.bodyMuted.copyWith(height: 1.5)),
                            ],
                          )
                        : Text(
                            c.arabic ?? c.name,
                            key: const ValueKey<bool>(false),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 48,
                              height: 1.6,
                              color: AppColors.goldLight,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_flipped) ...<Widget>[
              PlayButton(label: 'I know it', onPressed: () => _answer(true)),
              const SizedBox(height: 10),
              OutlineAction(label: 'Again', onPressed: () => _answer(false)),
            ] else
              PlayButton(
                label: 'Turn over',
                onPressed: () => setState(() => _flipped = true),
              ),
          ],
        );
      },
    );
  }
}
