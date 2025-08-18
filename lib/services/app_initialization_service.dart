import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import 'background_service.dart';
import 'remote_db.dart';

class AppInitializationService {
  static final _logger = Logger.forClass('AppInitializationService');

  static String _env(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  // <CHANGE> Standardized comments to English and removed excessive empty lines
  /// Complete app initialization
  static Future<void> initialize() async {
    try {
      Logger.lifecycle('App initialization started');

      await _loadEnvironmentVariables();
      await _testDatabaseConnection();
      await _initializeNotifications();
      await _initializeBackgroundServices();

      Logger.lifecycle('App initialization completed successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Critical error during app initialization',
        error: e,
        stackTrace: stackTrace,
      );

      Logger.lifecycle(
        'App initialization completed with errors - some features may be unavailable',
      );
      rethrow;
    }
  }

  /// Load .env file
  static Future<void> _loadEnvironmentVariables() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      _logger.info('Environment variables loaded successfully');

      final requiredVars = ['DB_HOST', 'DB_NAME', 'DB_USER'];
      final missingVars = <String>[];

      for (final varName in requiredVars) {
        if (_env(varName).isEmpty) {
          missingVars.add(varName);
        }
      }

      if (missingVars.isNotEmpty) {
        _logger.warning(
          'Missing environment variables: ${missingVars.join(', ')}',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load environment variables',
        error: e,
        stackTrace: stackTrace,
      );
      Logger.lifecycle('Using default configuration values');
    }
  }

  /// Test database connection
  static Future<void> _testDatabaseConnection() async {
    try {
      final isConnected = await RemoteDB.testConnection().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (isConnected) {
        _logger.info("Database connection test successful!");
        _logger.debug("DB_HOST: ${_env('DB_HOST')}");
        _logger.debug("DB_PORT: ${_env('DB_PORT')}");
        _logger.debug("DB_NAME: ${_env('DB_NAME')}");
      } else {
        throw Exception("Database connection test failed");
      }
    } catch (e, stackTrace) {
      _logger.error(
        "Database connection failed",
        error: e,
        stackTrace: stackTrace,
      );
      Logger.lifecycle('App will continue without database connectivity');
    }
  }

  /// Initialize notifications
  static Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initialize();
      final permissionsGranted = await NotificationService.requestPermissions();

      if (permissionsGranted) {
        _logger.info('Notification service initialized successfully');
      } else {
        _logger.warning(
          'Notification permissions not granted - notifications will be disabled',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize notifications',
        error: e,
        stackTrace: stackTrace,
      );
      Logger.lifecycle('App will continue without notification support');
    }
  }

  /// Initialize background services
  static Future<void> _initializeBackgroundServices() async {
    try {
      await BackgroundService.initialize();
      await BackgroundService.registerPeriodicTask();
      _logger.info('Background service initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize background service',
        error: e,
        stackTrace: stackTrace,
      );
      Logger.lifecycle('App will continue without background task support');
    }
  }

  /// Restart background services after device boot
  static Future<void> handleAutoStartAfterBoot() async {
    try {
      await BackgroundService.registerAfterBoot();
      _logger.info('Background services restarted after boot successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to restart background services after boot',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<Map<String, dynamic>> getInitializationStatus() async {
    final status = <String, dynamic>{};

    try {
      final dbConnected = await RemoteDB.testConnection().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      status['database'] = {
        'connected': dbConnected,
        'host': _env('DB_HOST'),
        'port': _env('DB_PORT'),
      };
    } catch (e) {
      status['database'] = {'connected': false, 'error': e.toString()};
    }

    try {
      final notificationsEnabled =
          await NotificationService.areNotificationsEnabled();
      status['notifications'] = {'enabled': notificationsEnabled};
    } catch (e) {
      status['notifications'] = {'enabled': false, 'error': e.toString()};
    }

    return status;
  }
}
