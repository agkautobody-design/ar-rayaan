import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/i18n/app_locale.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/core/content_loader.dart';
import '../../../app/core/online_status.dart';
import '../../../app/core/modules/module_status.dart';
import '../../../app/core/providers.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../domain/next_step.dart';
import '../../stories/presentation/new_muslim_path_screen.dart' show NewMuslimPathScreen, pathRevisionProvider;
import '../../academy/application/academy_providers.dart';
import '../../academy/application/family_service.dart';
import '../../menu/presentation/menu_screen.dart' show isAcademyRoute;
import '../../elder/application/elder_mode.dart';
import '../../hadi/presentation/hadi_ask_bar.dart';
import '../../noor/application/noor_providers.dart';
import '../../noor/domain/noor_entry.dart';
import '../../quran/application/quran_translit.dart';
import '../../reading/presentation/arabic_block.dart';
import '../../hadith/presentation/daily_hadith_banner.dart';
import '../../tracking/presentation/tracking_card.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../lamha/domain/lamha.dart';
import '../../prayer/application/prayer_providers.dart';
import '../../prayer/domain/prayer_times.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../../academy/domain/atmosphere.dart';
import '../../academy/presentation/atmosphere_layer.dart';
import '../../calendar/application/hijri_settings.dart';
import '../../calendar/domain/hijri_date.dart';
import '../../../app/core/i18n/bidi.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';

/// Screen 4 · Home — greeting, nine core tiles, "Today for You".
///
/// Tile subtitles are LIVE (locked visuals): next prayer, real reading
/// position, adhkar remaining today, and the honest Forty-Hadith label
/// (O-5 deviation, pending Founder ruling).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final L10n l10n = ref.watch(l10nProvider);
    String ui(String key) => l10n.ui(key);
    // "Today for You" is today's NOOR (a different bundled text each day,
    // the same one the NOOR screen shows). Until it loads, or if it cannot,
    // the card shows one fixed verse instead of nothing.
    final NoorEntry? noor = ref.watch(todayNoorProvider).valueOrNull;
    final String todayArabic = noor?.arabic ?? 'وَاذْكُر رَّبَّكَ إِذَا نَسِيتَ';
    final String todayEnglish =
        noor?.english ?? 'And remember your Lord when you forget.';
    // Transliteration for a Qur'an item comes from the dataset (never typed);
    // a hadith has none yet and the card says so.
    final Map<String, String>? translitMap =
        ref.watch(quranTranslitProvider).valueOrNull;
    String? todayTranslit;
    if (noor != null && noor.kind == NoorKind.quran && translitMap != null) {
      todayTranslit = translitMap[noor.reference];
    }
    final String todaySource =
        noor?.source.toUpperCase() ?? 'QUR\u2019AN 18:24';
    // A prayer name in the person's language (the six names are translated;
    // anything else stays as it is).
    String prayerName(String name) {
      final String key = 'prayer.${name.toLowerCase()}';
      return L10n.words.containsKey(key) ? l10n.w(key) : name;
    }

    // --- Live tile subtitles -------------------------------------------------
    // Times are shown only for a location the person set (never a stand-in).
    final bool locationSet = ref.watch(prayerLocationProvider).isSet;
    String? nextPrayerLabel;
    final String prayerSub = !locationSet
        ? ui('sub.setLocation')
        : ref
              .watch(prayerTimesProvider)
              .when(
                data: (PrayerTimes t) {
                  final (String name, DateTime time) =
                      t.nextPrayer(DateTime.now());
                  nextPrayerLabel = '$name at ${DateFormat.jm().format(time)}';
                  final String clock = DateFormat.jm().format(time);
                  return '${prayerName(name)} · ${LocaleController.isRtl(l10n.locale) ? isolateLtr(clock) : clock}';
                },
                loading: () => ui('sub.loadingTimes'),
                error: (_, _) => ui('sub.timesUnavailable'),
              );

    final ReadingPosition? pos = ref.watch(readingPositionProvider);
    String quranSub = ui('sub.beginReading');
    String? quranResume;
    if (pos != null) {
      final List<SurahMeta>? index = ref.watch(quranIndexProvider).valueOrNull;
      final SurahMeta? meta = index
          ?.where((s) => s.number == pos.surah)
          .firstOrNull;
      quranSub = meta == null
          ? ui('sub.continueReading')
          : '${ui('ui.continue')} · ${meta.transliteration} ${pos.surah}:${pos.ayah}';
      if (meta != null) {
        quranResume = '${meta.transliteration} ${pos.surah}:${pos.ayah}';
      }
    }
    // Web only: say so before the first tap if the Qur'an is not yet kept on
    // this device (null while checking, and always ready on the phone apps).
    quranSub = quranTileSubtitle(
      quranSub,
      offlineReady: ref.watch(quranOfflineReadyProvider).valueOrNull,
    );
    if (quranSub == kQuranNeedsInternetNote) {
      quranSub = ui('sub.needsInternet');
      // Say what to DO, not only what is missing (English; the other
      // languages keep their translated first-time note).
      if (l10n.locale.languageCode == 'en') {
        quranSub = deviceReportsOnline == false
            ? 'Needs internet once: connect, then tap'
            : 'Tap to open it and keep it offline';
      }
    }

    String dhikrSub = ui('sub.morningAdhkar');
    int? adhkarLeft;
    final List<AdhkarSet>? sets = ref.watch(adhkarSetsProvider).valueOrNull;
    if (sets != null && sets.isNotEmpty) {
      ref.watch(adhkarProgressProvider);
      final AdhkarSet morning = sets.first;
      final int done = ref
          .read(adhkarProgressProvider.notifier)
          .completedInSet(morning);
      adhkarLeft = morning.totalRepetitions - done;
      dhikrSub = l10n.locale.languageCode == 'en'
          ? '${ui('sub.morningAdhkar')} · $adhkarLeft ${ui('home.remaining')}'
          : '${ui('sub.morningAdhkar')} · ${ui('home.remaining')} $adhkarLeft';
    }

    final List<(IconData, String, String, String?)> tiles = [
      (
        Icons.nights_stay_outlined,
        'Prayer Times',
        prayerSub,
        AppRoutes.prayerTimes,
      ),
      (Icons.menu_book_outlined, 'Qur’an', quranSub, AppRoutes.quran),
      (Icons.wb_sunny_outlined, 'Dhikr & Du’a', dhikrSub, AppRoutes.adhkar),
      (
        Icons.article_outlined,
        'Hadith',
        'The Forty Hadith · An-Nawawi',
        AppRoutes.hadith,
      ),
      (
        Icons.auto_awesome,
        'Today’s NOOR',
        'A fresh light for your heart',
        AppRoutes.noor,
      ),
      (
        Icons.lightbulb_outline,
        'Hādi',
        'Ask anything · Get guidance',
        AppRoutes.hadi,
      ),
      (
        Icons.calendar_month_outlined,
        'Islamic Calendar',
        'Hijri date, converter & events',
        AppRoutes.calendar,
      ),
      (
        Icons.school_outlined,
        'Stories',
        'Stories, khutbahs & duas',
        AppRoutes.stories,
      ),
      (
        Icons.child_care,
        'Wasia Academy',
        'Letters school & Family Wing',
        AppRoutes.academyGate,
      ),
      (
        Icons.sports_esports_outlined,
        'Games',
        'Quizzes, Ludo & Shatranj',
        AppRoutes.games,
      ),
      (
        Icons.trending_up,
        'My Journey',
        'Track, Reflect & Grow',
        AppRoutes.journey,
      ),
    ];

    // Kill switch: ar.flag.academy=false removes every Academy entry point.
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final List<(IconData, String, String, String?)> shownTiles = [
      for (final t in tiles)
        if (showAcademy || !isAcademyRoute(t.$4)) t,
    ];
    // Today's Hijri date: pure and synchronous (no waiting on anything), and
    // re-read when the person changes the calendar basis.
    ref.watch(hijriSettingsProvider);
    final String hijriRaw =
        '${HijriDate.fromGregorian(DateTime.now()).format()} AH';
    // Latin month names and numbers keep their order inside a right-to-left
    // layout.
    final String hijriToday = LocaleController.isRtl(l10n.locale)
        ? isolateLtr(hijriRaw)
        : hijriRaw;
    // Fixed-aspect tiles must grow with the system text size or the text
    // overflows: give them proportionally more height.
    final double textScale =
        (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
    // A narrow phone or big text: the top blocks shrink so the Prayer Times
    // tile is not pushed below the fold.
    final bool compact =
        textScale > 1.3 || MediaQuery.sizeOf(context).width < 380;
    // The goal chosen in the introduction. Watched, so a Home built before
    // the choice shows the choice's next step as soon as it is back in view.
    final String? needNow = ref.watch(homeNeedProvider);
    final bool newToIslam = needNow == 'new';
    // Someone who is new to Islam, or only here to learn about it, gets a
    // plain greeting: no prayer for a blessing on a day they did not ask for.
    final bool plainGreeting = needNow == 'new' || needNow == 'learn';
    final NextStep step = _nextStepFor(
      ref,
      academyOn: showAcademy,
      nextPrayer: nextPrayerLabel,
      adhkarLeft: adhkarLeft,
      quranResume: quranResume,
    );

    final Widget quick = _SemanticTap(
                label: '${ui('home.quick')}. ${ui('home.quickSub')}',
                onTap: () => context.go('/home/quick'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    color: const Color(0x1A05090F),
                  ),
                  child: Row(children: [
                    const Icon(Icons.dashboard_outlined, color: AppColors.goldLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ui('home.quick'), style: AppText.body.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.goldLight)),
                        // At big text or on a narrow screen the card stays
                        // (it is the way into the quick doors) but sheds its
                        // second line so it does not push the tiles away.
                        if (!compact)
                          Text(ui('home.quickSub'),
                              style: AppText.bodyMuted.copyWith(fontSize: 12)),
                      ],
                    )),
                    const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                  ]),
                ),
              );

    return Scaffold(
      body: AtmosphereLayer(
              emotion: AtmosphereEngine.resolve(now: DateTime.now()).emotion,
              child: Stack(
        children: [
          const ScenicBackground.home(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Color(0xE605090F),
                      Color(0xA605090F),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _Header(
                    // Big text or a narrow phone: the Ask bar gets its own
                    // line instead of being squeezed between the icons.
                    stacked: textScale > 1.3 ||
                        MediaQuery.sizeOf(context).width < 380,
                  ),
                ),
                Expanded(
                  // Tab goes top to bottom, row by row: Elder Mode, Quick
                  // Access, the tiles, the links, then the cards below.
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // Greeting sits directly on the scenery (locked board).
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: compact ? 0 : 178),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ui(plainGreeting ? 'home.greeting.new' : 'home.greeting'),
                                style: AppText.bodyMuted.copyWith(fontSize: 12),
                              ),
                              Text(
                                hijriToday,
                                key: const Key('home-hijri-date'),
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 12,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GoldText(
                                ui('home.welcome'),
                                style: AppText.displayMedium.copyWith(
                                  fontSize: 32,
                                ),
                              ),
                              if (textScale <= 1.3) ...[
                                const SizedBox(height: 8),
                                Text(
                                  ui(plainGreeting ? 'home.blessing.new' : 'home.blessing'),
                                  style: AppText.bodyMuted.copyWith(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
              // Someone new to Islam sees the 30-day road first, ahead of
              // Elder Mode and Quick Access.
              if (newToIslam)
                _NextStepCard(
                  step: step,
                  compact: compact,
                  label: ui('home.nextStep'),
                ),
              _SemanticTap(
                label: ref.watch(elderModeProvider)
                    ? '${ui('home.elder')}, ${ui('home.elderOn')}. Open the Elder home.'
                    : '${ui('home.elder')}, ${ui('home.elderOff')}. ${ui('home.elderSub')}',
                onTap: () async {
                  // Already on: just go there. Otherwise it stays on across
                  // launches, so ask first.
                  if (!ref.read(elderModeProvider) &&
                      !await _confirmElderMode(context)) {
                    return;
                  }
                  await ref.read(elderModeProvider.notifier).set(true);
                  if (context.mounted) context.go(ElderMode.homeRoute);
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.2),
                    color: const Color(0x2405090F),
                  ),
                  // The words come first: at big text or on a narrow phone
                  // the icon and chevron step aside and the title is one
                  // line that shrinks, never "ELDE / R / MODE".
                  child: Row(children: [
                    if (textScale <= 1.3) ...[
                      const Icon(Icons.elderly_outlined, color: AppColors.goldLight, size: 26),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(ui('home.elder'), maxLines: 1, softWrap: false,
                              style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w800, fontSize: 15,
                                  color: AppColors.goldLight, letterSpacing: 1.2)),
                        ),
                        Text(
                            ref.watch(elderModeProvider)
                                ? 'On now. Tap to open the Elder home.'
                                : compact
                                    ? ui('home.elderSub')
                                    : ui('home.elderSubLong'),
                            style: AppText.bodyMuted.copyWith(fontSize: 12)),
                      ],
                    )),
                    // On or off, in words (never by colour alone).
                    Container(
                      key: const Key('home-elder-state'),
                      margin: const EdgeInsetsDirectional.only(start: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withValues(
                              alpha: ref.watch(elderModeProvider) ? 0.9 : 0.4),
                        ),
                        color: ref.watch(elderModeProvider)
                            ? AppColors.gold.withValues(alpha: 0.18)
                            : Colors.transparent,
                      ),
                      child: Text(
                        ref.watch(elderModeProvider)
                            ? ui('home.elderOn')
                            : ui('home.elderOff'),
                        style: AppText.body.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (textScale <= 1.3)
                      const Icon(Icons.chevron_right, color: AppColors.gold, size: 22),
                  ]),
                ),
              ),
              quick,
              if (!newToIslam)
                _NextStepCard(
                  step: step,
                  compact: compact,
                  label: ui('home.nextStep'),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  label: 'Support and wellbeing. Help with a struggle, and people to call.',
                  excludeSemantics: true,
                  child: InkWell(
                    key: const Key('home-support-card'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.open(AppRoutes.support),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.favorite_border,
                              color: AppColors.gold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                'Support & wellbeing: help with a struggle, and people to call',
                                style: AppText.body.copyWith(fontSize: 14)),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.gold, size: 22),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              GridView.count(
                        // Adaptive: phones keep three tiles; wide screens
                        // gain columns so nothing stretches into emptiness.
                        crossAxisCount: MediaQuery.of(context).size.width > 1100
                            ? 5
                            : MediaQuery.of(context).size.width > 780
                                ? 4
                                // A very narrow window (a zoomed browser):
                                // two columns, so a tile word has room.
                                : MediaQuery.of(context).size.width < 300
                                    ? 2
                                    : 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 10,
                        childAspectRatio:
                            (MediaQuery.of(context).size.width > 780
                                    ? 1.15
                                    // A 320px phone has ~87px-wide tiles: a
                                    // little taller so title and subtitle fit.
                                    : MediaQuery.of(context).size.width < 360
                                        ? 0.88
                                        : 1.0) /
                                textScale,
                        children: [
                          for (final (_, title, sub, route) in shownTiles)
                            _PictureTile(
                              image: _tileImage(title),
                              title: l10n.english(title),
                              subtitle: l10n.english(sub),
                              badge: _badgeFor(ref, route, l10n),
                              onTap: () =>
                                  context.go(route ?? AppRoutes.explore),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(ui('home.also'), style: AppText.bodyMuted),
                          _AlsoLink(
                            label: ui('home.nasheeds'),
                            onTap: () => context.open(AppRoutes.player),
                          ),
                          _AlsoLink(
                            label: ui('home.forChildren'),
                            onTap: () => context.open(AppRoutes.kids),
                          ),
                          _AlsoLink(
                            label: ui('home.mosques'),
                            onTap: () => context.open('/masajid'),
                          ),
                          _AlsoLink(
                            label: ui('ui.qibla'),
                            onTap: () => context.open(AppRoutes.qibla),
                          ),
                          _AlsoLink(
                            label: ui('home.names99'),
                            onTap: () => context.open(AppRoutes.names99),
                          ),
                          // One tap from Home: help with a struggle, with
                          // people to call. Not hidden inside another room.
                          _AlsoLink(
                            label: 'Support & wellbeing',
                            onTap: () => context.open(AppRoutes.support),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Below the tiles on purpose: it loads late, and above them it
                      // pushed the tiles down under a person's finger.
                      const DailyHadithBanner(),
                      const TrackingCard(),
                      GlassCard(
                        strong: true,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ui('home.today'),
                                  style: AppText.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                _SemanticTap(
                                  label: '${ui('home.viewAll')}: ${ui('home.today')}',
                                  minHeight: 48,
                                  onTap: () => context.go(AppRoutes.noor),
                                  child: Text(
                                    ui('home.viewAll'),
                                    style: AppText.bodyMuted.copyWith(
                                      fontSize: 12,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ArabicBlock(
                                        key: const Key('home-daily-verse'),
                                        arabic: todayArabic,
                                        translit: todayTranslit,
                                        meaning: todayEnglish,
                                        needsReview: todayTranslit != null,
                                        translitSource: 'quran-json',
                                        arabicSize: 20,
                                        density: ArabicBlockDensity.compact,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        todaySource,
                                        style: AppText.eyebrow.copyWith(
                                          fontSize: 12,
                                          letterSpacing: compact ? 0.5 : 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Large text: the picture would squeeze the
                                // verse into a one-letter-wide column.
                                if (!compact) ...<Widget>[
                                  const SizedBox(width: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/today-quran.png',
                                      width: 104,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Lamha — the gentle Sunnah glance (max 2/week by
                      // constitution; nothing shows on quiet days).
                      if (LamhaEngine.forDate(DateTime.now()) != null) ...[
                        const SizedBox(height: 16),
                        _LamhaCard(moment: LamhaEngine.forDate(DateTime.now())!),
                      ],
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

/// "Turn on Elder Mode?" - true to go ahead. Elder Mode is remembered, so a
/// stray tap on Home must not switch it on for good.
Future<bool> _confirmElderMode(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      semanticLabel: 'Turn on Elder Mode?',
      backgroundColor: const Color(0xFF0A0F18),
      title: Text('Turn on Elder Mode?', style: AppText.titleMedium),
      content: Text(
        'The app will open on a simple home with big words and a few simple doors '
        'every time, until you turn Elder Mode off (on that home, or in '
        'Settings).',
        style: AppText.bodyMuted,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          key: const Key('elder-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Turn on'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Reads the stored goal and progress, then asks the pure rules which card
/// to show. Everything comes from providers and preferences the app already
/// has; a failure to read falls back to the Qur'an card.
NextStep _nextStepFor(
  WidgetRef ref, {
  required bool academyOn,
  required String? nextPrayer,
  required int? adhkarLeft,
  required String? quranResume,
}) {
  final String? need = ref.watch(homeNeedProvider);
  // Ticking a day of the road, here or inside the day, re-reads this.
  ref.watch(pathRevisionProvider);
  int newMuslimDone = 0;
  try {
    final SharedPreferences p = ref.read(sharedPreferencesProvider);
    if (need == 'new') {
      for (final String k in p.getKeys()) {
        if (k.startsWith(NewMuslimPathScreen.donePrefix) &&
            p.getBool(k) == true) {
          newMuslimDone++;
        }
      }
    }
  } catch (_) {}
  final int lessonsDone = need == 'learn' && academyOn
      ? ref.watch(lessonsDoneProvider)
      : 0;
  final int kids = need == 'children' && academyOn
      ? (ref.watch(childrenProvider).valueOrNull?.length ?? 0)
      : 0;
  return resolveNextStep(
    need: need,
    academyOn: academyOn,
    childrenAdded: kids,
    nextPrayer: nextPrayer,
    adhkarLeft: adhkarLeft,
    quranResume: quranResume,
    newMuslimDone: newMuslimDone,
    lessonsDone: lessonsDone,
  );
}

/// The single "Your next step" card under the greeting.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.step,
    required this.compact,
    required this.label,
  });

  final NextStep step;
  final bool compact;

  /// The small heading above the card ("YOUR NEXT STEP", translated).
  final String label;

  @override
  Widget build(BuildContext context) {
    final String? second = step.secondaryRoute;
    return Padding(
      key: const Key('home-next-step'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
          color: const Color(0x8005090F),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SemanticTap(
              label: '$label. ${step.headline}. ${step.detail}',
              minHeight: 48,
              onTap: () => context.open(step.route),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppText.eyebrow),
                          const SizedBox(height: 2),
                          Text(
                            step.headline,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AppColors.goldLight,
                            ),
                          ),
                          Text(
                            step.detail,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            if (second != null && step.secondaryLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: _AlsoLink(
                  label: step.secondaryLabel!,
                  onTap: () => context.open(second),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Home's top line: the Ask Hādi bar, Search and Menu. [stacked] puts the bar
/// on its own line below the icons.
///
/// There is no Back arrow here. Home is the root of the Home tab (every route
/// to it replaces the stack), so there is never a screen under it to return
/// to; the arrow was a node at the top of Home's reading order that did
/// nothing useful, or bounced.
class _Header extends StatelessWidget {
  const _Header({required this.stacked});

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final Widget search = _HeaderIcon(
      icon: Icons.search,
      tooltip: 'Search',
      onTap: () => context.open(AppRoutes.search),
    );
    final Widget menu = _HeaderIcon(
      icon: Icons.menu,
      tooltip: 'Menu',
      onTap: () => context.open(AppRoutes.menu),
    );

    if (stacked) {
      return Column(
        children: [
          Row(
            children: [
              const Spacer(),
              search,
              const SizedBox(width: 8),
              menu,
            ],
          ),
          const SizedBox(height: 8),
          const HadiAskBar(),
        ],
      );
    }
    return Row(
      children: [
        const Expanded(child: HadiAskBar()),
        const SizedBox(width: 12),
        search,
        const SizedBox(width: 8),
        menu,
      ],
    );
  }
}

/// The Lamha strip — one sourced glance, dismissible by simply scrolling
/// past; never stacked, never loud.
class _LamhaCard extends StatelessWidget {
  const _LamhaCard({required this.moment});

  final LamhaMoment moment;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LAMHA · ${moment.title.toUpperCase()}',
                  style: AppText.eyebrow.copyWith(
                    color: AppColors.gold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            moment.body,
            style: AppText.body.copyWith(
              fontSize: 12.5,
              height: 1.6,
              color: AppColors.sand.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moment.source,
            style: AppText.eyebrow.copyWith(
              fontSize: 12,
              color: AppColors.gold.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small text shortcut on Home (the 'Also' row under the tiles).
class _AlsoLink extends StatelessWidget {
  const _AlsoLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SemanticTap(
      label: label,
      minHeight: 48,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: AppText.bodyMuted.copyWith(
            color: AppColors.gold,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.gold.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusSafeSemantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: FocusRing(
          borderRadius: 22,
          child: Material(
          type: MaterialType.transparency,
          child: FocusRing(borderRadius: 12, child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            // 48 px touch target around the 36 px circle.
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.glassFill,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.sand.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          )),
          ),
        ),
      ),
    );
  }
}


String _tileImage(String t) {
  const base = 'assets/images/tiles';
  if (t.startsWith('Prayer')) return '$base/tile_prayer.jpg';
  if (t.startsWith('Qur')) return '$base/tile_quran.jpg';
  if (t.startsWith('Dhikr')) return '$base/tile_dhikr.jpg';
  if (t.startsWith('Hadith')) return '$base/tile_hadith.jpg';
  if (t.startsWith('Today')) return '$base/tile_noor.jpg';
  if (t.startsWith('H\u0101di') || t.startsWith('Hadi')) {
    return '$base/tile_hadi.jpg';
  }
  if (t.startsWith('Islamic')) return '$base/tile_calendar.jpg';
  if (t.startsWith('Stories')) return '$base/tile_knowledge.jpg';
  if (t.startsWith('Games')) return '$base/tile_knowledge.jpg';
  // Fallback until a dedicated Academy tile image ships
  // (see state/art_list.md, Wave 1 #1).
  if (t.startsWith('Wasia')) return '$base/tile_knowledge.jpg';
  return '$base/tile_journey.jpg';
}


/// Badge text for a tile's module, straight from the registry. Null when
/// live, unmapped, or still loading — a tile is never badged on a guess.
String? _badgeFor(WidgetRef ref, String? route, L10n l10n) {
  if (route == null) return null;
  final String? moduleId = _tileModule[route];
  if (moduleId == null) return null;
  String status = 'live';
  ref
      .watch(moduleRegistryProvider)
      .whenData((ModuleStatusService s) => status = s.statusOf(moduleId));
  if (status == 'live') return null;
  return l10n.ui('home.soon');
}

/// Which registry module each home tile answers to. Tiles without an
/// entry are never badged — unknown must never be shamed.
const Map<String, String> _tileModule = <String, String>{
  '/prayer': 'prayer',
  '/quran': 'quran',
  '/adhkar': 'adhkar',
  '/hadith': 'daily-hadith',
  '/noor': 'noor',
  '/hadi': 'hadi',
  '/stories': 'stories',
  '/academy/gate': 'academy',
};

class _PictureTile extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  const _PictureTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return FocusSafeSemantics(
      button: true,
      label: badge == null ? '$title. $subtitle' : '$title, $badge. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: FocusableTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.16, 0.55, 1.0],
              colors: const [
                Colors.transparent,
                Color(0xB805090F),
                Color(0xFA05090F),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          // The badge floats at the top; the words sit at the bottom and give
          // way (ellipsis) rather than overflow on a 320px phone or at big
          // text.
          child: Stack(
            children: [
              if (badge != null)
                Positioned(
                  top: 8,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xCC05090F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      badge!,
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: WholeWordText(
                        title,
                        maxLines: 2,
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: WholeWordText(
                        subtitle,
                        maxLines: 2,
                        style: AppText.bodyMuted.copyWith(
                          fontSize: 12,
                          height: 1.3,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 6),
                          ],
                        ),
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
}


/// A tappable region that screen readers announce as a button, with an
/// optional minimum touch height (48 for small text links).
class _SemanticTap extends StatelessWidget {
  const _SemanticTap({
    required this.label,
    required this.onTap,
    required this.child,
    this.minHeight = 0,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return FocusSafeSemantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusableTap(
        borderRadius: 12,
        onTap: onTap,
        child: minHeight > 0
            ? ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Align(alignment: Alignment.center, widthFactor: 1, child: child),
              )
            : child,
      ),
    );
  }
}
