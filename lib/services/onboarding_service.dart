import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class OnboardingService extends ChangeNotifier {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  bool _isOnboardingCompleted = false;
  SharedPreferences? _prefs;

  bool get isOnboardingCompleted => _isOnboardingCompleted;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted =
          _prefs?.getBool(_onboardingCompletedKey) ?? false;
      Logger.info(
        'Onboarding service initialized. Completed: $_isOnboardingCompleted',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to initialize OnboardingService: $error',
        stackTrace: stackTrace,
      );
      _isOnboardingCompleted = false;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      _isOnboardingCompleted = true;
      await _prefs?.setBool(_onboardingCompletedKey, true);
      Logger.info('Onboarding completed and saved');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to save onboarding completion: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> resetOnboarding() async {
    try {
      _isOnboardingCompleted = false;
      await _prefs?.setBool(_onboardingCompletedKey, false);
      Logger.info('Onboarding reset');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to reset onboarding: $error',
        stackTrace: stackTrace,
      );
    }
  }
}
