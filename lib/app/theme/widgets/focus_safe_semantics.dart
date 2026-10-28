import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A [Semantics] that replaces what is inside it with one label (the same as
/// `Semantics(excludeSemantics: true, ...)`) but still tells the screen
/// reader where keyboard focus is.
///
/// Why this exists: a plain `excludeSemantics: true` throws away the focus
/// information of the control inside it (an InkWell, a FocusableTap). The
/// framework then moves its own focus ring down a list while the browser's
/// focused element, which is what a screen reader follows, stays where it
/// was, or sits on an unnamed page element ("silent Tab stops"). This widget
/// watches focus inside its child and puts `focusable` and `focused` on the
/// labelled node itself, so the node that is read is the node that has
/// focus.
class FocusSafeSemantics extends StatefulWidget {
  const FocusSafeSemantics({
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.button = false,
    this.selected,
    this.enabled,
    this.expanded,
    this.inMutuallyExclusiveGroup,
    this.onTap,
    this.excludeSemantics = true,
    super.key,
  });

  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool button;
  final bool? selected;
  final bool? enabled;
  final bool? expanded;
  final bool? inMutuallyExclusiveGroup;
  final VoidCallback? onTap;

  /// Kept so call sites read like [Semantics]; always true in practice.
  final bool excludeSemantics;

  @override
  State<FocusSafeSemantics> createState() => _FocusSafeSemanticsState();
}

class _FocusSafeSemanticsState extends State<FocusSafeSemantics> {
  final FocusNode _probe = FocusNode(
    debugLabel: 'FocusSafeSemantics',
    canRequestFocus: false,
    skipTraversal: true,
  );
  bool _focused = false;
  bool _focusable = false;
  bool _scheduled = false;

  @override
  void dispose() {
    _probe.dispose();
    super.dispose();
  }

  void _look() {
    _scheduled = false;
    if (!mounted) return;
    bool found = false;
    for (final FocusNode n in _probe.descendants) {
      if (n.canRequestFocus && !n.skipTraversal) {
        found = true;
        break;
      }
    }
    if (found != _focusable) setState(() => _focusable = found);
  }

  @override
  Widget build(BuildContext context) {
    if (!_scheduled && !_focusable) {
      _scheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => _look());
    }
    return Focus(
      focusNode: _probe,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (bool f) {
        if (f != _focused && mounted) setState(() => _focused = f);
      },
      child: Semantics(
        button: widget.button,
        label: widget.label,
        hint: widget.hint,
        value: widget.value,
        selected: widget.selected,
        enabled: widget.enabled,
        expanded: widget.expanded,
        inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
        onTap: widget.onTap,
        focusable: _focusable ? true : null,
        focused: _focusable ? _focused : null,
        excludeSemantics: widget.excludeSemantics,
        child: widget.child,
      ),
    );
  }
}
