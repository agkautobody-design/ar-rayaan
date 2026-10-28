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
  bool showSakinaLink = true,
  bool child = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => _NeedHelpSheet(
          kind: kind,
          intro: intro,
          showSakinaLink: showSakinaLink,
          child: child,
        ),
  );
}

/// The countries that have at least one specific help line, as
/// (code, name) pairs sorted by name. The name is the `region` written on the
/// country's own rows (never a guess); a row shared by several countries
/// (for example "North America") does not name any of them.
List<(String, String)> helpCountryChoices() {
  final Map<String, String> names = <String, String>{};
  for (final HelpResource r in HelpResources.shown) {
    if (r.countries.length != 1) continue;
    final String cc = r.countries.first;
    final String? have = names[cc];
    if (have == null || r.region.length < have.length) names[cc] = r.region;
  }
  final List<(String, String)> out = <(String, String)>[
    for (final MapEntry<String, String> e in names.entries) (e.key, e.value),
  ]..sort(((String, String) a, (String, String) b) => a.$2.compareTo(b.$2));
  return out;
}

class _NeedHelpSheet extends ConsumerStatefulWidget {
  const _NeedHelpSheet({
    required this.kind,
    this.intro,
    this.showSakinaLink = true,
    this.child = false,
  });

  final CrisisKind kind;
  final String? intro;

  /// True when a child is asking: child lines first, and always included.
  final bool child;

  /// False inside Kids / child mode, where the Sakina section is closed.
  final bool showSakinaLink;

  @override
  ConsumerState<_NeedHelpSheet> createState() => _NeedHelpSheetState();
}

class _NeedHelpSheetState extends ConsumerState<_NeedHelpSheet> {
  @override
  Widget build(BuildContext context) {
    // The country the person picked here (kept for the whole visit, so a
    // crisis card shown afterwards agrees) wins over the device language.
    final String? picked = ref.watch(pickedHelpCountryProvider);
    final String? country = ref.watch(helpCountryProvider);
    final List<HelpResource> rows = CrisisResponses.resourcesFor(
      widget.kind,
      country,
      child: widget.child,
    ).take(6).toList();
    final String? cc = country?.trim().toUpperCase();
    // The general sheet also lists the lines for someone at home who hurts or
    // frightens the person (a women's or family-violence line), because a
    // person in that danger does not always say so in words.
    final Set<String> shownKeys = <String>{
      for (final HelpResource r in rows) '${r.dial ?? r.url ?? r.contact}',
    };
    final List<HelpResource> danger = widget.kind == CrisisKind.selfHarm &&
            !widget.child
        ? <HelpResource>[
            for (final HelpResource r
                in CrisisResponses.resourcesFor(CrisisKind.abuse, country))
              if (r.kinds.contains(HelpKind.abuse) &&
                  !r.kinds.contains(HelpKind.emergency) &&
                  shownKeys.add('${r.dial ?? r.url ?? r.contact}'))
                r,
          ].take(3).toList()
        : const <HelpResource>[];
    final bool hasLocal = cc != null &&
        cc.isNotEmpty &&
        rows.any((HelpResource r) => r.countries.contains(cc));
    final List<(String, String)> choices = helpCountryChoices();
    final bool pickedKnown =
        cc != null && choices.any(((String, String) c) => c.$1 == cc);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // A visible way out: a phone has no Escape key.
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('need-help-close'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                label: const Text('Close'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  minimumSize: const Size(96, 48),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('You do not have to carry this alone',
                style: AppText.titleMedium),
            const SizedBox(height: 8),
            Text(
              widget.intro ??
                  'If you are in danger right now, call your local emergency '
                      'number. These lines are free to talk to, and a real '
                      'person answers.',
              style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            // Honest about where the order comes from: the device language
            // setting or the country picked here, never a guessed place.
            Text(
              picked != null
                  ? (hasLocal
                      ? 'Lines for the country you picked come first.'
                      : 'There are no lines saved for that country yet, so '
                          'these work from anywhere.')
                  : (!hasLocal
                      ? 'We could not tell which country you are in, so '
                          'these lines work from anywhere.'
                      : 'Lines for the region $cc come first. That comes '
                          'from your device language setting, not your '
                          'location.'),
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text('Not your country? Choose yours:', style: AppText.caption),
            const SizedBox(height: 4),
            DropdownButton<String>(
              key: const Key('need-help-country'),
              isExpanded: true,
              dropdownColor: AppColors.night,
              hint: const Text('Choose your country'),
              value: pickedKnown ? cc : null,
              items: <DropdownMenuItem<String>>[
                for (final (String code, String name) in choices)
                  DropdownMenuItem<String>(
                    value: code,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (String? v) {
                if (v != null) {
                  ref.read(pickedHelpCountryProvider.notifier).state = v;
                }
              },
            ),
            const SizedBox(height: 10),
            for (final HelpResource r in rows) ...<Widget>[
              HelpLineTile(resource: r),
              const SizedBox(height: 8),
            ],
            if (danger.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'If someone at home hurts, threatens or frightens you',
                key: const Key('need-help-danger-heading'),
                style: AppText.caption.copyWith(
                  color: AppColors.sand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final HelpResource r in danger) ...<Widget>[
                HelpLineTile(resource: r),
                const SizedBox(height: 8),
              ],
            ],
            if (!hasLocal) ...<Widget>[
              Text(
                'Find your local emergency number and keep it close. The '
                'directory at findahelpline.com lists lines by country.',
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
            if (widget.showSakinaLink)
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
    this.showSakinaLink = true,
    this.forChild = false,
  });

  final bool large;
  final CrisisKind kind;
  final String label;
  final bool showSakinaLink;

  /// True inside child mode and Wasia: the sheet lists child lines first.
  final bool forChild;

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
        onTap: () => showNeedHelpSheet(
          context,
          kind: kind,
          showSakinaLink: showSakinaLink,
          child: forChild,
        ),
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
