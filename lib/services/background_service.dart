import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'capsule_service.dart';
import 'simple_notification_service.dart';
import 'auth_service.dart';
import '../utils/logger.dart';

class BackgroundService {
  static final _logger = Logger.forClass('BackgroundService');
  static const String _taskName = 'checkCapsules';

  // Initialize the background service
  static Future<void> initialize() async {
    _logger.info('Initializing background service');

    await Workmanager().initialize(callbackDispatcher);

    _logger.info('Background service initialized');
  }

  static Future<void> registerPeriodicTask() async {
    try {
      // Cancel any existing tasks first
      await Workmanager().cancelAll();

      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 1),
        constraints: Constraints(networkType: NetworkType.connected),
        initialDelay: const Duration(seconds: 30),
      );

      _logger.info(
        'Registered periodic task for capsule checking (every 1 minute)',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register periodic task',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> registerAfterBoot() async {
    try {
      _logger.info('Registering background tasks after device boot');

      await initialize();
      await registerPeriodicTask();

      _logger.info('Successfully registered background tasks after boot');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register background tasks after boot',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  //Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('Cancelled all background tasks');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to cancel background tasks',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  //Check for ready capsules and send notifications
  static Future<void> checkAndNotifyReadyCapsules() async {
    try {
      _logger.info('Checking for ready capsules to notify');

      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        _logger.warning('No current user found for background check');
        return;
      }

      final allCapsules = await CapsuleService.getAllUserCapsules(
        currentUser['id'],
      );
      final now = DateTime.now();

      final overdueCapsules =
          allCapsules
              .where(
                (capsule) =>
                    !capsule.isOpened && capsule.openDate.isBefore(now),
              )
              .toList();

      if (overdueCapsules.isEmpty) {
        _logger.debug('No overdue capsules found');
        return;
      }

      _logger.info('Found ${overdueCapsules.length} overdue capsules');

      for (final capsule in overdueCapsules) {
        try {
          await CapsuleService.openCapsule(capsule.id);

          await SimpleNotificationService.showImmediateNotification(
            id: capsule.id + 10000, // Ensure unique ID
            title: ' Your Time Capsule is Ready!',
            body:
                '${capsule.title ?? "Your capsule"} is now ready to be opened!',
            payload: capsule.id.toString(),
          );

          _logger.info(
            'Auto-opened and notified for capsule',
            data: {'capsuleId': capsule.id, 'title': capsule.title},
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to process overdue capsule',
            error: e,
            stackTrace: stackTrace,
            data: {'capsuleId': capsule.id},
          );
        }
      }

      _logger.info(
        'Completed checking overdue capsules',
        data: {'processedCount': overdueCapsules.length},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to check and notify ready capsules',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<Map<String, dynamic>?> _getCurrentUser() async {
    try {
      return AuthService.currentUser;
    } catch (e) {
      _logger.error('Failed to get current user', error: e);
      return null;
    }
  }
}

// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger.forClass('BackgroundTask');

    try {
      logger.info('Executing background task: $task');

      if (task == BackgroundService._taskName) {
        await SimpleNotificationService.initialize();

        await BackgroundService.checkAndNotifyReadyCapsules();

        logger.info('Background task completed successfully');
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      logger.error('Background task failed', error: e, stackTrace: stackTrace);
      return Future.value(false);
    }
  });
}
