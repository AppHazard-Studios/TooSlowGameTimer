import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Returns 'sherpa' or 'flutter'
  String getTtsProvider() {
    return _prefs.getString('tts_provider') ?? 'sherpa';
  }

  Future<void> setTtsProvider(String provider) async {
    await _prefs.setString('tts_provider', provider);
  }
}