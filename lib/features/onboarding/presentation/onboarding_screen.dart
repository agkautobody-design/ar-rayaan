import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const pref = 'ar.onboarded.v1';

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(pref) != true;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  static const _slides = [
    (Icons.mosque_outlined, 'AS-SALAAMU ALAIKUM', 'This is Ar-Rayaan',
        'One app for your whole deen: prayer times and the Quran, stories of the Prophets, a school for your children, games, and a companion who answers your questions.'),
    (Icons.auto_awesome, 'MEET HADI', 'Ask him anything',
        'Tap the Ask Hadi pill on any screen and ask in plain words. He answers from the Quran and the Sunnah, and shows you where it lives in the app.'),
    (Icons.wb_twilight, 'YOUR FIRST HOUR', 'Three things, gently',
        'Check your prayer times. Read one story. Then open the Academy and let Wasia teach your family. That is the whole app.'),
  ];

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(OnboardingScreen.pref, true);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _finish,
              child: Text('Skip', style: AppText.bodyMuted),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              onPageChanged: (i) => setState(() => _i = i),
              itemCount: _slides.length,
              itemBuilder: (c, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92, height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Icon(s.$1, size: 40, color: AppColors.goldLight),
                      ),
                      const SizedBox(height: 26),
                      Text(s.$2, style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(s.$3, textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 30, color: AppColors.goldLight)),
                      const SizedBox(height: 14),
                      Text(s.$4, textAlign: TextAlign.center,
                          style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.7)),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var d = 0; d < _slides.length; d++)
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
                  if (_i < _slides.length - 1) {
                    _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  } else {
                    _finish();
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0A0F18),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_i < _slides.length - 1 ? 'Next' : 'Begin'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
