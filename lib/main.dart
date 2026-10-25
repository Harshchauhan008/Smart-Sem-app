
import 'package:flutter/material.dart';
import 'package:smartsem/widget/splash_screen.dart';

import 'helper/pref.dart';
import 'service/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Pref.initialize();
  await ReminderService.init();

  runApp(const SmartSemApp());
}

class SmartSemApp extends StatelessWidget {
  const SmartSemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D91),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
