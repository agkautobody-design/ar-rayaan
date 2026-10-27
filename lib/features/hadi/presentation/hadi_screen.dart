import '../../../app/core/scholar_review.dart';
import 'dart:async';

import '../../../app/core/tight_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../share/application/share_text.dart';
import '../../share/presentation/share_actions.dart';
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
import '../data/hadi_routing.dart';
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
import '../../support/presentation/privacy_shield.dart';
import '../../support/presentation/support_widgets.dart';

/// The items under the More options button in the header.
enum _HadiMenu { newConversation, school, advanced, about }

/// The longest question the box takes. Longer pasted text is cut to this and
/// the person is told.
const int kHadiMaxInput = 1000;

/// Counter shows once the text reaches this many characters.
const int kHadiCounterFrom = 800;

/// Cuts text to [max] characters (never in the middle of a character) and
/// calls [onCut] when it did.
class _CapFormatter extends TextInputFormatter {
  _CapFormatter(this.max, this.onCut);

  final int max;
  final VoidCallback onCut;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= max) return newValue;
    onCut();
    int end = max;
    final int last = newValue.text.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end -= 1; // half an emoji
    return TextEditingValue(
      text: newValue.text.substring(0, end),
      selection: TextSelection.collapsed(offset: end),
    );
  }
}

/// Screen 6 · Ask Hādī — live AI guidance (Groq free tier, user's key) with
/// a curated authentic offline fallback (O-7). Guardrails: Qur'an + Sihah
/// Sitta only, honest declines, no invented rulings.
class HadiScreen extends ConsumerStatefulWidget {
  const HadiScreen({super.key, this.initialQuery});

  /// A question to ask as soon as the screen opens (for example the text
  /// typed in the bar on the home screen). It is sent once.
  final String? initialQuery;

  @override
  ConsumerState<HadiScreen> createState() => _HadiScreenState();
}

class _HadiScreenState extends ConsumerState<HadiScreen> {
  bool _allStarters = false;

  /// On a narrow phone the intro is one line until the person opens it.
  bool _introOpen = false;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// The last [HadiScreen.initialQuery] taken, so it is never sent twice.
  String? _takenQuery;

  /// True after pasted text was cut to [kHadiMaxInput].
  bool _cut = false;

  /// One key per message, so the newest question can be brought into view.
  final Map<int, GlobalKey> _bubbleKeys = <int, GlobalKey>{};

  late final List<TextInputFormatter> _formatters = <TextInputFormatter>[
    _CapFormatter(kHadiMaxInput, () {
      if (mounted && !_cut) setState(() => _cut = true);
    }),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takeInitialQuery();
      // Coming back to an earlier conversation: start at the latest message.
      if (mounted &&
          ref.read(hadiControllerProvider).messages.length > 1 &&
          _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(HadiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      if ((widget.initialQuery ?? '').trim().isEmpty) _takenQuery = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _takeInitialQuery());
    }
  }

  /// Asks the question the screen was opened with. If Hādi is busy it goes
  /// into the text box instead, so what the person typed is never lost.
  void _takeInitialQuery() {
    if (!mounted) return;
    final String q = (widget.initialQuery ?? '').trim();
    if (q.isEmpty || q == _takenQuery) return;
    _takenQuery = q;
    if (ref.read(hadiControllerProvider).typing) {
      _input.text = q;
      return;
    }
    unawaited(_send(q));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    String q = (preset ?? _input.text).trim();
    if (q.isEmpty) return;
    // Hādi is still answering: keep what was typed, do not swallow it.
    if (ref.read(hadiControllerProvider).typing) return;
    if (q.length > kHadiMaxInput) q = q.substring(0, kHadiMaxInput).trim();
    if (preset == null) {
      // Empty the box completely, text, selection and the composing mark,
      // so nothing of a long message is left for the next one.
      _input.value = TextEditingValue.empty;
      if (_cut) setState(() => _cut = false);
    }
    await ref.read(hadiControllerProvider.notifier).ask(q);
  }

  /// Set by build: little room, so a reply is shown from its first line.
  bool _tight = false;

  /// Brings the newest exchange into view: the question just asked (so the
  /// start of a long reply is not scrolled past), or the bottom while Hādi
  /// is still answering.
  void _followConversation(HadiState? before, HadiState now) {
    final bool grew = before == null ||
        now.messages.length != before.messages.length ||
        now.typing != before.typing;
    if (!grew) return;
    if (now.messages.length < (before?.messages.length ?? 0)) {
      _bubbleKeys.clear();
    }
    final bool replied =
        !now.typing && now.messages.isNotEmpty && now.messages.last.fromHadi;
    if (!replied) {
      _scrollToEnd();
      return;
    }
    // With little room the question and its reply do not fit together:
    // show the reply itself, from its first line.
    final int asked = !_tight &&
            now.messages.length >= 2 &&
            !now.messages[now.messages.length - 2].fromHadi
        ? now.messages.length - 2
        : now.messages.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? ctx = _bubbleKeys[asked]?.currentContext;
      if (ctx != null && ctx.mounted) {
        unawaited(Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ));
      } else {
        _scrollToEnd();
      }
    });
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
                                'will be sent the next time you open the '
                                'app with a connection.'),
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
                    body: 'On a phone, in the phone\u2019s secure store. In a '
                        'web browser it is kept for this visit only, and '
                        'you paste it again next time. It is never saved in '
                        'plain text. Use a key you can revoke.',
                  ),
                  const _PrivacyNote(
                    title: 'What never leaves your device',
                    body: 'Messages about suicide, self-harm, abuse, '
                        'anyone\u2019s safety, or about drinking, drugs, '
                        'gambling, pornography, smoking or a relapse are '
                        'answered here on your device. They are never sent, '
                        'never saved, and cannot be reported.',
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
    final bool compact = MediaQuery.sizeOf(context).width < 400;
    // Large text leaves little room for the chat itself, so the long
    // introduction stays folded (one tap opens it) just as on a small phone.
    final bool largeText =
        MediaQuery.textScalerOf(context).scale(14) / 14 > 1.2;
    // A very small window (a browser zoomed to 200% is about 195 dp wide):
    // the header keeps only its buttons, the status moves into the intro and
    // the composer shrinks, so the chat gets at least half the screen.
    final bool tight = isTightLayout(context);
    _tight = tight;
    final bool fullIntro = _introOpen || (!compact && !largeText && !tight);
    ref.listen<HadiState>(
      hadiControllerProvider,
      (HadiState? before, HadiState now) => _followConversation(before, now),
    );
    // With large text or a very narrow phone the status pill moves to its
    // own row under the buttons, so it never gets squeezed to nothing.
    // Round 6: at 2x the pill stayed on its own row and left a tiny chat.
    // It now shares the top row (its text is capped at 1.3x) unless the
    // screen is under 330 dp wide.
    final bool stackedHeader = MediaQuery.sizeOf(context).width < 330;
    final Widget statusPill = Container(
      key: const Key('hadi-status-pill'),
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.auto_awesome,
            size: 15,
            color: AppColors.gold.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Text(
                hadi.live
                    ? (compact
                        ? 'Hādi · live AI'
                        : 'Hādi · live AI (guardrailed)')
                    : 'Hādi · built-in library',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMuted.copyWith(color: AppColors.textFaint),
              ),
            ),
          ),
        ],
      ),
    );

    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.night.withValues(alpha: 0.92),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.12),
                  ),
                ),
              ),
              // Never taller than 45% of the screen: the intro scrolls inside
              // the band rather than pushing the chat out of view.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: <Widget>[
                        _HeaderIcon(
                          icon: Icons.arrow_back,
                          label: 'Back to home',
                          onTap: () => context.go(AppRoutes.home),
                        ),
                        const SizedBox(width: 4),
                        if (stackedHeader || tight)
                          const Spacer()
                        else
                          Expanded(child: statusPill),
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
                              case _HadiMenu.about:
                                setState(() => _introOpen = !_introOpen);
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
                            if (tight)
                              PopupMenuItem<_HadiMenu>(
                                value: _HadiMenu.about,
                                child: Text('About Hādi', style: AppText.body),
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
                  if (stackedHeader && !tight)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: SizedBox(width: double.infinity, child: statusPill),
                    ),
                  SizedBox(height: tight ? 0 : (compact ? 2 : 10)),
            if (fullIntro && tight)
              Text(
                hadi.live ? 'Hādi · live AI' : 'Hādi · built-in library',
                key: const Key('hadi-status-line'),
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12,
                  color: AppColors.textFaint,
                ),
                textAlign: TextAlign.center,
              ),
            if (fullIntro)
              Text(
                hadi.live
                    ? 'Live answers · Qur\'an & Sihah Sitta guardrails'
                    : 'Free. Answers come from the built-in library. An online '
                        'AI account is optional (More options menu, top '
                        'right).',
                style: AppText.bodyMuted.copyWith(
                  fontSize: 12,
                  color: AppColors.textFaint,
                ),
                textAlign: TextAlign.center,
              ),
            if (hadi.messages.length == 1 && !fullIntro && !tight)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextButton(
                  key: const Key('hadi-intro-more'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => setState(() => _introOpen = true),
                  child: Text(
                    'A study aid, not a scholar. Free today. More ▾',
                    style: AppText.bodyMuted.copyWith(
                      color: AppColors.gold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (hadi.messages.length == 1 && fullIntro)
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
            if (hadi.messages.length == 1 && fullIntro)
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
                        'Who writes the answers, and what I cannot do →',
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
                ],
              ),
                ),
              ),
            ),
            if (hadi.messages.any((HadiMessage m) =>
                m.fromHadi && (m.support != null || m.crisis != null)))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: QuickExitButton(),
              ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(tight ? 12 : 20, tight ? 8 : 16, tight ? 12 : 20, 16),
                children: [
                  for (int i = 0; i < hadi.messages.length; i++)
                    KeyedSubtree(
                      key: _bubbleKeys.putIfAbsent(i, () => GlobalKey()),
                      child: _Bubble(
                      message: hadi.messages[i],
                      isLatest: i == hadi.messages.length - 1 && !hadi.typing,
                      // Opened ON TOP of the chat (a tab route is reached
                      // with go, as always), so Back returns to the
                      // conversation instead of jumping Home.
                      onOpen: (String route) => context.open(route),
                      onOnlineMode: hadi.live ? null : _openKeySheet,
                      onRetry: hadi.messages[i].retryQuestion != null &&
                              i == hadi.messages.length - 1 &&
                              !hadi.typing
                          ? () => _send(hadi.messages[i].retryQuestion)
                          : null,
                      // No Report on a crisis or support exchange, or on
                      // a reply to text that is one: that text stays on the
                      // device (see HadiReportPolicy).
                      onReport: hadi.messages[i].fromHadi &&
                              i > 0 &&
                              !hadi.messages[i].sensitive &&
                              hadi.messages[i].support == null &&
                              hadi.messages[i].crisis == null &&
                              HadiReportPolicy.mayInclude(
                                  hadi.messages[i - 1].text)
                          ? () => _openReportSheet(
                                hadi.messages[i],
                                !hadi.messages[i - 1].fromHadi &&
                                        !hadi.messages[i - 1].sensitive
                                    ? hadi.messages[i - 1].text
                                    : null,
                              )
                          : null,
                    ),
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
                  if (hadi.messages.every((HadiMessage m) => m.fromHadi))
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
                          HadiActionButton(
                            label: 'More questions\u2026',
                            icon: Icons.add,
                            iconSize: 14,
                            onPressed: () =>
                                setState(() => _allStarters = true),
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
                            lastQuestion: <String>[
                              for (final HadiMessage m in hadi.messages)
                                if (!m.fromHadi && !m.sensitive) m.text,
                            ].lastOrNull,
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
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (BuildContext _, TextEditingValue v, Widget? __) {
                final int n = v.text.length;
                if (!_cut && n < kHadiCounterFrom) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 4),
                  child: Text(
                    _cut
                        ? 'Your text was cut to $kHadiMaxInput characters. '
                            '($n/$kHadiMaxInput)'
                        : '$n/$kHadiMaxInput characters',
                    key: const ValueKey<String>('hadi-input-note'),
                    style: AppText.bodyMuted.copyWith(
                      fontSize: 12,
                      color: AppColors.textFaint,
                    ),
                    textAlign: TextAlign.end,
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, tight ? 6 : 16),
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
                        padding: EdgeInsets.symmetric(vertical: tight ? 8 : 12),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _input,
                          builder: (BuildContext _, TextEditingValue v,
                              Widget? __) {
                            return TextField(
                              controller: _input,
                              inputFormatters: _formatters,
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
                                hintText: tight ? 'Ask Hādi' : 'Ask Hādi anything…',
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
class _CrisisHelpPanel extends ConsumerStatefulWidget {
  const _CrisisHelpPanel({required this.kind});

  final CrisisKind kind;

  @override
  ConsumerState<_CrisisHelpPanel> createState() => _CrisisHelpPanelState();
}

class _CrisisHelpPanelState extends ConsumerState<_CrisisHelpPanel> {
  /// A country the person picked here; wins over the device language.
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final String? country = _picked ?? ref.watch(deviceCountryProvider);
    final List<HelpResource> rows = CrisisResponses.resourcesFor(
      widget.kind,
      country,
    ).take(6).toList();
    final String? cc = country?.trim().toUpperCase();
    final List<(String, String)> choices = helpCountryChoices();
    final bool known =
        cc != null && choices.any(((String, String) c) => c.$1 == cc);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final HelpResource r in rows) ...<Widget>[
            HelpLineTile(resource: r),
            const SizedBox(height: 6),
          ],
          Text('Not your country? Choose yours:', style: AppText.caption),
          DropdownButton<String>(
            key: const Key('hadi-help-country'),
            isExpanded: true,
            dropdownColor: AppColors.night,
            hint: const Text('Choose your country'),
            value: known ? cc : null,
            items: <DropdownMenuItem<String>>[
              for (final (String code, String name) in choices)
                DropdownMenuItem<String>(
                  value: code,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (String? v) {
              if (v != null) setState(() => _picked = v);
            },
          ),
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
/// gave it. Tapping it opens the surah for a verse, or Our Sources for a
/// hadith, and the card says so.
class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.passage});

  final Passage passage;

  /// Where a tap goes: the surah for a Qur'an verse, Our Sources otherwise.
  String get _route {
    if (passage.kind == PassageKind.quran) {
      final List<String> parts = passage.id.split(':');
      final int? surah = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (surah != null && surah >= 1 && surah <= 114) {
        return AppRoutes.surah(surah);
      }
    }
    return AppRoutes.sources;
  }

  @override
  Widget build(BuildContext context) {
    final String? grade = passage.gradeLine;
    final String route = _route;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: AppColors.gold.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            // open(), not push(): a tap that lands twice (the reply grows
            // under the finger) must not stack the same surah twice.
            onTap: () => context.open(route),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          : 'Excerpt written for this app, not a full '
                              'translation.',
                      style: AppText.caption.copyWith(
                        color: AppColors.sand.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        route == AppRoutes.sources
                            ? 'Where this comes from'
                            : 'Open this surah',
                        style: AppText.caption.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.goldLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
    return HadiActionButton(
      label: label,
      icon: Icons.chat_bubble_outline,
      iconSize: 14,
      onPressed: onTap,
    );
  }
}

/// A Hadi reply for copying: the answer, then each cited passage with its
/// reference (and grade line), then the app credit.
String hadiReplyShareText(String answer, List<Passage> passages) {
  final StringBuffer b = StringBuffer(answer.trim());
  if (passages.isNotEmpty) {
    b.write('\n\nSources:');
    for (final Passage p in passages) {
      b.write('\n\u2014 ${p.reference}');
      final String? grade = p.gradeLine;
      if (grade != null && grade.trim().isNotEmpty) b.write(' ($grade)');
      if (p.english.trim().isNotEmpty) b.write(': ${p.english.trim()}');
    }
  }
  b.write('\n\n$kSharedFromLine');
  return b.toString();
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.message,
    this.onReport,
    this.onOpen,
    this.onRetry,
    this.onOnlineMode,
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

  /// Opens Hādi's settings for the optional online mode; null when the
  /// person already has it on.
  final VoidCallback? onOnlineMode;

  /// Puts the reply on the clipboard (without markup, with the passages it
  /// cites) and says so.
  static Future<void> _copy(
    BuildContext context,
    String text,
    List<Passage> passages,
  ) =>
      copyWithFeedback(
        context,
        hadiReplyShareText(HadiMarkdown.plain(text), passages),
        message: 'Copied to the clipboard.',
      );

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
          // No avatar in a very small window: the words need the width.
          if (hadi && !isTightLayout(context)) ...[
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
                        const ScholarReviewNote(
                          key: Key('hadi-review-note'),
                          reviewKey: 'hadi',
                          padding: EdgeInsets.only(top: 8),
                        ),
                        if (message.notes.isNotEmpty)
                          HadiNotesPanel(notes: message.notes),
                        if (message.crisis != null)
                          _CrisisHelpPanel(kind: message.crisis!),
                        if (message.checkin) const CheckinPanel(),
                        if (message.supportIds.isNotEmpty)
                          SupportProvenanceButton(ids: message.supportIds),
                        if (message.helpScope != null &&
                            message.supportIds.isNotEmpty)
                          SupportHelpLines(scope: message.helpScope!),
                        if (onOnlineMode != null &&
                            !message.live &&
                            HadiRouting.isRefusal(message.text))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              key: const Key('hadi-online-mode'),
                              onPressed: onOnlineMode,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                                alignment: AlignmentDirectional.centerStart,
                              ),
                              child: Text(
                                'Optional: use your own AI account for more answers',
                                style: AppText.caption.copyWith(
                                  color: AppColors.textFaint,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        if (message.routes.isNotEmpty && onOpen != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final String route in message.routes)
                                  HadiActionButton(
                                    strong: true,
                                    label: HadiTokens.labelFor(route),
                                    icon: Icons.arrow_forward,
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
                                onPressed: () => _copy(context, shown, passages),
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
