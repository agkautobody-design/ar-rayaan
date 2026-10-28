import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../sakina/application/sakina_providers.dart';
import '../../sakina/domain/sakina_content.dart';
import '../../sakina/presentation/widgets/help_line_tile.dart';
import '../../hadi/application/hadi_controller.dart';
import '../data/helplines_loader.dart';
import '../data/pack_repository.dart';
import '../domain/checkin_scheduler.dart';
import '../domain/support_pack.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// The gentle check-in answers: three choices and a small "Don't ask me
/// again". Plain words, large targets, no guilt.
class CheckinChips extends StatelessWidget {
  const CheckinChips({required this.onOkay, required this.onHard, required this.onRather, required this.onStop, super.key});

  final VoidCallback onOkay;
  final VoidCallback onHard;
  final VoidCallback onRather;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String label, VoidCallback f) => OutlinedButton(
          key: Key(key),
          onPressed: f,
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(label),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              chip('checkin-okay', 'I’m okay', onOkay),
              chip('checkin-hard', 'It’s been hard lately', onHard),
              chip('checkin-rather', 'I’d rather not say', onRather),
            ],
          ),
          TextButton(
            key: const Key('checkin-stop'),
            onPressed: onStop,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48), alignment: AlignmentDirectional.centerStart),
            child: Text(
              'Don’t ask me again',
              style: AppText.caption.copyWith(color: AppColors.textFaint, fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

/// "How I know this": the sources, the review state and the pack version of
/// the wording a reply was built from.
class SupportProvenanceButton extends StatelessWidget {
  const SupportProvenanceButton({required this.ids, super.key});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    return TextButton(
      key: const Key('support-provenance'),
      onPressed: () => showNamedSheet<void>(
        label: 'How I know this',
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.night,
        builder: (BuildContext c) => SupportProvenanceSheet(ids: ids),
      ),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), alignment: AlignmentDirectional.centerStart),
      child: Text('How I know this',
          style: AppText.caption.copyWith(color: AppColors.textFaint, fontSize: 12, decoration: TextDecoration.underline)),
    );
  }
}

class SupportProvenanceSheet extends StatelessWidget {
  const SupportProvenanceSheet({required this.ids, super.key});

  final List<String> ids;

  static String describeSource(Map<String, dynamic> s) {
    final String type = (s['type'] ?? '').toString();
    switch (type) {
      case 'quran':
        return 'Qur’an ${s['ref']}';
      case 'hadith':
        return '${(s['ref'] ?? '').toString().replaceFirst(':', ' ')}, ${s['grade'] ?? 'grade not stated'}';
      default:
        final String t = (s['title'] ?? s['note'] ?? s['section'] ?? type).toString();
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (final String id in ids) {
      for (final SupportPack p in SupportPackRepository.packs) {
        for (final SupportSnippet s in p.snippets) {
          if (s.id != id) continue;
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Wording from the "${p.name}" pack, version ${p.version}', style: AppText.caption),
                Text(
                  s.shippable
                      ? 'Reviewed and approved.'
                      : 'Not yet reviewed. ${s.needsScholarReview ? 'Scholar review needed. ' : ''}${s.needsClinicianReview ? 'Clinician review needed.' : ''}',
                  style: AppText.bodyMuted.copyWith(fontSize: 13),
                ),
                if (s.sources.isEmpty)
                  Text('This line is plain wording, not a factual claim.', style: AppText.bodyMuted.copyWith(fontSize: 13))
                else
                  for (final Map<String, dynamic> src in s.sources)
                    Text('• ${describeSource(src)}', style: AppText.bodyMuted.copyWith(fontSize: 13)),
              ],
            ),
          ));
        }
      }
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
                child: const Text('Close'),
              ),
            ),
            Text('How I know this', style: AppText.titleMedium),
            const SizedBox(height: 8),
            if (rows.isEmpty) Text('No details are available for this reply.', style: AppText.bodyMuted) else ...rows,
          ],
        ),
      ),
    );
  }
}

/// The verified help lines for a support [scope], under a reply.
class SupportHelpLines extends ConsumerWidget {
  const SupportHelpLines({required this.scope, super.key});

  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? country = ref.watch(helpCountryProvider);
    final List<HelpResource> rows = HelplinesLoader.forScope(scope, country).take(4).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('People who can help', style: AppText.caption),
          const SizedBox(height: 4),
          for (final HelpResource r in rows) ...<Widget>[
            HelpLineTile(resource: r),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// The check-in answers wired to Hadi.
class CheckinPanel extends ConsumerWidget {
  const CheckinPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HadiController c = ref.read(hadiControllerProvider.notifier);
    return CheckinChips(
      onOkay: () => c.answerCheckin(CheckinAnswer.okay),
      onHard: () => c.answerCheckin(CheckinAnswer.hard),
      onRather: () => c.answerCheckin(CheckinAnswer.rather),
      onStop: c.stopCheckins,
    );
  }
}
