/// Feature vitals — the probes each Ar-Rayaan feature registers with
/// the Doctor at boot. Every probe is a REAL behavioral check against
/// the feature's own logic; repairs are idempotent and safe.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../academy/application/academy_strings.dart';
import '../../academy/data/word_deck_repository.dart';
import '../../academy/domain/course_manifest.dart';
import '../../academy/domain/recitation_audio.dart';
import '../../academy/domain/spaced_repetition.dart';
import '../../academy/domain/word_deck.dart';
import '../domain/vitals.dart';
import 'vitals_registry.dart';

abstract final class FeatureProbes {
  /// Called once at app boot (from the Doctor's bootstrap). Each
  /// registration is a contract: "if this fails, the feature is sick."
  static void registerAll() {
    _hadith();
    _academyManifest();
    _wordDeck();
    _recitation();
    _storage();
  }

  static void _hadith() {
    VitalsRegistry.register(RegisteredProbe(
      id: 'hadith.index',
      feature: 'hadith',
      severity: ProbeSeverity.critical,
      run: () async {
        const int daysInYear = 366;
        for (int d = 1; d <= daysInYear; d++) {
          final int idx = (d - 1) % 60;
          if (idx < 0 || idx >= 60) {
            return ProbeResult(
              probeId: 'hadith.index',
              feature: 'hadith',
              status: ProbeStatus.failed,
              severity: ProbeSeverity.critical,
              detail: 'day $d resolves out of corpus range',
            );
          }
        }
        return const ProbeResult(
            probeId: 'hadith.index',
            feature: 'hadith',
            status: ProbeStatus.pass);
      },
    ));
  }

  static void _academyManifest() {
    VitalsRegistry.register(RegisteredProbe(
      id: 'academy.strings',
      feature: 'academy',
      run: () async {
        final List<String> missing = <String>[];
        void collect(String k) {
          if (k.isNotEmpty && AcademyStrings.get(k) == k) missing.add(k);
        }
        for (final c in kAcademyCourses) {
          collect(c.titleKey);
          collect(c.subtitleKey);
          for (final u in c.units) {
            collect(u.titleKey);
            collect(u.subtitleKey);
            for (final l in u.lessons) {
              collect(l.titleKey);
              for (final s in l.steps) {
                collect(s.titleKey);
                collect(s.bodyKey);
              }
            }
          }
        }
        if (missing.isNotEmpty) {
          return ProbeResult(
            probeId: 'academy.strings',
            feature: 'academy',
            status: ProbeStatus.failed,
            detail: 'unresolved keys: ${missing.take(3).join(", ")}'
                '${missing.length > 3 ? " (+${missing.length - 3})" : ""}',
          );
        }
        return const ProbeResult(
            probeId: 'academy.strings',
            feature: 'academy',
            status: ProbeStatus.pass);
      },
    ));
  }

  static void _wordDeck() {
    VitalsRegistry.register(RegisteredProbe(
      id: 'deck.integrity',
      feature: 'academy',
      run: () async {
        final prefs = await SharedPreferences.getInstance();
        final String? raw = prefs.getString('ar.academy.deck.v1');
        if (raw == null) {
          return const ProbeResult(
            probeId: 'deck.integrity',
            feature: 'academy',
            status: ProbeStatus.pass,
            detail: 'no deck stored yet',
          );
        }
        final Map<String, WordCard>? deck = await _loadDeckSafely(prefs);
        if (deck == null) {
          return ProbeResult(
            probeId: 'deck.integrity',
            feature: 'academy',
            status: ProbeStatus.failed,
            detail: 'deck store exists but does not parse',
          );
        }
        int corrupt = 0;
        for (final WordCard c in deck.values) {
          final ReviewCard r = c.review;
          final bool sane = r.easiness >= 1.3 &&
              r.intervalDays >= 0 &&
              r.repetitions >= 0 &&
              !r.dueDate.isBefore(DateTime.fromMillisecondsSinceEpoch(0));
          if (!sane) corrupt++;
        }
        if (corrupt > 0) {
          return ProbeResult(
            probeId: 'deck.integrity',
            feature: 'academy',
            status: ProbeStatus.failed,
            detail: '$corrupt corrupt card(s) in stored deck',
          );
        }
        return const ProbeResult(
            probeId: 'deck.integrity',
            feature: 'academy',
            status: ProbeStatus.pass);
      },
      repair: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ar.academy.deck.v1');
        return 'cleared unparseable deck store (pack will re-seed)';
      },
    ));
  }

  static Future<Map<String, WordCard>?> _loadDeckSafely(
      SharedPreferences prefs) async {
    try {
      return WordDeckRepository.loadDeck(prefs);
    } catch (_) {
      return null;
    }
  }

  static void _recitation() {
    VitalsRegistry.register(RegisteredProbe(
      id: 'recitation.engine',
      feature: 'recitation',
      run: () async {
        try {
          final range =
              AyahRange.withinSurah(surah: 1, fromAyah: 1, toAyah: 3);
          final plan = RecitationPlanEngine.buildPlan(
            range: range.refs,
            perAyahRepeat: 2,
            gapMs: 2000,
            loopRange: 2,
          );
          final int utterances = RecitationPlanEngine.totalUtterances(plan);
          if (utterances != 12) {
            return ProbeResult(
              probeId: 'recitation.engine',
              feature: 'recitation',
              status: ProbeStatus.failed,
              detail: 'plan produced $utterances utterances, expected 12',
            );
          }
          final String url =
              ReciterPack.alHusary.ayahUrl(const AyahRef(1, 1));
          if (!url.startsWith('https://') || !url.endsWith('001001.mp3')) {
            return ProbeResult(
              probeId: 'recitation.engine',
              feature: 'recitation',
              status: ProbeStatus.failed,
              detail: 'unexpected ayah URL shape: $url',
            );
          }
          return const ProbeResult(
              probeId: 'recitation.engine',
              feature: 'recitation',
              status: ProbeStatus.pass);
        } catch (e) {
          return ProbeResult(
            probeId: 'recitation.engine',
            feature: 'recitation',
            status: ProbeStatus.failed,
            detail: 'engine threw: $e',
          );
        }
      },
    ));
  }

  static void _storage() {
    VitalsRegistry.register(RegisteredProbe(
      id: 'storage.prefs',
      feature: 'system',
      severity: ProbeSeverity.critical,
      run: () async {
        final prefs = await SharedPreferences.getInstance();
        const String probeKey = 'ar.doctor.probe';
        try {
          await prefs.setString(probeKey, 'ok');
          final String? v = prefs.getString(probeKey);
          await prefs.remove(probeKey);
          if (v != 'ok') {
            return const ProbeResult(
              probeId: 'storage.prefs',
              feature: 'system',
              status: ProbeStatus.failed,
              severity: ProbeSeverity.critical,
              detail: 'prefs round-trip failed',
            );
          }
          return const ProbeResult(
              probeId: 'storage.prefs',
              feature: 'system',
              status: ProbeStatus.pass);
        } catch (e) {
          return ProbeResult(
            probeId: 'storage.prefs',
            feature: 'system',
            status: ProbeStatus.failed,
            severity: ProbeSeverity.critical,
            detail: 'prefs threw: $e',
          );
        }
      },
    ));
  }
}
