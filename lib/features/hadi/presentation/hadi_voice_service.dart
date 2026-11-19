import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../app/core/sound/sound_services.dart' show SpeechService;
import '../../../app/core/sound/voice_picker.dart';

/// Handles voice input (speech-to-text) and voice output (text-to-speech)
/// for the Hadi conversation experience.
///
/// Usage:
///   final voice = HadiVoiceService(speech: ref.read(speechServiceProvider));
///   final text = await voice.startListening(...);
///   await voice.speak('Hadi response here');
class HadiVoiceService {
  HadiVoiceService({required SpeechService speech}) : _out = speech {
    _initSpeech();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();

  /// The one shared voice engine: it holds the man's voice the person chose
  /// for Hādi, the speed, and reads Arabic in Arabic.
  final SpeechService _out;
  bool _speechAvailable = false;
  bool _isListening = false;

  /// Whether the device supports speech recognition.
  bool get isAvailable => _speechAvailable;

  /// Whether currently listening for voice input.
  bool get isListening => _isListening;

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') _isListening = false;
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
  }

  /// Start listening for voice input. Returns transcribed text when done.
  Future<String?> startListening({
    required VoidCallback onListeningStarted,
    required VoidCallback onListeningFinished,
    required void Function(String) onPartialResult,
  }) async {
    if (!_speechAvailable) return null;

    _isListening = true;
    onListeningStarted();

    String? finalResult;

    await _speech.listen(
      onResult: (result) {
        onPartialResult(result.recognizedWords);
        if (result.finalResult) {
          finalResult = result.recognizedWords;
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );

    // Wait for listening to finish
    await Future<void>.delayed(const Duration(milliseconds: 500));
    while (_isListening) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    onListeningFinished();
    return finalResult;
  }

  /// Stop listening manually.
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Speak Hadi's response aloud.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _out.speak(text, profile: VoiceProfile.hadi);
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _out.stop();
  }

  void dispose() {
    _speech.stop();
    _out.stop();
  }
}
