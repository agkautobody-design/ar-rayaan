/// Letters school — the 28-letter grid and the letter lesson sheet.
/// Locked visual rhythm: centered gold icon (the letter), Playfair
/// title, muted line beneath. Mastery ring appears after all four
/// forms are traced + audio heard (engine lands with the tracing
/// canvas; the grid and lesson ship now).
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/letter_audio_provider.dart';
import '../domain/letters_data.dart';

class LettersSchoolScreen extends StatelessWidget {
  const LettersSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: kHijaiLetters.length,
            itemBuilder: (context, i) {
              final LetterEntry l = kHijaiLetters[i];
              return GlassCard(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _LetterSheet(letter: l),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      l.isolated,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 30,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l.name, style: AppText.caption,
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LetterSheet extends StatelessWidget {
  const _LetterSheet({required this.letter});

  final LetterEntry letter;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: const Color(0xFF0B1426), // deep navy sheet surface
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.gold)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListView(
          controller: controller,
          children: <Widget>[
            Center(
              child: Text(
                letter.isolated,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 96,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(letter.name,
                style: AppText.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Where it comes from',
                      style: AppText.caption.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text(letter.makhraj, style: AppText.body),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _LetterAudio.playExample(letter),
              icon: const Icon(Icons.volume_up_outlined, size: 20),
              label: const Text('Hear it in the Qur’an'),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('In the Qur’an',
                      style: AppText.caption.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      letter.example,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 28,
                        color: AppColors.sand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LetterAudio {
  _LetterAudio._();
  static Future<void> playExample(LetterEntry letter) =>
      LetterAudioProvider.instance.play(letter);
}
