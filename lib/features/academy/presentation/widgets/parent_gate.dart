/// Parent gate: the check before anything that is for a grown-up (the Family
/// Wing, adding / deleting a child, leaving Kids Corner, the AI setting for
/// children).
///
/// It is the parent's PIN ([ParentPin]): 4 to 6 digits the parent chose on this
/// device. A sum a child can answer is not a gate, so the PIN is what runs
/// everywhere. The first grown-up to reach a gate is asked to choose it.
/// The sum ([ParentGateChallenge]) remains only as a fixed-question fallback
/// for tests and for the rare case where the device storage cannot be read.
///
/// A solved gate stays open for [kParentGateWindow] (two minutes), is closed
/// when Kids Corner or child mode starts, and the Family Wing has a Lock
/// button.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/parent_pin.dart';
import '../../../../app/core/providers.dart';
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
const Duration kParentGateWindow = Duration(minutes: 2);

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

/// The PIN dialog: asks for the PIN, or, when none is set yet, asks the parent
/// to choose one. Pops true when it is right (or chosen), false on cancel.
class ParentPinDialog extends StatefulWidget {
  const ParentPinDialog({required this.pin, super.key});

  final ParentPin pin;

  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;
  late final bool _creating = !widget.pin.isSet;

  @override
  void dispose() {
    _input.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String pin = _input.text.trim();
    if (_creating) {
      final String? problem = ParentPin.problemWith(pin);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      if (pin != _confirm.text.trim()) {
        setState(() => _error = 'The two PINs are not the same.');
        return;
      }
      await widget.pin.set(pin);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    final Duration? locked = widget.pin.lockedFor();
    if (locked != null) {
      setState(() => _error = _lockedText(locked));
      return;
    }
    final bool ok = await widget.pin.verify(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    final Duration? nowLocked = widget.pin.lockedFor();
    setState(() {
      _input.clear();
      _error = nowLocked != null
          ? _lockedText(nowLocked)
          : 'That is not the PIN. ${widget.pin.triesLeft} '
              '${widget.pin.triesLeft == 1 ? 'try' : 'tries'} left.';
    });
  }

  static String _lockedText(Duration left) {
    final int m = (left.inSeconds / 60).ceil().clamp(1, 60).toInt();
    return 'Too many tries. Please wait $m ${m == 1 ? 'minute' : 'minutes'} '
        'and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration deco = const InputDecoration(counterText: '');
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0F18),
      title: Text('For parents', style: AppText.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _creating
                  ? 'Choose a PIN of 4 to 6 digits. It keeps children out of '
                      'the grown-up parts of the app and is needed to leave '
                      'Kids Corner. Keep it to yourself. It is saved on '
                      'this device only.'
                  : 'Please ask a parent or guardian to enter their PIN to '
                      'continue.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('parent-pin-input'),
              controller: _input,
              autofocus: true,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: AppText.body,
              decoration: deco.copyWith(
                labelText: _creating ? 'New PIN' : 'Parent PIN',
              ),
              onSubmitted: (_) {
                if (!_creating) _submit();
              },
            ),
            if (_creating) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                key: const Key('parent-pin-confirm'),
                controller: _confirm,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                style: AppText.body,
                decoration: deco.copyWith(labelText: 'Type it again'),
                onSubmitted: (_) => _submit(),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Forgotten it? The Privacy page, under Children, explains '
                  'what to do.',
                  style: AppText.caption,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const Key('parent-pin-error'),
                    style: AppText.caption.copyWith(color: AppColors.gold),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            _creating ? 'Save PIN' : 'Continue',
            style: const TextStyle(color: AppColors.goldLight),
          ),
        ),
      ],
    );
  }
}

/// Show the gate; true when passed. With a [challenge] it is the fixed sum
/// (tests). Otherwise it is the parent PIN, from [pin] or, when not given,
/// the app's own storage; if storage cannot be reached the sum is the fallback.
Future<bool> showParentGate(
  BuildContext context, {
  ParentGateChallenge? challenge,
  ParentPin? pin,
}) async {
  ParentPin? p = pin;
  if (challenge == null && p == null) {
    try {
      final SharedPreferences prefs = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(sharedPreferencesProvider);
      p = ParentPin(prefs);
    } catch (_) {
      p = null;
    }
  }
  final ParentPin? usePin = challenge == null ? p : null;
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => usePin != null
        ? ParentPinDialog(pin: usePin)
        : ParentGateDialog(challenge: challenge),
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
