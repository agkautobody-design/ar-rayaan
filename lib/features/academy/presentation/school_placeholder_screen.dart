import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/academy_strings.dart';

/// Placeholder for a school that has a route but no content yet.
/// Honest by design: "Coming soon — insha'Allah", never a paywall,
/// never an empty broken page (Simplicity Charter + no dead ends).
class SchoolPlaceholderScreen extends StatelessWidget {
  const SchoolPlaceholderScreen({super.key, required this.schoolKey});

  /// The school's titleKey in AcademyStrings (e.g. 'school.letters.title').
  final String schoolKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: AcademyStrings.get(schoolKey)),
              const SizedBox(height: 24),
              GlassCard(
                strong: true,
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.gold,
                      size: 36,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AcademyStrings.get('academy.comingSoon'),
                      style: AppText.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AcademyStrings.get('school.soonBody'),
                      style: AppText.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/academy'),
                      child: Text(AcademyStrings.get('common.back')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
