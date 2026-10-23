import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/web_offline.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Full-area state for content that could not be fetched: says so plainly
/// (on the web, that it needs internet) and offers a retry. Never blank,
/// never a grey box.
class NeedsInternetView extends StatefulWidget {
  const NeedsInternetView({
    required this.what,
    this.onRetry,
    this.web,
    this.hint,
    super.key,
  });

  /// An extra plain sentence under the message, e.g. how to have it ready
  /// offline next time. Shown only on the web (the phone apps never need it).
  final String? hint;

  /// What failed to load, as a short noun phrase: "The Qur'an", "Trivia".
  final String what;

  /// Called by the Try again button. No button when null.
  final VoidCallback? onRetry;

  /// Forces the web or native wording (defaults to the running platform).
  final bool? web;

  @override
  State<NeedsInternetView> createState() => _NeedsInternetViewState();
}

class _NeedsInternetViewState extends State<NeedsInternetView> {
  Timer? _timer;
  bool _checking = false;
  bool _stillFailing = false;

  /// Try again must visibly do something: show "Checking" for a moment, and
  /// if this same view is still on screen afterwards, say it is still
  /// failing (instead of looking like the button did nothing).
  void _retry() {
    final VoidCallback? go = widget.onRetry;
    if (go == null) return;
    setState(() {
      _checking = true;
      _stillFailing = false;
    });
    go();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _stillFailing = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.gold.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 14),
            Text(
              WebOffline.needsInternet(widget.what, web: widget.web),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(height: 1.5),
            ),
            if (widget.hint != null && (widget.web ?? WebOffline.isWeb))
              ...<Widget>[
              const SizedBox(height: 10),
              Text(
                widget.hint!,
                key: const Key('needs-internet-hint'),
                textAlign: TextAlign.center,
                style: AppText.bodyMuted.copyWith(height: 1.4),
              ),
            ],
            if (_stillFailing) ...<Widget>[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Still could not load. Check your connection and try '
                  'again in a moment.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(height: 1.4),
                ),
              ),
            ],
            if (widget.onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _checking ? null : _retry,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(_checking ? 'Checking\u2026' : 'Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
