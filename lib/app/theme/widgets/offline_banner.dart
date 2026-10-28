import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart' hide Text;
import 'tr_text.dart';

import '../../core/online_status.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import 'announce.dart';
import 'focus_ring.dart';
import 'focus_safe_semantics.dart';

/// A slim notice at the top of every screen while the browser reports that
/// the device is offline, saying what still works. It takes no space while
/// online, and never appears in the phone apps (where nothing needs a
/// connection to open).
///
/// What it lists is only what has been checked to work with no connection:
/// the prayer times and Qibla (calculated on the device), the Academy lessons
/// and Hadi's built-in library are part of the app; the Qur'an and the other
/// saved items work only if they were saved in Settings > Downloads.
/// What the notice says (also its spoken text).
const String kOfflineBannerText =
    'You are offline. Prayer times, Qibla, the Academy lessons, Hadi\u2019s '
    'built-in library and anything you saved in Settings > Downloads still '
    'work.';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({required this.child, this.probe, this.changes, super.key});

  final Widget child;

  /// Test hooks; default to the browser's flag and events.
  final bool? Function()? probe;
  final Stream<bool> Function()? changes;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;
  bool _dismissed = false;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    final bool? now = (widget.probe ?? () => deviceReportsOnline)();
    _offline = now == false;
    try {
      _sub = (widget.changes ?? deviceOnlineChanges)().listen((bool online) {
        if (!mounted) return;
        setState(() {
          _offline = !online;
          // A new loss of connection shows the notice again.
          if (online) _dismissed = false;
        });
      });
    } catch (_) {
      // No events here: the first reading stands.
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool show = _offline && !_dismissed;
    return Column(
      children: <Widget>[
        if (show)
          Material(
            color: const Color(0xFF1B2A3A),
            child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
                child: Row(
                  key: const Key('offline-banner'),
                  children: <Widget>[
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 18,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 10),
                    // A status message: one labelled node in the semantics
                    // tree (role status, a live region), so a screen reader
                    // finds the words by reading the page and hears them
                    // when the notice appears. The visible words are hidden
                    // from the reader so they are not said twice. The words
                    // are also sent as an announcement.
                    Expanded(
                      child: Announce(
                        message: kOfflineBannerText,
                        child: Semantics(
                          key: const Key('offline-banner-message'),
                          role: SemanticsRole.status,
                          liveRegion: true,
                          container: true,
                          label: kOfflineBannerText,
                          child: ExcludeSemantics(
                            child: Text(
                              kOfflineBannerText,
                              style: AppText.caption.copyWith(height: 1.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // No Tooltip here: this sits above the Navigator, so
                    // there is no Overlay for one to use.
                    FocusSafeSemantics(
                      button: true,
                      label: 'Hide this notice',
                      excludeSemantics: true,
                      onTap: () => setState(() => _dismissed = true),
                      child: FocusableTap(
                        key: const Key('offline-banner-close'),
                        borderRadius: 22,
                        onTap: () => setState(() => _dismissed = true),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
        // Keyed so the app underneath is never rebuilt from scratch when the
        // notice appears or goes.
        Expanded(key: const ValueKey<String>('app-content'), child: widget.child),
      ],
    );
  }
}
