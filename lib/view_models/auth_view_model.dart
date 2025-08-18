import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class AuthViewModel extends ChangeNotifier {
  static final _logger = Logger.forClass('AuthViewModel');

  bool isLoading = false;
  String? errorMessage;
  bool _disposed = false;

  final AuthService _authService = AuthService();

  Future<bool> login(String email, String password) async {
    if (_disposed) return false;

    try {
      _setLoading(true);
      _clearError();

      if (email.trim().isEmpty) {
        _setError('Email cannot be empty');
        return false;
      }

      if (password.isEmpty) {
        _setError('Password cannot be empty');
        return false;
      }

      _logger.info('Attempting login for email: $email');

      final result = await _authService.login(email.trim(), password);

      if (result.startsWith('success')) {
        _logger.info('Login successful');
        _clearError();
        return true;
      } else {
        _logger.warning('Login failed: $result');
        _setError(result);
        return false;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Login error in view model',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    if (_disposed) return false;

    try {
      _setLoading(true);
      _clearError();

      if (name.trim().isEmpty) {
        _setError('Name cannot be empty');
        return false;
      }

      if (email.trim().isEmpty) {
        _setError('Email cannot be empty');
        return false;
      }

      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        return false;
      }

      _logger.info('Attempting registration for email: $email');

      final result = await _authService.register(
        name.trim(),
        email.trim(),
        password,
      );

      if (result.startsWith('success')) {
        _logger.info('Registration successful');
        _clearError();
        return true;
      } else {
        _logger.warning('Registration failed: $result');
        _setError(result);
        return false;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Registration error in view model',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    try {
      _logger.info('Logging out user');
      AuthService.logout();
      _clearError();
      _logger.info('User logged out successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Logout error in view model',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Logout failed. Please try again.');
    }
  }

  bool get isLoggedIn {
    try {
      return AuthService.isLoggedIn;
    } catch (e, stackTrace) {
      _logger.error(
        'Error checking login status',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Map<String, dynamic>? get currentUser {
    try {
      return AuthService.currentUser;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting current user',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void _setLoading(bool loading) {
    if (_disposed) return;
    isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_disposed) return;
    errorMessage = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e, stackTrace) {
        _logger.error(
          'Error notifying listeners',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
