import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/error_handling.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/feedback_providers.dart';
import '../data/feedback_service.dart';

/// Send feedback to the founders: a problem, something missing, something
/// confusing. The app's recent error notes (type and message only — never
/// user data) can ride along so a bug report explains itself.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  final _email = TextEditingController();
  bool _attachErrors = true;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final FeedbackService? svc = ref.read(feedbackServiceProvider);
    if (svc == null || _sending) return;
    setState(() => _sending = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await svc.send(
        message: _message.text,
        email: _email.text,
        errors: _attachErrors
            ? List<String>.of(AppErrorHandling.recent)
            : const <String>[],
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
          content: Text('Thank you — it goes straight to the founders.')));
      Navigator.of(context).pop();
    } on FeedbackRejected catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not send it. Check your connection and try '
              'again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(feedbackEnabledProvider);
    final int errorCount = AppErrorHandling.recent.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            const ScreenHeader(title: 'Send feedback', close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (!enabled)
                    GlassCard(
                      child: Text(
                        'Feedback needs the app\u2019s cloud, which this '
                        'build does not carry.',
                        style: AppText.bodyMuted.copyWith(height: 1.45),
                      ),
                    )
                  else ...[
                    Text(
                      'Something broken, missing or confusing? A sentence is '
                      'enough. This goes straight to the founders — nothing '
                      'is public.',
                      style: AppText.bodyMuted.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'What happened, or what is missing?',
                            child: TextField(
                              key: const Key('feedback-message'),
                              controller: _message,
                              style: AppText.body,
                              maxLines: 5,
                              maxLength: FeedbackService.messageMax,
                              decoration: const InputDecoration(
                                hintText: 'What happened, or what is missing?',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Email, if you want a reply (optional)',
                            child: TextField(
                              key: const Key('feedback-email'),
                              controller: _email,
                              style: AppText.body,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText:
                                    'Email, if you want a reply (optional)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            errorCount == 0
                                ? 'Attach the app\u2019s recent error notes '
                                    '(none recorded right now)'
                                : 'Attach the app\u2019s recent error notes '
                                    '($errorCount) — type and message only, '
                                    'never your data',
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ),
                        Switch(
                          key: const Key('feedback-attach-errors'),
                          value: _attachErrors,
                          activeThumbColor: AppColors.gold,
                          onChanged: (v) =>
                              setState(() => _attachErrors = v),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    GoldButton(
                      key: const Key('feedback-send'),
                      label: _sending ? 'Sending…' : 'Send to the founders',
                      trailing: const Icon(Icons.send, size: 18),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
