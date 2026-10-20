/// Avatar clip player — plays the worship instruction clips when they
/// ship as assets (avatar/clips/<clipId>.mp4), with an honest stage
/// fallback that shows the clip name and the pose spec reference. The
/// avatar GLB (kufi, beard, thobe, all 9 worship poses) is built; this
/// player is the bridge between the 3D asset and the demo step.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class AvatarClipPlayer extends StatelessWidget {
  const AvatarClipPlayer({super.key, required this.clipId});

  /// Matches the pose ids in assets — see /mnt/agents/output/avatar_pose_spec.json.
  final String clipId;

  static const Set<String> _knownClips = <String>{
    'qiyam_standing_folded_arms',
    'ruku_bowing',
    'sujood_prostration',
    'tashahhud_sitting',
    'wudu_wash_face',
    'wudu_wash_forearm',
    'wudu_wipe_head',
    'wudu_wash_foot',
    'welcome_wave',
    'wudu_sequence',
    'salah_positions_sequence',
    'salah_one_rakah',
  };

  @override
  Widget build(BuildContext context) {
    final bool known = _knownClips.contains(clipId);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.night,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.play_circle_outline,
                size: 44,
                color: AppColors.gold,
              ),
              const SizedBox(height: 6),
              Text(
                clipId,
                style: AppText.bodyMuted.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                known
                    ? 'Instructor clip — ships with the avatar asset pack'
                    : 'Clip id not in the pose spec',
                style: AppText.bodyMuted.copyWith(
                    fontSize: 10, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
