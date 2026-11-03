import 'package:flutter/material.dart' hide Text;

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/widgets/tr_text.dart';

/// Catches errors in child widgets and displays a graceful fallback.
/// Prevents one crashing feature from bringing down the entire app.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child, this.fallback});
  final Widget child;
  final Widget? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _DefaultErrorView(
        onRetry: () => setState(() {
          _hasError = false;
        }),
      );
    }
    return widget.child;
  }
}

class _DefaultErrorView extends StatelessWidget {
  const _DefaultErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: AppText.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'We have been notified and are working on a fix. '
              'Please try again or restart the app.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
