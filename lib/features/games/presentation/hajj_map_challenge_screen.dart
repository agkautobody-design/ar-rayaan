import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

/// The five places of the Hajj map.
enum _Place { makkah, mina, arafat, muzdalifah, jamarat }

extension on _Place {
  String get label => switch (this) {
        _Place.makkah => 'Makkah',
        _Place.mina => 'Mina',
        _Place.arafat => 'Arafat',
        _Place.muzdalifah => 'Muzdalifah',
        _Place.jamarat => 'Jamarat',
      };

  /// Where the marker sits on the map, as a fraction of its width and height.
  Offset get at => switch (this) {
        _Place.makkah => const Offset(0.16, 0.74),
        _Place.mina => const Offset(0.46, 0.52),
        _Place.arafat => const Offset(0.84, 0.2),
        _Place.muzdalifah => const Offset(0.72, 0.84),
        _Place.jamarat => const Offset(0.5, 0.14),
      };
}

class _Rite {
  const _Rite(this.name, this.line, this.place, this.hint);
  final String name;
  final String line;
  final _Place place;
  final String hint;
}

const List<_Rite> _rites = <_Rite>[
  _Rite('Tawaf', 'Circling the Kaaba.', _Place.makkah,
      'The Kaaba is in the Sacred Mosque in Makkah, so Tawaf is done there.'),
  _Rite('Stay in Mina', 'Staying in Mina during the days of Hajj.',
      _Place.mina, 'The pilgrims go to Mina on the 8th of Dhul-Hijjah and stay there.'),
  _Rite('Wuquf at Arafat', 'Standing at Arafat on the 9th of Dhul-Hijjah.',
      _Place.arafat, 'Standing at Arafat on the 9th is the heart of Hajj.'),
  _Rite('Stay in Muzdalifah',
      'Spending the night in Muzdalifah and collecting pebbles.',
      _Place.muzdalifah,
      'Muzdalifah comes after Arafat, where pilgrims spend the night and collect pebbles for the stoning of Jamarat. It is not in Mina.'),
  _Rite('Ramy al-Jamarat', 'Stoning the pillars at Jamarat.', _Place.jamarat,
      'The pillars are at Jamarat, reached from Mina, where the stoning is done.'),
];

/// Hajj Map Challenge: place each rite of Hajj on the map, then review the
/// answers with a reason for each miss. The steps follow the Hajj guide in
/// the Huda section of the app.
class HajjMapChallengeScreen extends StatefulWidget {
  const HajjMapChallengeScreen({super.key});

  @override
  State<HajjMapChallengeScreen> createState() => _HajjMapState();
}

class _HajjMapState extends State<HajjMapChallengeScreen> {
  late List<_Rite> _order;
  final Map<String, _Place> _placed = <String, _Place>{};
  int _i = 0;
  Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _order = List<_Rite>.of(_rites)..shuffle(Random());
    _placed.clear();
    _i = 0;
    _clock = Stopwatch()..start();
  }

  void _place(_Place p) {
    if (_i >= _order.length) return;
    setState(() {
      _placed[_order[_i].name] = p;
      _i++;
      if (_i >= _order.length) _clock.stop();
    });
  }

  Widget _map({_Rite? current}) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ExcludeSemantics(
                  child: GamesArt.asset(ArtSlot.hajjMap, fit: BoxFit.cover),
                ),
                for (final _Place p in _Place.values)
                  Positioned(
                    left: p.at.dx * c.maxWidth,
                    top: p.at.dy * c.maxHeight,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: Semantics(
                        button: current != null,
                        label: current != null
                            ? 'Place ${current.name} at ${p.label}'
                            : p.label,
                        child: GestureDetector(
                          onTap: current == null ? null : () => _place(p),
                          child: ExcludeSemantics(
                            child: Container(
                              constraints: const BoxConstraints(
                                  minHeight: 44, minWidth: 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xE605090F),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.gold),
                              ),
                              child: Text(
                                p.label,
                                style: AppText.label
                                    .copyWith(color: AppColors.goldLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_i < _order.length) {
      final _Rite r = _order[_i];
      return PuzzleFrame(
        title: 'Hajj Map Challenge',
        tagline: 'Place each rite where it happens',
        children: <Widget>[
          const SizedBox(height: 8),
          Text('Rite ${_i + 1} of ${_order.length}'.toUpperCase(),
              style: AppText.eyebrow),
          const SizedBox(height: 8),
          GamePanel(
            child: Row(
              children: <Widget>[
                _RitePic(r.name),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(r.name, style: AppText.titleMedium),
                      const SizedBox(height: 4),
                      Text(r.line, style: AppText.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Tap the place on the map', style: AppText.bodyMuted),
          const SizedBox(height: 8),
          _map(current: r),
        ],
      );
    }
    final int right = <_Rite>[
      for (final _Rite r in _rites)
        if (_placed[r.name] == r.place) r,
    ].length;
    final Duration t = _clock.elapsed;
    final String time =
        '${t.inMinutes}:${(t.inSeconds % 60).toString().padLeft(2, '0')}';
    return PuzzleFrame(
      title: 'Hajj Map Challenge',
      tagline: 'Answer review',
      children: <Widget>[
        const SizedBox(height: 8),
        _map(),
        const SizedBox(height: 10),
        GamePanel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _stat('$right of ${_rites.length}', 'Correct'),
              _stat('${_rites.length - right}', 'Mismatch'),
              _stat(time, 'Time used'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final _Rite r in _rites)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GamePanel(
              semanticsLabel:
                  '${r.name}. ${_placed[r.name] == r.place ? 'Correct' : 'Incorrect, you placed this at ${_placed[r.name]?.label}'}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    _RitePic(r.name),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(r.name, style: AppText.titleMedium),
                          Text(r.line, style: AppText.bodyMuted),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _placed[r.name] == r.place
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _placed[r.name] == r.place
                          ? GamesTheme.good
                          : const Color(0xFFFF8A80),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _placed[r.name] == r.place
                          ? r.place.label
                          : 'You: ${_placed[r.name]?.label}',
                      style: AppText.label,
                    ),
                  ]),
                  if (_placed[r.name] != r.place) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(r.hint,
                        style: AppText.bodyMuted.copyWith(height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        GamePanel(
          child: Text(
            'Qur’an 22:27: Allah told Ibrahim to call the people to Hajj.',
            style: AppText.bodyMuted.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        PlayButton(label: 'Try again', onPressed: () => setState(_deal)),
      ],
    );
  }

  Widget _stat(String big, String small) => Column(
        children: <Widget>[
          Text(big, style: AppText.titleMedium),
          Text(small, style: AppText.caption),
        ],
      );
}

/// A rite's picture (assets/games/rites/<name>.webp) when there is one.
class _RitePic extends StatelessWidget {
  const _RitePic(this.name);

  final String name;

  static const Map<String, String> _files = <String, String>{
    'Tawaf': 'tawaf',
    'Wuquf at Arafat': 'arafat',
    'Stay in Muzdalifah': 'muzdalifah',
    'Ramy al-Jamarat': 'jamarat',
  };

  @override
  Widget build(BuildContext context) {
    final String? f = _files[name];
    if (f == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/games/rites/$f.webp',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (BuildContext c, Object e, StackTrace? st) =>
              const SizedBox.shrink(),
        ),
      ),
    );
  }
}
