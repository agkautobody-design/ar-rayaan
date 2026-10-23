import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../application/sakina_providers.dart';
import '../../domain/crisis_detector.dart';
import '../../domain/sakina_content.dart';
import 'help_line_tile.dart';

/// Opens the help sheet: the person's own country first, then the lines that
/// work anywhere. Used on Sakina, Feelings, Notes, Hādi and Elder Care so a
/// person is never more than one tap from a human.
Future<void> showNeedHelpSheet(
  BuildContext context, {
  CrisisKind kind = CrisisKind.selfHarm,
  String? intro,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => _NeedHelpSheet(kind: kind, intro: intro),
  );
}

class _NeedHelpSheet extends ConsumerWidget {
  const _NeedHelpSheet({required this.kind, this.intro});

  final CrisisKind kind;
  final String? intro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? country = ref.watch(deviceCountryProvider);
    final List<HelpResource> rows = CrisisResponses.resourcesFor(
      kind,
      country,
    ).take(6).toList();
    final String? cc = country?.trim().toUpperCase();
    final bool hasLocal = cc != null &&
        cc.isNotEmpty &&
        rows.any((HelpResource r) => r.countries.contains(cc));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('You do not have to carry this alone',
                style: AppText.titleMedium),
            const SizedBox(height: 8),
            Text(
              intro ??
                  'If you are in danger right now, call your local emergency '
                      'number. These lines are free to talk to, and a real '
                      'person answers.',
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            // Honest about where the order comes from: the device language
            // setting, never a guessed or hard-coded place.
            Text(
              !hasLocal
                  ? 'We could not tell which country you are in, so these '
                      'lines work from anywhere. Every country is listed in '
                      'Sakina below.'
                  : 'Lines for the region $cc come first. That comes '
                      'from your device language setting, not your location. '
                      'In another country? Every country is listed in '
                      'Sakina below.',
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            for (final HelpResource r in rows) ...<Widget>[
              HelpLineTile(resource: r),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.sakina);
              },
              child: Text(
                'More help lines, every country (Sakina)',
                style: AppText.caption.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A calm, always-visible button that opens [showNeedHelpSheet].
class NeedHelpNowButton extends StatelessWidget {
  const NeedHelpNowButton({
    super.key,
    this.large = false,
    this.kind = CrisisKind.selfHarm,
    this.label = 'Need help now',
  });

  final bool large;
  final CrisisKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double h = large ? 64 : 48;
    final TextStyle style = (large ? AppText.titleMedium : AppText.caption)
        .copyWith(color: AppColors.night, fontWeight: FontWeight.w700);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showNeedHelpSheet(context, kind: kind),
        child: Container(
          constraints: BoxConstraints(minHeight: h, minWidth: 48),
          padding: EdgeInsets.symmetric(horizontal: large ? 24 : 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.favorite_outline,
                  size: large ? 26 : 16, color: AppColors.night),
              SizedBox(width: large ? 10 : 6),
              // Flexible: at large text the label wraps instead of running
              // off the edge of a narrow phone.
              Flexible(
                child: Text(label, style: style, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
