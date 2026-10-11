/// Request-a-nasheed screen (1b.4).
/// No backend: the request is composed as honest text the user sends
/// through any channel. Requests are reviewed before anything enters
/// the official catalog; personal imports belong in My Additions.
/// Design: locked glass-card grammar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/nasheed_request_provider.dart';
import '../domain/nasheed_request.dart';

class RequestNasheedScreen extends ConsumerStatefulWidget {
  const RequestNasheedScreen({super.key});

  @override
  ConsumerState<RequestNasheedScreen> createState() =>
      _RequestNasheedScreenState();
}

class _RequestNasheedScreenState extends ConsumerState<RequestNasheedScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _artist = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _url.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    await ref.read(nasheedRequestProvider.notifier).add(
          title: _title.text,
          artist: _artist.text,
          url: _url.text,
          note: _note.text,
        );
    _title.clear();
    _artist.clear();
    _url.clear();
    _note.clear();
    setState(() => _sent = true);
  }

  Future<void> _send(NasheedRequest r) async {
    if (kRequestChannelEmail.isNotEmpty) {
      final Uri mail = Uri(
        scheme: 'mailto',
        path: kRequestChannelEmail,
        query: 'subject=${Uri.encodeComponent('Nasheed request: ${r.title}')}'
            '&body=${Uri.encodeComponent(r.shareText)}',
      );
      await launchUrl(mail);
    } else {
      await Clipboard.setData(ClipboardData(text: r.shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request copied — paste it to the founder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NasheedRequest> requests = ref.watch(nasheedRequestProvider);

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Request a Nasheed'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Ask for the catalog', style: AppText.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Requests are reviewed before anything enters the '
                      'official catalog. Your own files belong in My Additions.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _title,
                      style: AppText.body,
                      onChanged: (_) {
                        if (_sent) setState(() => _sent = false);
                      },
                      decoration:
                          const InputDecoration(labelText: 'Title *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _artist,
                      style: AppText.body,
                      decoration: const InputDecoration(labelText: 'Artist'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _url,
                      style: AppText.body,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'Link (https://…)', hintText: 'optional'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _note,
                      style: AppText.body,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold),
                      onPressed: _submit,
                      child: Text('Send request',
                          style: AppText.titleMedium
                              .copyWith(color: AppColors.navy)),
                    ),
                    if (_sent) ...<Widget>[
                      const SizedBox(height: 8),
                      Text('Request saved — send it with the button below.',
                          style: AppText.bodyMuted),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (requests.isEmpty)
                GlassCard(
                  child: Text(
                    'No requests yet. Something missing from the catalog? '
                    'Ask — the Player grows by request.',
                    style: AppText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...requests.map((NasheedRequest r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: Material(
              color: Colors.transparent,
              child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(r.title, style: AppText.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (r.artist != null)
                                Text(r.artist!, style: AppText.bodyMuted),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Pending review',
                                    style: AppText.bodyMuted
                                        .copyWith(fontSize: 11)),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.send_outlined,
                                    color: AppColors.gold),
                                onPressed: () => _send(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.gold),
                                onPressed: () => ref
                                    .read(nasheedRequestProvider.notifier)
                                    .remove(r.id),
                              ),
                            ],
                          ),
                        )),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
