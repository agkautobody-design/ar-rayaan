import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../auth/application/auth_providers.dart';
import '../application/places_providers.dart';
import '../data/community_places_service.dart';
import '../domain/jumuah_time.dart';

/// The Jumu'ah line on a masjid card: the time when one is known, and where
/// it is not, a button to add it for everyone.
///
/// [masjidKey] is [PlacesPolicy.osmTargetId] for a map result or the place
/// id for a community masjid. [mapTime] is the raw Friday rule from open map
/// data, if the mapper filled it in.
class JumuahLine extends ConsumerWidget {
  const JumuahLine({
    super.key,
    required this.masjidKey,
    required this.name,
    this.mapTime,
  });

  final String masjidKey;
  final String name;
  final String? mapTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(communityPlacesEnabledProvider);
    final JumuahEntry? entry =
        ref.watch(jumuahTimesProvider).valueOrNull?[masjidKey];
    final String? time = entry?.text ?? mapTime;
    final String source = entry != null
        ? 'added by a community member'
        : 'from open map data';
    final TextStyle gold = AppText.body.copyWith(
        color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(children: [
        const Icon(Icons.access_time, size: 15, color: AppColors.gold),
        const SizedBox(width: 6),
        Expanded(
          child: time != null
              ? Text.rich(TextSpan(children: [
                  TextSpan(text: 'Jumu’ah: $time', style: gold),
                  TextSpan(
                      text: '  · $source — confirm with the masjid',
                      style: AppText.bodyMuted.copyWith(fontSize: 12)),
                ]))
              : Text('Jumu’ah time not listed',
                  key: const Key('jumuah-not-listed'),
                  style: AppText.bodyMuted.copyWith(fontSize: 12.5)),
        ),
        if (enabled)
          TextButton(
            key: const Key('jumuah-add'),
            onPressed: () =>
                showAddJumuahSheet(context, masjidKey: masjidKey, name: name),
            child: Text(time == null ? 'Add time' : 'Update',
                style: const TextStyle(color: AppColors.goldLight, fontSize: 12)),
          ),
      ]),
    );
  }
}

Future<void> showAddJumuahSheet(
  BuildContext context, {
  required String masjidKey,
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddJumuahSheet(masjidKey: masjidKey, name: name),
    ),
  );
}

class _AddJumuahSheet extends ConsumerStatefulWidget {
  const _AddJumuahSheet({required this.masjidKey, required this.name});
  final String masjidKey;
  final String name;

  @override
  ConsumerState<_AddJumuahSheet> createState() => _AddJumuahSheetState();
}

class _AddJumuahSheetState extends ConsumerState<_AddJumuahSheet> {
  final TextEditingController _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (ref.read(authStateProvider).value == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Sign in with an account to add a time.')));
      return;
    }
    final String? problem = JumuahPolicy.validate(_text.text);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _sending = true);
    try {
      final CommunityPlacesService? svc =
          ref.read(communityPlacesServiceProvider);
      if (svc == null) throw const PlacesRejected('Not available.');
      await svc.submitJumuah(key: widget.masjidKey, text: _text.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Thank you — the time now shows for everyone.')));
    } on PlacesRejected catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save that. Check your connection.')));
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
            Text('Jumu’ah time',
                style: AppText.body
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(widget.name, style: AppText.bodyMuted.copyWith(fontSize: 12)),
            const SizedBox(height: 10),
            Semantics(
              label: 'Jumuah time',
              child: TextField(
                key: const Key('jumuah-text'),
                controller: _text,
                style: AppText.body,
                maxLength: JumuahPolicy.textMax,
                decoration: const InputDecoration(
                  hintText: 'e.g. 1:30 PM, or 1:00 PM and 2:00 PM',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only add a time you know from the masjid itself. It shows for '
              'everyone as added by a community member.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 10),
            GoldButton(
              key: const Key('jumuah-submit'),
              label: _sending ? 'Saving…' : 'Save time',
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
