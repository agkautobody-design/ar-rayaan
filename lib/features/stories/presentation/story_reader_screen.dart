import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../hadi/application/hadi_controller.dart';
import '../domain/story.dart';
import 'source_label_chip.dart';
import 'story_layers_section.dart';

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
              fontFamily: 'PlayfairDisplay',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(story.subtitle, style: AppText.bodyMuted),
          const SizedBox(height: 14),
          if (story.sourceLabel != kLabelEstablished)
            SourceLabelNote(label: story.sourceLabel),
          if (story.hasUnverified && !isUnverifiedLabel(story.sourceLabel))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Some chapters of this story are UNVERIFIED. They are marked '
                'where they appear.',
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          if (story.hasWeakNarration)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'This story cites a WEAK (daif) narration, named in its '
                'sources below. Do not rely on it for a ruling.',
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          const SizedBox(height: 6),
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
          if (current.label != null && current.label != story.sourceLabel)
            SourceLabelNote(label: current.label!, prefix: 'This chapter:'),
          if (current.heading.isNotEmpty) ...[
            Text(
              current.heading,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.sand,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (current.arabic != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                current.arabic!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  height: 1.9,
                  color: Color(0xFFEAD9A8),
                ),
              ),
            ),
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
                  label: Text('Previous', style: AppText.bodyMuted),
                )
              else
                const SizedBox.shrink(),
              if (_chapter < last)
                TextButton.icon(
                  onPressed: () => setState(() => _chapter++),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.gold),
                  label: Text('Next', style: AppText.bodyMuted),
                ),
            ],
          ),
          const SizedBox(height: 20),
          StoryLayersSection(storyId: story.id),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOURCES', style: AppText.eyebrow),
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
                            style: AppText.bodyMuted.copyWith(height: 1.5),
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
                Text('SIT TOGETHER', style: AppText.eyebrow),
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
          const SizedBox(height: 12),
          _AskHadiAboutStory(story: story, chapter: current),
        ],
      ),
    );
  }
}

/// Conversation mode: Hadi reads along. Ask about THIS story and he answers
/// from the text in front of you, with read-aloud for the answer.
class _AskHadiAboutStory extends ConsumerStatefulWidget {
  final Story story;
  final StoryChapter chapter;
  const _AskHadiAboutStory({required this.story, required this.chapter});

  @override
  ConsumerState<_AskHadiAboutStory> createState() => _AskHadiAboutStoryState();
}

class _AskHadiAboutStoryState extends ConsumerState<_AskHadiAboutStory> {
  final _input = TextEditingController();
  String? _answer;

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(hadiControllerProvider).typing;
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASK HADI ABOUT THIS STORY', style: AppText.eyebrow),
          const SizedBox(height: 4),
          Text(
            'Ask about a character, a word, a meaning, "why did he…?" — Hadi answers from this story.',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: AppText.body.copyWith(fontSize: 13),
                decoration: const InputDecoration(
                    hintText: 'What does this story teach about patience?'),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.gold,
              radius: 20,
              child: IconButton(tooltip: 'Send question',
                icon: busy
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Color(0xFF0A0F18)))
                    : const Icon(Icons.send, size: 16, color: Color(0xFF0A0F18)),
                onPressed: busy
                    ? null
                    : () async {
                        final q = _input.text.trim();
                        if (q.isEmpty) return;
                        final title = widget.story.title;
                        final heading = widget.chapter.heading;
                        final ctx =
                            "The user is reading '$title' (${widget.story.kicker}). "
                            "Current chapter '$heading': ${widget.chapter.body} "
                            'Sources: ${widget.story.sources.join('; ')}. '
                            'Answer their question about THIS story briefly, '
                            'warmly, and stay faithful to the text above. If '
                            'beyond the story, say what the sources establish '
                            'and recommend a scholar. Question: $q';
                        final a = await ref
                            .read(hadiControllerProvider.notifier)
                            .ask(ctx);
                        setState(() => _answer = a);
                      },
              ),
            ),
          ]),
          if (_answer != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text(_answer!,
                        style: AppText.body.copyWith(height: 1.6, fontSize: 13))),
                SpeakButton(text: _answer!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
