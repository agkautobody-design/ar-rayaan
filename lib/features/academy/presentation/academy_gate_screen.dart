import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../reading/presentation/quran_snippet_views.dart';

/// The gate of Wasia Academy — entered the way Ar-Rayaan itself is entered:
/// a threshold of light. Bismillah in calligraphy, the knowledge verse,
/// one tap to step inside.
///
/// The pause before the tap works is 3 seconds the first time and well under
/// a second after that; there is no pause for a screen reader or when the
/// system asks for reduced motion.
class AcademyGateScreen extends StatefulWidget {
  const AcademyGateScreen({super.key});
  @override
  State<AcademyGateScreen> createState() => _AcademyGateState();
}

/// How long the gate waits the first time, and on every later visit.
const Duration kGateFirstDwell = Duration(seconds: 3);
const Duration kGateReturningDwell = Duration(milliseconds: 600);

/// Stored once the gate has been entered, so later visits are short.
const String kGateSeenPref = 'ar.academy.gate.seen';

class _AcademyGateState extends State<AcademyGateScreen> {
  Timer? _dwell;
  bool _minElapsed = false;
  bool _started = false;

  /// Enter or a tap that came before the pause ended: the school opens as
  /// soon as it does, instead of the key press being lost.
  bool _enterWhenReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool skip = MediaQuery.accessibleNavigationOf(context) ||
        MediaQuery.disableAnimationsOf(context);
    if (skip) {
      _minElapsed = true;
    } else {
      _begin();
    }
  }

  Future<void> _begin() async {
    bool seen = false;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      seen = p.getBool(kGateSeenPref) ?? false;
    } catch (_) {}
    if (!mounted) return;
    _dwell = Timer(seen ? kGateReturningDwell : kGateFirstDwell, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
      if (_enterWhenReady) _enter(context);
    });
  }

  Future<void> _remember() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(kGateSeenPref, true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  void _enter(BuildContext context) {
    if (!_minElapsed) {
      _enterWhenReady = true;
      return;
    }
    _remember();
    context.go(AppRoutes.academy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Semantics(
        button: true,
        enabled: _minElapsed,
        label: 'Wasia Academy, the school that carries her name. '
            'Are those who know equal to those who do not know? '
            'Qur\u2019an 39:9. '
            '${_minElapsed ? 'Double tap or press Enter to enter.' : 'Entering the school, one moment.'}',
        excludeSemantics: true,
        onTap: _minElapsed ? () => _enter(context) : null,
        // A FocusableTap, not a bare GestureDetector: the keyboard can reach
        // it (Tab, then Enter or Space) and a ring shows where focus is.
        child: FocusableTap(
        key: const Key('academy-gate'),
        autofocus: true,
        borderRadius: 0,
        onTap: () => _enter(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFF05090F).withValues(alpha: 0.30),
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/images/welcome-reflection-full.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // No sharp copy of the artwork here: the picture has the Welcome
            // screen's own words baked in (Bismillah, the dua, the three
            // cards, "Continue"), and drawn sharp they sat under this screen's
            // live text and read as overlapping text and a greyed button.
            // Blurred, it is only light and colour.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x5505090F),
                    Color(0xAA05090F),
                    Color(0xF205090F),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) =>
                    SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const BismillahView(arabicSize: 32),
                    const SizedBox(height: 26),
                    Text(
                      'WASIA ACADEMY',
                      style: AppText.eyebrow.copyWith(letterSpacing: 6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The school that carries her name',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const KnowledgeVerseView(arabicSize: 21),
                    ),
                    const Spacer(flex: 3),
                    Text(
                      _minElapsed
                          ? 'TAP OR PRESS ENTER TO ENTER'
                          : 'ENTERING THE SCHOOL\u2026',
                      style: AppText.eyebrow.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
