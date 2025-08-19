import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/capsule.dart';
import '../utils/logger.dart';

class SimpleNotificationService {
  static final _logger = Logger.forClass('SimpleNotificationService');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    _logger.info('Initializing simple notification service');

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');


    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    _logger.info('Simple notification service initialized successfully');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    _logger.info(
      'Notification tapped',
      data: {'id': response.id, 'payload': response.payload},
    );
  }

  static Future<bool> requestPermissions() async {
    _logger.info('Requesting notification permissions (simplified)');

    final iosImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  static Future<void> scheduleCapsuleNotification(Capsule capsule) async {
    if (!_initialized) await initialize();

    try {
      final scheduledDate = tz.TZDateTime.from(capsule.openDate, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduledDate.isBefore(now)) {
        _logger.warning(
          'Cannot schedule notification for past date',
          data: {
            'capsuleId': capsule.id,
            'openDate': capsule.openDate.toIso8601String(),
          },
        );
        return;
      }

      await _notifications.zonedSchedule(
        capsule.id,
        ' Time Capsule Ready!',
        '${capsule.title ?? "Your capsule"} is now ready to open!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'capsule_ready',
            'Capsule Ready',
            channelDescription:
                'Notifications when time capsules are ready to open',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: capsule.id.toString(),
      );

      _logger.info(
        'Scheduled notification for capsule',
        data: {
          'capsuleId': capsule.id,
          'title': capsule.title,
          'scheduledFor': scheduledDate.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to schedule notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'immediate',
            'Immediate Notifications',
            channelDescription: 'Immediate notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(sound: 'default'),
        ),
        payload: payload,
      );

      _logger.info(
        'Showed immediate notification',
        data: {'id': id, 'title': title},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to show immediate notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> cancelCapsuleNotification(int capsuleId) async {
    try {
      await _notifications.cancel(capsuleId);
      _logger.info('Cancelled notification for capsule: $capsuleId');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to cancel notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      _logger.debug('Found ${pending.length} pending notifications');
      return pending;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get pending notifications',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.info('Cancelled all notifications');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to cancel all notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    try {
      await showImmediateNotification(
        id: 999,
        title: ' Test Notification',
        body: 'If you see this, notifications are working!',
        payload: 'test',
      );

      _logger.info('Test notification sent successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to send test notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> debugScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();
      _logger.info(
        'Debug: Found ${pending.length} pending notifications',
        data: {
          'notifications':
              pending
                  .map(
                    (n) => {
                      'id': n.id,
                      'title': n.title,
                      'body': n.body,
                      'payload': n.payload,
                    },
                  )
                  .toList(),
        },
      );

      for (final notification in pending) {
        _logger.info(
          'Pending notification details',
          data: {
            'id': notification.id,
            'title': notification.title,
            'body': notification.body,
            'payload': notification.payload,
          },
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to debug scheduled notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
