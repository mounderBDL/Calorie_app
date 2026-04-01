import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/inference_service.dart';
import 'services/database_service.dart';
import 'screens/auth_wrapper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize inference service
  final inferenceService = InferenceService();
  try {
    await inferenceService.init();
  } catch (e) {
    debugPrint('Model not ready yet: $e');
  }

  final databaseService = DatabaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<InferenceService>.value(value: inferenceService),
        Provider<DatabaseService>.value(value: databaseService),
      ],
      child: const SmartDZMealApp(),
    ),
  );
}

class SmartDZMealApp extends StatelessWidget {
  const SmartDZMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDZMeal',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}
