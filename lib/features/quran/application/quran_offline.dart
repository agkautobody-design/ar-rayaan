/// "Save the Qur'an for offline": fetches the Qur'an's data files into the
/// on-device copy that [ContentLoader] keeps (browser only: the Android and
/// iPhone apps already carry the files, so there is nothing to save there).
///
/// Text only (Arabic, English, transliteration, credits). Recitation audio is
/// streamed and is NOT part of this.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../../../app/core/online_status.dart';

/// Every file the Qur'an reader needs to open with no connection.
const List<String> kQuranOfflineAssets = <String>[
  kQuranAsset,
  'assets/quran/transliteration.json',
  'assets/quran/texts.json',
];

/// Shown under "needs an internet connection" when the text cannot load.
const String kQuranOfflineHint =
    'Open the Qur\u2019an once while online (or use Settings > Save '
    'Qur\u2019an for offline). The app and the saved text then reopen '
    'without internet, as long as this browser keeps this site\u2019s data '
    '(private windows do not).';

/// What a save ended as.
enum QuranSaveResult {
  /// Every file is stored and was read back.
  saved,

  /// The files loaded but the browser would not keep them (private window,
  /// blocked site data, plain http): reading works now, not offline later.
  notKept,

  /// A file could not be fetched (no connection, server error).
  failed,
}

/// Loads each of [keys] with [load] (which stores it on the way) and reports
/// progress after each one. Returns [QuranSaveResult.saved] only when every
/// file reads back as stored afterwards; never claims more than it checked.
Future<QuranSaveResult> saveForOffline(
  List<String> keys, {
  Future<String> Function(String key)? load,
  Future<bool> Function(String key)? isStored,
  void Function(int done, int total)? onProgress,
}) async {
  final Future<String> Function(String) fetch =
      load ?? ContentLoader.loadString;
  final Future<bool> Function(String) stored =
      isStored ?? ContentLoader.isAvailableOffline;
  onProgress?.call(0, keys.length);
  int done = 0;
  for (final String key in keys) {
    try {
      await fetch(key);
    } catch (_) {
      return QuranSaveResult.failed;
    }
    done++;
    onProgress?.call(done, keys.length);
  }
  for (final String key in keys) {
    if (!await stored(key)) return QuranSaveResult.notKept;
  }
  return QuranSaveResult.saved;
}

enum QuranSavePhase { idle, saving, saved, notKept, failed, offline }

class QuranSaveState {
  const QuranSaveState(this.phase, {this.done = 0, this.total = 0});

  final QuranSavePhase phase;
  final int done;
  final int total;

  /// 0..1 while saving; null when there is nothing to measure yet.
  double? get fraction => total == 0 ? null : done / total;
}

class QuranOfflineController extends Notifier<QuranSaveState> {
  @override
  QuranSaveState build() => const QuranSaveState(QuranSavePhase.idle);

  Future<void> save() async {
    if (state.phase == QuranSavePhase.saving) return;
    // Saving fetches the files, so say so up front instead of failing later.
    if (deviceReportsOnline == false) {
      state = const QuranSaveState(QuranSavePhase.offline);
      return;
    }
    state = QuranSaveState(
      QuranSavePhase.saving,
      total: kQuranOfflineAssets.length,
    );
    final QuranSaveResult result = await saveForOffline(
      kQuranOfflineAssets,
      onProgress: (int done, int total) {
        state = QuranSaveState(QuranSavePhase.saving, done: done, total: total);
      },
    );
    state = QuranSaveState(switch (result) {
      QuranSaveResult.saved => QuranSavePhase.saved,
      QuranSaveResult.notKept => QuranSavePhase.notKept,
      QuranSaveResult.failed => QuranSavePhase.failed,
    });
    // The Home tile and the Qur'an screen re-check what is stored.
    ref.invalidate(quranOfflineReadyProvider);
  }
}

final NotifierProvider<QuranOfflineController, QuranSaveState>
quranOfflineSaveProvider =
    NotifierProvider<QuranOfflineController, QuranSaveState>(
      QuranOfflineController.new,
    );

/// Honest wording for each state; [web] picks the browser or phone version.
String quranOfflineMessage(
  QuranSavePhase phase, {
  required bool web,
  required bool alreadyStored,
}) {
  const String audio =
      'Recitation audio still needs internet unless you download it '
      '(Settings > Downloads).';
  if (!web) {
    return 'The whole Qur’an (Arabic, English and transliteration) is '
        'inside this app, so it opens with no internet. $audio';
  }
  switch (phase) {
    case QuranSavePhase.saving:
      return 'Saving the Qur’an to this device… keep this page open.';
    case QuranSavePhase.saved:
      return 'Saved. The Qur’an text now opens in this browser with no '
          'internet, also after you close the tab or reopen the app. '
          '$audio If you clear this site’s data, save it again.';
    case QuranSavePhase.notKept:
      return 'The Qur’an loaded, but this browser would not keep a copy '
          '(private windows and blocked site data often do this). It will '
          'still need internet next time.';
    case QuranSavePhase.failed:
      return 'Could not save it. Saving needs a connection once. Connect, '
          'then try again.';
    case QuranSavePhase.offline:
      return 'You are offline. Connect once to save it.';
    case QuranSavePhase.idle:
      return alreadyStored
          ? 'Saved on this device. The Qur’an text opens in this browser '
                'with no internet. $audio'
          : 'To read with no internet, save the Qur’an to this browser '
                'first (about 2 MB, text only). The app reopens offline once '
                'it has been opened online, as long as this browser keeps '
                'this site’s data (private windows do not). $audio';
  }
}
