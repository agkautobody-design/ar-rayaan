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

  group('Android voice ids', () {
    test('gender comes from the name, the Google code or the word', () {
      expect(VoicePicker.genderOf('en-us-x-iom-local'), VoiceGender.male);
      expect(VoicePicker.genderOf('en-us-x-sfg-network'), VoiceGender.female);
      expect(VoicePicker.genderOf('en-gb-x-rjs-local'), VoiceGender.male);
      expect(VoicePicker.genderOf('en-us-x-sfg#female_1-local'),
          VoiceGender.female);
      expect(VoicePicker.genderOf('en-us-x-abc#male_2-local'), VoiceGender.male);
      expect(VoicePicker.genderOf('Google UK English Male'), VoiceGender.male);
      expect(VoicePicker.genderOf('Google UK English Female'),
          VoiceGender.female);
      expect(VoicePicker.genderOf('en-US-SMTf00'), VoiceGender.female);
      expect(VoicePicker.genderOf('en-US-SMTm01'), VoiceGender.male);
      expect(VoicePicker.genderOf('English United States'),
          VoiceGender.unknown);
    });

    test('Hadi gets the male code, never the female one', () {
      final List<Map<dynamic, dynamic>> a = <Map<dynamic, dynamic>>[
        v('en-us-x-sfg-local'),
        v('en-us-x-iom-local'),
        v('en-us-x-tpf-local'),
      ];
      expect(VoicePicker.choose(a, VoiceProfile.hadi).name,
          'en-us-x-iom-local');
      expect(VoicePicker.choose(a, VoiceProfile.wasia).name,
          'en-us-x-sfg-local');
    });

    test('a female name tagged female is never given to Hadi', () {
      final List<Map<dynamic, dynamic>> a = <Map<dynamic, dynamic>>[
        v('en-us-x-sfg#female_1-local'),
      ];
      expect(VoicePicker.choose(a, VoiceProfile.hadi).name, isNull);
    });
  });

  group('options and Arabic', () {
    test('lists English and Arabic voices, labelled, men first', () {
      final List<VoiceOption> o = VoicePicker.options(<Map<dynamic, dynamic>>[
        v('en-us-x-sfg-local'),
        v('en-us-x-iom-local'),
        v('ar-xa-x-ard-local', 'ar'),
        v('Fred'),
        v('Thomas', 'fr-FR'),
      ]);
      expect(o.length, 3);
      expect(o.first.gender, VoiceGender.male);
      expect(o.first.label, contains('man'));
      expect(o.last.arabic, isTrue);
    });

    test('an Arabic voice is chosen, or none when the phone has none', () {
      final VoiceChoice c = VoicePicker.chooseArabic(<Map<dynamic, dynamic>>[
        v('Samantha'),
        v('Majed', 'ar-SA'),
      ], VoiceProfile.hadi);
      expect(c.name, 'Majed');
      expect(
          VoicePicker.chooseArabic(
              <Map<dynamic, dynamic>>[v('Samantha')], VoiceProfile.hadi).name,
          isNull);
    });
  });
}

