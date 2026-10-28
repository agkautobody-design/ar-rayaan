/// The teaching steps of an Academy v3 lesson: teach / why / story, say,
/// listen and repeat, how-to, school differences, recap and "do it for real".
library;

import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/v3/lesson_v3_model.dart';
import '../../domain/v3/phrase_registry.dart' show WordGloss;
import '../../domain/v3/phrase_resolver.dart';
import '../widgets/glossary_text.dart';
import 'v3_widgets.dart';

TextStyle _body() => AppText.body.copyWith(height: 1.6, fontSize: 15);

class TeachView extends StatelessWidget {
  const TeachView({super.key, required this.step, required this.resolver});

  final TeachStep step;
  final PhraseResolver resolver;

  @override
  Widget build(BuildContext context) {
    final String kind = switch (step.style) {
      TeachStyle.teach => '',
      TeachStyle.why => t('v3.why'),
      TeachStyle.story => t('v3.story'),
    };
    final String? q = step.quranRef;
    final ResolvedPhrase? ayah = q == null ? null : resolver.resolve(q);
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[kind, step.label ?? '']),
        Text(step.title, style: AppText.titleMedium),
        const SizedBox(height: 10),
        for (final String p in step.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlossaryText(p, style: _body()),
          ),
        for (final String b in step.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 6, color: AppColors.gold),
                ),
                Expanded(child: Text(b, style: _body())),
              ],
            ),
          ),
        if (ayah != null) ...<Widget>[
          const SizedBox(height: 10),
          PhraseBlock(phrase: ayah),
          Center(child: HearButton(phrase: ayah)),
        ],
        SourceLine(step.source),
      ],
    );
  }
}

class SayView extends StatelessWidget {
  const SayView({super.key, required this.step, required this.resolver});

  final SayStep step;
  final PhraseResolver resolver;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.say'), step.label ?? '']),
        if (step.title.isNotEmpty) Text(step.title, style: AppText.titleMedium),
        const SizedBox(height: 10),
        for (final String ref in step.refs) _one(ref),
        if (step.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GlossaryText(step.note!, style: _body()),
          ),
        SourceLine(step.source),
      ],
    );
  }

  Widget _one(String ref) {
    final List<GlossSpec>? g = step.words[ref];
    final ResolvedPhrase? p = resolver.resolve(
      ref,
      words: g == null
          ? null
          : <WordGloss>[for (final GlossSpec s in g) WordGloss(tr: s.tr, en: s.en)],
    );
    if (p == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PhraseBlock(phrase: p),
        Center(child: HearButton(phrase: p)),
        NoAudioNote(phrase: p),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Listen and repeat. Only ever an ayah, with the real recitation.
class ListenView extends StatelessWidget {
  const ListenView({super.key, required this.step, required this.resolver});

  final ListenStep step;
  final PhraseResolver resolver;

  @override
  Widget build(BuildContext context) {
    final ResolvedPhrase? p = resolver.resolve(step.ref);
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.listen')]),
        Text(
          step.title.isEmpty ? t('v3.listenTitle') : step.title,
          style: AppText.titleMedium,
        ),
        const SizedBox(height: 10),
        if (step.note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(step.note!, style: _body()),
          ),
        if (p != null) ...<Widget>[
          PhraseBlock(phrase: p),
          Center(
            child: HearButton(
              phrase: p,
              repeats: step.repeats,
              gapMs: 3500,
              label: t('v3.listenGo'),
            ),
          ),
          NoAudioNote(phrase: p),
        ],
      ],
    );
  }
}

class HowToView extends StatelessWidget {
  const HowToView({super.key, required this.step});

  final HowToStep step;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.howto'), step.label ?? '']),
        Text(step.title, style: AppText.titleMedium),
        if (step.intro != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GlossaryText(step.intro!, style: _body()),
          ),
        const SizedBox(height: 12),
        for (int i = 0; i < step.items.length; i++)
          _Item(n: i + 1, item: step.items[i]),
        if (step.mistakes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(t('v3.mistakes'), style: AppText.eyebrow),
          const SizedBox(height: 6),
          for (final String m in step.mistakes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3, right: 8),
                    child: Icon(Icons.info_outline,
                        size: 16, color: AppColors.gold),
                  ),
                  Expanded(child: Text(m, style: _body())),
                ],
              ),
            ),
        ],
        SourceLine(step.source),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.n, required this.item});

  final int n;
  final HowToItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold),
            ),
            child: Text('$n', style: AppText.label),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.text,
                    style: _body().copyWith(fontWeight: FontWeight.w600)),
                if (item.count != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.count!,
                        style: AppText.caption.copyWith(color: AppColors.gold)),
                  ),
                if (item.detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.detail!, style: _body().copyWith(fontSize: 14)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContrastView extends StatelessWidget {
  const ContrastView({super.key, required this.step});

  final ContrastStep step;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.schools'), step.label ?? '[Interpretive]']),
        Text(step.title, style: AppText.titleMedium),
        if (step.intro != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(step.intro!, style: _body()),
          ),
        if (step.agree != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(step.agree!, style: _body()),
          ),
        const SizedBox(height: 12),
        for (final ContrastRow r in step.rows)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(r.name,
                    style: _body().copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.gold)),
                const SizedBox(height: 4),
                Text(r.text, style: _body().copyWith(fontSize: 14)),
              ],
            ),
          ),
        Text(step.closing ?? t('v3.schoolsNote'), style: _body()),
        SourceLine(step.source),
      ],
    );
  }
}

class RecapView extends StatelessWidget {
  const RecapView({super.key, required this.step});

  final RecapStep step;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.recap')]),
        Text(step.title.isEmpty ? t('v3.canDo') : step.title,
            style: AppText.titleMedium),
        const SizedBox(height: 10),
        for (final String c in step.canDo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 10),
                  child: Icon(Icons.check_circle_outline,
                      size: 20, color: AppColors.gold),
                ),
                Expanded(child: Text(c, style: _body())),
              ],
            ),
          ),
        if (step.next != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(step.next!, style: AppText.bodyMuted.copyWith(fontSize: 14)),
          ),
      ],
    );
  }
}

/// "Do it for real": opens a real screen of the app (prayer times, qibla, ...).
class DoItView extends StatelessWidget {
  const DoItView({super.key, required this.step});

  final DoItStep step;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      children: <Widget>[
        Eyebrow(<String>[t('v3.doIt')]),
        Text(step.title, style: AppText.titleMedium),
        const SizedBox(height: 8),
        Text(step.body, style: _body()),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('v3-doit'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => context.push(step.route),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(step.button),
        ),
        const SizedBox(height: 6),
        Text(t('v3.doItOptional'), style: AppText.caption),
      ],
    );
  }
}
