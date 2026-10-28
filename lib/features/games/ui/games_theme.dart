import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/screen_header.dart';
import 'games_art.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';

/// The Games look: the app's navy and gold, with a brighter gold for the
/// things you press, a pointed-arch header and gold-bordered panels. The
/// owner's art (`games_art.dart`) is laid over it where a file exists; every
/// piece is also drawn in code, so it works without any art file.
abstract final class GamesTheme {
  /// The gold of Play Now, Continue and Start (sampled from the final
  /// designs; a little warmer than the app's [AppColors.goldGradient]).
  static const LinearGradient playGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFD367), Color(0xFFE2A63F), Color(0xFFCE8D2C)],
    stops: <double>[0, 0.5, 1],
  );

  /// Panel fill: near-black navy, slightly see-through.
  static const Color panelFill = Color(0xD9010F16);

  /// Gold border of a panel, and the brighter one for the selected one.
  static const Color border = Color(0x99D4AF37);
  static const Color borderBright = AppColors.goldLight;

  /// Champagne for titles on the dark panel.
  static const Color champagne = Color(0xFFFFF6C8);

  static const double radius = 22;

  /// The smallest height of anything you press.
  static const double minTap = 48;

  /// Muted green for "right", used together with an icon and a word.
  static const Color good = Color(0xFF7FD1A8);
}

/// The icon for a registry [GameDef.iconKey].
IconData gameIcon(String key) => switch (key) {
      'quran' => Icons.menu_book_outlined,
      'stories' => Icons.auto_stories_outlined,
      'names' => Icons.spa_outlined,
      'tree' => Icons.account_tree_outlined,
      'route' => Icons.route_outlined,
      'hifz' => Icons.record_voice_over_outlined,
      'chess' => Icons.extension_outlined,
      'ludo' => Icons.casino_outlined,
      'memory' => Icons.grid_view_outlined,
      'seerah' => Icons.explore_outlined,
      'timeline' => Icons.timeline_outlined,
      'hadith' => Icons.format_quote_outlined,
      'steps' => Icons.format_list_numbered_outlined,
      'letters' => Icons.translate_outlined,
      'grid' => Icons.apps_outlined,
      _ => Icons.sports_esports_outlined,
    };

/// The header of every Games page: the usual back button and title, and
/// under it the owner's art, or (with no art file) a pointed arch with a
/// skyline, a crescent and stars drawn in code.
///
/// The default is the big arch (`hubHeader`). With [band] it is the slim
/// skyline strip (`skylineBand`) with the tagline in a dark band under it.
class ArchHeader extends StatelessWidget {
  const ArchHeader({
    required this.title,
    this.tagline,
    this.close = false,
    this.band = false,
    super.key,
  });

  final String title;

  /// One short line inside the arch.
  final String? tagline;
  final bool close;

  /// The slim strip instead of the big arch.
  final bool band;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScreenHeader(title: title, close: close, showSettings: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: ArtBuilder(
                slot: band ? ArtSlot.skylineBand : ArtSlot.hubHeader,
                builder: (BuildContext context, bool present) {
                  if (!present) return _PaintedArch(tagline: tagline);
                  return band
                      ? _ArtBand(tagline: tagline)
                      : _ArtArch(tagline: tagline);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The big arch picture. The tagline sits in the dark sky inside the arch, so
/// it needs no band behind it.
class _ArtArch extends StatelessWidget {
  const _ArtArch({this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 941 / 430,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GamesArt.asset(
                ArtSlot.hubHeader,
                alignment: Alignment.bottomCenter,
              ),
              if (tagline != null)
                Align(
                  alignment: const Alignment(0, 0.18),
                  child: SizedBox(
                    width: c.maxWidth * 0.5,
                    height: c.maxHeight * 0.3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: c.maxWidth * 0.5,
                        child: Text(
                          tagline!,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: GamesTheme.champagne,
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
    );
  }
}

/// The slim skyline strip with a dark band for the tagline under it.
class _ArtBand extends StatelessWidget {
  const _ArtBand({this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GamesTheme.radius),
        border: Border.all(color: GamesTheme.borderBright, width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2ED4AF37), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GamesTheme.radius - 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 941 / 222,
              child: GamesArt.asset(
                ArtSlot.skylineBand,
                alignment: Alignment.bottomCenter,
              ),
            ),
            if (tagline != null)
              Container(
                width: double.infinity,
                color: AppColors.night.withValues(alpha: 0.86),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  tagline!,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: GamesTheme.champagne),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The header drawn in code, used when the art file is missing.
class _PaintedArch extends StatelessWidget {
  const _PaintedArch({this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ArchPainter(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: tagline == null
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  // A dark band under the words: the sunset behind them would
                  // not give the text enough contrast.
                  color: AppColors.night.withValues(alpha: 0.72),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    tagline!,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: GamesTheme.champagne),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  const _ArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // A pointed (ogee) arch: straight sides, two curves meeting at the top.
    final Path arch = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.5)
      ..cubicTo(0, h * 0.2, w * 0.36, h * 0.12, w * 0.5, 0)
      ..cubicTo(w * 0.64, h * 0.12, w, h * 0.2, w, h * 0.5)
      ..lineTo(w, h)
      ..close();

    canvas.save();
    canvas.clipPath(arch);
    // Sky: night at the top, warm amber at the horizon.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF020611),
            Color(0xFF0B1B2A),
            Color(0xFF5A3A22),
            Color(0xFFB9772E),
          ],
          stops: <double>[0, 0.45, 0.8, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // A few stars.
    final Paint star = Paint()..color = const Color(0xCCFFF6C8);
    for (final Offset o in <Offset>[
      Offset(w * 0.18, h * 0.34),
      Offset(w * 0.3, h * 0.2),
      Offset(w * 0.72, h * 0.26),
      Offset(w * 0.84, h * 0.4),
      Offset(w * 0.62, h * 0.12),
    ]) {
      canvas.drawCircle(o, 1.3, star);
    }
    // Crescent.
    final Offset moon = Offset(w * 0.5, h * 0.3);
    final Path crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moon, radius: 11)),
      Path()
        ..addOval(
          Rect.fromCircle(center: moon + const Offset(5, -2), radius: 10),
        ),
    );
    canvas.drawPath(crescent, Paint()..color = AppColors.goldLight);
    // Skyline: domes and minarets in the night colour.
    final Paint sil = Paint()..color = const Color(0xFF05090F);
    final double base = h;
    final Path sky = Path()..moveTo(0, base);
    sky
      ..lineTo(0, h * 0.84)
      ..lineTo(w * 0.1, h * 0.84)
      ..lineTo(w * 0.1, h * 0.7)
      ..lineTo(w * 0.115, h * 0.6)
      ..lineTo(w * 0.13, h * 0.7)
      ..lineTo(w * 0.13, h * 0.84)
      ..lineTo(w * 0.3, h * 0.84)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.84),
        radius: Radius.elliptical(w * 0.1, h * 0.26),
        clockwise: true,
      )
      ..lineTo(w * 0.7, h * 0.84)
      ..lineTo(w * 0.87, h * 0.84)
      ..lineTo(w * 0.87, h * 0.68)
      ..lineTo(w * 0.885, h * 0.58)
      ..lineTo(w * 0.9, h * 0.68)
      ..lineTo(w * 0.9, h * 0.84)
      ..lineTo(w, h * 0.84)
      ..lineTo(w, base)
      ..close();
    canvas.drawPath(sky, sil);
    canvas.restore();

    // The gold edge with a soft glow.
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.gold.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.goldLight,
    );
    // A little lantern at each foot.
    final Paint lantern = Paint()..color = AppColors.goldLight;
    for (final double x in <double>[8, w - 8]) {
      canvas.drawCircle(Offset(x, h - 8), 3, lantern);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) => false;
}

/// A filter chip: solid gold when chosen, a gold outline when not.
class GameChip extends StatelessWidget {
  const GameChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? AppColors.night : AppColors.sand;
    return FocusSafeSemantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(
        borderRadius: 999,
        child: Material(
          type: MaterialType.transparency,
          child: FocusRing(borderRadius: 999, child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: GamesTheme.minTap,
                minWidth: GamesTheme.minTap,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: selected ? GamesTheme.playGradient : null,
                  color: selected ? null : AppColors.night.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? GamesTheme.borderBright
                        : AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                // widthFactor 1: the chip is as wide as its label. (A Container
                // with `alignment` fills the whole row in a Wrap, which stacked
                // every chip full width and pushed the games off the screen.)
                child: Align(
                  widthFactor: 1,
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (selected)
                      Icon(Icons.check, size: 16, color: fg)
                    else if (icon != null)
                      Icon(icon, size: 16, color: fg),
                    if (selected || icon != null) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

/// A gold-bordered dark panel, tappable when [onTap] is given.
class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.onTap,
    this.selected = false,
    this.semanticsLabel,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.ornate = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Lays the owner's Islamic pattern corners over the panel (only when the
  /// art file is bundled; the panel is unchanged without it).
  final bool ornate;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(GamesTheme.radius);
    final Widget inner = !ornate
        ? Padding(padding: padding, child: child)
        : ArtBuilder(
            slot: ArtSlot.cornerOrnament,
            builder: (BuildContext context, bool present) {
              // Room for the corners so they never sit under the words.
              final EdgeInsetsGeometry room = present
                  ? padding.add(const EdgeInsets.all(8))
                  : padding;
              return Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Padding(padding: room, child: child),
                  if (present) const Positioned.fill(child: PanelCorners()),
                ],
              );
            },
          );
    final Widget box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: GamesTheme.panelFill,
        borderRadius: radius,
        border: Border.all(
          color: selected ? GamesTheme.borderBright : GamesTheme.border,
          width: selected ? 2 : 1.2,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2ED4AF37), blurRadius: 16),
        ],
      ),
      child: inner,
    );
    if (onTap == null) return box;
    final Widget tappable = FocusRing(
      borderRadius: GamesTheme.radius,
      child: Material(
        type: MaterialType.transparency,
        child: FocusRing(borderRadius: 12, child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GamesTheme.minTap),
            child: box,
          ),
        )),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      onTap: onTap,
      child: tappable,
    );
  }
}

/// The big gold action: Play, Start, Next.
class PlayButton extends StatelessWidget {
  const PlayButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool on = onPressed != null;
    return FocusSafeSemantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: FocusRing(
        borderRadius: 999,
        child: Material(
          type: MaterialType.transparency,
          child: FocusRing(borderRadius: 999, child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52, minWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                gradient: on ? GamesTheme.playGradient : null,
                color: on ? null : const Color(0x66EAD6B4),
                borderRadius: BorderRadius.circular(999),
                boxShadow: on
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x59D4AF37),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: AppColors.night),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.night,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}

/// The quiet action beside [PlayButton]: a gold outline.
class OutlineAction extends StatelessWidget {
  const OutlineAction({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FocusSafeSemantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: FocusRing(
        borderRadius: 999,
        child: Material(
          type: MaterialType.transparency,
          child: FocusRing(borderRadius: 999, child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52, minWidth: 96),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: GamesTheme.border, width: 1.4),
                color: AppColors.night.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: AppColors.goldLight),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}

/// The bar at the foot of a Games page that holds its buttons. Buttons wrap
/// onto more lines at large text instead of being squeezed.
class BottomActions extends StatelessWidget {
  const BottomActions({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.night.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A round gold-ringed icon for a game.
class GameBadge extends StatelessWidget {
  const GameBadge({required this.iconKey, this.size = 48, super.key});

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: <Color>[Color(0xFF1B2D44), Color(0xFF0B1B2A)],
          ),
          border: Border.all(color: GamesTheme.border, width: 1.4),
        ),
        child: Icon(
          gameIcon(iconKey),
          size: size * 0.5,
          color: AppColors.goldLight,
        ),
      ),
    );
  }
}

/// A thin gold progress bar with a text alternative.
class GameProgressBar extends StatelessWidget {
  const GameProgressBar({required this.value, this.label, super.key});

  /// 0 to 1.
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '${(value * 100).round()} percent',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      ),
    );
  }
}

/// A section title with a one-line note under it.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.note,
    this.art,
    super.key,
  });

  final String title;
  final String? note;

  /// A hub-category picture shown beside the title, when its file exists.
  final ArtSlot? art;

  @override
  Widget build(BuildContext context) {
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppText.titleMedium.copyWith(
              color: GamesTheme.champagne,
              fontSize: 20,
            ),
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(note!, style: AppText.bodyMuted),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: art == null
          ? words
          : ArtBuilder(
              slot: art!,
              builder: (BuildContext context, bool present) {
                if (!present) return words;
                return Row(
                  children: <Widget>[
                    ExcludeSemantics(
                      child: Container(
                        width: 88,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GamesTheme.border,
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: GamesArt.asset(art!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: words),
                  ],
                );
              },
            ),
    );
  }
}
