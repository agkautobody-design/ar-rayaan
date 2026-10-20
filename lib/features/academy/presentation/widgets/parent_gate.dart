/// Parent gate: a simple adult check before anything that manages a child
/// (the Family Wing, adding / deleting a child, the AI setting for children).
///
/// It is a speed bump for a young child, not security: a multiplication a
/// child under about ten is unlikely to answer, in plain words, with no
/// "I am over 18" tick-box (which the FTC says is not an acceptable age
/// screen). The question is new every time.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// One multiplication question.
class ParentGateChallenge {
  const ParentGateChallenge(this.a, this.b);

  final int a;
  final int b;

  int get answer => a * b;
  String get question => 'What is $a × $b?';

  /// A fresh question: a in 12..19, b in 3..9.
  factory ParentGateChallenge.generate([Random? rng]) {
    final Random r = rng ?? Random();
    return ParentGateChallenge(12 + r.nextInt(8), 3 + r.nextInt(7));
  }

  bool accepts(String input) => int.tryParse(input.trim()) == answer;
}

/// How long a solved gate stays open.
const Duration kParentGateWindow = Duration(minutes: 5);

/// Until when the gate is open (null = locked).
class ParentGateNotifier extends StateNotifier<DateTime?> {
  ParentGateNotifier() : super(null);

  bool isOpen([DateTime? now]) {
    final DateTime? until = state;
    return until != null && (now ?? DateTime.now()).isBefore(until);
  }

  void unlock([DateTime? now]) =>
      state = (now ?? DateTime.now()).add(kParentGateWindow);

  void lock() => state = null;
}

final StateNotifierProvider<ParentGateNotifier, DateTime?>
    parentGateProvider =
    StateNotifierProvider<ParentGateNotifier, DateTime?>(
        (Ref ref) => ParentGateNotifier());

/// The dialog. Pops true when answered correctly, false on cancel.
class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key, this.challenge});

  /// Fixed question for tests; null = a random one (and a new one after each
  /// wrong answer).
  final ParentGateChallenge? challenge;

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  late ParentGateChallenge _challenge;
  final TextEditingController _input = TextEditingController();
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge ?? ParentGateChallenge.generate();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_challenge.accepts(_input.text)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _input.clear();
      if (widget.challenge == null) {
        _challenge = ParentGateChallenge.generate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0F18),
      title: Text('For parents', style: AppText.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Please ask a parent or guardian to answer this to continue.',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 14),
          Text(_challenge.question, style: AppText.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: AppText.body,
            decoration: const InputDecoration(hintText: 'Your answer'),
            onSubmitted: (_) => _submit(),
          ),
          if (_wrong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Not quite — here is a new question.',
                style: AppText.caption.copyWith(color: AppColors.gold),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Continue',
            style: TextStyle(color: AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}

/// Show the gate; true when passed.
Future<bool> showParentGate(
  BuildContext context, {
  ParentGateChallenge? challenge,
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => ParentGateDialog(challenge: challenge),
  );
  return ok ?? false;
}

/// Pass the gate unless it is already open. On success the gate stays open
/// for [kParentGateWindow].
Future<bool> requireParent(
  BuildContext context,
  WidgetRef ref, {
  ParentGateChallenge? challenge,
}) async {
  final ParentGateNotifier gate = ref.read(parentGateProvider.notifier);
  if (gate.isOpen()) return true;
  final bool ok = await showParentGate(context, challenge: challenge);
  if (ok) gate.unlock();
  return ok;
}
