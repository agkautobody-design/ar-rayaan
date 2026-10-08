import 'package:ar_rayaan/features/academy/domain/atmosphere.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtmosphereEngine.resolve', () {
    test('explicit emotion always wins over the hour', () {
      final a = AtmosphereEngine.resolve(emotion: AtmosphereEmotion.awe, hour: 15);
      expect(a.sceneKey, 'horizon');
      expect(a.emotion, AtmosphereEmotion.awe);
      final n = AtmosphereEngine.resolve(emotion: AtmosphereEmotion.night, hour: 9);
      expect(n.sceneKey, 'night-sky');
    });

    test('hour carries the mood when no emotion is given', () {
      expect(AtmosphereEngine.resolve(hour: 5).sceneKey, 'courtyard');   // Fajr
      expect(AtmosphereEngine.resolve(hour: 10).sceneKey, 'arch-lattice'); // Duha
      expect(AtmosphereEngine.resolve(hour: 17).sceneKey, 'garden');     // Maghrib hour
      expect(AtmosphereEngine.resolve(hour: 20).sceneKey, 'night-desert'); // Isha
      expect(AtmosphereEngine.resolve(hour: 2).sceneKey, 'night-sky');   // deep night
    });

    test('every emotion maps to a distinct scene+light (no collisions)', () {
      final seen = <String>{};
      for (final e in AtmosphereEmotion.values) {
        final a = AtmosphereEngine.resolve(emotion: e, hour: 12);
        expect(a.sceneKey, isNotEmpty);
        expect(a.lightState, isNotEmpty);
        expect(seen.add(a.sceneKey), isTrue, reason: '${e.name} duplicates a scene key');
        expect(a.tint, isNot(0), reason: '${e.name} must carry a color wash');
      }
    });

    test('parallel integration style also resolves (contentEmotion/now)', () {
      final a = AtmosphereEngine.resolve(
          contentEmotion: AtmosphereEmotion.peace,
          now: DateTime(2026, 10, 6, 15));
      expect(a.sceneKey, 'arch-lattice');
      final b = AtmosphereEngine.resolve(now: DateTime(2026, 10, 6, 21));
      expect(b.sceneKey, 'night-desert');
    });

    test('boundary hours are deterministic', () {
      expect(AtmosphereEngine.resolve(hour: 6).sceneKey, 'courtyard');
      expect(AtmosphereEngine.resolve(hour: 7).sceneKey, 'arch-lattice');
      expect(AtmosphereEngine.resolve(hour: 15).sceneKey, 'arch-lattice');
      expect(AtmosphereEngine.resolve(hour: 16).sceneKey, 'garden');
      expect(AtmosphereEngine.resolve(hour: 18).sceneKey, 'garden');
      expect(AtmosphereEngine.resolve(hour: 19).sceneKey, 'night-desert');
      expect(AtmosphereEngine.resolve(hour: 22).sceneKey, 'night-desert');
      expect(AtmosphereEngine.resolve(hour: 23).sceneKey, 'night-sky');
      expect(AtmosphereEngine.resolve(hour: 3).sceneKey, 'night-sky');
    });
  });
}
