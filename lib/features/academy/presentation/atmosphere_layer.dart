/// AtmosphereLayer — renders the resolved atmosphere as a breathing
/// tint beneath a screen's content (over ScenicScaffold, under scrims).
/// Null atmosphere → SizedBox.shrink: zero change to existing screens.
library;

import 'package:flutter/material.dart';

import '../domain/atmosphere.dart';

class AtmosphereLayer extends StatelessWidget {
  const AtmosphereLayer({super.key, required this.emotion, this.child});

  final AtmosphereEmotion? emotion;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (emotion == null) return child ?? const SizedBox.shrink();
    final Atmosphere a = AtmosphereEngine.resolve(
      contentEmotion: emotion,
      now: DateTime.now(),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        if (child != null) child!,
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.5, -0.6),
                radius: 1.3,
                colors: <Color>[
                  Color(a.tint).withValues(alpha: 0.55),
                  Color(a.tint).withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
