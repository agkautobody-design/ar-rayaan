import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/places_providers.dart';
import '../data/community_places_service.dart';
import '../domain/community_place.dart';

/// Report or correct a place or event. Opens as a bottom sheet; submissions
/// go to the founders' queue (one per person per target).
///
/// [targetType] is 'place', 'event' or 'osm' (an OpenStreetMap result, whose
/// id comes from [PlacesPolicy.osmTargetId]).
Future<void> showReportPlaceSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String name,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ReportSheet(targetType: targetType, targetId: targetId, name: name),
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.name,
  });

  final String targetType;
  final String targetId;
  final String name;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String _reason = PlacesPolicy.reportReasons.keys.first;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final CommunityPlacesService? svc =
          ref.read(communityPlacesServiceProvider);
      if (svc == null) throw const PlacesRejected('Not available.');
      await svc.report(
        targetType: widget.targetType,
        targetId: widget.targetId,
        name: widget.name,
        reason: _reason,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Thank you — the founders will look at it.')));
    } on PlacesRejected catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not send the report. You may have already '
              'reported this one.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report or correct',
                style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(widget.name,
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
            const SizedBox(height: 10),
            for (final e in PlacesPolicy.reportReasons.entries)
              RadioListTile<String>(
                key: Key('report-reason-${e.key}'),
                value: e.key,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v ?? _reason),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.gold,
                title: Text(e.value,
                    style: AppText.body.copyWith(fontSize: 13)),
              ),
            Semantics(
              label: 'A short note (optional)',
              child: TextField(
                key: const Key('report-note'),
                controller: _note,
                style: AppText.body,
                maxLines: 2,
                maxLength: PlacesPolicy.reportNoteMax,
                decoration: const InputDecoration(
                  hintText: 'A short note (optional)',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 10),
            GoldButton(
              key: const Key('report-submit'),
              label: _sending ? 'Sending…' : 'Send report',
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
