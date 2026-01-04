import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '../utils/constants.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  // Customizable properties
  String language = 'en-US';
  double speechRate = 0.46;
  double volume = 1.0;
  double pitch = 1.0;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);
  }

  // Update settings on the fly
  Future<void> updateSettings({
    String? newLanguage,
    double? newRate,
    double? newVolume,
    double? newPitch,
  }) async {
    if (newLanguage != null) {
      language = newLanguage;
      await _tts.setLanguage(language);
    }
    if (newRate != null) {
      speechRate = newRate;
      await _tts.setSpeechRate(speechRate);
    }
    if (newVolume != null) {
      volume = newVolume;
      await _tts.setVolume(volume);
    }
    if (newPitch != null) {
      pitch = newPitch;
      await _tts.setPitch(pitch);
    }
  }

  Future<void> speakRoast(String playerName, String mode) async {
    final templates = GameConstants.roastTemplates[mode] ?? GameConstants.roastTemplates['Banter']!;
    final template = templates[_random.nextInt(templates.length)];
    final roast = template.replaceAll('{name}', playerName);

    await _tts.speak(roast);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Get available voices (platform specific)
  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }

  // Set specific voice
  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  // Get available languages
  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }
}