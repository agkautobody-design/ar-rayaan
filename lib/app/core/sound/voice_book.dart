/// What the person chose about voices (which voice for Hādi, which for Wasia,
/// how fast, whether Arabic is read in Arabic), plus the logic that applies it
/// to the device's text-to-speech. Every read is defensive: screens built
/// without SharedPreferences (tests) simply get the defaults.
library;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'voice_picker.dart';

/// One stretch of text and whether it is Arabic script.
class SpeechRun {
  const SpeechRun(this.text, this.arabic);

  final String text;
  final bool arabic;
}

abstract final class SpeechRuns {
  /// Arabic letters and their marks. Arabic punctuation and digits are
  /// neutral, so a comma inside English does not switch the voice.
  static bool isArabicRune(int r) {
    if (r == 0x060C || r == 0x061B || r == 0x061F || r == 0x06D4) return false;
    if ((r >= 0x0660 && r <= 0x0669) || (r >= 0x06F0 && r <= 0x06F9)) {
      return false;
    }
    if (r >= 0x066A && r <= 0x066D) return false;
    return _arabicBlock(r);
  }

  static bool _arabicBlock(int r) =>
      (r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0x08A0 && r <= 0x08FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF);

  static bool _isLatinLetter(int r) =>
      (r >= 0x41 && r <= 0x5A) ||
      (r >= 0x61 && r <= 0x7A) ||
      (r >= 0xC0 && r <= 0x24F) ||
      (r >= 0x1E00 && r <= 0x1EFF);

  /// Cuts [text] into runs that switch language at the script change, so the
  /// Arabic is spoken by an Arabic voice and the English by an English one.
  /// Spaces and punctuation stay with the run they are inside.
  static List<SpeechRun> split(String text) {
    final List<SpeechRun> out = <SpeechRun>[];
    final StringBuffer buf = StringBuffer();
    bool? arabic;
    void flush() {
      final String s = buf.toString().trim();
      buf.clear();
      if (s.isEmpty || arabic == null) return;
      // A run of only punctuation or digits is not worth a voice switch.
      final bool hasLetter =
          s.runes.any((int r) => isArabicRune(r) || _isLatinLetter(r));
      if (hasLetter) out.add(SpeechRun(s, arabic!));
    }

    for (final int r in text.runes) {
      final bool ar = isArabicRune(r);
      final bool latin = _isLatinLetter(r);
      if (ar || latin) {
        if (arabic != null && arabic != ar) flush();
        arabic = ar;
      }
      buf.writeCharCode(r);
    }
    flush();
    return out;
  }
}

class VoiceBook {
  VoiceBook(this._prefs);

  final SharedPreferences? _prefs;
  List<Map<dynamic, dynamic>>? _voices;

  static const String _speedKey = 'ar.voice.speed';
  static const String _arabicKey = 'ar.voice.arabic';
  static String _key(VoiceProfile p) => 'ar.voice.${p.name}';

  /// 1.0 is the guide's normal pace.
  double get speed {
    try {
      return (_prefs?.getDouble(_speedKey) ?? 1.0).clamp(0.6, 1.5);
    } catch (_) {
      return 1.0;
    }
  }

  /// Arabic in the text is spoken by an Arabic voice. On by default.
  bool get readArabic {
    try {
      return _prefs?.getBool(_arabicKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setSpeed(double v) async {
    try {
      await _prefs?.setDouble(_speedKey, v.clamp(0.6, 1.5));
    } catch (_) {}
  }

  Future<void> setReadArabic(bool v) async {
    try {
      await _prefs?.setBool(_arabicKey, v);
    } catch (_) {}
  }

  /// The voice the person picked for [p] as (name, locale), or null for
  /// "automatic".
  (String, String)? saved(VoiceProfile p) {
    try {
      final String? s = _prefs?.getString(_key(p));
      if (s == null) return null;
      final int i = s.indexOf('|');
      if (i < 0) return null;
      return (s.substring(0, i), s.substring(i + 1));
    } catch (_) {
      return null;
    }
  }

  /// Saves the person's pick; null goes back to automatic.
  Future<void> save(VoiceProfile p, VoiceOption? o) async {
    try {
      if (o == null) {
        await _prefs?.remove(_key(p));
      } else {
        await _prefs?.setString(_key(p), '${o.name}|${o.locale}');
      }
    } catch (_) {}
  }

  Future<List<Map<dynamic, dynamic>>> rawVoices(FlutterTts tts) async {
    final List<Map<dynamic, dynamic>>? known = _voices;
    if (known != null && known.isNotEmpty) return known;
    try {
      final dynamic raw = await tts.getVoices;
      _voices = (raw is List ? raw : <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .toList();
    } catch (_) {
      _voices = <Map<dynamic, dynamic>>[];
    }
    return _voices!;
  }

  Future<List<VoiceOption>> options(FlutterTts tts) async =>
      VoicePicker.options(await rawVoices(tts));

  double rateFor(VoiceProfile p) =>
      (VoicePicker.baseRate(p) * speed).clamp(0.1, 1.0);

  /// Points [tts] at the right voice for [p]. For Arabic, returns false when
  /// the device has no Arabic voice, so the caller skips that stretch rather
  /// than have an English voice read Arabic letters as nonsense.
  Future<bool> apply(FlutterTts tts, VoiceProfile p,
      {required bool arabic}) async {
    final List<Map<dynamic, dynamic>> pool = await rawVoices(tts);
    if (arabic) {
      final VoiceChoice c = VoicePicker.chooseArabic(pool, p);
      if (c.name == null) {
        try {
          final dynamic ok = await tts.isLanguageAvailable('ar');
          if (ok != true && ok != 1) return false;
          await tts.setLanguage('ar');
        } catch (_) {
          return false;
        }
      } else {
        await tts.setLanguage(c.locale ?? 'ar');
        await tts.setVoice(<String, String>{
          'name': c.name!,
          'locale': c.locale ?? 'ar',
        });
      }
      await tts.setPitch(1.0);
      await tts.setSpeechRate(rateFor(p));
      return true;
    }
    final (String, String)? mine = saved(p);
    VoiceChoice c;
    if (mine != null &&
        pool.any((Map<dynamic, dynamic> v) => v['name'].toString() == mine.$1)) {
      c = VoiceChoice(
          name: mine.$1,
          locale: mine.$2,
          pitch: 1.0,
          rate: VoicePicker.baseRate(p));
    } else {
      c = VoicePicker.choose(pool, p);
    }
    await tts.setLanguage(c.locale ?? 'en-US');
    if (c.name != null) {
      await tts.setVoice(<String, String>{
        'name': c.name!,
        'locale': c.locale ?? 'en-US',
      });
    }
    await tts.setPitch(c.pitch);
    await tts.setSpeechRate((c.rate * speed).clamp(0.1, 1.0));
    return true;
  }

  /// Applies one specific voice (for the sample button) without saving it.
  Future<void> applyOption(FlutterTts tts, VoiceOption o) async {
    await tts.setLanguage(o.locale);
    await tts.setVoice(<String, String>{'name': o.name, 'locale': o.locale});
    await tts.setPitch(1.0);
    await tts.setSpeechRate(rateFor(VoiceProfile.neutral));
  }
}
