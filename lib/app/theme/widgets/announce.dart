import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

/// Speaks [message] to a screen reader when this widget first appears and
/// whenever the message changes, then shows [child] unchanged.
///
/// A live-region label alone is not enough on every platform: on the web the
/// browser's announcement area stayed empty, so "Right. The shahada comes
/// first" was on screen but never said. This sends the words as an explicit
/// announcement as well. It does nothing when the message is empty, and
/// nothing is announced when no screen reader is running.
class Announce extends StatefulWidget {
  const Announce({
    required this.message,
    required this.child,
    this.assertive = false,
    super.key,
  });

  final String message;
  final Widget child;

  /// Interrupts what is being read (a wrong answer, an error) instead of
  /// waiting its turn.
  final bool assertive;

  @override
  State<Announce> createState() => _AnnounceState();
}

class _AnnounceState extends State<Announce> {
  @override
  void initState() {
    super.initState();
    _later();
  }

  @override
  void didUpdateWidget(Announce old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _later();
  }

  void _later() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _say());
  }

  void _say() {
    if (!mounted || widget.message.trim().isEmpty) return;
    announceToScreenReader(context, widget.message, assertive: widget.assertive);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sends one announcement. Safe to call from anywhere with a context; any
/// failure (no view, no screen reader) is ignored.
void announceToScreenReader(
  BuildContext context,
  String message, {
  bool assertive = false,
}) {
  try {
    final TextDirection dir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      dir,
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    ).ignore();
  } catch (_) {
    // Nothing to announce to.
  }
}
