import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/inference_service.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  final inferenceService = InferenceService();
  
  // Don't crash if model isn't ready yet
  try {
    await inferenceService.init();
  } catch (e) {
    debugPrint('Model not ready yet: $e');
  }

  final databaseService = DatabaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider<InferenceService>.value(value: inferenceService),
        Provider<DatabaseService>.value(value: databaseService),
      ],
      child: const FoodLensApp(),
    ),
  );
}

class FoodLensApp extends StatelessWidget {
  const FoodLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLens',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
