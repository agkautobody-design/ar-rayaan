/// Naat words: read, hear and learn the words of public-domain naats and
/// poems of prayer, line by line, in English, Urdu, Arabic or Bangla, and keep
/// poems of your own.
library;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../reading/presentation/arabic_block.dart' show TranslitLine;
import '../application/naat_recital.dart';
import '../application/user_poems_provider.dart';
import '../domain/naat_words.dart';
import '../domain/user_poem.dart';

/// The list of works, then the person's own poems.
class NaatWordsScreen extends ConsumerWidget {
  const NaatWordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<UserPoem> mine = ref.watch(userPoemsProvider);
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
                    'Read the words, hear them read aloud line by line, and '
                    'learn what they mean in English, Urdu, Arabic or Bangla. '
                    'These are naats and poems whose words are free to share. '
                    'The recordings in the player belong to their artists, so '
                    'their lyrics are not copied here.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final NaatWork w in kNaatWorks) ...<Widget>[
                _EntryCard(
                  id: w.id,
                  original: w.titleOriginal,
                  title: w.title,
                  line: '${w.poet} · ${w.kind}',
                  rtl: true,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              Text('Your own poems', style: AppText.label),
              const SizedBox(height: 6),
              for (final UserPoem p in mine) ...<Widget>[
                _EntryCard(
                  id: p.id,
                  original: p.lines.first,
                  title: p.title,
                  line: 'Added by you · on this phone only',
                  rtl: p.lang == 'ar' || p.lang == 'ur',
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                key: const Key('naat-add'),
                onPressed: () => context.push('${AppRoutes.naatWords}/add'),
                icon: const Icon(Icons.add, color: AppColors.gold),
                label: Text('Add your own poem or naat'),
              ),
              const SizedBox(height: 16),
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

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.id,
    required this.original,
    required this.title,
    required this.line,
    required this.rtl,
  });

  final String id;
  final String original;
  final String title;
  final String line;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $line',
      excludeSemantics: true,
      child: GlassCard(
        onTap: () => context.push('${AppRoutes.naatWords}/$id'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    m.Text(
                      original,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                      style: AppText.arabic.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    m.Text(title, style: AppText.body),
                    const SizedBox(height: 2),
                    m.Text(
                      line,
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

/// What the reader shows, whether the poem is from the library or the
/// person's own.
class _View {
  const _View({
    required this.title,
    required this.titleOriginal,
    required this.subtitle,
    required this.about,
    required this.source,
    required this.lang,
    required this.lines,
    required this.meaningLangs,
    this.mine = false,
    this.audioUrl,
    this.id = '',
  });

  final String id;
  final String title;
  final String titleOriginal;
  final String subtitle;
  final String about;
  final String source;
  final String lang;
  final List<_VLine> lines;

  /// Languages a meaning can be shown in, in the order of the buttons.
  final List<String> meaningLangs;
  final bool mine;
  final String? audioUrl;

  bool get canRecite => kRecitalLanguages.contains(lang);
}

class _VLine {
  const _VLine(this.original, this.sounds, this.meaning, [this.hindi]);

  final String original;
  final String? sounds;

  /// The original in Hindi script, when the poem has it.
  final String? hindi;
  final Map<String, String> meaning;
}

_View? _viewFor(String id, List<UserPoem> mine) {
  final NaatWork? w = naatWorkById(id);
  if (w != null) {
    return _View(
      title: w.title,
      titleOriginal: w.titleOriginal,
      subtitle: '${w.poet} · ${w.kind}',
      about: w.about,
      source: w.source,
      lang: w.originalLang,
      meaningLangs: <String>[
        for (final String l in kNaatLanguages.keys)
          if (l != w.originalLang) l,
      ],
      lines: <_VLine>[
        for (final NaatLine l in w.lines)
          _VLine(l.original, l.sounds, l.meaning, l.devanagari),
      ],
    );
  }
  for (final UserPoem p in mine) {
    if (p.id != id) continue;
    return _View(
      id: p.id,
      title: p.title,
      titleOriginal: p.lines.first,
      subtitle: 'Added by you · on this phone only',
      about: '',
      source: 'Words added by you. The app has not checked them.',
      lang: p.lang,
      mine: true,
      audioUrl: p.audioUrl,
      meaningLangs: <String>[
        if (p.meaningLang != null && p.meanings.isNotEmpty) p.meaningLang!,
      ],
      lines: <_VLine>[
        for (int i = 0; i < p.lines.length; i++)
          _VLine(p.lines[i], null, <String, String>{
            if (p.meaningLang != null &&
                i < p.meanings.length &&
                p.meanings[i].trim().isNotEmpty)
              p.meaningLang!: p.meanings[i],
          }),
      ],
    );
  }
  return null;
}

/// One poem, line by line.
class NaatReaderScreen extends ConsumerStatefulWidget {
  const NaatReaderScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<NaatReaderScreen> createState() => _NaatReaderScreenState();
}

class _NaatReaderScreenState extends ConsumerState<NaatReaderScreen> {
  String? _lang;
  bool _sounds = true;
  bool _hindiScript = false;
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};

  void _follow(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _keys[index]?.currentContext;
      if (c == null || !c.mounted) return;
      try {
        Scrollable.ensureVisible(
          c,
          alignment: 0.3,
          duration: const Duration(milliseconds: 300),
        );
      } catch (_) {
        // Not scrollable right now.
      }
    });
  }

  Future<void> _remove(_View v) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Remove this poem?'),
        content: Text('It is only on this phone. This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Keep it'),
          ),
          TextButton(
            key: const Key('poem-remove-yes'),
            onPressed: () => Navigator.pop(c, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await ref.read(userPoemsProvider.notifier).remove(v.id);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.naatWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<UserPoem> mine = ref.watch(userPoemsProvider);
    final _View? v = _viewFor(widget.id, mine);
    ref.listen<RecitalState>(naatRecitalProvider, (
      RecitalState? prev,
      RecitalState next,
    ) {
      if (next.index >= 0 && next.index != prev?.index) _follow(next.index);
    });
    final RecitalState recital = ref.watch(naatRecitalProvider);

    if (v == null) {
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
    // The chosen language, else the app's own language when this poem has
    // it, else the first one it has.
    final String appLang = uiLang(context);
    final String? lang = v.meaningLangs.isEmpty
        ? null
        : (_lang != null && v.meaningLangs.contains(_lang)
              ? _lang
              : (v.meaningLangs.contains(appLang)
                    ? appLang
                    : (v.meaningLangs.contains('en')
                          ? (v.lang == 'en' ? v.meaningLangs.first : 'en')
                          : v.meaningLangs.first)));
    final bool rtlMeaning = lang == 'ur' || lang == 'ar';
    final bool rtlOriginal = v.lang == 'ar' || v.lang == 'ur';
    final bool anySounds = v.lines.any((_VLine l) => l.sounds != null);
    final bool anyHindi = v.lines.any((_VLine l) => l.hindi != null);

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: v.title),
              const ScholarReviewNote(reviewKey: 'nasheed.lyrics'),
              Center(
                child: m.Text(
                  v.titleOriginal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: rtlOriginal
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: AppText.arabicLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: m.Text(
                  v.subtitle,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              if (v.about.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      v.about,
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _RecitalBar(view: v, state: recital),
              if (v.audioUrl != null) ...<Widget>[
                const SizedBox(height: 8),
                _UserAudio(url: v.audioUrl!),
              ],
              if (lang != null) ...<Widget>[
                const SizedBox(height: 12),
                Text('Learn the meaning in', style: AppText.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String l in v.meaningLangs)
                      ChoiceChip(
                        key: Key('naat-lang-$l'),
                        label: m.Text(
                          (v.mine ? kUserPoemLanguages : kNaatLanguages)[l] ??
                              l,
                        ),
                        selected: lang == l,
                        onSelected: (_) => setState(() => _lang = l),
                      ),
                  ],
                ),
              ],
              if (anySounds) ...<Widget>[
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
                  onChanged: (bool x) => setState(() => _sounds = x),
                ),
              ],
              if (anyHindi)
                SwitchListTile(
                  key: const Key('naat-devanagari'),
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show in Hindi script', style: AppText.body),
                  subtitle: Text(
                    'The words in Devanagari (हिन्दी)',
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                  value: _hindiScript,
                  onChanged: (bool x) => setState(() => _hindiScript = x),
                ),
              const SizedBox(height: 8),
              for (int i = 0; i < v.lines.length; i++) ...<Widget>[
                KeyedSubtree(
                  key: _keys.putIfAbsent(i, GlobalKey.new),
                  child: DecoratedBox(
                    key: Key('naat-line-$i'),
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: recital.index == i
                          ? Border.all(color: AppColors.gold, width: 2)
                          : null,
                    ),
                    child: GlassCard(
                      onTap: v.canRecite
                          ? () => ref
                                .read(naatRecitalProvider.notifier)
                                .play(
                                  <String>[
                                    for (final _VLine l in v.lines)
                                      l.original.replaceAll('\n', ' '),
                                  ],
                                  v.lang,
                                  from: i,
                                )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            m.Text(
                              v.lines[i].original,
                              textDirection: rtlOriginal
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style: AppText.arabic.copyWith(
                                fontSize: 24,
                                height: 1.9,
                              ),
                            ),
                            if (_hindiScript && v.lines[i].hindi != null) ...<Widget>[
                              const SizedBox(height: 8),
                              m.Text(
                                v.lines[i].hindi!,
                                textAlign: TextAlign.center,
                                style: AppText.body.copyWith(
                                  fontSize: 20,
                                  height: 1.7,
                                ),
                              ),
                            ],
                            if (_sounds && v.lines[i].sounds != null) ...<Widget>[
                              const SizedBox(height: 8),
                              TranslitLine(v.lines[i].sounds!, centered: true),
                            ],
                            if (lang != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Directionality(
                                textDirection: rtlMeaning
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: m.Text(
                                  v.lines[i].meaning[lang] ??
                                      'This line is not available in this '
                                          'language yet.',
                                  textAlign: TextAlign.center,
                                  style: AppText.body.copyWith(height: 1.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                v.source,
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 6),
              if (!v.mine)
                Text(
                  kNaatDraftNote,
                  style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
                ),
              if (v.mine)
                TextButton.icon(
                  key: const Key('poem-remove'),
                  onPressed: () => _remove(v),
                  icon: const Icon(Icons.delete_outline, color: AppColors.gold),
                  label: Text('Remove this poem'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Play, pause and step through the lines, read aloud in the app's voice.
class _RecitalBar extends ConsumerWidget {
  const _RecitalBar({required this.view, required this.state});

  final _View view;
  final RecitalState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!view.canRecite) {
      return Text(
        'Reading aloud is available for Arabic, Urdu, Hindi, English and Bangla.',
        style: AppText.bodyMuted.copyWith(fontSize: 12),
      );
    }
    final NaatRecital c = ref.read(naatRecitalProvider.notifier);
    final List<String> spoken = <String>[
      for (final _VLine l in view.lines) l.original.replaceAll('\n', ' '),
    ];
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  key: const Key('naat-prev'),
                  tooltip: 'Previous line',
                  onPressed: state.index > 0 ? c.previous : null,
                  icon: const Icon(Icons.skip_previous, color: AppColors.gold),
                ),
                IconButton(
                  key: const Key('naat-play'),
                  tooltip: state.playing ? 'Pause' : 'Read aloud',
                  iconSize: 40,
                  onPressed: () {
                    if (state.playing) {
                      c.pause();
                    } else if (state.index >= 0) {
                      c.resume();
                    } else {
                      c.play(spoken, view.lang);
                    }
                  },
                  icon: Icon(
                    state.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: AppColors.gold,
                  ),
                ),
                IconButton(
                  key: const Key('naat-next'),
                  tooltip: 'Next line',
                  onPressed: state.index >= 0 && state.index < spoken.length - 1
                      ? c.next
                      : null,
                  icon: const Icon(Icons.skip_next, color: AppColors.gold),
                ),
                FilterChip(
                  key: const Key('naat-slow'),
                  label: Text('Slow'),
                  selected: state.slow,
                  onSelected: (_) => c.toggleSlow(),
                ),
              ],
            ),
            if (state.unavailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  'This phone has no voice for this language, so it cannot '
                  'read it aloud. The words still work.',
                  key: const Key('naat-no-voice'),
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plays the person's own audio link next to their words.
class _UserAudio extends StatefulWidget {
  const _UserAudio({required this.url});

  final String url;

  @override
  State<_UserAudio> createState() => _UserAudioState();
}

class _UserAudioState extends State<_UserAudio> {
  AudioPlayer? _p;
  bool _on = false;
  String? _err;

  Future<void> _toggle() async {
    try {
      AudioPlayer? p = _p;
      if (p == null) {
        p = AudioPlayer();
        _p = p;
        await p.setUrl(widget.url);
        p.playerStateStream.listen((PlayerState s) {
          if (mounted) {
            setState(
              () => _on =
                  s.playing && s.processingState != ProcessingState.completed,
            );
          }
        });
      }
      if (p.playing) {
        await p.pause();
      } else {
        await p.play();
      }
      if (mounted) setState(() => _err = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _err =
              'That link would not play. It needs to be a direct audio link.',
        );
      }
    }
  }

  @override
  void dispose() {
    _p?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextButton.icon(
              key: const Key('naat-my-audio'),
              onPressed: _toggle,
              icon: Icon(
                _on ? Icons.pause : Icons.play_arrow,
                color: AppColors.gold,
              ),
              label: Text(_on ? 'Pause my audio' : 'Play my audio'),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: m.Text(
                  _err!,
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
