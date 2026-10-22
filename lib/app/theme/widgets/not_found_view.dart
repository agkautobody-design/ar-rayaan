import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import 'screen_header.dart';

/// A page that is not there (an unknown link, a bad id in a link): the
/// header with its back button, a plain sentence and a way out. Never a bare
/// line of text on an empty screen.
///
/// Content only (no Scaffold), so it works inside an existing Scaffold body
/// as well as under [NotFoundScreen].
class NotFoundView extends StatelessWidget {
  const NotFoundView({
    this.message = 'This page is not here.',
    this.title = 'Not found',
    super.key,
  });

  final String message;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScreenHeader(title: title, showSettings: false),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.explore_off_outlined,
                    size: 40,
                    color: AppColors.gold.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Go home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [NotFoundView] as a whole screen (the router's not-found page).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    this.message = 'This page is not here.',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: NotFoundView(message: message)),
    );
  }
}
