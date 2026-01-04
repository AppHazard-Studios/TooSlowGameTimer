import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '../utils/constants.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.43);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
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
}