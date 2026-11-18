import 'package:flutter_test/flutter_test.dart';
import 'package:ar_rayaan/app/core/sound/voice_picker.dart';

Map<dynamic, dynamic> v(String n, [String l = 'en-US']) =>
    <dynamic, dynamic>{'name': n, 'locale': l};

void main() {
  final List<Map<dynamic, dynamic>> voices = <Map<dynamic, dynamic>>[
    v('Samantha'),
    v('Daniel', 'en-GB'),
    v('Fred'),
    v('Karen', 'en-AU'),
    v('Thomas', 'fr-FR'),
    v('Microsoft Guy Online (Natural)'),
  ];

  test('Hadi gets a man, never a woman or a novelty voice', () {
    final VoiceChoice c = VoicePicker.choose(voices, VoiceProfile.hadi);
    expect(c.name, 'Microsoft Guy Online (Natural)');
  });

  test('Wasia gets a woman', () {
    final VoiceChoice c = VoicePicker.choose(voices, VoiceProfile.wasia);
    expect(c.name, 'Samantha');
  });

  test('no matching voice falls back to pitch, lower for Hadi', () {
    final List<Map<dynamic, dynamic>> few = <Map<dynamic, dynamic>>[
      v('Samantha'),
    ];
    final VoiceChoice h = VoicePicker.choose(few, VoiceProfile.hadi);
    final VoiceChoice w = VoicePicker.choose(few, VoiceProfile.wasia);
    expect(h.name, isNull);
    expect(h.pitch, lessThan(w.pitch));
    expect(w.rate, lessThan(0.48));
  });

  test('non-English voices are ignored', () {
    final VoiceChoice c = VoicePicker.choose(
        <Map<dynamic, dynamic>>[v('Thomas', 'fr-FR')], VoiceProfile.hadi);
    expect(c.name, isNull);
  });
}
