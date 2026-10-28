import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/web_offline.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../quran/presentation/reciter_picker.dart';
import '../application/download_manager.dart';
import '../domain/download_catalog.dart';
import 'pack_row.dart';

/// The status line for a recitation pack.
String audioStatusLine(DownloadsState s, AudioPack p) {
  final PackPhase phase = s.audioPhase(p);
  final int done = s.countStored(p.refs);
  final int total = p.refs.length;
  final String size = 'about ${formatBytes(p.estimatedBytes)}';
  switch (phase) {
    case PackPhase.notDownloaded:
      return 'Not downloaded · $size';
    case PackPhase.queued:
      return 'Waiting its turn · $size';
    case PackPhase.downloading:
      return 'Downloading · $done of $total ayahs';
    case PackPhase.paused:
      return 'Paused · $done of $total ayahs saved';
    case PackPhase.partial:
      return 'Partly downloaded · $done of $total ayahs · the rest '
          'still streams';
    case PackPhase.failed:
      return 'Stopped · $done of $total ayahs saved';
    case PackPhase.downloaded:
      return 'On this device · $size';
    case PackPhase.included:
      return 'Inside the app';
  }
}

/// The status line for a text pack.
String textStatusLine(
  DownloadsState s,
  TextPackSpec t, {
  required bool bundled,
}) {
  final PackPhase phase = s.textPhase(t, bundled: bundled);
  final String size = 'about ${formatBytes(t.estimatedBytes)}';
  switch (phase) {
    case PackPhase.included:
      return 'Inside the app · works with no internet';
    case PackPhase.downloaded:
      return 'Saved in this browser · $size';
    case PackPhase.notDownloaded:
      return 'Not saved yet · needs internet to read · $size';
    case PackPhase.queued:
      return 'Waiting its turn · $size';
    case PackPhase.downloading:
      return 'Saving… $size';
    case PackPhase.paused:
      return 'Paused · $size';
    case PackPhase.failed:
      return 'Stopped · not saved';
    case PackPhase.partial:
      return 'Partly saved';
  }
}

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key, this.web});

  /// Forces the browser or phone wording (defaults to the running platform).
  final bool? web;

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    // Look at what is really on the device each time the screen opens.
    Future<void>.microtask(
      () => ref.read(downloadsProvider.notifier).refresh(),
    );
  }

  bool get _web => widget.web ?? WebOffline.isWeb;

  Future<bool> _confirm(String title, String body, String action) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        semanticLabel: title,
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-yes'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _everything() async {
    final DownloadsController c = ref.read(downloadsProvider.notifier);
    final int bytes = c.everythingEstimate();
    final bool wifi =
        ref.read(downloadsProvider).wifiOnly &&
        ref.read(downloadCanDetectWifiProvider);
    final bool ok = await _confirm(
      'Download everything?',
      'This needs about ${formatBytes(bytes)} of free space (an estimate). '
          '${wifi ? 'It downloads on Wi-Fi only. ' : 'Use Wi-Fi if you can. '}'
          'You can pause at any time and delete any download later.',
      'Download',
    );
    if (ok) c.downloadEverything();
  }

  Future<void> _delete(String id, String name) async {
    final bool ok = await _confirm(
      'Delete this download?',
      '$name will be removed from this device. You can download it again '
          'any time. Recitation goes back to streaming.',
      'Delete',
    );
    if (ok) await ref.read(downloadsProvider.notifier).delete(id);
  }

  Widget _audioRow(DownloadsState s, AudioPack p) {
    final DownloadsController c = ref.read(downloadsProvider.notifier);
    final PackPhase phase = s.audioPhase(p);
    final int done = s.countStored(p.refs);
    return PackRow(
      packId: p.id,
      title: p.title,
      phase: phase,
      status: audioStatusLine(s, p),
      fraction: p.refs.isEmpty ? null : done / p.refs.length,
      problem: s.failed[p.id],
      onDownload: () => c.download(p.id),
      onPause: c.pause,
      onResume: c.resume,
      onCancel: () => c.cancel(p.id),
      onDelete: done > 0 ? () => _delete(p.id, p.title) : null,
    );
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
    child: Text(text, style: AppText.eyebrow),
  );

  Widget _group(String title, String subtitle, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        blur: false,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              title,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle, style: AppText.bodyMuted),
            iconColor: AppColors.gold,
            collapsedIconColor: AppColors.gold,
            childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            children: children,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DownloadsState s = ref.watch(downloadsProvider);
    final DownloadsController c = ref.read(downloadsProvider.notifier);
    final bool bundled = ref.watch(downloadTextBundledProvider);
    final bool canWifi = ref.watch(downloadCanDetectWifiProvider);
    final AudioCatalog catalog = AudioCatalog.of(s.reciter);
    final int estimate = c.everythingEstimate();
    final bool active = s.queue.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Downloads', close: true),
              GlassCard(
                blur: false,
                child: Text(
                  _web
                      ? 'In a browser, downloads are kept in this browser’s '
                            'storage. Once you have opened the app online, '
                            'this browser also keeps a copy of the app itself, '
                            'so it can reopen with no internet (not in a '
                            'private window, and not after you clear this '
                            'site’s data). Saved recitation and text then '
                            'work too; anything you have not opened or saved '
                            'still needs a connection. The Android app keeps '
                            'everything on the phone and opens with no '
                            'internet.'
                      : 'The Qur’an text, stories, guides and duas are '
                            'already inside this app and work with no internet. '
                            'Recitation audio can be downloaded to this phone '
                            'below.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                blur: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Download everything',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estimate == 0
                          ? 'Everything below is already on this device.'
                          : 'Still to download: about ${formatBytes(estimate)} '
                                '(an estimate). Check your free space first.',
                      key: const Key('downloads-estimate'),
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          key: const Key('download-everything'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.night,
                          ),
                          onPressed: estimate == 0 || (active && !s.paused)
                              ? null
                              : _everything,
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Download everything'),
                        ),
                        if (active)
                          OutlinedButton.icon(
                            key: const Key('downloads-pause-resume'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: AppColors.gold,
                            ),
                            onPressed: s.paused ? c.resume : c.pause,
                            icon: Icon(
                              s.paused ? Icons.play_arrow : Icons.pause,
                              size: 18,
                            ),
                            label: Text(s.paused ? 'Resume' : 'Pause all'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      key: const Key('downloads-wifi-only'),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.gold,
                      title: Text('Wi-Fi only', style: AppText.body),
                      subtitle: Text(
                        canWifi
                            ? 'Downloads wait for Wi-Fi so they do not use '
                                  'mobile data. The phone only guesses which '
                                  'network it is on, so check before a big '
                                  'download.'
                            : 'A browser cannot tell Wi-Fi from mobile data, '
                                  'so this only works in the Android app. '
                                  'Downloads here are large: use Wi-Fi.',
                        style: AppText.bodyMuted,
                      ),
                      value: canWifi && s.wifiOnly,
                      onChanged: canWifi ? c.setWifiOnly : null,
                    ),
                    if (s.banner != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            s.banner!,
                            key: const Key('downloads-banner'),
                            style: AppText.body.copyWith(
                              color: AppColors.goldLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _section('WORKS WITHOUT INTERNET'),
              GlassCard(
                key: const Key('downloads-offline-status'),
                blur: false,
                padding: const EdgeInsets.all(14),
                child: Text(
                  kOfflineStatusNote,
                  style: AppText.bodyMuted.copyWith(height: 1.55),
                ),
              ),
              _section('QUR’AN RECITATION'),
              GlassCard(
                blur: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.reciter.displayName,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Downloads are for this reciter only. Real recorded '
                      'recitation from everyayah.com, the same source the '
                      'reader streams from. A downloaded ayah plays with no '
                      'internet.',
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('downloads-change-reciter'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: AppColors.gold,
                      ),
                      onPressed: () => showReciterPicker(context, ref),
                      icon: const Icon(
                        Icons.record_voice_over_outlined,
                        size: 18,
                      ),
                      label: const Text('Change reciter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!s.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Checking what is already on this device\u2026',
                    style: AppText.caption,
                  ),
                ),
              _audioRow(s, catalog.all),
              _group('By juz', '30 parts', <Widget>[
                for (final AudioPack p in catalog.juz) _audioRow(s, p),
              ]),
              _group('By surah', '114 surahs', <Widget>[
                for (final AudioPack p in catalog.surahs) _audioRow(s, p),
              ]),
              _section(
                bundled ? 'TEXT — ALREADY IN THE APP' : 'TEXT — READ OFFLINE',
              ),
              if (!bundled && c.allTextEstimate() > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      key: const Key('download-all-text'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.night,
                      ),
                      onPressed: c.downloadAllText,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: Text(
                        'Save all text (about '
                        '${formatBytes(c.allTextEstimate())})',
                      ),
                    ),
                  ),
                ),
              for (final TextPackSpec t in kTextPackSpecs)
                PackRow(
                  packId: t.id,
                  title: t.title,
                  subtitle: t.subtitle,
                  phase: s.textPhase(t, bundled: bundled),
                  status: textStatusLine(s, t, bundled: bundled),
                  fraction: s.textProgress[t.id],
                  problem: s.failed[t.id],
                  downloadLabel: 'Save for offline',
                  onDownload: () => c.download(t.id),
                  onPause: c.pause,
                  onResume: c.resume,
                  onCancel: () => c.cancel(t.id),
                  onDelete: () => _delete(t.id, t.title),
                ),
              _section('NASHEEDS AND OTHER AUDIO'),
              GlassCard(
                key: const Key('downloads-nasheed-note'),
                blur: false,
                child: Text(
                  kNasheedNoDownloadNote,
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              _section('HANDOUTS'),
              GlassCard(
                blur: false,
                child: Text(
                  _web
                      ? 'Open a story or lesson, tap “Make a handout”, '
                            'then Print, or Save to device to keep it as a '
                            'file you can open later.'
                      : 'Open a story or lesson, tap “Make a handout”, '
                            'then Copy and paste it into any document. Saving '
                            'a handout as a file is available on the web '
                            'version.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
