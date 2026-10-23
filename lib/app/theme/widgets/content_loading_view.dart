import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/web_offline.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// How long a load has been going, in the three steps the person sees.
enum LoadingPhase {
  /// Under [slowAfter]: just the spinner (most loads end here).
  quick,

  /// A message and, where known, the size of the first download.
  slow,

  /// Long enough that a retry is offered next to the message.
  stalled,
}

/// Pure mapping from elapsed time to [LoadingPhase].
LoadingPhase loadingPhaseFor(
  Duration elapsed, {
  Duration slowAfter = const Duration(seconds: 2),
  Duration stalledAfter = const Duration(seconds: 25),
}) {
  if (elapsed >= stalledAfter) return LoadingPhase.stalled;
  if (elapsed >= slowAfter) return LoadingPhase.slow;
  return LoadingPhase.quick;
}

/// The wording for a [LoadingPhase], kept apart from the widget for tests.
/// [web] picks the browser wording; the native apps load from the device.
String loadingMessageFor(
  LoadingPhase phase,
  String what, {
  String? sizeHint,
  bool? web,
}) {
  final bool onWeb = web ?? WebOffline.isWeb;
  switch (phase) {
    case LoadingPhase.quick:
      return '';
    case LoadingPhase.slow:
      if (onWeb && sizeHint != null) {
        return 'Loading $what… first time only ($sizeHint). '
            'After this it opens quickly, even with no connection.';
      }
      return 'Loading $what…';
    case LoadingPhase.stalled:
      return 'Still loading $what. Your connection may be slow or offline. '
          'You can keep waiting, or try again.';
  }
}

/// Full-area loading state: a spinner, then (after two seconds) a plain
/// message with the size of the first download, then (after about 25
/// seconds) a Try again button. Never a blank screen with a tiny spinner.
class ContentLoadingView extends StatefulWidget {
  const ContentLoadingView({
    required this.what,
    this.sizeHint,
    this.onRetry,
    this.slowAfter = const Duration(seconds: 2),
    this.stalledAfter = const Duration(seconds: 25),
    this.web,
    super.key,
  });

  /// What is loading, as a short noun phrase: "the Qur’an".
  final String what;

  /// Rough size of the first download, e.g. "about 2 MB". Shown on the web.
  final String? sizeHint;

  /// Re-fetches. The Try again button appears only when this is set.
  final VoidCallback? onRetry;

  final Duration slowAfter;
  final Duration stalledAfter;

  /// Forces the web or native wording (defaults to the running platform).
  final bool? web;

  @override
  State<ContentLoadingView> createState() => _ContentLoadingViewState();
}

class _ContentLoadingViewState extends State<ContentLoadingView> {
  Timer? _slow;
  Timer? _stalled;
  LoadingPhase _phase = LoadingPhase.quick;

  @override
  void initState() {
    super.initState();
    _slow = Timer(widget.slowAfter, () => _go(LoadingPhase.slow));
    _stalled = Timer(widget.stalledAfter, () => _go(LoadingPhase.stalled));
  }

  void _go(LoadingPhase p) {
    if (mounted) setState(() => _phase = p);
  }

  @override
  void dispose() {
    _slow?.cancel();
    _stalled?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String message = loadingMessageFor(
      _phase,
      widget.what,
      sizeHint: widget.sizeHint,
      web: widget.web,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(color: AppColors.gold),
            if (message.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(height: 1.5),
                ),
              ),
            ],
            if (_phase == LoadingPhase.stalled &&
                widget.onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
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
