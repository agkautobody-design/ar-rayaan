import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/core/i18n/app_locale.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../../elder/application/elder_mode.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const pref = 'ar.onboarded.v1';
  static const needPref = 'ar.need';

  /// Every claim here is checked against the app: nothing in it asks for a
  /// card, the free list is in Settings, and no screen needed for prayer
  /// times, the Qur\u2019an or stories asks for an account. (No "no ads":
  /// the optional YouTube/Spotify players may show their own.)
  static const String welcomeTrustLine =
      'Free today. No sign-up needed. Nothing asks for a card.';

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

  /// Set at once when the introduction ends, so a button mashed twice (or
  /// Skip then Begin) finishes once and cannot push the chosen room twice.
  bool _finishing = false;

  static const _needs = <_Need>[
    _Need('learn', Icons.menu_book_outlined, 'Learning about Islam',
        'Stories, Friday talks (khutbahs), and knowledge'),
    _Need('peace', Icons.favorite_outline, 'Peace for my heart',
        'Du’as and comfort for heavy days'),
    _Need('children', Icons.child_care, 'Teaching my children',
        'Wasia’s letters school and Family Wing'),
    _Need('pray', Icons.access_time, 'Praying on time',
        'Prayer times, qibla, and adhkar'),
    _Need('new', Icons.door_front_door_outlined, 'New to Islam or just curious',
        'A gentle 30-day road, one step at a time. Everyone is welcome'),
    _Need('community', Icons.people_outline, 'A community',
        'Finding your masjid and your people'),
  ];

  /// [skipped]: the person tapped Skip. Their goal is still remembered, but
  /// Skip always lands on Home.
  Future<void> _finish({bool skipped = false}) async {
    if (_finishing) return;
    _finishing = true;
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

  /// Big text or a very narrow screen: the person probably struggles to read
  /// small words, so the welcome offers Elder Mode right here.
  static bool _bigOrNarrow(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3 ||
      MediaQuery.sizeOf(context).width < 260;

  /// Elder Mode from the first screen: ends the introduction (it is seen) and
  /// opens the Elder home, which keeps the app big from then on.
  Future<void> _useElderMode() async {
    if (_finishing) return;
    _finishing = true;
    final GoRouter router = GoRouter.of(context);
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context);
    } catch (_) {
      // No provider scope (a bare test harness): the plain flag is set below.
    }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(OnboardingScreen.pref, true);
    } catch (_) {}
    OnboardingScreen.completedThisSession = true;
    if (container != null) {
      await container.read(elderModeProvider.notifier).set(true);
    } else {
      await ElderMode.set(true);
    }
    router.go(ElderMode.homeRoute);
  }

  /// Two screens only: one short welcome, then the goal choice.
  static const int slides = 2;

  @override
  Widget build(BuildContext context) {
    // Back on a later slide steps to the slide before it (the system Back
    // and the browser-less Android gesture); on the first slide it leaves
    // as usual, to the Home the introduction was opened over.
    final L10n l10n = ref.watch(l10nProvider);
    return PopScope(
      canPop: _i == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _i > 0) {
          unawaited(_page.previousPage(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ));
        }
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            // A real button: 48dp high, readable 16sp words.
            child: TextButton(
              onPressed: () => _finish(skipped: true),
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Skip',
                style: AppText.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _i = i),
              children: [_welcomeSlide(l10n), _needSlide(l10n)],
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
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                    _i < slides - 1 ? l10n.ui('ui.next') : l10n.ui('ui.begin')),
              ),
            ),
          ),
        ]),
      ),
    ),
    );
  }

  /// The one welcome screen. It scrolls, so big text never hides the words.
  Widget _welcomeSlide(L10n l10n) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.mosque_outlined, size: 36, color: AppColors.goldLight),
                ),
                const SizedBox(height: 20),
                Text('AS-SALAAMU ALAIKUM', style: AppText.eyebrow),
                const SizedBox(height: 8),
                const Text('Welcome to Ar-Rayaan', textAlign: TextAlign.center,
                    key: Key('onboarding-welcome-title'),
                    style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 28, color: AppColors.goldLight)),
                const SizedBox(height: 14),
                Text(
                  'Prayer times, the Qur\u2019an, stories, a school for your '
                  'children, and Hādi, a guide you can ask in plain words. '
                  'You do not need to be Muslim to look around.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 18),
                Text(
                  OnboardingScreen.welcomeTrustLine,
                  key: const Key('onboarding-trust-line'),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: AppColors.goldLight),
                ),
                const SizedBox(height: 22),
                _languageChooser(l10n),
                if (_bigOrNarrow(context)) ...[
                  const SizedBox(height: 18),
                  _elderOffer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Easier to read?" - one big tap for Elder Mode (big words, big buttons,
  /// a simple home). It can be switched off again in Settings.
  Widget _elderOffer() {
    return Semantics(
      button: true,
      label: 'Easier to read. Turn on Elder Mode: big words and a simple home.',
      excludeSemantics: true,
      child: InkWell(
        key: const Key('onboarding-elder-offer'),
        onTap: _useElderMode,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
            color: AppColors.gold.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WholeWordText(
                'Easier to read? Turn on Elder Mode',
                style: AppText.body.copyWith(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.goldLight),
              ),
              const SizedBox(height: 4),
              WholeWordText(
                'Big words, big buttons and a simple home. '
                'You can turn it off in Settings.',
                style: AppText.bodyMuted.copyWith(fontSize: 13),
              ),
            ],
          ),
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.ui('onb.question').toUpperCase(),
                    textAlign: TextAlign.center, style: AppText.eyebrow),
                const SizedBox(height: 8),
                Text('Choose one \u2014 it only sets your first door.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMuted.copyWith(fontSize: 13)),
                const SizedBox(height: 18),
                if (_bigOrNarrow(context) ||
                    MediaQuery.textScalerOf(context).scale(14) / 14 > 1.15)
                  // One card per line: two side by side are too narrow for
                  // whole words at big text.
                  for (final _Need n in _needs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: _needCard(n, l10n),
                      ),
                    )
                else
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          for (var col = 0; col < 2; col++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: col == 0 ? 5 : 0,
                                    left: col == 1 ? 5 : 0),
                                child: _needCard(_needs[row * 2 + col], l10n),
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
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
          WholeWordText(l10n.english(n.title), textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: selected ? AppColors.goldLight : null)),
          const SizedBox(height: 4),
          WholeWordText(n.blurb, textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.4)),
        ]),
      ),
    );
  }
}
