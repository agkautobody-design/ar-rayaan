import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/secret_store.dart';
import '../domain/checkin_scheduler.dart';
import '../domain/user_memory.dart';

/// Where each setting lives. All of these stay on the device; none is sent
/// to analytics. Every default is the private one.
abstract final class SupportKeys {
  static const String checkinOff = 'ar.support.checkin_off';
  static const String checkinFreq = 'ar.support.checkin_freq';
  static const String checkinLast = 'ar.support.checkin_last';
  static const String checkinNext = 'ar.support.checkin_next';
  static const String wasiaCheckinPrefix = 'ar.support.wasia_checkin.';
  static const String remember = 'ar.support.remember';
  static const String onlineModel = 'ar.support.online_model';
  static const String privateMode = 'ar.support.private_mode';
  static const String quickExit = 'ar.support.quick_exit';
  static const String quickExitLeft = 'ar.support.quick_exit_left';
  static const String language = 'ar.support.language';
  static const String showSakina = 'ar.support.show_sakina';
  static const String tone = 'ar.support.tone';
  static const String childBandPrefix = 'ar.support.child_band.';

  /// Held in the secure store, not in preferences.
  static const String safeWordSecret = 'ar.support.safe_word';
  static const String memorySecret = 'ar.support.memory';
}

/// The languages support lines may be shown in, in the order they are built
/// and reviewed: English first, then Arabic, Urdu, Bangla.
const List<String> kSupportLanguages = <String>['en', 'ar', 'ur', 'bn'];

class SupportSettings {
  const SupportSettings({
    this.checkin = const CheckinState(),
    this.remember = false,
    this.onlineModel = false,
    this.privateMode = false,
    this.quickExit = true,
    this.quickExitLeft = false,
    this.language = 'en',
    this.showSakina = true,
    this.tone = 'auto',
  });

  final CheckinState checkin;

  /// "Let Hadi remember things I tell it": off until the person turns it on.
  final bool remember;

  /// "Use the online model for support chats": off until the person turns it
  /// on after reading what is sent.
  final bool onlineModel;

  /// No history, a neutral label and screen when the app resumes, and no
  /// notification content.
  final bool privateMode;
  final bool quickExit;
  final bool quickExitLeft;
  final String language;
  final bool showSakina;
  final String tone;

  SupportSettings copy({
    CheckinState? checkin,
    bool? remember,
    bool? onlineModel,
    bool? privateMode,
    bool? quickExit,
    bool? quickExitLeft,
    String? language,
    bool? showSakina,
    String? tone,
  }) =>
      SupportSettings(
        checkin: checkin ?? this.checkin,
        remember: remember ?? this.remember,
        onlineModel: onlineModel ?? this.onlineModel,
        privateMode: privateMode ?? this.privateMode,
        quickExit: quickExit ?? this.quickExit,
        quickExitLeft: quickExitLeft ?? this.quickExitLeft,
        language: language ?? this.language,
        showSakina: showSakina ?? this.showSakina,
        tone: tone ?? this.tone,
      );

  static SupportSettings read(SharedPreferences p) {
    DateTime? day(String k) => DateTime.tryParse(p.getString(k) ?? '');
    CheckinFrequency freq() {
      final String? v = p.getString(SupportKeys.checkinFreq);
      for (final CheckinFrequency f in CheckinFrequency.values) {
        if (f.name == v) return f;
      }
      return CheckinFrequency.fortnightly;
    }

    final String lang = p.getString(SupportKeys.language) ?? 'en';
    return SupportSettings(
      checkin: CheckinState(
        off: p.getBool(SupportKeys.checkinOff) ?? false,
        frequency: freq(),
        lastAsked: day(SupportKeys.checkinLast),
        nextDue: day(SupportKeys.checkinNext),
      ),
      remember: p.getBool(SupportKeys.remember) ?? false,
      onlineModel: p.getBool(SupportKeys.onlineModel) ?? false,
      privateMode: p.getBool(SupportKeys.privateMode) ?? false,
      quickExit: p.getBool(SupportKeys.quickExit) ?? true,
      quickExitLeft: p.getBool(SupportKeys.quickExitLeft) ?? false,
      language: kSupportLanguages.contains(lang) ? lang : 'en',
      showSakina: p.getBool(SupportKeys.showSakina) ?? true,
      tone: p.getString(SupportKeys.tone) ?? 'auto',
    );
  }
}

class SupportSettingsNotifier extends Notifier<SupportSettings> {
  @override
  SupportSettings build() {
    try {
      return SupportSettings.read(ref.watch(sharedPreferencesProvider));
    } catch (_) {
      return const SupportSettings();
    }
  }

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _bool(String k, bool v) async {
    try {
      await _prefs?.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _str(String k, String? v) async {
    try {
      if (v == null) {
        await _prefs?.remove(k);
      } else {
        await _prefs?.setString(k, v);
      }
    } catch (_) {}
  }

  String? _iso(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Stores the check-in state: only the two days, the off flag and the
  /// interval. Nothing else about the check-in is ever kept.
  Future<void> saveCheckin(CheckinState c) async {
    state = state.copy(checkin: c);
    await _bool(SupportKeys.checkinOff, c.off);
    await _str(SupportKeys.checkinFreq, c.frequency.name);
    await _str(SupportKeys.checkinLast, _iso(c.lastAsked));
    await _str(SupportKeys.checkinNext, _iso(c.nextDue));
  }

  Future<void> setFrequency(CheckinFrequency f) async {
    await saveCheckin(CheckinScheduler.setFrequency(state.checkin, f));
    // Switching the check-in on in Settings also lifts any child's
    // "Don't ask me again" in Wasia.
    if (f != CheckinFrequency.off) {
      try {
        final SharedPreferences p = await SharedPreferences.getInstance();
        for (final String k in p.getKeys().toList()) {
          if (k.startsWith(SupportKeys.wasiaCheckinPrefix)) await p.remove(k);
        }
      } catch (_) {}
    }
  }

  Future<void> setRemember(bool v) async {
    state = state.copy(remember: v);
    await _bool(SupportKeys.remember, v);
  }

  Future<void> setOnlineModel(bool v) async {
    state = state.copy(onlineModel: v);
    await _bool(SupportKeys.onlineModel, v);
  }

  Future<void> setPrivateMode(bool v) async {
    state = state.copy(privateMode: v);
    await _bool(SupportKeys.privateMode, v);
  }

  Future<void> setQuickExit(bool v) async {
    state = state.copy(quickExit: v);
    await _bool(SupportKeys.quickExit, v);
  }

  Future<void> setQuickExitLeft(bool v) async {
    state = state.copy(quickExitLeft: v);
    await _bool(SupportKeys.quickExitLeft, v);
  }

  Future<void> setLanguage(String l) async {
    if (!kSupportLanguages.contains(l)) return;
    state = state.copy(language: l);
    await _str(SupportKeys.language, l);
  }

  Future<void> setShowSakina(bool v) async {
    state = state.copy(showSakina: v);
    await _bool(SupportKeys.showSakina, v);
  }

  Future<void> setTone(String t) async {
    state = state.copy(tone: t);
    await _str(SupportKeys.tone, t);
  }

  // ── The safe word (secure store only) ──────────────────────────────────
  String? get safeWord => SecretStore.readSync(SupportKeys.safeWordSecret);

  Future<void> setSafeWord(String? w) async {
    final String? t = w?.trim();
    await SecretStore.write(SupportKeys.safeWordSecret, (t == null || t.isEmpty) ? null : t.toLowerCase());
    state = state.copy();
  }

  /// True when [message] is exactly the safe word (ignoring case and spaces).
  bool isSafeWord(String message) {
    final String? w = safeWord;
    return w != null && w.isNotEmpty && message.trim().toLowerCase() == w;
  }

  // ── "What Hadi knows about me" ─────────────────────────────────────────
  List<MemoryItem> get memory => UserMemory.decode(SecretStore.readSync(SupportKeys.memorySecret));

  Future<void> _saveMemory(List<MemoryItem> items) async {
    await SecretStore.write(SupportKeys.memorySecret, items.isEmpty ? null : UserMemory.encode(items));
    state = state.copy();
  }

  /// Adds one item, only while the switch is on and the text is allowed.
  /// Returns false when nothing was saved.
  Future<bool> remember(String text, DateTime now) async {
    if (!state.remember) return false;
    final String t = text.trim();
    if (t.isEmpty || t.length > UserMemory.maxLength || !UserMemory.mayRemember(t)) return false;
    final List<MemoryItem> items = memory;
    if (items.length >= UserMemory.maxItems) return false;
    final String day = _iso(now) ?? '';
    await _saveMemory(<MemoryItem>[
      ...items,
      MemoryItem(id: 'm${now.microsecondsSinceEpoch}', text: t, on: day),
    ]);
    return true;
  }

  Future<void> editMemory(String id, String text) async {
    final String t = text.trim();
    if (t.isEmpty || t.length > UserMemory.maxLength || !UserMemory.mayRemember(t)) return;
    await _saveMemory(<MemoryItem>[
      for (final MemoryItem i in memory) i.id == id ? i.withText(t) : i,
    ]);
  }

  Future<void> deleteMemory(String id) =>
      _saveMemory(<MemoryItem>[for (final MemoryItem i in memory) if (i.id != id) i]);

  Future<void> deleteAllMemory() => _saveMemory(<MemoryItem>[]);

  String exportMemory() => UserMemory.export(memory);
}

final NotifierProvider<SupportSettingsNotifier, SupportSettings> supportSettingsProvider =
    NotifierProvider<SupportSettingsNotifier, SupportSettings>(SupportSettingsNotifier.new);
