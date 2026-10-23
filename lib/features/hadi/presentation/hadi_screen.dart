import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../../../app/core/subscription/subscription_service.dart';
import '../../../app/core/subscription/billing_gateway.dart';
import '../../../app/core/providers.dart';
import '../application/hadi_controller.dart';
import '../application/hadi_provider.dart';
import '../application/hadi_samples.dart';
import '../data/hadi_report_service.dart';
import '../grounding/corpus.dart';
import '../grounding/madhhab.dart';
import '../grounding/passage.dart';
import 'hadi_markdown.dart';
import 'hadi_widgets.dart';
import '../../sakina/application/sakina_providers.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../../sakina/domain/sakina_content.dart';
import '../../sakina/presentation/widgets/help_line_tile.dart';
import '../../sakina/presentation/widgets/need_help_button.dart';

/// The items under the ⋮ button in the header.
enum _HadiMenu { newConversation, school, advanced }

/// Screen 6 · Ask Hādī — live AI guidance (Groq free tier, user's key) with
/// a curated authentic offline fallback (O-7). Guardrails: Qur'an + Sihah
/// Sitta only, honest declines, no invented rulings.
class HadiScreen extends ConsumerStatefulWidget {
  const HadiScreen({super.key});

  @override
  ConsumerState<HadiScreen> createState() => _HadiScreenState();
}

class _HadiScreenState extends ConsumerState<HadiScreen> {
  bool _allStarters = false;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final String q = (preset ?? _input.text).trim();
    if (q.isEmpty) return;
    // Hādi is still answering: keep what was typed, do not swallow it.
    if (ref.read(hadiControllerProvider).typing) return;
    if (preset == null) _input.clear();
    _scrollToEnd();
    await ref.read(hadiControllerProvider.notifier).ask(q);
    _scrollToEnd();
  }

  /// Suggestion chips go under the last reply, but never after a crisis
  /// exchange and never while Hādi is still answering.
  bool _showNext(HadiState hadi) {
    if (hadi.typing || hadi.messages.isEmpty) return false;
    final HadiMessage last = hadi.messages.last;
    return last.fromHadi && !last.sensitive && last.crisis == null;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmNewConversation() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.night,
        title: Text(
          'New conversation?',
          style: AppText.body.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          'Hādi will forget this conversation on this device and we will '
          'start fresh.',
          style: AppText.bodyMuted,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppText.bodyMuted),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.night,
            ),
            child: const Text('Start fresh'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(hadiControllerProvider.notifier).clearThread();
    }
  }

  Future<void> _openMadhhabSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => Consumer(
        builder: (BuildContext c, WidgetRef r, Widget? _) {
          final Madhhab current = r.watch(hadiControllerProvider).madhhab;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Your school of law', style: AppText.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$kHadiScopeNote With a live key, where the four Sunni '
                    'schools differ, Hādi names your school\u2019s view first '
                    'and says that others differ. On the built-in shelf it '
                    'holds no verified text for a single school, so it tells '
                    'you when an answer is the general view and points you to '
                    'a scholar of your school. Stored on this device only.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final Madhhab m in Madhhab.values)
                        ChoiceChip(
                          label: Text(m.label),
                          selected: current == m,
                          onSelected: (_) => r
                              .read(hadiControllerProvider.notifier)
                              .setMadhhab(m),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openReportSheet(HadiMessage m, String? question) async {
    HadiReportReason reason = HadiReportReason.wrongQuote;
    bool withQuestion = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Report this answer', style: AppText.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'This sends the answer and the passages it showed. Your '
                  'name and account are not included. If a quote looks '
                  'wrong, please also check it with a scholar.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final HadiReportReason r in HadiReportReason.values)
                      ChoiceChip(
                        label: Text(r.label),
                        selected: reason == r,
                        onSelected: (_) => setSheet(() => reason = r),
                      ),
                  ],
                ),
                if (question != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: withQuestion,
                    onChanged: (bool? v) =>
                        setSheet(() => withQuestion = v ?? false),
                    title: Text(
                      'Include my question',
                      style: AppText.caption.copyWith(color: AppColors.sand),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final SharedPreferences prefs =
                        ref.read(sharedPreferencesProvider);
                    final ScaffoldMessengerState messenger =
                        ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    final bool sent = await HadiReportService(prefs).submit(
                      HadiReport(
                        reason: reason,
                        answer: m.text,
                        question: withQuestion ? question : null,
                        sources: m.sources,
                        live: m.live,
                      ),
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(sent
                            ? 'Thank you. The report was sent.'
                            : 'Thank you. It is saved on this device and '
                                'will be sent when the app can reach the '
                                'server.'),
                      ),
                    );
                  },
                  child: const Text('Send report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Advanced: live AI. The key is optional; the built-in shelf needs none.
  /// What is sent, where the key is kept and what is checked are short
  /// sections that open on a tap, so the sheet is not a wall of small print.
  Future<void> _openKeySheet() async {
    final TextEditingController keyInput = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        String providerChoice = ref
            .read(hadiControllerProvider.notifier)
            .providerName;
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setSheet) => SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Your own AI account (optional)',
                      style: AppText.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'You do not need this. Hādi already answers from '
                    'curated knowledge stored on your device, offline, for '
                    'free. If you want open-ended conversation, you can '
                    'paste a key from your own account with an AI company '
                    '(Groq, OpenRouter or xAI). Those companies offer free '
                    'plans; this app does not charge you for it.',
                    style: AppText.bodyMuted.copyWith(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _PrivacyNote(
                    title: 'What is sent with a key',
                    body: 'What you type, the recent conversation, and your '
                        'name if you turned that on in Settings go to the '
                        'provider you choose, together with your key, with '
                        'every question.',
                  ),
                  const _PrivacyNote(
                    title: 'Where your key is kept',
                    body: 'On this device, in plain text. Use a key you can '
                        'revoke.',
                  ),
                  const _PrivacyNote(
                    title: 'What never leaves your device',
                    body: 'Messages about suicide, self-harm, abuse or '
                        'anyone\u2019s safety are answered here on your '
                        'device and are never sent.',
                  ),
                  const _PrivacyNote(
                    title: 'How live answers are checked',
                    body: 'Hādi prints scripture itself from its own '
                        'library and removes references it cannot verify. '
                        'Hādi is for adults and is not a scholar.',
                  ),
                  const SizedBox(height: 8),
                  const _SubscriptionPanel(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Groq'),
                        selected: providerChoice == 'groq',
                        onSelected: (_) =>
                            setSheet(() => providerChoice = 'groq'),
                      ),
                      ChoiceChip(
                        label: const Text('OpenRouter'),
                        selected: providerChoice == 'openrouter',
                        onSelected: (_) =>
                            setSheet(() => providerChoice = 'openrouter'),
                      ),
                      ChoiceChip(
                        label: const Text('xAI (Grok)'),
                        selected: providerChoice == 'xai',
                        onSelected: (_) =>
                            setSheet(() => providerChoice = 'xai'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyInput,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: AppText.body,
                    onChanged: (String v) {
                      if (v.trim().isEmpty) return;
                      final String detected = HadiController.detectProvider(v);
                      if (detected != providerChoice) {
                        setSheet(() => providerChoice = detected);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: providerChoice == 'groq'
                          ? 'gsk_…'
                          : providerChoice == 'openrouter'
                              ? 'sk-or-…'
                              : 'xai-…',
                      hintStyle: AppText.bodyMuted,
                      filled: true,
                      fillColor: AppColors.glassFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            await ref
                                .read(hadiControllerProvider.notifier)
                                .saveApiKey('');
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(
                            'Remove key',
                            style: AppText.caption.copyWith(
                              fontSize: 14,
                              color: AppColors.sand.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final HadiController notifier =
                                ref.read(hadiControllerProvider.notifier);
                            await notifier.saveApiProvider(providerChoice);
                            await notifier.saveApiKey(keyInput.text);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.night,
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HadiState hadi = ref.watch(hadiControllerProvider);

    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _HeaderIcon(
                    icon: Icons.arrow_back,
                    label: 'Back to home',
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 15,
                            color: AppColors.gold.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hadi.live
                                  ? 'Hādi · live AI (guardrailed)'
                                  : 'Hādi · authentic offline knowledge',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMuted.copyWith(
                                color: AppColors.textFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _HeaderIcon(
                    icon: Icons.favorite_outline,
                    label: 'Need help now',
                    onTap: () => showNeedHelpSheet(context),
                  ),
                  PopupMenuButton<_HadiMenu>(
                    tooltip: 'More options',
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.sand.withValues(alpha: 0.85),
                    ),
                    color: AppColors.night,
                    onSelected: (_HadiMenu m) {
                      switch (m) {
                        case _HadiMenu.newConversation:
                          _confirmNewConversation();
                        case _HadiMenu.school:
                          _openMadhhabSheet();
                        case _HadiMenu.advanced:
                          _openKeySheet();
                      }
                    },
                    itemBuilder: (BuildContext _) =>
                        <PopupMenuEntry<_HadiMenu>>[
                      PopupMenuItem<_HadiMenu>(
                        value: _HadiMenu.newConversation,
                        child: Text('New conversation', style: AppText.body),
                      ),
                      PopupMenuItem<_HadiMenu>(
                        value: _HadiMenu.school,
                        child: Text('Your school of law', style: AppText.body),
                      ),
                      PopupMenuItem<_HadiMenu>(
                        value: _HadiMenu.advanced,
                        child: Text(
                          'Your own AI account (optional, advanced)',
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hadi.live
                  ? 'Live answers · Qur\'an & Sihah Sitta guardrails'
                  : 'Free, works offline · your own AI account is optional, '
                      'under ⋮ › Advanced',
              style: AppText.bodyMuted.copyWith(
                fontSize: 12,
                color: AppColors.textFaint,
              ),
              textAlign: TextAlign.center,
            ),
            if (hadi.messages.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text(
                  'A study aid, not a scholar. I will not rule on your own '
                  'situation, and when I do not know, I will say so.',
                  style: AppText.bodyMuted.copyWith(
                    fontSize: 12,
                    color: AppColors.textFaint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (hadi.messages.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Column(
                  children: <Widget>[
                    Text(
                      'Free today: everything in this app, including Hādi. '
                      'Nothing asks for a card. A paid plan for extra live '
                      'answers is planned but not open yet.',
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 12,
                        color: AppColors.textFaint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => context.push(AppRoutes.sources),
                      child: Text(
                        'Where do the answers come from? Our Sources →',
                        style: AppText.bodyMuted.copyWith(
                          color: AppColors.gold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  for (int i = 0; i < hadi.messages.length; i++)
                    _Bubble(
                      message: hadi.messages[i],
                      isLatest: i == hadi.messages.length - 1 && !hadi.typing,
                      onOpen: (String route) => context.go(route),
                      onRetry: hadi.messages[i].retryQuestion != null &&
                              i == hadi.messages.length - 1 &&
                              !hadi.typing
                          ? () => _send(hadi.messages[i].retryQuestion)
                          : null,
                      onReport: hadi.messages[i].fromHadi &&
                              i > 0 &&
                              !hadi.messages[i].sensitive
                          ? () => _openReportSheet(
                                hadi.messages[i],
                                !hadi.messages[i - 1].fromHadi &&
                                        !hadi.messages[i - 1].sensitive
                                    ? hadi.messages[i - 1].text
                                    : null,
                              )
                          : null,
                    ),
                  if (hadi.typing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: <Widget>[
                          IconTile(icon: Icons.auto_awesome, size: 28),
                          SizedBox(width: 8),
                          GlassCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: HadiTypingIndicator(),
                          ),
                        ],
                      ),
                    ),
                  if (hadi.messages.length == 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final HadiExchange e in _allStarters
                            ? kProposedHadiExchanges
                            : kProposedHadiExchanges
                                .take(kHadiOpeningChipCount))
                          _StarterChip(
                            label: e.question,
                            onTap: () => _send(e.question),
                          ),
                        if (!_allStarters)
                          ActionChip(
                            onPressed: () =>
                                setState(() => _allStarters = true),
                            label: const Text('More questions\u2026'),
                            labelStyle: AppText.bodyMuted.copyWith(
                              fontSize: 13,
                              color: AppColors.goldLight,
                            ),
                            backgroundColor: Colors.transparent,
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    )
                  else if (_showNext(hadi))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final String question in hadiSuggestions(
                            <String>[
                              for (final HadiMessage m in hadi.messages)
                                if (!m.fromHadi) m.text,
                            ],
                          ))
                            _StarterChip(
                              label: question,
                              onTap: () => _send(question),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 4,
                  top: 4,
                  bottom: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _input,
                          builder: (BuildContext _, TextEditingValue v,
                              Widget? __) {
                            return TextField(
                              controller: _input,
                              onSubmitted: (String _) => _send(),
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.send,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textDirection: HadiMarkdown.isMostlyRtl(v.text)
                                  ? TextDirection.rtl
                                  : null,
                              style: AppText.body,
                              decoration: InputDecoration(
                                hintText: 'Ask Hādi anything…',
                                hintStyle: AppText.bodyMuted.copyWith(
                                  color: AppColors.textFaint,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      enabled: !hadi.typing,
                      label: 'Send',
                      excludeSemantics: true,
                      onTap: hadi.typing ? null : _send,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: hadi.typing ? null : _send,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Opacity(
                              opacity: hadi.typing ? 0.4 : 1,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.goldGradient,
                                ),
                                child: const Icon(
                                  Icons.send,
                                  size: 18,
                                  color: AppColors.night,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable, copyable help lines under a crisis reply, for the person's
/// own country, with a way into Sakina for every other country.
class _CrisisHelpPanel extends ConsumerWidget {
  const _CrisisHelpPanel({required this.kind});

  final CrisisKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<HelpResource> rows = CrisisResponses.resourcesFor(
      kind,
      ref.watch(deviceCountryProvider),
    ).take(6).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final HelpResource r in rows) ...<Widget>[
            HelpLineTile(resource: r),
            const SizedBox(height: 6),
          ],
          TextButton(
            onPressed: () => context.push(AppRoutes.sakina),
            child: Text(
              'More help lines, every country (Sakina)',
              style: AppText.caption.copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

/// A passage printed from Hādi's own library under a reply: the label, the
/// citation, the Arabic and translation, and for a hadith its grade and who
/// gave it.
class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.passage});

  final Passage passage;

  @override
  Widget build(BuildContext context) {
    final String? grade = passage.gradeLine;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${passage.label} · ${passage.reference}',
            style: AppText.caption.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (passage.arabic != null) ...<Widget>[
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                passage.arabic!,
                style: AppText.body.copyWith(fontSize: 18, height: 1.8),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            passage.english,
            style: AppText.caption.copyWith(
              color: AppColors.sand.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          if (grade != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Grade: $grade',
              style: AppText.caption.copyWith(
                color: AppColors.sand.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
          if (passage.textKind != null) ...<Widget>[
            Text(
              passage.textKind == 'summary'
                  ? 'Summary written for this app, not a translation.'
                  : 'Excerpt written for this app, not a full translation.',
              style: AppText.caption.copyWith(
                color: AppColors.sand.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A suggested question the person can tap instead of typing.
class _StarterChip extends StatelessWidget {
  const _StarterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(
        Icons.chat_bubble_outline,
        size: 14,
        color: AppColors.gold,
      ),
      label: Text(label),
      labelStyle: AppText.bodyMuted.copyWith(
        fontSize: 13,
        color: AppColors.sand.withValues(alpha: 0.85),
      ),
      backgroundColor: AppColors.gold.withValues(alpha: 0.05),
      side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.message,
    this.onReport,
    this.onOpen,
    this.onRetry,
    this.isLatest = false,
  });

  final HadiMessage message;

  /// True for the newest reply: a screen reader announces it when it
  /// arrives.
  final bool isLatest;
  final VoidCallback? onReport;

  /// Called with a route when the person taps an "Open …" button.
  final void Function(String route)? onOpen;

  /// Set on a reply that fell back to the shelf because live failed.
  final VoidCallback? onRetry;

  /// Puts the reply on the clipboard (without markup) and says so.
  static Future<void> _copy(BuildContext context, String text) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: HadiMarkdown.plain(text)));
    messenger.showSnackBar(
      const SnackBar(content: Text('Copied to the clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HadiCorpus? corpus = message.sources.isEmpty
        ? null
        : ref.watch(hadiCorpusProvider).valueOrNull;
    final List<Passage> passages = <Passage>[
      if (corpus != null)
        for (final String id in message.sources)
          if (corpus.resolve(id) != null) corpus.resolve(id)!,
    ];
    final bool hadi = message.fromHadi;
    final String shown = HadiTokens.strip(message.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: hadi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hadi) ...[
            const IconTile(icon: Icons.auto_awesome, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: hadi
                ? Semantics(
                    container: true,
                    liveRegion: isLatest,
                    child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        HadiRichText(
                          text: shown,
                          style: AppText.body.copyWith(
                            height: 1.5,
                            color: AppColors.sand.withValues(alpha: 0.9),
                          ),
                        ),
                        for (final Passage p in passages) _PassageCard(passage: p),
                        if (message.notes.isNotEmpty)
                          HadiNotesPanel(notes: message.notes),
                        if (message.crisis != null)
                          _CrisisHelpPanel(kind: message.crisis!),
                        if (message.routes.isNotEmpty && onOpen != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final String route in message.routes)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: AppColors.gold,
                                    ),
                                    label: Text(HadiTokens.labelFor(route)),
                                    labelStyle: AppText.body.copyWith(
                                      fontSize: 14,
                                      color: AppColors.goldLight,
                                    ),
                                    backgroundColor:
                                        AppColors.gold.withValues(alpha: 0.08),
                                    side: BorderSide(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    onPressed: () => onOpen!(route),
                                  ),
                              ],
                            ),
                          ),
                        if (onRetry != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Try the live answer again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.goldLight,
                                side: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                ),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              if (onReport != null)
                                TextButton.icon(
                                  onPressed: onReport,
                                  icon: const Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Report'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        AppColors.sand.withValues(alpha: 0.75),
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Copy this reply',
                                onPressed: () => _copy(context, shown),
                                icon: const Icon(Icons.copy_outlined, size: 18),
                                color: AppColors.sand.withValues(alpha: 0.75),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                              ),
                              SpeakButton(
                                text: HadiMarkdown.plain(shown),
                                minTapTarget: 48,
                                semanticLabel: 'Read this reply aloud',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: SelectableText(
                      message.text,
                      textDirection: HadiMarkdown.isMostlyRtl(message.text)
                          ? TextDirection.rtl
                          : null,
                      style: AppText.body.copyWith(
                        color: AppColors.night,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(
      {required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The circle is 40 dp; the area that answers a tap is 48 dp.
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.glassFill,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.sand.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One short privacy section in the Advanced sheet: a heading that opens to
/// a sentence or two.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return HadiDisclosure(
      title: title,
      child: Text(
        body,
        style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
      ),
    );
  }
}

/// Subscription status inside the key sheet: tier, quota, expiry, and the
/// restore flow (placeholder until billing plugs into the same contract).
class _SubscriptionPanel extends ConsumerWidget {
  const _SubscriptionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String tier = ref.watch(subscriptionServiceProvider);
    final SubscriptionService sub =
        ref.watch(subscriptionServiceProvider.notifier);
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final bool entitled = sub.isEntitled;
    final int? expires = prefs.getInt(SubscriptionService.expiresPref);
    final String expiryLabel = expires == null
        ? ''
        : DateTime.fromMillisecondsSinceEpoch(expires).toLocal().toString().substring(0, 10);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                entitled
                    ? 'Subscription · ${tier[0].toUpperCase()}${tier.substring(1)}'
                    : 'Free today · nothing to pay',
                style: AppText.body.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entitled
                ? '${sub.remainingToday} live questions left today'
                    '${expiryLabel.isEmpty ? '' : ' · renews $expiryLabel'}'
                : 'A paid plan for extra live answers is planned, not open '
                    'yet, and nothing here asks for a card. Hādi\u2019s '
                    'built-in shelf is free and never runs out. You can also '
                    'use your own AI account below.',
            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              alignment: AlignmentDirectional.centerStart,
            ),
            onPressed: () async {
              final gateway = ref.read(billingGatewayProvider);
              final BillingResult result = await gateway.restore();
              final String? error =
                  await activateBillingResult(
                      ref.read(subscriptionServiceProvider.notifier), result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ??
                        'Subscription restored — ${result.tier} is active.'),
                  ),
                );
              }
            },
            child: Text('Already paid on another device? Restore →',
                style: AppText.bodyMuted.copyWith(
                    color: AppColors.gold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
