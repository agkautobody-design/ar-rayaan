/// Routes for the Terms, Privacy and Delete-account screens.
///
/// Register in `lib/app/router.dart` (owned by the platform agent) by adding
/// this import and spreading the list into the top-level `routes:`:
///
/// ```dart
/// import '../features/legal/legal_routes.dart';
/// ...
///   routes: [
///     ...legalRoutes,
///     // existing routes
///   ],
/// ```
///
/// Link "Delete account" from the profile or menu screen with
/// `context.push(LegalRoutes.deleteAccount)`. The sign-up screen already
/// links Terms and Privacy through [LegalRoutes].
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/legal_screens.dart';

abstract final class LegalRoutes {
  static const String terms = '/legal/terms';
  static const String privacy = '/legal/privacy';
  static const String deleteAccount = '/legal/delete-account';
}

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondary, c) =>
        FadeTransition(opacity: animation, child: c),
  );
}

final List<RouteBase> legalRoutes = <RouteBase>[
  GoRoute(
    path: LegalRoutes.terms,
    pageBuilder: (context, state) => _page(state, const TermsScreen()),
  ),
  GoRoute(
    path: LegalRoutes.privacy,
    pageBuilder: (context, state) => _page(state, const PrivacyScreen()),
  ),
  GoRoute(
    path: LegalRoutes.deleteAccount,
    pageBuilder: (context, state) =>
        _page(state, const DeleteAccountScreen()),
  ),
];
