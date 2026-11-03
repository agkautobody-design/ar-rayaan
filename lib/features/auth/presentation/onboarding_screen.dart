import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/widgets/gold_button.dart';
import '../../app/theme/widgets/tr_text.dart';

/// First-time user onboarding: 4 screens introducing the app's mission.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.mosque,
      title: 'Welcome to Ar-Rayaan',
      body: 'Your companion for the journey. Track prayers, read Quran, learn with Academy, and grow with your family — all in one place.',
    ),
    _OnboardingPage(
      icon: Icons.access_time_filled,
      title: 'Never Miss a Prayer',
      body: 'Accurate prayer times for your location. Qibla direction. Adhan reminders. Start and end your day with salah.',
    ),
    _OnboardingPage(
      icon: Icons.menu_book,
      title: 'Learn & Grow',
      body: 'Academy has structured courses for every level: Quran, Arabic, Aqeedah, Seerah, Fiqh, and more. Learn at your own pace.',
    ),
    _OnboardingPage(
      icon: Icons.family_restroom,
      title: 'Grow Together',
      body: 'Add your family. Monitor your children\'s progress. Speak to Wasia about their learning. Invite teachers for live reviews.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _skip,
                child: const TrText('Skip', style: TextStyle(color: Colors.white54)),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _PageContent(page: _pages[i]),
              ),
            ),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GoldButton(
                onPressed: _next,
                label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 96, color: AppColors.gold.withValues(alpha: 0.8)),
          const SizedBox(height: 40),
          TrText(
            page.title,
            style: AppText.heading2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TrText(
            page.body,
            style: AppText.body.copyWith(color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
