import 'package:flutter/material.dart';

import '../../core/web_offline.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Full-area state for content that could not be fetched: says so plainly
/// (on the web, that it needs internet) and offers a retry. Never blank,
/// never a grey box.
class NeedsInternetView extends StatelessWidget {
  const NeedsInternetView({
    required this.what,
    this.onRetry,
    this.web,
    super.key,
  });

  /// What failed to load, as a short noun phrase: "The Qur'an", "Trivia".
  final String what;

  /// Called by the Try again button. No button when null.
  final VoidCallback? onRetry;

  /// Forces the web or native wording (defaults to the running platform).
  final bool? web;

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
              WebOffline.needsInternet(what, web: web),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(height: 1.5),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
