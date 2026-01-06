import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/setup_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  await PreferencesService().init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TooSlowApp());
}

class TooSlowApp extends StatelessWidget {
  const TooSlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Too Slow Game Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFDF7),
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFFD60A),
        ),
      ),
      home: const SetupScreen(),
    );
  }
}