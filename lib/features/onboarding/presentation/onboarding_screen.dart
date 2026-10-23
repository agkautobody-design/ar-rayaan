import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/core/i18n/app_locale.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const pref = 'ar.onboarded.v1';
  static const needPref = 'ar.need';

  static Future<bool> shouldShow() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(pref) != true;
    } catch (_) {
      // Storage unreadable: treat as a first run rather than not starting.
      return true;
    }
  }

  /// True once this session has completed (or skipped) the introduction. The
  /// router uses it so Back, or a stale history entry, cannot reopen the
  /// welcome slides. A deliberate replay from Settings carries `?replay=1`.
  static bool completedThisSession = false;

  /// Whether a visit to the onboarding route should bounce to Home instead.
  static bool shouldBounce({required bool completed, required Uri uri}) =>
      completed && uri.queryParameters['replay'] != '1';

  /// Where a returning user should land after replaying the introduction.
  static Future<String> homeRouteFor(String? need) {
    switch (need) {
      case 'learn':
        // "Learning my deen" starts at Home, where the Academy, the Qur'an
        // and the stories are all one tap away (it used to open the stories
        // list, which read as a wrong turn).
        return Future.value(AppRoutes.home);
      case 'peace':
        return Future.value(AppRoutes.sakina);
      case 'children':
        // "Teaching my children" lands on the Family Wing (add a child,
        // then Wasia's letters school), not the generic Academy gate.
        return Future.value('/academy/family');
      case 'pray':
        return Future.value(AppRoutes.prayerTimes);
      case 'new':
        return Future.value(AppRoutes.newMuslimPath);
      case 'community':
        return Future.value(AppRoutes.community);
      default:
        return Future.value(AppRoutes.home);
    }
  }

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _Need {
  const _Need(this.key, this.icon, this.title, this.blurb);
  final String key;
  final IconData icon;
  final String title;
  final String blurb;
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;
  String? _need;

  static const _needs = <_Need>[
    _Need('learn', Icons.menu_book_outlined, 'Learning about Islam',
        'Stories, Friday talks (khutbahs), and knowledge'),
    _Need('peace', Icons.favorite_outline, 'Peace for my heart',
        'Du’as and comfort for heavy days'),
    _Need('children', Icons.child_care, 'Teaching my children',
        'Arabic letters school and Family Wing'),
    _Need('pray', Icons.access_time, 'Praying on time',
        'Prayer times, qibla, and adhkar'),
    _Need('new', Icons.door_front_door_outlined, 'New to Islam or just curious',
        'A gentle 30-day path. Everyone is welcome'),
    _Need('community', Icons.people_outline, 'A community',
        'Finding your masjid and your people'),
  ];

  /// [skipped]: the person tapped Skip. Their goal is still remembered, but
  /// Skip always lands on Home.
  Future<void> _finish({bool skipped = false}) async {
    // Remembering that onboarding was seen is a nicety: if storage refuses,
    // the person must still get through to the app.
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(OnboardingScreen.pref, true);
      if (_need != null) await p.setString(OnboardingScreen.needPref, _need!);
    } catch (_) {}
    OnboardingScreen.completedThisSession = true;
    final String route =
        skipped ? AppRoutes.home : await OnboardingScreen.homeRouteFor(_need);
    if (!mounted) return;
    // Home first, then the chosen room on top of it, so Back / Close from
    // that room returns Home instead of leaving an empty stack.
    final GoRouter router = GoRouter.of(context);
    if (kShellTabPaths.contains(route)) {
      router.go(route);
      return;
    }
    router.go(AppRoutes.home);
    if (route != AppRoutes.home) {
      // Let the jump to Home settle so the room opens ON TOP of it.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      unawaited(router.push<void>(route));
    }
  }

  @override
  Widget build(BuildContext context) {
    const slides = 6;
    final L10n l10n = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _finish(skipped: true),
              child: Text('Skip', style: AppText.bodyMuted),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              onPageChanged: (i) => setState(() => _i = i),
              itemCount: slides,
              itemBuilder: (c, i) {
                if (i == 1) return _needSlide(l10n);
                final (icon, eyebrow, title, body) = switch (i) {
                  0 => (
                      Icons.mosque_outlined,
                      'AS-SALAAMU ALAIKUM',
                      'This is Ar-Rayaan',
                      'Prayer times, the Qur’an, stories of the Prophets, '
                          'a school for your children, and a guide called '
                          'Hādi. You do not need to be Muslim to look '
                          'around.'
                    ),
                  2 => (
                      Icons.auto_awesome,
                      'MEET HADI',
                      'Ask Hādi anything',
                      'Type a question in plain words. Hādi answers from '
                          'a built-in shelf of cited texts, free and '
                          'offline, and never invents a source. You can '
                          'connect your own AI account later for open '
                          'conversation.'
                    ),
                  3 => (
                      Icons.school_outlined,
                      'MEET WASIA',
                      'The letters school',
                      'Wasia teaches children the Arabic letters, one '
                          'step at a time. The Family Wing shows every '
                          'lesson and exam they finish.'
                    ),
                  4 => (
                      Icons.home_outlined,
                      'YOUR HOME',
                      'Made for your days',
                      'Your first hour: check prayer times, read one '
                          'story, open the Academy. When your heart feels '
                          'heavy, For Your Heart is always open.'
                    ),
                  _ => (
                      Icons.wb_twilight,
                      'LET’S BEGIN',
                      'Bismillah',
                      'Whatever you chose, you can change it later. Every '
                          'room of the house stays open to you.'
                    ),
                };
                return _scrollSlide(
                  horizontal: 30,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92, height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Icon(icon, size: 40, color: AppColors.goldLight),
                      ),
                      const SizedBox(height: 26),
                      Text(eyebrow, style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(title, textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 30, color: AppColors.goldLight)),
                      const SizedBox(height: 14),
                      Text(body, textAlign: TextAlign.center,
                          style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.7)),
                      if (i == 0) ...[
                        const SizedBox(height: 22),
                        _languageChooser(l10n),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var d = 0; d < slides; d++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: d == _i ? 20 : 7, height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: d == _i ? AppColors.gold : AppColors.sand.withValues(alpha: 0.25),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_i < slides - 1) {
                    _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  } else {
                    _finish();
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0A0F18),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                    _i < slides - 1 ? l10n.ui('ui.next') : l10n.ui('ui.begin')),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// A slide that centres its content when there is room and scrolls when
  /// there is not (320 px wide phones, large text), instead of overflowing.
  Widget _scrollSlide({required double horizontal, required Widget child}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) =>
          SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 16),
          child: Center(child: child),
        ),
      ),
    );
  }

  /// The first-run language choice. It sets the language straight away (and
  /// the layout direction for Arabic and Urdu) and says plainly how much of
  /// the app that changes.
  Widget _languageChooser(L10n l10n) {
    final Locale current = ref.watch(localeProvider);
    const Map<String, String> names = <String, String>{
      'en': 'English',
      'ar': 'العربية',
      'bn': 'বাংলা',
      'ur': 'اردو',
    };
    return Column(
      key: const Key('onboarding-language'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.ui('ui.language').toUpperCase(), style: AppText.eyebrow),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final Locale loc in LocaleController.firstRunChoices)
              Semantics(
                button: true,
                selected: current.languageCode == loc.languageCode,
                label: names[loc.languageCode],
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale(loc),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 72),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: current.languageCode == loc.languageCode
                          ? AppColors.gold.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: current.languageCode == loc.languageCode
                            ? AppColors.gold
                            : AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(names[loc.languageCode] ?? '',
                        style: AppText.body.copyWith(
                            color: current.languageCode == loc.languageCode
                                ? AppColors.goldLight
                                : null)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Menus and titles change. Lessons, stories and answers stay in '
          'English for now.',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _needSlide(L10n l10n) {
    return _scrollSlide(
      horizontal: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.ui('onb.question').toUpperCase(),
              textAlign: TextAlign.center, style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text('Choose one — it only sets your first door.',
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 13)),
          const SizedBox(height: 22),
          for (var row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: col == 0 ? 5 : 0, left: col == 1 ? 5 : 0),
                      child: _needCard(_needs[row * 2 + col], l10n),
                    ),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _needCard(_Need n, L10n l10n) {
    final bool selected = _need == n.key;
    return GestureDetector(
      onTap: () => setState(() => _need = n.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.25),
          ),
          color: selected
              ? AppColors.gold.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(children: [
          Icon(n.icon, size: 22,
              color: selected ? AppColors.gold : AppColors.sand.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(l10n.english(n.title), textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: selected ? AppColors.goldLight : null)),
          const SizedBox(height: 4),
          Text(n.blurb, textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.4)),
        ]),
      ),
    );
  }
}
