import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../auth/application/auth_providers.dart';
import '../../../app/analytics.dart';
import '../application/wasia_parent_bridge.dart';

class WasiaParentChatScreen extends ConsumerStatefulWidget {
  const WasiaParentChatScreen({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<WasiaParentChatScreen> createState() => _WasiaParentChatScreenState();
}

class _WasiaParentChatScreenState extends ConsumerState<WasiaParentChatScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.logWasiaParentChatOpened(widget.childId);
  }
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(wasiaParentBridgeProvider)
        .sendParentMessage(user.uid, text, childId: widget.childId);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final messagesAsync = user != null
        ? ref.watch(wasiaChatProvider(user.uid))
        : const AsyncData<List<WasiaMessage>>([]);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const TrText('Speak to Wasia', style: AppText.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const TrText(
                            "Ask Wasia anything about your child's learning:\n"
                            "\u2022 How is their progress?\n"
                            "\u2022 What did they score on their last test?\n"
                            "\u2022 What are they studying now?\n"
                            "\u2022 How can I help them at home?",
                            style: AppText.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _MessageBubble(message: messages[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: TrText('Error: $e', style: AppText.body.copyWith(color: Colors.red))),
            ),
          ),
          _InputBar(ctrl: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final WasiaMessage message;

  @override
  Widget build(BuildContext context) {
    final isParent = message.sender == 'parent';
    return Align(
      alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isParent
              ? AppColors.gold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isParent ? 16 : 4),
            bottomRight: Radius.circular(isParent ? 4 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrText(
              message.text,
              style: AppText.body.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            TrText(
              _formatTime(message.sentAt),
              style: AppText.caption.copyWith(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $am';
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.ctrl, required this.onSend});
  final TextEditingController ctrl;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: AppText.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask Wasia about your child...',
                  hintStyle: AppText.body.copyWith(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
