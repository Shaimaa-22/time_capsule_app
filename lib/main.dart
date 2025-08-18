import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_initialization_service.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';
import 'services/localization_service.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/capsule_view_model.dart';
import 'views/app_wrapper.dart';
import 'utils/logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    Logger.info('Time Capsule App starting up');

    await AppInitializationService.initialize();
    await LocalizationService().initialize();

    runApp(const MyApp());
  } catch (error, stackTrace) {
    Logger.error('Failed to initialize app: $error', stackTrace: stackTrace);
    runApp(_buildErrorApp(error.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.ui('Building MyApp widget');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _createThemeService()),
        ChangeNotifierProvider(create: (_) => _createOnboardingService()),
        ChangeNotifierProvider.value(value: LocalizationService()),
        ChangeNotifierProvider(create: (_) => _createAuthViewModel()),
        ChangeNotifierProvider(create: (_) => _createCapsuleViewModel()),
      ],
      child: AppWrapper(navigatorKey: navigatorKey),
    );
  }

  ThemeService _createThemeService() {
    try {
      final themeService = ThemeService();
      themeService.initialize();
      return themeService;
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to initialize ThemeService: $error',
        stackTrace: stackTrace,
      );
      return ThemeService();
    }
  }

  OnboardingService _createOnboardingService() {
    try {
      final onboardingService = OnboardingService();
      onboardingService.initialize();
      return onboardingService;
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to initialize OnboardingService: $error',
        stackTrace: stackTrace,
      );
      return OnboardingService();
    }
  }

  AuthViewModel _createAuthViewModel() {
    try {
      return AuthViewModel();
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to create AuthViewModel: $error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  CapsuleViewModel _createCapsuleViewModel() {
    try {
      return CapsuleViewModel();
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to create CapsuleViewModel: $error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

MaterialApp _buildErrorApp(String error) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'App Failed to Start',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Error: $error'),
          ],
        ),
      ),
    ),
  );
}
