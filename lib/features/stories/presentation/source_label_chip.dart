import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../domain/story.dart';

/// Small pill showing a story's (or a chapter's) honesty label. Gold for
/// Established, sand for everything weaker. Long labels wrap to two lines
/// instead of overflowing the row.
class SourceLabelChip extends StatelessWidget {
  final String label;
  const SourceLabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final established = label == kLabelEstablished;
    final unverified = isUnverifiedLabel(label);
    final String meaning = storyLabelMeaning(label);
    final Widget chip = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (established
                    ? AppColors.gold
                    : unverified
                        ? Colors.orangeAccent
                        : AppColors.sand)
                .withValues(alpha: unverified ? 0.8 : 0.4),
          ),
        ),
        child: Text(
          storyLabelDisplay(label),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.4,
            color: established
                ? AppColors.goldLight
                : unverified
                    ? Colors.orangeAccent
                    : AppColors.sand,
          ),
        ),
      ),
    );
    // Hover (web) or long-press (phone) says what the label means.
    return meaning.isEmpty ? chip : Tooltip(message: meaning, child: chip);
  }
}

/// The label plus one sentence saying what it means. Shown in the reader
/// whenever a label is weaker than Established, so the reader knows how far
/// to lean on what follows.
class SourceLabelNote extends StatelessWidget {
  final String label;
  final String? prefix;
  const SourceLabelNote({super.key, required this.label, this.prefix});

  @override
  Widget build(BuildContext context) {
    final meaning = storyLabelMeaning(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SourceLabelChip(label: label),
          if (meaning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              prefix == null ? meaning : '$prefix $meaning',
              style: AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
