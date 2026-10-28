import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../academy/application/child_age_band.dart';
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
  /// The parent-set age band of the child using the phone ('5-8', '9-12',
  /// '13-17'). Read only to decide which lines a child is shown. Null until
  /// read, and for an adult.
  String? _band;

  @override
  void initState() {
    super.initState();
    if (widget.child) {
      ChildAgeBand.active().then((String b) {
        if (mounted) setState(() => _band = b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The country the person picked here (kept for the whole visit, so a
    // crisis card shown afterwards agrees) wins over the device language.
    final String? picked = ref.watch(pickedHelpCountryProvider);
    final String? country = ref.watch(helpCountryProvider);
    // A child sees the child lines first. Until the band is read, the
    // youngest band's list is used, so an adult line is never flashed to a
    // small child.
    final String? band = widget.child ? (_band ?? '5-8') : null;
    List<HelpResource> ordered = CrisisResponses.resourcesFor(
      widget.kind,
      country,
      child: widget.child,
      band: band,
    );
    if (!widget.child) {
      // An adult in danger sees the emergency number first (911 in the
      // United States); the order inside each group is unchanged.
      ordered = <HelpResource>[
        for (final HelpResource r in ordered)
          if (r.kinds.contains(HelpKind.emergency)) r,
        for (final HelpResource r in ordered)
          if (!r.kinds.contains(HelpKind.emergency)) r,
      ];
    }
    // A child aged 5 to 8 is shown lines a grown-up can call with them (a
    // phone number), plus one directory; text-only and chat-only lines are
    // left to the older bands. (SAFEGUARDING REVIEW NEEDED.)
    final bool youngest = widget.child && band == '5-8';
    if (youngest) {
      bool directory = false;
      ordered = <HelpResource>[
        for (final HelpResource r in ordered)
          if (r.dial != null)
            r
          else if (r.url != null && !directory && (directory = true))
            r,
      ];
    }
    final List<HelpResource> rows = ordered.take(6).toList();
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
    // A child who is very sad, or thinking of hurting themselves, is also
    // shown the crisis and text lines for their country (988 and the Crisis
    // Text Line in the United States, 9-8-8 in Canada), once, under their own
    // heading. A kind that already lists them (self-harm) does not repeat them.
    final List<HelpResource> distress = widget.child
        ? <HelpResource>[
            for (final HelpResource r in CrisisResponses.resourcesFor(
              CrisisKind.selfHarm,
              country,
              child: true,
              band: band,
            ))
              if (r.kinds.contains(HelpKind.suicide) &&
                  (!youngest || r.dial != null) &&
                  !r.kinds.contains(HelpKind.emergency) &&
                  !r.kinds.contains(HelpKind.child) &&
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
                  (youngest
                      ? 'If you are scared or hurt, tell a grown-up near you '
                          'right now. A grown-up can call these numbers with '
                          'you, and a real person answers.'
                      : (widget.child && band == '9-12')
                          ? 'If you are in danger, tell a grown-up near you, '
                              'or call the emergency number. These lines are '
                              'for children, and a real person answers.'
                          : (widget.child
                              ? 'If you are in danger right now, call your '
                                  'local emergency number. These lines are '
                                  'for young people, and a real person '
                                  'answers.'
                              : 'If you are in danger right now, call your '
                                  'local emergency number. These lines are '
                                  'free to talk to, and a real person '
                                  'answers.')),
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
                  : (cc == null || !pickedKnown
                      ? 'We could not tell which country you are in, so '
                          'these lines work from anywhere.'
                      : (hasLocal
                          ? 'Lines for the region $cc come first. That comes '
                              'from your device language setting, not your '
                              'location.'
                          : 'We have no checked line of this kind saved for '
                              '${choices.firstWhere(((String, String) c) => c.$1 == cc).$2} '
                              'yet, so these lines work from anywhere. '
                              'Choose another country below if that is '
                              'wrong.')),
              style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
            ),
            const NativeReviewNote(safety: true),
            const SizedBox(height: 10),
            Text('Not your country? Choose yours:', style: AppText.caption),
            const SizedBox(height: 4),
            DropdownButton<String>(
              key: const Key('need-help-country'),
              isExpanded: true,
              dropdownColor: AppColors.night,
              hint: const Text('Choose your country'),
              // Only a country the person chose is shown as chosen; one taken from
              // the device language is not pre-selected, so the note above and
              // the box never disagree.
              value: (picked != null && choices.any(((String, String) c) => c.$1 == picked.trim().toUpperCase())) ? picked.trim().toUpperCase() : null,
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
            if (distress.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                youngest
                    ? 'If you feel very sad, ask a grown-up to call with you'
                    : 'If you feel very sad, or you want to hurt yourself',
                key: const Key('need-help-distress-heading'),
                style: AppText.caption.copyWith(
                  color: AppColors.sand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final HelpResource r in distress) ...<Widget>[
                HelpLineTile(resource: r),
                const SizedBox(height: 8),
              ],
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
