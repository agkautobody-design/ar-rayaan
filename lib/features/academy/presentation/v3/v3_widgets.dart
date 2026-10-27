/// Small shared pieces of the Academy v3 lesson screen: cards, Arabic text, a
/// phrase block, and the hear-it control (shown only when real audio exists).
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../application/academy_strings.dart';
import '../../application/recitation_player_provider.dart';
import '../../domain/recitation_audio.dart';
import '../../domain/v3/phrase_resolver.dart';

String t(String key) => AcademyStrings.get(key);

/// A big Arabic line: right to left, Amiri, wraps at any text size.
class ArabicText extends StatelessWidget {
  const ArabicText(this.text, {super.key, this.size = 30, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: AppText.arabic.copyWith(
        fontSize: size,
        height: 1.9,
        color: color ?? AppColors.goldLight,
      ),
    );
  }
}

/// The eyebrow line of a card: the honesty label and/or the kind of card.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.parts, {super.key});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final String text = parts.where((String p) => p.isNotEmpty).join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppText.eyebrow.copyWith(color: AppColors.gold)),
    );
  }
}

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.children, this.semanticsLabel});

  final List<Widget> children;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      semanticsLabel: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class SourceLine extends StatelessWidget {
  const SourceLine(this.source, {super.key});

  final String? source;

  @override
  Widget build(BuildContext context) {
    final String? s = source;
    if (s == null || s.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text('Source: $s', style: AppText.caption),
    );
  }
}

/// One phrase or ayah block: Arabic, transliteration, meaning, word by word.
class PhraseBlock extends StatelessWidget {
  const PhraseBlock({super.key, required this.phrase, this.highlightAyah});

  final ResolvedPhrase phrase;

  /// Ayah number to highlight (the one being recited).
  final int? highlightAyah;

  @override
  Widget build(BuildContext context) {
    final StringBuffer label = StringBuffer('Arabic. ');
    for (final ResolvedLine l in phrase.lines) {
      if (l.translit != null) label.write('${l.translit}. ');
      if (l.meaning != null) label.write('${l.meaning} ');
    }
    return Semantics(
      container: true,
      label: label.toString(),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final ResolvedLine l in phrase.lines)
              _LineBlock(
                line: l,
                highlighted: highlightAyah != null && l.ayah == highlightAyah,
              ),
            if (phrase.wholeMeaning != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                phrase.wholeMeaning!,
                style: AppText.body.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineBlock extends StatelessWidget {
  const _LineBlock({required this.line, required this.highlighted});

  final ResolvedLine line;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlighted ? AppColors.gold.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: highlighted ? 0.7 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ArabicText(line.arabic),
          if (line.translit != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              line.translit!,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.gold,
                height: 1.5,
              ),
            ),
          ],
          if (line.meaning != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              line.meaning!,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(height: 1.5),
            ),
            if (line.meaningCredit != null)
              Text(
                'Translation: ${line.meaningCredit}',
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),
          ],
          if (line.words != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(t('v3.wordByWord'), style: AppText.eyebrow),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: <Widget>[
                for (final ResolvedWord w in line.words!) _WordChip(word: w),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word});

  final ResolvedWord word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.gold.withValues(alpha: 0.07),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ArabicText(word.arabic, size: 22),
          if (word.tr != null)
            Text(
              word.tr!,
              style: AppText.caption.copyWith(color: AppColors.gold),
              textAlign: TextAlign.center,
            ),
          if (word.en != null)
            Text(word.en!, style: AppText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// "Hear it": plays the real recitation of the ayat in [phrase]. Renders
/// nothing for Arabic the app has no recording of (it never fakes audio).
class HearButton extends ConsumerWidget {
  const HearButton({
    super.key,
    required this.phrase,
    this.repeats = 1,
    this.gapMs = 2500,
    this.label,
  });

  final ResolvedPhrase phrase;

  /// How many times the whole run is played (listen and repeat).
  final int repeats;
  final int gapMs;
  final String? label;

  List<AyahRef> get _refs => <AyahRef>[
        for (final ResolvedLine l in phrase.lines)
          if (l.isAyah) AyahRef(l.surah!, l.ayah!),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!phrase.hasAudio) return const SizedBox.shrink();
    final RecitationPlaybackState st = ref.watch(recitationPlayerProvider);
    final String reciter = ref.watch(selectedReciterProvider).displayName;
    final bool playing = st.playing;
    return Column(
      children: <Widget>[
        FilledButton.icon(
          key: const Key('v3-hear'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.night,
          ),
          onPressed: () {
            final RecitationPlayerNotifier n =
                ref.read(recitationPlayerProvider.notifier);
            if (playing) {
              unawaited(n.stop());
              return;
            }
            unawaited(n.playPlan(RecitationPlanEngine.buildPlan(
              range: _refs,
              perAyahRepeat: 1,
              gapMs: gapMs,
              loopRange: repeats.clamp(1, 10),
            )));
          },
          icon: Icon(playing ? Icons.stop : Icons.volume_up, size: 20),
          label: Text(playing ? t('v3.stop') : (label ?? t('v3.hear'))),
        ),
        const SizedBox(height: 4),
        Text('${t('v3.reciter')}: $reciter', style: AppText.caption),
        if (st.failed)
          Text(t('v3.audioFailed'), style: AppText.caption),
      ],
    );
  }
}

/// Said when the Arabic has no recording: honest, never silent.
class NoAudioNote extends StatelessWidget {
  const NoAudioNote({super.key, required this.phrase});

  final ResolvedPhrase phrase;

  @override
  Widget build(BuildContext context) {
    if (phrase.hasAudio) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(t('v3.noAudio'), style: AppText.caption),
    );
  }
}
