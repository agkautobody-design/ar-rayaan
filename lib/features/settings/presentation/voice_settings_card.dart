import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/sound/sound_services.dart';
import '../../../app/core/sound/voice_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/tr_text.dart';

/// Language & Voice: pick the voice Hādi and Wasia speak with, hear it first,
/// set the speed, and choose whether Arabic is read in Arabic. The voices are
/// the ones installed on this phone, so the list differs per device.
class VoiceSettingsCard extends ConsumerStatefulWidget {
  const VoiceSettingsCard({super.key});

  @override
  ConsumerState<VoiceSettingsCard> createState() => _VoiceSettingsCardState();
}

class _VoiceSettingsCardState extends ConsumerState<VoiceSettingsCard> {
  static const String _hadiSample =
      'As-salaamu alaykum. I am Hadi. This is how I sound when I read an '
      'answer to you.';
  static const String _wasiaSample =
      'As-salaamu alaykum. I am Wasia. This is how I sound when I read a '
      'story to you.';
  static const String _arabicSample = 'السلام '
      'عليكم ورحمة '
      'الله';

  double? _speed;

  SpeechService get _speech => ref.read(speechServiceProvider);

  String _currentLabel(VoiceProfile p) {
    final (String, String)? mine = _speech.book.saved(p);
    return mine == null ? 'Automatic' : 'Chosen on this phone';
  }

  Future<void> _choose(VoiceProfile profile) async {
    final String name = profile == VoiceProfile.hadi ? 'Hādi' : 'Wasia';
    final List<VoiceOption> options = await _speech.voiceOptions();
    if (!mounted) return;
    final (String, String)? mine = _speech.book.saved(profile);
    final VoiceOption? picked = await showModalBottomSheet<VoiceOption?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      builder: (BuildContext sheet) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            builder: (BuildContext _, ScrollController scroll) {
              return ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: <Widget>[
                  Text('Choose $name’s voice', style: AppText.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    options.isEmpty
                        ? 'This phone did not list any voices. Install a '
                            'text-to-speech voice in your phone’s settings, '
                            'then come back.'
                        : 'Tap the speaker to hear a voice. Tap the name to use it.',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Automatic', style: AppText.body),
                    subtitle: Text(
                        profile == VoiceProfile.hadi
                            ? 'Looks for a man’s voice'
                            : 'Looks for a gentle woman’s voice',
                        style: AppText.bodyMuted),
                    trailing: mine == null
                        ? const Icon(Icons.check, color: AppColors.gold)
                        : null,
                    onTap: () => Navigator.of(sheet).pop(
                      const VoiceOption(
                        name: '',
                        locale: '',
                        gender: VoiceGender.unknown,
                        label: '',
                        arabic: false,
                        natural: false,
                      ),
                    ),
                  ),
                  for (final VoiceOption o in options)
                    ListTile(
                      title: Text(o.label, style: AppText.body),
                      leading: IconButton(
                        tooltip: 'Hear this voice',
                        icon: const Icon(Icons.volume_up_outlined,
                            color: AppColors.gold),
                        onPressed: () => _speech.sample(
                          o,
                          o.arabic
                              ? _arabicSample
                              : (profile == VoiceProfile.hadi
                                  ? _hadiSample
                                  : _wasiaSample),
                        ),
                      ),
                      trailing: mine != null && mine.$1 == o.name
                          ? const Icon(Icons.check, color: AppColors.gold)
                          : null,
                      onTap: () => Navigator.of(sheet).pop(o),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
    await _speech.stop();
    if (picked == null) return;
    await _speech.book.save(profile, picked.name.isEmpty ? null : picked);
    if (mounted) setState(() {});
  }

  Future<void> _test(VoiceProfile p) => _speech.speak(
        p == VoiceProfile.hadi ? _hadiSample : _wasiaSample,
        profile: p,
      );

  Widget _row(VoiceProfile p, String name, String who) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$name · $who', style: AppText.body),
                Text(_currentLabel(p), style: AppText.bodyMuted),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hear $name now',
            icon: const Icon(Icons.play_circle_outline, color: AppColors.gold),
            onPressed: () => _test(p),
          ),
          TextButton(
            onPressed: () => _choose(p),
            child: Text('Choose', style: AppText.body),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double speed = _speed ?? _speech.book.speed;
    final bool arabic = _speech.book.readArabic;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('VOICES', style: AppText.eyebrow),
            const SizedBox(height: 6),
            Text(
              'Hādi speaks with a man’s voice and Wasia with a '
              'woman’s. These are the voices installed on this phone, so '
              'the list is different on each phone. If one sounds robotic, '
              'choose another, or install a natural or enhanced voice in your '
              'phone’s text-to-speech settings and pick it here.',
              style: AppText.bodyMuted.copyWith(height: 1.5),
            ),
            _row(VoiceProfile.hadi, 'Hādi', 'man'),
            _row(VoiceProfile.wasia, 'Wasia', 'woman'),
            const SizedBox(height: 14),
            Text('Speed', style: AppText.body),
            Slider(
              value: speed,
              min: 0.6,
              max: 1.5,
              divisions: 9,
              label: '${speed.toStringAsFixed(1)}x',
              onChanged: (double v) => setState(() => _speed = v),
              onChangeEnd: (double v) => _speech.book.setSpeed(v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Read Arabic in Arabic', style: AppText.body),
              subtitle: Text(
                  'Verses and du’as are read by an Arabic voice. If this '
                  'phone has no Arabic voice, the Arabic is skipped and the '
                  'English is still read.',
                  style: AppText.bodyMuted),
              value: arabic,
              onChanged: (bool v) async {
                await _speech.book.setReadArabic(v);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
