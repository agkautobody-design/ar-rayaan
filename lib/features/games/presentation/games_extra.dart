import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/lineage_rounds.dart';

Future<Map<String, dynamic>> _loadTree() async =>
    json.decode(await rootBundle.loadString('assets/family/tree.json'))
        as Map<String, dynamic>;

Future<List<dynamic>> _loadQuran() async =>
    json.decode(await rootBundle.loadString('assets/quran/quran.json')) as List<dynamic>;

class _Round {
  final String prompt;
  final List<String> options;
  final int answer;
  final String why;
  const _Round(this.prompt, this.options, this.answer, this.why);
}

/// GAME 3 of 5 — the Lineage Challenge: who begot whom, which river, which era.
class LineageChallengeScreen extends ConsumerStatefulWidget {
  const LineageChallengeScreen({super.key});
  @override
  ConsumerState<LineageChallengeScreen> createState() => _LineageState();
}

class _LineageState extends ConsumerState<LineageChallengeScreen> {
  List<_Round>? _rounds;
  int _i = 0, _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final tree = await _loadTree();
    final rounds = <_Round>[
      for (final LineageRound r in buildLineageRounds(tree, Random()))
        _Round(r.prompt, r.options, r.answer, r.why),
    ];
    setState(() => _rounds = rounds);
  }

  /// One choice. Before an answer it is a plain card. After it, the right
  /// choice shows a tick and the words "Correct answer", and a wrong pick shows
  /// a cross and "Your answer", so the result never depends on colour alone.
  Widget _lineageOption(_Round r, int o) {
    final bool answered = _picked != null;
    final bool right = answered && o == r.answer;
    final bool wrong = answered && o == _picked && o != r.answer;
    final String? tag = right
        ? (o == _picked ? 'Correct answer \u00b7 your answer' : 'Correct answer')
        : (wrong ? 'Your answer' : null);
    final Color? edge = right
        ? const Color(0xFF7FD1A8)
        : (wrong ? const Color(0xFFE8A07F) : null);
    final Widget card = GlassCard(
      onTap: answered ? null : () => setState(() => _picked = o),
      semanticsLabel: tag == null ? null : '${r.options[o]}. $tag',
      child: Row(children: [
        if (answered && edge != null) ...[
          Icon(right ? Icons.check_circle : Icons.cancel, size: 20, color: edge),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.options[o], style: AppText.body.copyWith(fontSize: 13)),
            if (tag != null)
              Text(tag, style: AppText.bodyMuted.copyWith(fontSize: 12, color: edge)),
          ]),
        ),
      ]),
    );
    if (edge == null) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge, width: 2),
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rounds == null) {
      return const Scaffold(backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    final r = _rounds![_i];
    final last = _i == _rounds!.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        const ScreenHeader(title: 'Lineage Challenge', close: true),
        Text('ROUND ${_i + 1} OF ${_rounds!.length} \u00b7 SCORE $_score', style: AppText.eyebrow),
        const SizedBox(height: 10),
        GlassCard(child: Text(r.prompt, style: AppText.body.copyWith(fontSize: 15.5, height: 1.5))),
        const SizedBox(height: 12),
        for (var o = 0; o < r.options.length; o++)
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: _lineageOption(r, o)),
        if (_picked != null)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(_picked == r.answer ? 'Correct! ${r.why}' : 'Not quite — ${r.why}',
                style: AppText.bodyMuted.copyWith(height: 1.5))),
        const SizedBox(height: 8),
        if (_picked != null)
          Align(alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_picked == r.answer) _score++;
                if (!last) setState(() { _picked = null; _i++; });
                else showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  semanticLabel: 'Journey complete',
                  backgroundColor: const Color(0xFF0A0F18),
                  title: Text('Journey complete', style: AppText.titleMedium),
                  content: Text('Score: $_score/${_rounds!.length}. The tree of the Prophets is becoming yours.',
                      style: AppText.bodyMuted),
                  actions: [TextButton(onPressed: () { Navigator.pop(ctx); context.go(AppRoutes.games); },
                      child: const Text('Done', style: TextStyle(color: AppColors.goldLight)))],
                ));
              },
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.gold),
              label: Text(last ? 'Finish' : 'Next', style: AppText.bodyMuted))),
      ]),
    );
  }
}

/// GAME 4 of 5 — Ayah Completion: one word is veiled; choose what the Qur'an says.
class AyahCompletionScreen extends ConsumerStatefulWidget {
  const AyahCompletionScreen({super.key});
  @override
  ConsumerState<AyahCompletionScreen> createState() => _AyahState();
}

class _AyahState extends ConsumerState<AyahCompletionScreen> {
  List<_Round>? _rounds;
  int _i = 0, _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final quran = await _loadQuran();
    final rnd = Random();
    final rounds = <_Round>[];
    final candidates = <Map<String, dynamic>>[];
    for (final s in quran) {
      final v = (s['v'] as List<dynamic>);
      for (final a in v) {
        final row = a as List<dynamic>;
        final words = (row[1] as String).split(RegExp(r'\s+'))
            .where((w) => w.length > 3 && !w.contains('۟')).toList();
        if (words.length >= 3 && words.length <= 8) {
          candidates.add({'surah': s['tl'], 'ayah': row[0], 'text': row[1], 'words': words, 'en': row.length > 2 ? '${row[2]}' : ''});
        }
      }
    }
    candidates.shuffle(rnd);
    for (final c in candidates.take(8)) {
      final words = c['words'] as List<String>;
      final idx = 1 + rnd.nextInt(words.length - 2);
      final blanked = words[idx];
      final others = candidates.map((x) => (x['words'] as List<String>)).expand((x) => x)
          .where((w) => w != blanked).toList()..shuffle(rnd);
      final opts = [blanked, others[0], others[1]]..shuffle(rnd);
      final shown = words.toList();
      shown[idx] = '_____';
      rounds.add(_Round(
        '${c['surah']} ${c['ayah']} — what did Allah say?',
        ['${shown.join(' ')}', opts[0], opts[1], opts[2]], 0,
        '${c['text']}',
      ));
      // rebuild: store the real options separately
      rounds.last = _Round(rounds.last.prompt, opts, opts.indexOf(blanked),
          'The ayah reads: ${c['text']}${(c['en'] as String).isEmpty ? '' : '\n\nIn English: ${c['en']}'}');
    }
    setState(() => _rounds = rounds);
  }

  @override
  Widget build(BuildContext context) {
    if (_rounds == null) {
      return const Scaffold(backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    final r = _rounds![_i];
    final last = _i == _rounds!.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        const ScreenHeader(title: 'Ayah Completion', close: true),
        Text('ROUND ${_i + 1} OF ${_rounds!.length} \u00b7 SCORE $_score', style: AppText.eyebrow),
        const SizedBox(height: 10),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COMPLETE THE AYAH', style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text(r.prompt.split(' — ')[0], textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, height: 1.9,
                  color: Color(0xFFEAD9A8))),
        ])),
        const SizedBox(height: 12),
        for (var o = 0; o < r.options.length; o++)
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              onTap: _picked == null ? () => setState(() => _picked = o) : null,
              child: Center(child: Text(r.options[o],
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 22,
                      color: Color(0xFFEAD9A8)))),
            )),
        if (_picked != null)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(_picked == r.answer ? 'Correct, ma sha Allah! ' : 'Not quite — ',
                style: AppText.bodyMuted.copyWith(height: 1.5))),
        const SizedBox(height: 8),
        if (_picked != null)
          Align(alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_picked == r.answer) _score++;
                if (!last) setState(() { _picked = null; _i++; });
                else showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  semanticLabel: 'Walk complete',
                  backgroundColor: const Color(0xFF0A0F18),
                  title: Text('Walk complete', style: AppText.titleMedium),
                  content: Text('Score: $_score/${_rounds!.length}. Each ayah you complete is a verse that now knows your name.',
                      style: AppText.bodyMuted),
                  actions: [TextButton(onPressed: () { Navigator.pop(ctx); context.go(AppRoutes.games); },
                      child: const Text('Done', style: TextStyle(color: AppColors.goldLight)))],
                ));
              },
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.gold),
              label: Text(last ? 'Finish' : 'Next', style: AppText.bodyMuted))),
      ]),
    );
  }
}

/// GAME 5 of 5 — the Hijrah journey: a road under the stars, station by station.
class HijrahMapScreen extends StatelessWidget {
  const HijrahMapScreen({super.key});

  static const _stops = [
    ('Makkah', 'The night of the departure', 'The disbelievers plotted “to restrain you or kill you or evict you” (8:30). The Prophet ﷺ left Makkah with Abu Bakr and made for a cave on the mountain of Thawr.', 'Qur’an 8:30 · Sahih al-Bukhari 3905'),
    ('The Cave of Thawr', 'Three nights in the cave', 'With Abu Bakr beside him he said: “do not grieve; indeed Allah is with us” (9:40). They stayed in the cave three nights. Later tradition adds a spider’s web; it is not in the Qur’an or in Bukhari 3905.', 'Qur’an 9:40 · Sahih al-Bukhari 3905'),
    ('The Road North', 'Suraqa and the sinking horse', 'Suraqa ibn Malik rode after them for the reward Quraysh had announced, equal to a blood-price. His horse stumbled, then sank into the ground up to its knees. He called for safety, told them what Quraysh planned, and was asked: “Do not tell others about us.”', 'Sahih al-Bukhari 3906'),
    ('Quba', 'The first stop near Madinah', 'He stayed with Banu Amr ibn Awf at Quba: fourteen nights in Bukhari 3932, ten in Bukhari 3906. The Qur’an speaks of “a mosque founded on righteousness from the first day” (9:108), understood to be Masjid Quba.', 'Sahih al-Bukhari 3932, 3906 · Qur’an 9:108'),
    ('Madinah', 'The city that came out to see him', 'The news spread in Madinah and the people came out saying, “Allah’s Prophet has come!” He alighted near the house of Abu Ayyub.', 'Sahih al-Bukhari 3911'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        const ScreenHeader(title: 'The Hijrah Journey', close: true),
        Center(child: Text('A ROAD UNDER THE STARS \u00b7 622 CE', style: AppText.eyebrow)),
        const SizedBox(height: 14),
        for (var i = 0; i < _stops.length; i++) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 30, height: 30, alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF0A0F18),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.6))),
                child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: AppColors.goldLight))),
              if (i < _stops.length - 1)
                Container(width: 1, height: 34,
                  color: AppColors.gold.withValues(alpha: 0.3)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: GlassCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_stops[i].$1, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(_stops[i].$2, style: AppText.bodyMuted.copyWith(fontSize: 12)),
                const SizedBox(height: 6),
                Text(_stops[i].$3, style: AppText.bodyMuted.copyWith(height: 1.55)),
                const SizedBox(height: 4),
                Text(_stops[i].$4, style: AppText.bodyMuted.copyWith(fontSize: 12)),
              ],
            ))),
          ]),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 8),
        GlassCard(strong: true, child: Text(
          '\u201cAnd those who emigrated for [the cause of] Allah after they had been wronged - We will surely settle them in this world in a good place\u2026\u201d (16:41). The Hijrah is the proof that leaving everything for Allah is never a loss.',
          style: AppText.body.copyWith(height: 1.6, fontSize: 13.5))),
      ]),
    );
  }
}
