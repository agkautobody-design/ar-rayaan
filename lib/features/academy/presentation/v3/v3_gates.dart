/// The steps that gate an Academy v3 lesson: check (multiple choice, fill the
/// word, scenario), arrange the steps, and match.
///
/// A wrong answer re-teaches and offers the step that taught it. After two
/// misses the answer is shown and the learner moves on: nobody is trapped.
/// Nothing here counts points, scores or streaks.
library;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../domain/v3/lesson_v3_model.dart';
import '../../domain/v3/lesson_v3_review.dart' show fillSentence;
import '../../domain/v3/lesson_v3_state.dart';
import '../../domain/v3/phrase_resolver.dart';
import 'v3_widgets.dart';

TextStyle _body() => AppText.body.copyWith(height: 1.55, fontSize: 15);

/// Moves keyboard focus to [node] after the next frame. A button that has just
/// been used often turns off or leaves the list, and focus would then drop to
/// the top of the page ("Copy this lesson"), so every check puts it somewhere
/// useful on purpose.
void _focusLater(State<StatefulWidget> state, FocusNode? node) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!state.mounted || node == null) return;
    if (node.canRequestFocus && node.context != null) node.requestFocus();
  });
}

/// The result of a check, spoken as soon as it appears (a polite live region)
/// and a place focus can be sent to. [spoken] is the whole sentence read out;
/// the visible [child] is hidden from the reader so it is not said twice.
class _Result extends StatelessWidget {
  const _Result({
    required this.node,
    required this.spoken,
    required this.child,
  });

  final FocusNode node;
  final String spoken;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: node,
      skipTraversal: true,
      child: Semantics(
        liveRegion: true,
        container: true,
        label: spoken,
        child: ExcludeSemantics(child: child),
      ),
    );
  }
}

/// A face of a match or an option: plain text, or Arabic.
class FaceText extends StatelessWidget {
  const FaceText({super.key, this.text, this.arabic, this.translit});

  final String? text;
  final String? arabic;

  /// How the Arabic sounds, shown under it so a learner who cannot read the
  /// script yet can still check a match.
  final String? translit;

  @override
  Widget build(BuildContext context) {
    final String? a = arabic;
    final String? tl = translit;
    if (a != null && tl != null && tl.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ArabicText(a, size: 26),
          const SizedBox(height: 4),
          Text(
            tl,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(fontSize: 13, height: 1.35),
          ),
        ],
      );
    }
    if (a != null) return ArabicText(a, size: 26);
    return Text(text ?? '', textAlign: TextAlign.center, style: _body());
  }
}

ButtonStyle _choiceStyle({bool good = false, bool dim = false}) {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, 52),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    side: BorderSide(
      color: good
          ? AppColors.gold
          : AppColors.gold.withValues(alpha: dim ? 0.12 : 0.4),
      width: good ? 2 : 1,
    ),
  );
}

// ---------------------------------------------------------------------------
// Check
// ---------------------------------------------------------------------------

class CheckView extends StatefulWidget {
  const CheckView({
    super.key,
    required this.state,
    required this.resolver,
    required this.onGoBack,
    required this.onPassed,
  });

  final CheckStepState state;
  final PhraseResolver resolver;

  /// Show me the step that taught this.
  final void Function(String stepId) onGoBack;
  final VoidCallback onPassed;

  @override
  State<CheckView> createState() => _CheckViewState();
}

class _CheckViewState extends State<CheckView> {
  /// The items the learner was shown the answer to, asked once more.
  CheckStepState? _again;
  bool _passedSent = false;

  final Map<int, FocusNode> _optionNodes = <int, FocusNode>{};
  final FocusNode _nextNode = FocusNode(debugLabel: 'v3-next-question');
  final FocusNode _resultNode = FocusNode(debugLabel: 'v3-check-result');

  CheckStepState get _s => _again ?? widget.state;

  FocusNode _optionNode(int i) =>
      _optionNodes.putIfAbsent(i, () => FocusNode(debugLabel: 'v3-option-$i'));

  @override
  void dispose() {
    for (final FocusNode n in _optionNodes.values) {
      n.dispose();
    }
    _nextNode.dispose();
    _resultNode.dispose();
    super.dispose();
  }

  void _pick(int i) {
    setState(() => _s.pick(i));
    _afterChange();
    final CheckStepState s = _s;
    if (s.itemSettled) {
      // Right (or shown): on to the Next button, or the result on the last.
      _focusLater(this, s.isLastItem ? _resultNode : _nextNode);
    } else {
      // Wrong: stay in the options, on the first one still open; the live
      // region says what to look at again.
      for (int k = 0; k < s.item.options.length; k++) {
        if (!s.tried.contains(k)) {
          _focusLater(this, _optionNode(k));
          break;
        }
      }
    }
  }

  void _next() {
    setState(() => _s.advance());
    _afterChange();
    _focusLater(this, _optionNode(0));
  }

  void _afterChange() {
    final CheckStepState s = _s;
    if (!s.allSettled) return;
    if (_again == null) {
      final List<CheckItem> missed = <CheckItem>[
        for (int i = 0; i < widget.state.step.items.length; i++)
          if (widget.state.run.wasRevealed(widget.state.keyOf(i)))
            widget.state.step.items[i],
      ];
      if (missed.isNotEmpty) {
        setState(() {
          _again = CheckStepState(
            CheckStep(id: '${widget.state.step.id}~again', items: missed),
            GatedRun(),
          );
        });
        return;
      }
    }
    if (!_passedSent) {
      _passedSent = true;
      widget.onPassed();
    }
  }

  String _label(CheckOption o) {
    if (o.text != null) return o.text!;
    if (o.word != null) return widget.resolver.wordArabic(o.word!) ?? '';
    if (o.ref != null) return widget.resolver.resolve(o.ref!)?.arabicJoined ?? '';
    return '';
  }

  bool _isArabic(CheckOption o) => o.text == null;

  @override
  Widget build(BuildContext context) {
    final CheckStepState s = _s;
    final CheckItem it = s.item;
    final bool settled = s.itemSettled;
    final ResolvedPhrase? shown =
        it.ref == null ? null : widget.resolver.resolve(it.ref!);
    final String? blanked = fillSentence(it, widget.resolver);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_again != null) ...<Widget>[
          Text(t('v3.again'), style: AppText.titleMedium),
          const SizedBox(height: 4),
          Text(t('v3.againBody'), style: AppText.caption),
          const SizedBox(height: 10),
        ] else if ((widget.state.step.title).isNotEmpty) ...<Widget>[
          Text(widget.state.step.title, style: AppText.titleMedium),
          const SizedBox(height: 10),
        ],
        Text(
          '${s.current + 1} / ${s.step.items.length}',
          style: AppText.caption,
        ),
        const SizedBox(height: 6),
        GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (it.scenario != null) ...<Widget>[
                Eyebrow(<String>[t('v3.scenario')]),
                Text(it.scenario!, style: _body()),
                const SizedBox(height: 10),
              ],
              if (shown != null) ...<Widget>[
                PhraseBlock(phrase: shown),
                const SizedBox(height: 8),
              ],
              if (blanked != null && it.fill!.show == 'arabic') ...<Widget>[
                ArabicText(blanked, size: 30),
                const SizedBox(height: 8),
              ],
              Text(it.question,
                  style: _body().copyWith(fontWeight: FontWeight.w600)),
              if (blanked != null && it.fill!.show == 'translit')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    blanked,
                    textAlign: TextAlign.center,
                    style: AppText.titleMedium.copyWith(color: AppColors.gold),
                  ),
                ),
              const SizedBox(height: 12),
              for (int i = 0; i < it.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: Key('v3-option-$i'),
                    focusNode: _optionNode(i),
                    style: _choiceStyle(
                      good: settled && i == it.answer,
                      dim: s.tried.contains(i) || (settled && i != it.answer),
                    ),
                    onPressed:
                        settled || s.tried.contains(i) ? null : () => _pick(i),
                    child: _isArabic(it.options[i])
                        ? ArabicText(_label(it.options[i]), size: 26)
                        : Text(_label(it.options[i]),
                            textAlign: TextAlign.center, style: _body()),
                  ),
                ),
              if (s.reteach != null && !settled) ...<Widget>[
                const SizedBox(height: 4),
                _Result(
                  node: _resultNode,
                  spoken: '${t('v3.notQuite')} ${s.reteach!}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(t('v3.notQuite'),
                          style: _body().copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold)),
                      const SizedBox(height: 4),
                      Text(s.reteach!,
                          key: const Key('v3-reteach'), style: _body()),
                    ],
                  ),
                ),
                if (s.back != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('v3-show-step'),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => widget.onGoBack(s.back!),
                      icon: const Icon(Icons.undo, size: 18),
                      label: Text(t('v3.showStep')),
                    ),
                  ),
              ],
              if (settled) ...<Widget>[
                const SizedBox(height: 4),
                _Result(
                  node: _resultNode,
                  spoken: '${s.itemRevealed ? t('v3.answerIs') : t('v3.right')} '
                      '${it.explain}'
                      '${s.itemRevealed ? ' ${t('v3.comesBack')}' : ''}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        s.itemRevealed ? t('v3.answerIs') : t('v3.right'),
                        style: _body().copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold),
                      ),
                      const SizedBox(height: 4),
                      Text(it.explain,
                          key: const Key('v3-explain'), style: _body()),
                      if (s.itemRevealed) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(t('v3.comesBack'), style: AppText.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (settled && !s.isLastItem)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              key: const Key('v3-next-question'),
              focusNode: _nextNode,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _next,
              child: Text(t('v3.nextQuestion')),
            ),
          ),
        if (settled && s.isLastItem && s.allSettled)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(t('v3.checkDone'), style: AppText.bodyMuted),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Arrange
// ---------------------------------------------------------------------------

class ArrangeView extends StatefulWidget {
  const ArrangeView({
    super.key,
    required this.state,
    required this.onGoBack,
    required this.onPassed,
  });

  final ArrangeState state;
  final void Function(String stepId) onGoBack;
  final VoidCallback onPassed;

  @override
  State<ArrangeView> createState() => _ArrangeViewState();
}

class _ArrangeViewState extends State<ArrangeView> {
  ArrangeState get _s => widget.state;

  final Map<int, FocusNode> _poolNodes = <int, FocusNode>{};
  final FocusNode _checkNode = FocusNode(debugLabel: 'v3-check-order');
  final FocusNode _resultNode = FocusNode(debugLabel: 'v3-arrange-result');

  FocusNode _poolNode(int i) =>
      _poolNodes.putIfAbsent(i, () => FocusNode(debugLabel: 'v3-pool-$i'));

  @override
  void dispose() {
    for (final FocusNode n in _poolNodes.values) {
      n.dispose();
    }
    _checkNode.dispose();
    _resultNode.dispose();
    super.dispose();
  }

  /// After a step moves between the lists, focus goes to the first step still
  /// to place, or to Check once every step is placed.
  void _focusNextAction() {
    final List<int> left = _s.remaining;
    _focusLater(this, left.isEmpty ? _checkNode : _poolNode(left.first));
  }

  void _check() {
    setState(() => _s.check());
    if (_s.settled) {
      widget.onPassed();
      _focusLater(this, _resultNode);
    } else {
      _focusNextAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ArrangeStep step = _s.step;
    final ArrangeFeedback? fb = _s.feedback;
    final bool settled = _s.settled;
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Eyebrow(<String>[t('v3.arrange')]),
          if (step.title.isNotEmpty) Text(step.title, style: AppText.titleMedium),
          const SizedBox(height: 8),
          Text(step.prompt, style: _body()),
          const SizedBox(height: 4),
          Text(settled ? '' : t('v3.takeBack'), style: AppText.caption),
          const SizedBox(height: 8),
          Text(t('v3.yourOrder'), style: AppText.eyebrow),
          const SizedBox(height: 6),
          if (_s.placed.isEmpty)
            Text(t('v3.tapToPlace'), style: AppText.caption),
          for (int pos = 0; pos < _s.placed.length; pos++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: Key('v3-placed-$pos'),
                style: _choiceStyle(good: settled),
                onPressed: settled
                    ? null
                    : () {
                        setState(() => _s.takeBackFrom(pos));
                        _focusNextAction();
                      },
                child: Semantics(
                  label: 'Place ${pos + 1}: ${step.items[_s.placed[pos]].text}'
                      '${settled ? '' : '. Press to take it back.'}',
                  excludeSemantics: true,
                  child: Row(
                    children: <Widget>[
                      Text('${pos + 1}.  ', style: AppText.label),
                      Expanded(
                        child: Text(step.items[_s.placed[pos]].text,
                            style: _body()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!settled && _s.remaining.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(t('v3.remaining'), style: AppText.eyebrow),
            const SizedBox(height: 6),
            for (final int i in _s.remaining)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key('v3-pool-$i'),
                  focusNode: _poolNode(i),
                  style: _choiceStyle(),
                  onPressed: () {
                    setState(() => _s.place(i));
                    _focusNextAction();
                  },
                  child: Text(step.items[i].text, style: _body()),
                ),
              ),
          ],
          if (!settled)
            FilledButton(
              key: const Key('v3-check-order'),
              focusNode: _checkNode,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _s.complete ? _check : null,
              child: Text(t('v3.checkOrder')),
            ),
          if (fb != null && fb.reteach != null && !settled) ...<Widget>[
            const SizedBox(height: 10),
            _Result(
              node: _resultNode,
              spoken: '${t('v3.notQuite')} ${fb.reteach!}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(t('v3.notQuite'),
                      style: _body().copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.gold)),
                  Text(fb.reteach!,
                      key: const Key('v3-reteach'), style: _body()),
                ],
              ),
            ),
            if (fb.back != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('v3-show-step'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => widget.onGoBack(fb.back!),
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(t('v3.showStep')),
                ),
              ),
          ],
          if (settled) ...<Widget>[
            const SizedBox(height: 10),
            _Result(
              node: _resultNode,
              spoken: '${_s.revealed ? t('v3.answerIs') : t('v3.right')} '
                  '${step.explain}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _s.revealed ? t('v3.answerIs') : t('v3.right'),
                    style: _body().copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.gold),
                  ),
                  Text(step.explain,
                      key: const Key('v3-explain'), style: _body()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Match
// ---------------------------------------------------------------------------

class MatchView extends StatefulWidget {
  const MatchView({
    super.key,
    required this.state,
    required this.resolver,
    required this.onGoBack,
    required this.onPassed,
  });

  final MatchState state;
  final PhraseResolver resolver;
  final void Function(String stepId) onGoBack;
  final VoidCallback onPassed;

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  MatchFeedback? _fb;
  MatchState get _s => widget.state;

  final Map<int, FocusNode> _leftNodes = <int, FocusNode>{};
  final Map<int, FocusNode> _rightNodes = <int, FocusNode>{};
  final FocusNode _resultNode = FocusNode(debugLabel: 'v3-match-result');

  FocusNode _leftNode(int i) =>
      _leftNodes.putIfAbsent(i, () => FocusNode(debugLabel: 'v3-left-$i'));
  FocusNode _rightNode(int i) =>
      _rightNodes.putIfAbsent(i, () => FocusNode(debugLabel: 'v3-right-$i'));

  @override
  void dispose() {
    for (final FocusNode n in _leftNodes.values) {
      n.dispose();
    }
    for (final FocusNode n in _rightNodes.values) {
      n.dispose();
    }
    _resultNode.dispose();
    super.dispose();
  }

  /// The words of a face, for a screen reader (the Arabic when it is Arabic).
  String _plain(Face f) {
    final String? a = _arabicOf(f);
    if (f.text != null || a == null) return f.text ?? '';
    final String? tl = _translitOf(f);
    return tl == null || tl.isEmpty ? a : '$a, said $tl';
  }

  String? _arabicOf(Face f) {
    if (f.ref != null) return widget.resolver.resolve(f.ref!)?.arabicJoined;
    if (f.word != null) return widget.resolver.wordArabic(f.word!);
    return null;
  }

  String? _translitOf(Face f) {
    final String? ref = f.ref;
    if (ref == null) return null;
    final ResolvedPhrase? p = widget.resolver.resolve(ref);
    if (p == null || p.lines.length != 1) return null;
    return p.lines.first.translit;
  }

  Widget _face(Face f) => FaceText(
        text: f.text,
        arabic: _arabicOf(f),
        translit: _translitOf(f),
      );

  void _tapRight(int pair) {
    final MatchFeedback? r = _s.tapRight(pair);
    setState(() => _fb = r);
    if (_s.allSettled) {
      widget.onPassed();
      _focusLater(this, _resultNode);
      return;
    }
    // A joined pair turns its buttons off; keep focus in the list, on the
    // next left word still to match.
    for (int i = 0; i < _s.step.pairs.length; i++) {
      if (!_s.done.contains(i)) {
        _focusLater(this, _leftNode(i));
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MatchStep step = _s.step;
    final MatchFeedback? fb = _fb;
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Eyebrow(<String>[t('v3.match')]),
          if (step.title.isNotEmpty) Text(step.title, style: AppText.titleMedium),
          const SizedBox(height: 8),
          Text(step.prompt, style: _body()),
          const SizedBox(height: 12),
          for (int i = 0; i < step.pairs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: Key('v3-left-$i'),
                focusNode: _leftNode(i),
                style: _choiceStyle(
                  good: _s.selectedLeft == i,
                  dim: _s.done.contains(i),
                ),
                onPressed: _s.done.contains(i)
                    ? null
                    : () {
                        setState(() {
                          _s.selectLeft(i);
                          _fb = null;
                        });
                        // Next stop: the faces to match it with.
                        for (final int p in _s.rightOrder) {
                          if (!_s.done.contains(p)) {
                            _focusLater(this, _rightNode(p));
                            break;
                          }
                        }
                      },
                // The tick is not enough for a screen reader: say it.
                child: Semantics(
                  label: _s.done.contains(i)
                      ? '${_plain(step.pairs[i].left)}, matched with '
                          '${_plain(step.pairs[i].right)}'
                      : (_s.selectedLeft == i
                          ? '${_plain(step.pairs[i].left)}, chosen'
                          : _plain(step.pairs[i].left)),
                  excludeSemantics: true,
                  child: Row(
                    children: <Widget>[
                      if (_s.done.contains(i))
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child:
                              Icon(Icons.check, size: 18, color: AppColors.gold),
                        ),
                      Expanded(child: _face(step.pairs[i].left)),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(height: 24),
          Text(
            _s.selectedLeft == null ? t('v3.tapLeft') : t('v3.tapRight'),
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          for (final int p in _s.rightOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: Key('v3-right-$p'),
                focusNode: _rightNode(p),
                style: _choiceStyle(dim: _s.done.contains(p)),
                onPressed: _s.done.contains(p) || _s.selectedLeft == null
                    ? null
                    : () => _tapRight(p),
                child: Semantics(
                  label: _s.done.contains(p)
                      ? '${_plain(step.pairs[p].right)}, matched with '
                          '${_plain(step.pairs[p].left)}'
                      : _plain(step.pairs[p].right),
                  excludeSemantics: true,
                  child: _face(step.pairs[p].right),
                ),
              ),
            ),
          if (fb != null && fb.correct && !_s.allSettled) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              container: true,
              label: t('v3.right'),
              child: ExcludeSemantics(
                child: Text(
                  t('v3.right'),
                  key: const Key('v3-match-right'),
                  style: _body().copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.gold),
                ),
              ),
            ),
          ],
          if (fb != null && fb.reteach != null) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              container: true,
              label: fb.reteach!,
              child: ExcludeSemantics(
                child: Text(fb.reteach!,
                    key: const Key('v3-reteach'), style: _body()),
              ),
            ),
            if (fb.back != null && !_s.allSettled)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('v3-show-step'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => widget.onGoBack(fb.back!),
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(t('v3.showStep')),
                ),
              ),
          ],
          if (_s.allSettled) ...<Widget>[
            const SizedBox(height: 8),
            _Result(
              node: _resultNode,
              spoken: t('v3.matchedAll'),
              child: Text(t('v3.matchedAll'),
                  style: _body().copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.gold)),
            ),
          ],
        ],
      ),
    );
  }
}
