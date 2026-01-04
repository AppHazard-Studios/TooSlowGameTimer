import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '../utils/constants.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  // Track recently used roasts per mode to avoid repetition
  final Map<String, List<int>> _recentRoastIndices = {};
  final int _historySize = 5; // Don't repeat last 5 roasts

  String language = 'en-US';
  double speechRate = 0.48;
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

  int _getNextRoastIndex(String mode, int totalRoasts) {
    // Initialize history for this mode if needed
    _recentRoastIndices[mode] ??= [];

    final recentIndices = _recentRoastIndices[mode]!;

    // If we have fewer roasts than history size, just pick randomly from unused
    if (totalRoasts <= _historySize) {
      // Pick any index not in recent history
      final availableIndices = List.generate(totalRoasts, (i) => i)
          .where((i) => !recentIndices.contains(i))
          .toList();

      if (availableIndices.isEmpty) {
        // Used all roasts, clear history and start fresh
        recentIndices.clear();
        return _random.nextInt(totalRoasts);
      }

      return availableIndices[_random.nextInt(availableIndices.length)];
    }

    // Pick from indices NOT in recent history
    final availableIndices = List.generate(totalRoasts, (i) => i)
        .where((i) => !recentIndices.contains(i))
        .toList();

    final selectedIndex = availableIndices[_random.nextInt(availableIndices.length)];

    // Add to history
    recentIndices.add(selectedIndex);

    // Keep history size limited
    if (recentIndices.length > _historySize) {
      recentIndices.removeAt(0);
    }

    return selectedIndex;
  }

  Future<void> speakRoast(String playerName, String mode) async {
    final templates = GameConstants.roastTemplates[mode] ?? GameConstants.roastTemplates['Banter']!;

    // Get a roast that hasn't been used recently
    final roastIndex = _getNextRoastIndex(mode, templates.length);
    final template = templates[roastIndex];
    final roast = template.replaceAll('{name}', playerName);

    await _tts.speak(roast);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }
}