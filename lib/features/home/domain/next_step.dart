/// Home's single "Your next step" card, chosen from the goal the person
/// picked at the start (`ar.need`) and progress the app already keeps.
///
/// Pure Dart: every input is passed in, so the rules are unit-testable. No
/// religious text is made here; the card only names and opens existing
/// rooms of the app.
class NextStep {
  const NextStep({
    required this.headline,
    required this.detail,
    required this.route,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  /// One short line, e.g. "Pray Asr at 3:42 PM".
  final String headline;

  /// A calm second line.
  final String detail;

  /// Where tapping the card goes.
  final String route;

  /// Optional second door (for example Adhkar next to the prayer card).
  final String? secondaryLabel;
  final String? secondaryRoute;
}

/// Total lessons on the New Muslim path (the thirty lessons of the path).
const int kNewMuslimPathDays = 30;

/// Routes the card can open. Kept here (not imported from the router) so
/// this file stays pure Dart; `next_step_test.dart` checks they exist.
class NextStepRoutes {
  const NextStepRoutes._();
  static const String prayer = '/prayer';
  static const String adhkar = '/adhkar';
  static const String quran = '/quran';
  static const String stories = '/stories';
  static const String academyGate = '/academy/gate';
  static const String family = '/academy/family';
  static const String sakina = '/sakina';
  static const String newMuslimPath = '/new-muslim';
  static const String community = '/community';
}

/// Picks the card. [need] is the stored `ar.need` (null when the person
/// skipped the choice). [nextPrayer] is a ready label such as
/// "Asr at 3:42 PM", or null while no location is set. [adhkarLeft] is the
/// repetitions left in today's first adhkar set, null when unknown.
/// [quranResume] is a label such as "Al-Baqarah 2:5", null when nothing has
/// been read yet. [newMuslimDone] counts finished path lessons.
NextStep resolveNextStep({
  required String? need,
  required bool academyOn,
  String? nextPrayer,
  int? adhkarLeft,
  String? quranResume,
  int newMuslimDone = 0,
  int lessonsDone = 0,
}) {
  switch (need) {
    case 'pray':
      final String adhkarLine = adhkarLeft == null
          ? 'Then your adhkar.'
          : adhkarLeft <= 0
          ? 'Your adhkar for today are done.'
          : 'Then your adhkar: $adhkarLeft left today.';
      return NextStep(
        headline: nextPrayer == null
            ? 'Choose your place for prayer times'
            : 'Pray $nextPrayer',
        detail: nextPrayer == null
            ? 'Times are worked out on your device, from where you are.'
            : adhkarLine,
        route: NextStepRoutes.prayer,
        secondaryLabel: 'Adhkar',
        secondaryRoute: NextStepRoutes.adhkar,
      );
    case 'learn':
      if (academyOn) {
        return NextStep(
          headline: lessonsDone == 0
              ? 'Start your first lesson'
              : 'Continue your next lesson',
          detail: lessonsDone == 0
              ? 'Short steps in the Academy, at your own pace.'
              : '$lessonsDone lesson${lessonsDone == 1 ? '' : 's'} done so far.',
          route: NextStepRoutes.academyGate,
        );
      }
      return const NextStep(
        headline: 'Read a story',
        detail: 'Stories, khutbahs and duas in the Knowledge library.',
        route: NextStepRoutes.stories,
      );
    case 'new':
      if (newMuslimDone >= kNewMuslimPathDays) {
        return const NextStep(
          headline: 'Walk the 30-day road again',
          detail: 'You finished it. Every step is still open to you.',
          route: NextStepRoutes.newMuslimPath,
        );
      }
      return NextStep(
        headline: 'Day ${newMuslimDone + 1} of the 30-day road',
        detail: 'One gentle step a day. Everyone is welcome.',
        route: NextStepRoutes.newMuslimPath,
      );
    case 'peace':
      return const NextStep(
        headline: 'Take a quiet moment',
        detail: 'Du’as and comfort for a heavy day.',
        route: NextStepRoutes.sakina,
      );
    case 'children':
      return const NextStep(
        headline: 'Open the Family Wing',
        detail: 'Add a child, then start Wasia’s letters school.',
        route: NextStepRoutes.family,
      );
    case 'community':
      return const NextStep(
        headline: 'Find your masjid and your people',
        detail: 'Community, near you.',
        route: NextStepRoutes.community,
      );
    default:
      return NextStep(
        headline: quranResume == null
            ? 'Begin with Al-Fatihah'
            : 'Continue reading $quranResume',
        detail: 'The Qur’an, with the English beside it.',
        route: NextStepRoutes.quran,
      );
  }
}
