import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../domain/zakat_history.dart';

/// Saved calculations, newest first, on this device only.
class ZakatHistoryController extends Notifier<List<ZakatRecord>> {
  static const String _key = 'ar.zakat.history.v1';

  @override
  List<ZakatRecord> build() {
    try {
      return ZakatHistory.decode(
        ref.watch(sharedPreferencesProvider).getString(_key),
      );
    } catch (_) {
      return <ZakatRecord>[];
    }
  }

  Future<void> save(ZakatRecord record) async {
    state = ZakatHistory.add(state, record);
    await _persist();
  }

  Future<void> remove(ZakatRecord record) async {
    state = <ZakatRecord>[
      for (final ZakatRecord r in state)
        if (r.date != record.date) r,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_key, ZakatHistory.encode(state));
    } catch (_) {
      // Kept in memory for this session.
    }
  }
}

final NotifierProvider<ZakatHistoryController, List<ZakatRecord>>
zakatHistoryProvider =
    NotifierProvider<ZakatHistoryController, List<ZakatRecord>>(
      ZakatHistoryController.new,
    );
