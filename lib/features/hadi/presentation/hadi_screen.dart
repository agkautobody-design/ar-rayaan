import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/hadi_controller.dart';
import '../application/hadi_provider.dart';
import '../application/hadi_samples.dart';

/// Screen 6 · Ask Hādī — live AI guidance (Groq free tier, user's key) with
/// a curated authentic offline fallback (O-7). Guardrails: Qur'an + Sihah
/// Sitta only, honest declines, no invented rulings.
class HadiScreen extends ConsumerStatefulWidget {
  const HadiScreen({super.key});

  @override
  ConsumerState<HadiScreen> createState() => _HadiScreenState();
}

class _HadiScreenState extends ConsumerState<HadiScreen> {
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
    if (preset == null) _input.clear();
    _scrollToEnd();
    await ref.read(hadiControllerProvider.notifier).ask(q);
    _scrollToEnd();
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

  Future<void> _openKeySheet() async {
    final TextEditingController keyInput = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live AI for Hādi', style: AppText.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Hādi answers from curated authentic knowledge offline. For '
              'open conversation, paste a free Groq API key (console.groq.com '
              '→ API Keys — free, no card). The key never leaves your device.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyInput,
              obscureText: true,
              style: AppText.body,
              decoration: InputDecoration(
                hintText: 'gsk_…',
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
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await ref
                          .read(hadiControllerProvider.notifier)
                          .saveApiKey('');
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'Remove key',
                      style: AppText.caption.copyWith(
                        color: AppColors.sand.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(hadiControllerProvider.notifier)
                          .saveApiKey(keyInput.text);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.night,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _HeaderIcon(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(999),
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
                              style: AppText.bodyMuted.copyWith(
                                color: AppColors.textFaint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeaderIcon(
                    icon: Icons.key_outlined,
                    onTap: _openKeySheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hadi.live
                  ? 'Live answers · Qur\'an & Sihah Sitta guardrails'
                  : 'Offline mode · add a free key for live AI (tap the key icon)',
              style: AppText.bodyMuted.copyWith(
                fontSize: 10,
                color: AppColors.textFaint,
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  for (final HadiMessage m in hadi.messages)
                    _Bubble(message: m),
                  if (hadi.typing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          IconTile(icon: Icons.auto_awesome, size: 28),
                          SizedBox(width: 8),
                          GlassCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              '· · ·',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hadi.messages.length == 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in kProposedHadiExchanges)
                          ActionChip(
                            onPressed: () => _send(e.question),
                            avatar: const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.gold,
                            ),
                            label: Text(e.question),
                            labelStyle: AppText.bodyMuted.copyWith(
                              fontSize: 12,
                              color: AppColors.sand.withValues(alpha: 0.85),
                            ),
                            backgroundColor: AppColors.gold.withValues(
                              alpha: 0.05,
                            ),
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GlassCard(
                borderRadius: 999,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 6,
                  top: 4,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: _send,
                        style: AppText.body,
                        decoration: InputDecoration(
                          hintText: 'Ask Hādi anything…',
                          hintStyle: AppText.bodyMuted.copyWith(
                            color: AppColors.textFaint,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _send(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                        ),
                        child: const Icon(
                          Icons.send,
                          size: 16,
                          color: AppColors.night,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final HadiMessage message;

  @override
  Widget build(BuildContext context) {
    final bool hadi = message.fromHadi;
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
                ? GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.text,
                          style: AppText.body.copyWith(
                            height: 1.5,
                            color: AppColors.sand.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SpeakButton(text: message.text, size: 24),
                        ),
                      ],
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
                    child: Text(
                      message.text,
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
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.sand.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
