import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/download_manager.dart';

/// One downloadable pack: name, honest status, progress and the actions that
/// make sense in that state. Pure UI: the screen supplies the callbacks.
class PackRow extends StatelessWidget {
  const PackRow({
    required this.packId,
    required this.title,
    required this.phase,
    required this.status,
    super.key,
    this.subtitle,
    this.fraction,
    this.problem,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
    this.downloadLabel = 'Download',
  });

  final String packId;
  final String title;
  final String? subtitle;
  final PackPhase phase;

  /// The status line, already worded ("Not downloaded · about 12 MB").
  final String status;

  /// 0..1 while there is something to measure.
  final double? fraction;

  /// Why a failed pack stopped.
  final String? problem;
  final VoidCallback? onDownload;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final String downloadLabel;

  Widget _button(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    required String keySuffix,
    bool filled = false,
  }) {
    final ButtonStyle style = (filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.night,
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.gold,
          ));
    final Widget iconW = Icon(icon, size: 18);
    final Key k = Key('pack-$packId-$keySuffix');
    return filled
        ? FilledButton.icon(
            key: k,
            style: style,
            onPressed: onTap,
            icon: iconW,
            label: Text(label),
          )
        : OutlinedButton.icon(
            key: k,
            style: style,
            onPressed: onTap,
            icon: iconW,
            label: Text(label),
          );
  }

  List<Widget> _actions() {
    switch (phase) {
      case PackPhase.notDownloaded:
        return <Widget>[
          _button(
            downloadLabel,
            Icons.download_outlined,
            onDownload,
            keySuffix: 'download',
            filled: true,
          ),
        ];
      case PackPhase.queued:
        return <Widget>[
          _button(
            'Remove from queue',
            Icons.close,
            onCancel,
            keySuffix: 'cancel',
          ),
        ];
      case PackPhase.downloading:
        return <Widget>[
          _button('Pause', Icons.pause, onPause, keySuffix: 'pause'),
        ];
      case PackPhase.paused:
        return <Widget>[
          _button(
            'Resume',
            Icons.play_arrow,
            onResume,
            keySuffix: 'resume',
            filled: true,
          ),
          _button(
            'Remove from queue',
            Icons.close,
            onCancel,
            keySuffix: 'cancel',
          ),
        ];
      case PackPhase.partial:
        return <Widget>[
          _button(
            'Finish download',
            Icons.download_outlined,
            onDownload,
            keySuffix: 'download',
            filled: true,
          ),
          _button(
            'Delete',
            Icons.delete_outline,
            onDelete,
            keySuffix: 'delete',
          ),
        ];
      case PackPhase.failed:
        return <Widget>[
          _button(
            'Try again',
            Icons.refresh,
            onDownload,
            keySuffix: 'retry',
            filled: true,
          ),
          if (onDelete != null)
            _button(
              'Delete',
              Icons.delete_outline,
              onDelete,
              keySuffix: 'delete',
            ),
        ];
      case PackPhase.downloaded:
        return <Widget>[
          _button(
            'Delete',
            Icons.delete_outline,
            onDelete,
            keySuffix: 'delete',
          ),
        ];
      case PackPhase.included:
        return const <Widget>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool done =
        phase == PackPhase.downloaded || phase == PackPhase.included;
    final List<Widget> actions = _actions();
    final double? f = fraction;
    final bool showBar =
        f != null &&
        (phase == PackPhase.downloading ||
            phase == PackPhase.paused ||
            phase == PackPhase.partial ||
            phase == PackPhase.queued);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        key: Key('pack-$packId'),
        blur: false,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    done
                        ? Icons.check_circle_outline
                        : Icons.download_for_offline_outlined,
                    size: 20,
                    color: done ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!, style: AppText.bodyMuted),
                      const SizedBox(height: 2),
                      Semantics(
                        liveRegion: phase == PackPhase.failed,
                        child: Text(status, style: AppText.caption),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showBar) ...<Widget>[
              const SizedBox(height: 10),
              Semantics(
                label: 'Progress for $title',
                value: '${((f ?? 0) * 100).round()} percent',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: f,
                    minHeight: 6,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
              ),
            ],
            if (phase == PackPhase.failed && problem != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                problem!,
                key: Key('pack-$packId-problem'),
                style: AppText.bodyMuted.copyWith(color: AppColors.destructive),
              ),
            ],
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
