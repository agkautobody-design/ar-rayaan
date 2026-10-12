import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';

class WelcomeReflectionScreen extends StatelessWidget {
  const WelcomeReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            children: [
              Text('A THRESHOLD', style: AppText.eyebrow),
              const SizedBox(height: 10),
              Text('Before you enter, one breath.', style: AppText.titleMedium),
              const SizedBox(height: 14),
              GlassCard(
                child: Text(
                  '\u201cO Allah, show us the truth as truth and grant us the ability to follow it, and show us falsehood as falsehood and grant us the ability to avoid it.\u201d',
                  style: AppText.body.copyWith(height: 1.7),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0A0F18),
                  ),
                  child: const Text('Enter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
