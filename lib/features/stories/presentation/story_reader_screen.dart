import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/story.dart';

class StoryReaderScreen extends StatefulWidget {
  final Story story;
  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _chapter = 0;

  Story get story => widget.story;

  @override
  Widget build(BuildContext context) {
    final current = story.chapters[_chapter];
    final last = story.chapters.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ScreenHeader(title: story.kicker, close: true),
          const SizedBox(height: 8),
          Text(
            story.title,
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(story.subtitle, style: AppTypography.bodyMuted),
          const SizedBox(height: 20),
          if (story.chapters.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (var i = 0; i < story.chapters.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () => setState(() => _chapter = i),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: i == _chapter
                                  ? AppColors.gold
                                  : AppColors.sand.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (current.heading.isNotEmpty) ...[
            Text(
              current.heading,
              style: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.sand,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            current.body,
            style: const TextStyle(
              fontSize: 16.5,
              height: 1.75,
              color: AppColors.sand,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_chapter > 0)
                TextButton.icon(
                  onPressed: () => setState(() => _chapter--),
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 14, color: AppColors.gold),
                  label: Text('Previous', style: AppTypography.bodyMuted),
                )
              else
                const SizedBox.shrink(),
              if (_chapter < last)
                TextButton.icon(
                  onPressed: () => setState(() => _chapter++),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.gold),
                  label: Text('Next', style: AppTypography.bodyMuted),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOURCES', style: AppTypography.eyebrow),
                const SizedBox(height: 8),
                for (final s in story.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 4, color: AppColors.gold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: AppTypography.bodyMuted.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIT TOGETHER', style: AppTypography.eyebrow),
                const SizedBox(height: 8),
                Text(
                  story.familyQuestion,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: AppColors.sand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
