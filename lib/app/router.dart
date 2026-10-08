import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/reset_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/verify_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/academy/presentation/academy_home_screen.dart';
import '../features/academy/presentation/lesson_player_screen.dart';
import '../features/academy/presentation/my_additions_screen.dart';
import '../features/academy/presentation/request_nasheed_screen.dart';
import '../features/academy/presentation/letters_school_screen.dart';
import '../features/academy/presentation/school_placeholder_screen.dart';
import '../features/academy/presentation/tajweed_cards_screen.dart';
import '../features/academy/presentation/hifz_planner_screen.dart';
import '../features/academy/presentation/dua_school_screen.dart';
import '../features/academy/presentation/audio_packs_screen.dart';
import '../features/academy/presentation/dhikr_session_screen.dart';
import '../features/doctor/presentation/founder_console_screen.dart';
import '../features/academy/presentation/madinah_reader_view.dart';
import '../features/academy/presentation/review_session_screen.dart';
import '../features/dev_tools/presentation/theme_demo_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/hadi/presentation/hadi_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journey/presentation/journey_screen.dart';
import '../features/menu/presentation/menu_screen.dart';
import '../features/noor/presentation/noor_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/onboarding/presentation/welcome_reflection_screen.dart';
import '../features/prayer/presentation/prayer_times_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/adhkar/presentation/adhkar_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/hadith/presentation/hadith_screen.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../features/sakina/presentation/sakina_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/share/presentation/share_screen.dart';
import '../features/sources/presentation/sources_screen.dart';
import '../features/stories/presentation/stories_screen.dart';
import '../features/family/presentation/family_tree_screen.dart';
import '../features/huda/presentation/huda_screens.dart';
import '../features/games/presentation/games_screens.dart';
import '../features/stories/presentation/story_reader_screen.dart';
import '../features/stories/domain/story.dart';
import '../features/zakat/presentation/zakat_screen.dart';
import '../features/quran/presentation/quran_screen.dart';
import '../features/quran/presentation/surah_reader_screen.dart';
import 'theme/widgets/app_bottom_nav.dart';

/// Application routes (GoRouter) — Master Build Sheet §5.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String hadi = '/hadi';
  static const String noor = '/noor';
  static const String journey = '/journey';
  static const String community = '/community';
  static const String academy = '/academy';
  static const String myAdditions = '/player/my-additions';
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
  static const String games = '/games';
  static const String trivia = '/games/trivia';
  static const String names99 = '/games/names99';
  static const String huda = '/huda';
  static const String hudaGuide = '/huda/guide';
  static const String familyTree = '/family-tree';
  static const String stories = '/stories';
  static const String storyReader = '/stories/read';
  static const String adhkar = '/adhkar';
  static const String qibla = '/qibla';
  static const String calendar = '/calendar';
  static const String zakat = '/zakat';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String sources = '/sources';
  static const String sakina = '/sakina';
  static String surah(int number) => '/quran/$number';

  static const String themeDemo = '/dev/theme';
}

CustomTransitionPage<void> _fade(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Onboarding flow (no bottom nav)
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
          pageBuilder: (context, state) =>
              _fade(GuideScreen(guide: state.extra as Guide)),
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
          pageBuilder: (context, state) => _fade(StoryReaderScreen(story: state.extra as Story)),
        ),
        GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (c, s) => _fade(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (c, s) => _fade(const WelcomeReflectionScreen()),
      ),

      // Auth flow (no bottom nav)
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fade(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (c, s) => _fade(const SignUpScreen()),
      ),
      GoRoute(
        path: AppRoutes.reset,
        pageBuilder: (c, s) => _fade(const ResetScreen()),
      ),
      GoRoute(
        path: AppRoutes.verify,
        pageBuilder: (c, s) => _fade(const VerifyScreen()),
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
        path: AppRoutes.sakina,
        pageBuilder: (c, s) => _fade(const SakinaScreen()),
      ),
      GoRoute(
        path: '/quran/:surah',
        pageBuilder: (c, s) {
          final int number = int.tryParse(s.pathParameters['surah'] ?? '') ?? 1;
          return _fade(SurahReaderScreen(number: number.clamp(1, 114)));
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
          return _fade(MadinahReaderView(
            surah: int.parse(p['surah']!),
            ayahCount: int.parse(p['count']!),
          ));
        },
      ),
      GoRoute(
        path: '/academy/hifz',
        pageBuilder: (context, state) => _fade(const HifzPlannerScreen()),
      ),
      GoRoute(
        path: '/academy/dua',
        pageBuilder: (context, state) => _fade(const DuaSchoolScreen()),
      ),
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
        pageBuilder: (context, state) => _fade(const DhikrSessionScreen()),
      ),
      GoRoute(
        path: '/academy/review',
        pageBuilder: (context, state) => _fade(const ReviewSessionScreen()),
      ),
      GoRoute(
        path: '/academy/letters',
        pageBuilder: (context, state) => _fade(const LettersSchoolScreen()),
      ),
      GoRoute(
        path: '/academy/recitation',
        pageBuilder: (context, state) => _fade(const TajweedCardsScreen()),
      ),
      GoRoute(
        path: '/academy/quranic-arabic',
        pageBuilder: (context, state) => _fade(const SchoolPlaceholderScreen(schoolKey: 'school.arabic.title')),
      ),
      GoRoute(
        path: '/academy/understanding',
        pageBuilder: (context, state) => _fade(const SchoolPlaceholderScreen(schoolKey: 'school.understanding.title')),
      ),
      GoRoute(
        path: '/academy/lesson/:course/:unit/:lesson',
        pageBuilder: (context, state) {
          final p = state.pathParameters;
          return _fade(LessonPlayerScreen(
            courseId: p['course']!,
            unitId: p['unit']!,
            lessonId: p['lesson']!,
          ));
        },
      ),
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
                pageBuilder: (c, s) => _fade(const HomeScreen()),
              ),
              GoRoute(
                path: AppRoutes.noor,
                pageBuilder: (c, s) => _fade(const NoorScreen()),
              ),
              GoRoute(
                path: AppRoutes.journey,
                pageBuilder: (c, s) => _fade(const JourneyScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                pageBuilder: (c, s) => _fade(const ExploreScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                pageBuilder: (c, s) => _fade(const CommunityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hadi,
                pageBuilder: (c, s) => _fade(const HadiScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (c, s) => _fade(const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
