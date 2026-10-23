import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/reset_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/verify_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/academy/presentation/academy_home_screen.dart';
import '../features/academy/presentation/course_overview_screen.dart';
import '../features/academy/presentation/lesson_player_screen.dart';
import '../features/academy/presentation/my_additions_screen.dart';
import '../features/academy/presentation/request_nasheed_screen.dart';
import '../features/academy/presentation/wasia_lessons.dart';
import '../features/academy/presentation/academy_family.dart';
import '../features/academy/presentation/player_screen.dart';
import '../features/academy/presentation/playlists_screen.dart';
import '../features/academy/presentation/word_deck_screen.dart';
import '../features/academy/presentation/tajweed_cards_screen.dart';
import '../features/academy/presentation/hifz_planner_screen.dart';
import '../features/academy/presentation/dua_school_screen.dart';
import '../features/academy/presentation/understanding_school_screen.dart';
import '../features/academy/presentation/arabic_language_school_screen.dart';
import '../features/academy/presentation/aqeedah_school_screen.dart';
import '../features/academy/presentation/hadith_school_screen.dart';
import '../features/academy/presentation/seerah_school_screen.dart';
import '../features/academy/presentation/history_school_screen.dart';
import '../features/academy/presentation/stories_school_screen.dart';
import '../features/academy/presentation/character_school_screen.dart';
import '../features/academy/presentation/family_school_screen.dart';
import '../features/academy/presentation/youth_school_screen.dart';
import '../features/academy/presentation/womens_school_screen.dart';
import '../features/academy/presentation/transactions_school_screen.dart';
import '../features/academy/presentation/end_of_life_school_screen.dart';
import '../features/academy/presentation/dawah_school_screen.dart';
import '../features/academy/presentation/health_school_screen.dart';
import '../features/academy/presentation/hisn_al_muslim_screen.dart';
import '../features/academy/presentation/hajj_umrah_pack_screen.dart';
import '../features/academy/presentation/ramadan_mode_screen.dart';
import '../features/academy/presentation/qa_bank_screen.dart';
import '../features/academy/presentation/audio_packs_screen.dart';
import '../features/academy/presentation/dhikr_session_screen.dart';
import '../features/doctor/presentation/founder_console_screen.dart';
import '../features/academy/presentation/madinah_reader_view.dart';
import '../features/academy/presentation/review_session_screen.dart';
import '../features/dev_tools/presentation/theme_demo_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/hadi/presentation/hadi_screen.dart';
import '../features/legal/legal_routes.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journey/presentation/journey_screen.dart';
import '../features/menu/presentation/menu_screen.dart';
import '../features/noor/presentation/noor_screen.dart';
import '../features/prayer/presentation/prayer_times_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/adhkar/presentation/adhkar_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/hadith/presentation/hadith_screen.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../features/sakina/presentation/sakina_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/share/presentation/share_screen.dart';
import '../features/sources/presentation/content_policy_screen.dart';
import '../features/sources/presentation/sources_screen.dart';
import '../features/stories/presentation/stories_screen.dart';
import '../features/stories/presentation/new_muslim_path_screen.dart';
import '../features/family/presentation/family_tree_screen.dart';
import '../features/huda/presentation/huda_screens.dart';
import '../features/elder/presentation/elder_care_screen.dart';
import '../features/elder/presentation/elder_home_screen.dart';
import '../features/finance/presentation/tayyib_finance_screen.dart';
import '../features/finance/presentation/rayaan_stocks_screen.dart';
import '../features/finance/presentation/trading_floor_screen.dart';
import '../features/masjid/presentation/masjid_finder_screen.dart';
import '../features/ramadan/presentation/ramadan_screen.dart';
import '../features/settings/presentation/language_settings.dart';
import '../features/home/presentation/home_quick_screen.dart';
import '../features/games/presentation/games_screens.dart';
import '../features/games/presentation/games_extra.dart';
import '../features/games/presentation/shatranj_screen.dart';
import '../features/games/presentation/ludo_screen.dart';
import '../features/feelings/presentation/feelings_screens.dart';
import '../features/notes/presentation/tools_screens.dart';
import '../features/majlis/presentation/majlis_screens.dart';
import '../features/academy/presentation/academy_gate_screen.dart';
import '../features/stories/presentation/story_reader_screen.dart';
import '../features/stories/domain/story.dart';
import '../features/zakat/presentation/zakat_screen.dart';
import '../features/quran/presentation/quran_bookmarks_screen.dart';
import '../features/quran/presentation/quran_screen.dart';
import '../features/quran/presentation/surah_reader_screen.dart';
import 'theme/widgets/app_bottom_nav.dart';
import 'theme/widgets/ask_hadi_pill.dart';
import 'theme/widgets/not_found_view.dart';

/// Application routes (GoRouter) — Master Build Sheet §5.
/// Developer and founder tools are compiled into release builds only when
/// explicitly requested (--dart-define=FOUNDER_TOOLS=true).
const bool kFounderTools =
    !kReleaseMode || bool.fromEnvironment('FOUNDER_TOOLS');

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String search = '/search';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String hadi = '/hadi';
  static const String noor = '/noor';
  static const String journey = '/journey';
  static const String community = '/community';
  // The Family tab: the real Family Wing, inside the bottom-nav shell.
  static const String family = '/family';
  static const String academy = '/academy';
  static const String academyGate = '/academy/gate';
  static const String player = '/player';
  static const String myAdditions = '/player/my-additions';
  static const String myPlaylists = '/player/playlists';
  static const String requestNasheed = '/player/request';
  static String academyLesson(String c, String u, String l) =>
      '/academy/lesson/$c/$u/$l';

  static const String profile = '/profile';
  static const String menu = '/menu';

  // Auth flow (WP4 — pending Founder approval)
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String reset = '/auth/reset';
  static const String verify = '/auth/verify';

  // Feature modules (WP5 — pending Founder approval)
  static const String prayerTimes = '/prayer';
  static const String quran = '/quran';
  static const String hadith = '/hadith';
  static const String feelings = '/feelings';
  static const String majlis = '/majlis';
  static const String majlisThread = '/majlis/thread';
  static const String majlisNew = '/majlis/new';
  static const String notes = '/notes';
  static const String downloads = '/downloads';
  static const String games = '/games';
  static const String trivia = '/games/trivia';
  static const String names99 = '/games/names99';
  static const String huda = '/huda';
  static const String hudaGuide = '/huda/guide';
  static const String familyTree = '/family-tree';
  static const String stories = '/stories';
  static const String storyReader = '/stories/read';
  static const String newMuslimPath = '/new-muslim';
  static const String adhkar = '/adhkar';
  static const String qibla = '/qibla';
  static const String calendar = '/calendar';
  static const String zakat = '/zakat';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String sources = '/sources';
  static const String sourcesPolicy = '/sources/policy';
  static const String quranBookmarks = '/quran/bookmarks';
  static const String sakina = '/sakina';
  static String surah(int number) => '/quran/$number';
  static String surahAt(int number, int ayah) => '/quran/$number?ayah=$ayah';

  static const String themeDemo = '/dev/theme';
}

/// Routes that are tabs of the bottom-navigation shell. Opening one of these
/// with `push` would stack a second copy inside the shell, so they are
/// always reached with `go`.
const Set<String> kShellTabPaths = <String>{
  AppRoutes.home,
  AppRoutes.noor,
  AppRoutes.journey,
  AppRoutes.explore,
  AppRoutes.family,
  AppRoutes.community,
  AppRoutes.hadi,
  AppRoutes.profile,
};

/// Navigation that keeps Back honest.
extension AppNavigation on BuildContext {
  /// Opens [route] ON TOP of the current screen, so Back / Close return to
  /// it (a hub's list, a reader's shelf) instead of jumping to Home. Shell
  /// tabs are reached with `go`, as they replace the stack by design.
  void open(String route, {Object? extra}) {
    final String path = Uri.tryParse(route)?.path ?? route;
    if (kShellTabPaths.contains(path)) {
      go(route, extra: extra);
    } else {
      push(route, extra: extra);
    }
  }
}

/// One page of the soft-fade transition. [pill] adds the "Ask Hādi" pill
/// inside the page (see [AskHadiPillHost]); pass false for the tabs of the
/// bottom-navigation shell, first-run, boards and readers whose content the
/// pill would cover.
CustomTransitionPage<void> _fade(Widget child, {bool pill = true}) {
  // The soft transition: every screen breathes in with a gentle fade and a
  // whisper of rise. Built to dodge the web's stuck-grey-veil freeze the
  // founders hit: NO ScaleTransition (texture compositing was the trigger),
  // NO secondaryAnimation parallax, symmetric reverse, short durations, and
  // an easeOutCubic that settles fast even when the user taps mid-flight.
  return CustomTransitionPage<void>(
    child: pill ? AskHadiPillHost(child: child) : child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
                  .animate(curved),
          child: child,
        ),
      );
    },
  );
}

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    // Any unknown link lands somewhere useful instead of a red error page.
    errorPageBuilder: (context, state) =>
        _fade(const NotFoundScreen(), pill: false),
    routes: [
      ...legalRoutes,
      // Onboarding flow (no bottom nav)
      // '/' is only an entry point: Home lives exactly once, inside the
      // bottom-nav shell at /home (the Home tab), so '/' forwards there.
      GoRoute(
          path: AppRoutes.splash,
          redirect: (context, state) => AppRoutes.home,
        ),
        // First-run gate: onboarding completes and sets ar.onboarded.v1.
        // main() routes here only when the pref is unset.
        GoRoute(
          path: AppRoutes.onboarding,
          pageBuilder: (context, state) => _fade(const OnboardingScreen(), pill: false),
        ),
        GoRoute(
          path: AppRoutes.search,
          pageBuilder: (context, state) => _fade(const SearchScreen()),
        ),
        GoRoute(
          path: '/ramadan',
          pageBuilder: (context, state) => _fade(const RamadanScreen()),
        ),
        GoRoute(
          path: '/finance/floor',
          pageBuilder: (context, state) => _fade(const TradingFloorScreen()),
        ),
        GoRoute(
          path: '/finance/rayaan',
          pageBuilder: (context, state) => _fade(const RayaanStocksScreen()),
        ),
        GoRoute(
          path: '/finance/rayaan/:id',
          pageBuilder: (context, state) =>
              _fade(FinLessonScreen(lessonId: state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/settings/language',
          pageBuilder: (context, state) => _fade(const LanguageSettingsScreen()),
        ),
        GoRoute(
          path: '/masajid',
          pageBuilder: (context, state) => _fade(const MasjidFinderScreen()),
        ),
        GoRoute(
          path: '/finance',
          pageBuilder: (context, state) => _fade(const TayyibFinanceScreen()),
        ),
        GoRoute(
          path: '/home/elder',
          pageBuilder: (context, state) => _fade(const ElderHomeScreen()),
        ),
        GoRoute(
          path: '/elder-care',
          pageBuilder: (context, state) => _fade(const ElderCareScreen()),
        ),
        GoRoute(
          path: '/home/quick',
          pageBuilder: (context, state) => _fade(const HomeQuickScreen()),
        ),
        GoRoute(
          path: '/games/ludo',
          pageBuilder: (context, state) => _fade(const LudoScreen(), pill: false),
        ),
        GoRoute(
          path: '/games/shatranj',
          pageBuilder: (context, state) => _fade(const ShatranjScreen(), pill: false),
        ),
        GoRoute(
          path: '/games/lineage',
          pageBuilder: (context, state) => _fade(const LineageChallengeScreen()),
        ),
        GoRoute(
          path: '/games/ayah',
          pageBuilder: (context, state) => _fade(const AyahCompletionScreen()),
        ),
        GoRoute(
          path: '/games/hijrah',
          pageBuilder: (context, state) => _fade(const HijrahMapScreen()),
        ),
        GoRoute(
          path: AppRoutes.player,
          pageBuilder: (context, state) => _fade(const PlayerScreen()),
        ),
        GoRoute(
          path: AppRoutes.academyGate,
          pageBuilder: (context, state) => _fade(const AcademyGateScreen()),
        ),
        GoRoute(
          path: AppRoutes.majlis,
          pageBuilder: (context, state) => _fade(const MajlisScreen()),
        ),
        GoRoute(
          path: '${AppRoutes.majlisThread}/:id',
          pageBuilder: (context, state) => _fade(ThreadScreen(
            threadId: state.pathParameters['id']!,
            title: state.extra as String? ?? '',
          )),
        ),
        GoRoute(
          path: AppRoutes.majlisNew,
          pageBuilder: (context, state) => _fade(const NewThreadScreen()),
        ),
        GoRoute(
          path: AppRoutes.notes,
          pageBuilder: (context, state) => _fade(const NotesScreen()),
        ),
        GoRoute(
          path: AppRoutes.downloads,
          pageBuilder: (context, state) => _fade(const DownloadsScreen()),
        ),
        GoRoute(
          path: AppRoutes.feelings,
          pageBuilder: (context, state) => _fade(const FeelingsScreen()),
        ),
        GoRoute(
          path: '${AppRoutes.feelings}/:id',
          pageBuilder: (context, state) => _fade(
            FeelingScreen(feelingId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: AppRoutes.games,
          pageBuilder: (context, state) => _fade(const GamesScreen()),
        ),
        GoRoute(
          path: AppRoutes.trivia,
          pageBuilder: (context, state) => _fade(const TriviaScreen()),
        ),
        GoRoute(
          path: AppRoutes.names99,
          pageBuilder: (context, state) => _fade(const Names99Screen()),
        ),
        GoRoute(
          path: AppRoutes.huda,
          pageBuilder: (context, state) => _fade(const HudaScreen()),
        ),
        GoRoute(
          path: AppRoutes.hudaGuide,
          // The guide id travels in `?id=` so a browser refresh or a pasted
          // link still opens it; `extra` is only a fast path.
          pageBuilder: (context, state) => _fade(GuideRouteScreen(
            guideId: state.uri.queryParameters['id'],
            guide: state.extra is Guide ? state.extra! as Guide : null,
          )),
        ),
        GoRoute(
          path: AppRoutes.familyTree,
          pageBuilder: (context, state) =>
              _fade(const FamilyTreeScreen()),
        ),
        GoRoute(
          path: AppRoutes.stories,
          pageBuilder: (context, state) =>
              _fade(const StoriesScreen()),
        ),
        GoRoute(
          path: AppRoutes.storyReader,
          // Same refresh/deep-link hazard as the Huda guide: no `extra`,
          // no story - go back to the library rather than crash.
          redirect: (context, state) =>
              state.extra is Story ? null : AppRoutes.stories,
          pageBuilder: (context, state) =>
              _fade(StoryReaderScreen(story: state.extra! as Story)),
        ),
        GoRoute(
          path: AppRoutes.newMuslimPath,
          pageBuilder: (context, state) => _fade(const NewMuslimPathScreen()),
        ),

      // Auth flow (no bottom nav)
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fade(const LoginScreen(), pill: false),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (c, s) => _fade(const SignUpScreen(), pill: false),
      ),
      GoRoute(
        path: AppRoutes.reset,
        pageBuilder: (c, s) => _fade(const ResetScreen(), pill: false),
      ),
      GoRoute(
        path: AppRoutes.verify,
        pageBuilder: (c, s) => _fade(const VerifyScreen(), pill: false),
      ),

      // Feature modules (no bottom nav)
      GoRoute(
        path: AppRoutes.prayerTimes,
        pageBuilder: (c, s) => _fade(const PrayerTimesScreen()),
      ),
      GoRoute(
        path: AppRoutes.quran,
        pageBuilder: (c, s) => _fade(const QuranScreen()),
      ),
      GoRoute(
        path: AppRoutes.hadith,
        pageBuilder: (c, s) => _fade(const HadithScreen()),
      ),
      GoRoute(
        path: AppRoutes.adhkar,
        pageBuilder: (c, s) => _fade(const AdhkarScreen()),
      ),
      GoRoute(
        path: AppRoutes.qibla,
        pageBuilder: (c, s) => _fade(const QiblaScreen()),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        pageBuilder: (c, s) => _fade(const CalendarScreen()),
      ),
      GoRoute(
        path: AppRoutes.zakat,
        pageBuilder: (c, s) => _fade(const ZakatScreen()),
      ),
      GoRoute(
        path: AppRoutes.share,
        pageBuilder: (c, s) => _fade(const ShareScreen()),
      ),
      GoRoute(
        path: AppRoutes.myAdditions,
        pageBuilder: (c, s) => _fade(const MyAdditionsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myPlaylists,
        pageBuilder: (c, s) => _fade(const PlaylistsScreen()),
      ),
      GoRoute(
        path: AppRoutes.requestNasheed,
        pageBuilder: (c, s) => _fade(const RequestNasheedScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (c, s) => _fade(const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.sources,
        pageBuilder: (c, s) => _fade(const SourcesScreen()),
      ),
      GoRoute(
        path: AppRoutes.sourcesPolicy,
        pageBuilder: (c, s) => _fade(const ContentPolicyScreen()),
      ),
      GoRoute(
        path: AppRoutes.sakina,
        pageBuilder: (c, s) => _fade(const SakinaScreen()),
      ),
      GoRoute(
        path: AppRoutes.quranBookmarks,
        pageBuilder: (c, s) => _fade(const QuranBookmarksScreen()),
      ),
      GoRoute(
        path: '/quran/:surah',
        pageBuilder: (c, s) {
          final int? number = int.tryParse(s.pathParameters['surah'] ?? '');
          // A surah is 1-114; anything else is a page that is not there
          // (it used to open Al-Fatihah or An-Nas silently).
          if (number == null || number < 1 || number > 114) {
            return _fade(
              const NotFoundScreen(message: 'That surah is not here.'),
              pill: false,
            );
          }
          return _fade(
            SurahReaderScreen(
              number: number,
              // "?ayah=255" opens at that ayah (the Ayat al-Kursi shortcut).
              startAyah: int.tryParse(s.uri.queryParameters['ayah'] ?? ''),
            ),
            pill: false,
          );
        },
      ),

      // Standalone destinations
      GoRoute(
        path: AppRoutes.menu,
        pageBuilder: (c, s) => _fade(const MenuScreen()),
      ),
      GoRoute(
        path: AppRoutes.academy,
        pageBuilder: (context, state) => _fade(const AcademyHomeScreen()),
      ),
      GoRoute(
        path: '/quran/madinah/:surah/:count',
        pageBuilder: (context, state) {
          final p = state.pathParameters;
          // A link can carry anything: a surah is 1-114 and an ayah count is
          // a whole number of at least 1 (the longest surah has 286). Anything
          // else is a page that is not there, never an exception.
          final int? surah = int.tryParse(p['surah'] ?? '');
          final int? count = int.tryParse(p['count'] ?? '');
          if (surah == null ||
              count == null ||
              surah < 1 ||
              surah > 114 ||
              count < 1 ||
              count > 286) {
            return _fade(
              const NotFoundScreen(message: 'That page of the Qur\u2019an is not here.'),
              pill: false,
            );
          }
          return _fade(
            MadinahReaderView(surah: surah, ayahCount: count),
            pill: false,
          );
        },
      ),
      GoRoute(
        path: '/academy/hifz',
        pageBuilder: (context, state) => _fade(const HifzPlannerScreen()),
      ),
      GoRoute(
        path: '/academy/arabic-language',
        pageBuilder: (context, state) => _fade(const ArabicLanguageSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/aqeedah',
        pageBuilder: (context, state) => _fade(const AqeedahSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/hadith',
        pageBuilder: (context, state) => _fade(const HadithSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/seerah',
        pageBuilder: (context, state) => _fade(const SeerahSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/history',
        pageBuilder: (context, state) => _fade(const HistorySchoolScreen()),
      ),
      GoRoute(
        path: '/academy/stories',
        pageBuilder: (context, state) => _fade(const StoriesSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/character',
        pageBuilder: (context, state) => _fade(const CharacterSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/family-life',
        pageBuilder: (context, state) => _fade(const FamilySchoolScreen()),
      ),
      GoRoute(
        path: '/academy/youth',
        pageBuilder: (context, state) => _fade(const YouthSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/womens',
        pageBuilder: (context, state) => _fade(const WomensSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/transactions',
        pageBuilder: (context, state) => _fade(const TransactionsSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/end-of-life',
        pageBuilder: (context, state) => _fade(const EndOfLifeSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/dawah',
        pageBuilder: (context, state) => _fade(const DawahSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/health',
        pageBuilder: (context, state) => _fade(const HealthSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/hisn',
        pageBuilder: (context, state) => _fade(const HisnAlMuslimScreen()),
      ),
      GoRoute(
        path: '/academy/hajj-umrah-pack',
        pageBuilder: (context, state) => _fade(const HajjUmrahPackScreen()),
      ),
      GoRoute(
        path: '/academy/ramadan-mode',
        pageBuilder: (context, state) => _fade(const RamadanModeScreen()),
      ),
      GoRoute(
        path: '/academy/qa',
        pageBuilder: (context, state) => _fade(const QaBankScreen()),
      ),
      GoRoute(
        path: '/academy/dua',
        pageBuilder: (context, state) => _fade(const DuaSchoolScreen()),
      ),
      // Founder console and theme demo: debug builds, or a release built
      // with --dart-define=FOUNDER_TOOLS=true. Never open to every visitor.
      if (kFounderTools)
        GoRoute(
          path: '/founder',
          pageBuilder: (context, state) => _fade(const FounderConsoleScreen()),
        ),
      GoRoute(
        path: '/academy/audio-packs',
        pageBuilder: (context, state) => _fade(const AudioPacksScreen()),
      ),
      GoRoute(
        path: '/academy/dhikr',
        pageBuilder: (context, state) => _fade(const DhikrSessionScreen(), pill: false),
      ),
      GoRoute(
        path: '/academy/review',
        pageBuilder: (context, state) => _fade(const ReviewSessionScreen(), pill: false),
      ),
      GoRoute(
        path: '/academy/letters',
        pageBuilder: (context, state) => _fade(const LettersLessonsScreen()),
        routes: [
          GoRoute(
            path: 'lesson/:id',
            pageBuilder: (context, state) => _fade(
              // Keyed by lesson: "Next lesson" lands on the same route
              // pattern, and without a key the old screen state would be
              // reused (wrong lesson, old step).
              LessonRunnerScreen(
                key: ValueKey<String>('letters-${state.pathParameters['id']!}'),
                lessonId: state.pathParameters['id']!,
              ),
              pill: false,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/academy/family',
        pageBuilder: (context, state) =>
            _fade(const FamilyScreen(), pill: false),
      ),
      GoRoute(
        path: '/academy/exam/:id',
        pageBuilder: (context, state) =>
            _fade(ExamScreen(examId: state.pathParameters['id']!), pill: false),
      ),
      GoRoute(
        path: '/academy/recitation',
        pageBuilder: (context, state) => _fade(const TajweedCardsScreen()),
      ),
      GoRoute(
        path: '/academy/quranic-arabic',
        pageBuilder: (context, state) => _fade(const WordDeckScreen()),
      ),
      GoRoute(
        path: '/academy/understanding',
        pageBuilder: (context, state) => _fade(const UnderstandingSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/course/:course',
        pageBuilder: (context, state) => _fade(CourseOverviewScreen(
          key: ValueKey<String>('course-${state.pathParameters['course']!}'),
          courseId: state.pathParameters['course']!,
        )),
      ),
      GoRoute(
        path: '/academy/lesson/:course/:unit/:lesson',
        pageBuilder: (context, state) {
          final p = state.pathParameters;
          return _fade(LessonPlayerScreen(
            key: ValueKey<String>('lesson-${p['lesson']!}'),
            courseId: p['course']!,
            unitId: p['unit']!,
            lessonId: p['lesson']!,
          ), pill: false);
        },
      ),
      if (kFounderTools)
        GoRoute(
          path: AppRoutes.themeDemo,
          pageBuilder: (c, s) => _fade(const ThemeDemoScreen()),
        ),

      // Bottom-nav shell: Home · Faith · Family · Hādi · You
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return Scaffold(
            body: shell,
            bottomNavigationBar: AppBottomNav(shell: shell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (c, s) => _fade(const HomeScreen(), pill: false),
              ),
              GoRoute(
                path: AppRoutes.noor,
                pageBuilder: (c, s) => _fade(const NoorScreen(), pill: false),
              ),
              GoRoute(
                path: AppRoutes.journey,
                pageBuilder: (c, s) => _fade(const JourneyScreen(), pill: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                pageBuilder: (c, s) => _fade(const ExploreScreen(), pill: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // First route = what the Family tab opens: the Family Wing.
              GoRoute(
                path: AppRoutes.family,
                pageBuilder: (c, s) => _fade(const FamilyScreen(), pill: false),
              ),
              GoRoute(
                path: AppRoutes.community,
                pageBuilder: (c, s) => _fade(const CommunityScreen(), pill: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hadi,
                pageBuilder: (c, s) => _fade(const HadiScreen(), pill: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (c, s) => _fade(const ProfileScreen(), pill: false),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
