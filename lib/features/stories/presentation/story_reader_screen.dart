import '../../../app/core/scholar_review.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../hadi/application/hadi_controller.dart';
import '../../kids/domain/child_duas.dart';
import '../../kids/domain/child_stories.dart';
import '../../share/application/share_service.dart';
import '../../share/domain/handout.dart';
import '../../share/presentation/handout_screen.dart';
import '../../share/presentation/share_actions.dart';
import '../application/saved_stories_controller.dart';
import '../application/story_text_size.dart';
import '../data/stories_repository.dart';
import '../domain/story.dart';
import 'source_label_chip.dart';
import 'story_layers_section.dart';
import 'story_listen_bar.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// True when a chapter's Arabic is only the opening of the text (the pack
/// marks the cut with "..." or an ellipsis).
bool arabicIsElided(String arabic) =>
    arabic.contains('...') || arabic.contains('\u2026');

/// The Qur'an reference named in a story's sources ("Qur'an 2:255" gives
/// (2, 255); "Qur'an 112-114" gives (112, null)), or null when there is none.
(int, int?)? quranRefFromSources(List<String> sources) {
  final RegExp rx = RegExp(r'Qur.an\s+(\d{1,3})(?::(\d{1,3}))?');
  for (final String s in sources) {
    final RegExpMatch? m = rx.firstMatch(s);
    if (m == null) continue;
    final int surah = int.parse(m.group(1)!);
    if (surah < 1 || surah > 114) continue;
    final String? ayah = m.group(2);
    return (surah, ayah == null ? null : int.parse(ayah));
  }
  return null;
}

/// The /stories/read route. The story id travels in `?id=` so Back, a browser
/// refresh or a pasted link still opens the story; `extra` is only a fast
/// path. (Without the id, a history entry restored by the browser had no
/// story and fell into the error screen.)
class StoryRouteScreen extends ConsumerWidget {
  const StoryRouteScreen({super.key, this.storyId, this.story});

  final String? storyId;
  final Story? story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Story? given = story;
    if (given != null) return StoryReaderScreen(story: given);
    final AsyncValue<List<Story>> all = ref.watch(storiesProvider);
    return all.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (Object e, StackTrace _) => _missing(context),
      data: (List<Story> list) {
        for (final Story s in list) {
          if (s.id == storyId) return StoryReaderScreen(story: s);
        }
        return _missing(context);
      },
    );
  }

  Widget _missing(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            const ScreenHeader(title: 'Stories', close: true),
            Text('That story could not be found.', style: AppText.bodyMuted),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.stories),
              child: const Text('Back to all stories'),
            ),
          ],
        ),
      );
}

class StoryReaderScreen extends ConsumerStatefulWidget {
  final Story story;
  const StoryReaderScreen({super.key, required this.story});

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  int _chapter = 0;

  Story get story => widget.story;

  @override
  Widget build(BuildContext context) {
    final current = story.chapters[_chapter];
    final last = story.chapters.length - 1;
    final bool big = ref.watch(storyBigTextProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ScreenHeader(title: story.kicker, close: true),
          ScholarReviewNote(
            reviewKey: storyReviewKey(story.collection, story.id),
            padding: const EdgeInsets.only(bottom: 8),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShareButton(
                doc: storyChapterShareDoc(story, current),
                subject: 'this chapter',
              ),
              MakeHandoutButton(makeData: () => storyHandout(story)),
              _SaveStoryButton(
                storyId: story.id,
                isDua: story.collection == 'dailyduas',
              ),
            ],
          ),
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
                        child: FocusableTap(
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
          StoryListenBar(
            text: current.heading.isEmpty
                ? _bodyFor(story, current)
                : '${current.heading}. ${_bodyFor(story, current)}',
          ),
          if (current.heading.isNotEmpty) ...[
            Text(
              current.heading,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: storyHeadingSize(big: big),
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
            if (current.tl != null) ...[
              Text(
                current.tl!,
                key: const Key('story-chapter-tl'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: AppColors.goldLight,
                ),
              ),
              if (current.tlSource != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 14),
                  child: Text(
                    transliterationCreditLine(current.tlSource!),
                    key: const Key('story-chapter-tl-source'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.sand.withValues(alpha: 0.55),
                    ),
                  ),
                ),
            ],
            if (arabicIsElided(current.arabic!))
              _ElidedArabicNote(sources: story.sources),
          ],
          if (story.collection == 'dailyduas') ...<Widget>[
            Text('WHAT IT MEANS', style: AppText.eyebrow),
            const SizedBox(height: 6),
          ],
          Text(
            // A child is given the child's meaning of a dua, not the long
            // paragraph written for adults (its sources are still below).
            _bodyFor(story, current),
            style: TextStyle(
              fontSize: storyBodySize(big: big),
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
                Text(
                  story.collection == 'dailyduas'
                      ? 'SAY IT TOGETHER'
                      : 'SIT TOGETHER',
                  style: AppText.eyebrow,
                ),
                const SizedBox(height: 8),
                Text(
                  story.collection == 'dailyduas'
                      ? 'Say the dua together, a few words at a time. Then talk about when we say it.'
                      : story.familyQuestion,
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
          // No free-text box on a dua (it is not a story to ask about), and none
          // in child mode (a child has no open question box).
          if (story.collection != 'dailyduas' && !kChildMode.value) ...<Widget>[
            const SizedBox(height: 12),
            _AskHadiAboutStory(story: story, chapter: current),
          ],
        ],
      ),
    );
  }
}

/// The words of the chapter on screen: a child (child mode) is given the
/// child's meaning of a dua instead of the paragraph written for adults.
String _bodyFor(Story story, StoryChapter chapter) {
  if (kChildMode.value) {
    final String? mine = story.collection == 'dailyduas'
        ? childMeaningFor(story.id)
        : childStoryChapter(story.id, story.chapters.indexOf(chapter));
    if (mine != null) return mine;
  }
  return chapter.body;
}

/// The chapter on screen as plain text: title, Arabic, text, then the
/// story's source lines and its honesty label, then the app credit.
String storyChapterShareText(Story story, StoryChapter chapter) =>
    ShareService.build(storyChapterShareDoc(story, chapter));

/// The share for the chapter on screen: text only, never an image. A story or
/// khutbah that is not "Established" says so, and carries "Scholar review
/// needed" until a named scholar is recorded.
ShareDoc storyChapterShareDoc(Story story, StoryChapter chapter) {
  final String label = chapter.label ?? story.sourceLabel;
  final String sources = story.sources.join('; ');
  return ShareDoc.story(
    title: chapter.heading.isEmpty
        ? story.title
        : '${story.title}: ${chapter.heading}',
    arabic: chapter.arabic,
    body: chapter.body,
    source: label == kLabelEstablished
        ? sources
        : '$sources (${storyLabelDisplay(label)})',
    reviewKey: storyReviewKey(story.collection, story.id),
  );
}

/// A printable handout of the whole story: its chapters, sources and the
/// family question that already ends the story.
HandoutData storyHandout(Story story) => HandoutData(
      title: story.title,
      reviewKey: storyReviewKey(story.collection, story.id),
      subtitle: story.subtitle,
      notice: story.sourceLabel == kLabelEstablished
          ? null
          : '${storyLabelDisplay(story.sourceLabel)}. '
              '${storyLabelMeaning(story.sourceLabel)}',
      sections: <HandoutSection>[
        for (final StoryChapter c in story.chapters)
          HandoutSection(heading: c.heading, arabic: c.arabic, body: c.body),
      ],
      sources: story.sources,
      questions: <String>[
        if (story.familyQuestion.trim().isNotEmpty) story.familyQuestion,
      ],
    );

/// Save / unsave this story or dua. Saved items are listed under Bookmarks
/// in the You tab (and Hadi saves into the same list on request).
class _SaveStoryButton extends ConsumerWidget {
  const _SaveStoryButton({required this.storyId, this.isDua = false});

  final String storyId;
  final bool isDua;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool saved = ref.watch(savedStoriesProvider).contains(storyId);
    final String tip = saved
        ? 'Saved to Bookmarks. Tap to remove.'
        : (isDua
            ? 'Save this dua to Bookmarks'
            : 'Save this story to Bookmarks');
    return Tooltip(
      message: tip,
      child: TextButton.icon(
        onPressed: () {
          unawaited(ref.read(savedStoriesProvider.notifier).toggle(storyId));
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(saved
                  ? 'Removed from Bookmarks.'
                  : 'Saved. Find it in the You tab, under Bookmarks.'),
              duration: const Duration(seconds: 2),
            ));
        },
        icon: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          size: 18,
          color: AppColors.gold,
        ),
        label: Text(saved ? 'Saved' : 'Save', style: AppText.bodyMuted),
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
              child: Semantics(label: 'What does this story teach about patience?', child: TextField(
                controller: _input,
                style: AppText.body.copyWith(fontSize: 13),
                decoration: const InputDecoration(
                    hintText: 'What does this story teach about patience?'),
              )),
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

/// Under an Arabic text that the pack gives only in part: say so, and where
/// the whole Qur'an text is already in the app, link to it.
class _ElidedArabicNote extends StatelessWidget {
  const _ElidedArabicNote({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final (int, int?)? ref = quranRefFromSources(sources);
    final int? ayah = ref?.$2;
    return Padding(
      key: const Key('arabic-elided-note'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref == null
                ? 'This shows the opening words only. The full Arabic is not in the app yet.'
                : 'This shows the opening words only.',
            style: AppText.bodyMuted.copyWith(fontSize: 12),
          ),
          if (ref != null)
            TextButton(
              onPressed: () => context.push(
                ayah == null
                    ? AppRoutes.surah(ref.$1)
                    : AppRoutes.surahAt(ref.$1, ayah),
              ),
              child: const Text('Read it in full in the Qur\u2019an'),
            ),
        ],
      ),
    );
  }
}
