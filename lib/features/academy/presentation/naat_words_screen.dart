/// Naat words: read, say and learn the words of public-domain naats and
/// poems of prayer, line by line, in English, Urdu, Arabic or Bangla.
library;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import 'package:go_router/go_router.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../reading/presentation/arabic_block.dart' show TranslitLine;
import '../domain/naat_words.dart';

/// The list of works.
class NaatWordsScreen extends StatelessWidget {
  const NaatWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Naat Words'),
              const ScholarReviewNote(reviewKey: 'nasheed.lyrics'),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Read the words, see how to say them, and learn what they '
                    'mean in English, Urdu, Arabic or Bangla. These are '
                    'naats and poems whose words are free to share. The '
                    'recordings in the player belong to their artists, so '
                    'their lyrics are not copied here.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final NaatWork w in kNaatWorks) ...<Widget>[
                _WorkCard(work: w),
                const SizedBox(height: 12),
              ],
              Text(
                kNaatDraftNote,
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work});

  final NaatWork work;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${work.title}, ${work.poet}, ${work.kind}',
      excludeSemantics: true,
      child: GlassCard(
        onTap: () => context.push('${AppRoutes.naatWords}/${work.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    m.Text(
                      work.titleOriginal,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    m.Text(work.title, style: AppText.body),
                    const SizedBox(height: 2),
                    m.Text(
                      '${work.poet} · ${work.kind}',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

/// One work, line by line.
class NaatReaderScreen extends StatefulWidget {
  const NaatReaderScreen({super.key, required this.id});

  final String id;

  @override
  State<NaatReaderScreen> createState() => _NaatReaderScreenState();
}

class _NaatReaderScreenState extends State<NaatReaderScreen> {
  String? _lang;
  bool _sounds = true;

  @override
  Widget build(BuildContext context) {
    final NaatWork? work = naatWorkById(widget.id);
    if (work == null) {
      return Scaffold(
        body: ScenicScaffold.pattern(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: <Widget>[
                const ScreenHeader(title: 'Naat Words'),
                Text('That poem is not in the library.', style: AppText.body),
              ],
            ),
          ),
        ),
      );
    }
    // The chosen language, else the app's own language when this work has it,
    // else English. The original's own language shows the original only.
    final String appLang = uiLang(context);
    final List<String> langs = work.languages;
    final String lang = _lang ??
        (langs.contains(appLang) && appLang != work.originalLang
            ? appLang
            : (work.originalLang == 'en' ? 'ar' : 'en'));
    final bool rtlMeaning = lang == 'ur' || lang == 'ar';

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: work.title),
              const ScholarReviewNote(reviewKey: 'nasheed.lyrics'),
              Center(
                child: m.Text(
                  work.titleOriginal,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppText.arabicLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: m.Text(
                  '${work.poet} · ${work.kind}',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    work.about,
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Learn the meaning in', style: AppText.label),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String l in kNaatLanguages.keys)
                    if (l != work.originalLang)
                      ChoiceChip(
                        key: Key('naat-lang-$l'),
                        label: m.Text(kNaatLanguages[l]!),
                        selected: lang == l,
                        onSelected: (_) => setState(() => _lang = l),
                      ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                key: const Key('naat-sounds'),
                contentPadding: EdgeInsets.zero,
                title: Text('Show how to say it', style: AppText.body),
                subtitle: Text(
                  'The words in Latin letters',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
                value: _sounds,
                onChanged: (bool v) => setState(() => _sounds = v),
              ),
              const SizedBox(height: 8),
              for (final NaatLine line in work.lines) ...<Widget>[
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        m.Text(
                          line.original,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: AppText.arabic.copyWith(fontSize: 24, height: 1.9),
                        ),
                        if (_sounds) ...<Widget>[
                          const SizedBox(height: 8),
                          TranslitLine(line.sounds, centered: true),
                        ],
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection:
                              rtlMeaning ? TextDirection.rtl : TextDirection.ltr,
                          child: m.Text(
                            line.meaning[lang] ??
                                'This line is not available in this language yet.',
                            textAlign: TextAlign.center,
                            style: AppText.body.copyWith(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                work.source,
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                kNaatDraftNote,
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
