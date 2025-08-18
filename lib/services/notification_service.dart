import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/capsule.dart';
import '../utils/logger.dart';

class NotificationService {
  static final _logger = Logger.forClass('NotificationService');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Function(String title, String body, String? payload)?
  onForegroundNotification;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    _logger.info('Initializing notification service');

    // Initialize timezone data
    tz.initializeTimeZones();

    //  initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    await _createNotificationChannels();

    _initialized = true;
    _logger.info('Notification service initialized successfully');
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      //  for capsule ready notifications
      const AndroidNotificationChannel capsuleReadyChannel =
          AndroidNotificationChannel(
            'capsule_ready',
            'Capsule Ready',
            description: 'Notifications when time capsules are ready to open',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );

      //  for immediate notifications
      const AndroidNotificationChannel immediateChannel =
          AndroidNotificationChannel(
            'immediate',
            'Immediate Notifications',
            description: 'Immediate notifications for app events',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );

      await androidImplementation.createNotificationChannel(
        capsuleReadyChannel,
      );
      await androidImplementation.createNotificationChannel(immediateChannel);

      _logger.info('Android notification channels created');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    _logger.info(
      'Notification tapped',
      data: {'id': response.id, 'payload': response.payload},
    );
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    _logger.info(
      'Background notification tapped',
      data: {'id': response.id, 'payload': response.payload},
    );
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    _logger.info('Requesting notification permissions');

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      bool granted = true;

      if (androidImplementation != null) {
        try {
          granted =
              await androidImplementation.requestNotificationsPermission() ??
              true;
        } catch (e) {
          _logger.warning(
            'Android permission request failed, assuming granted for older version',
            error: e,
          );
          granted = true;
        }
      }

      _logger.info('Notification permissions granted: $granted');
      return granted;
    } catch (e, stackTrace) {
      _logger.error(
        'Error requesting permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return true;
    }
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
        'Time Capsule Ready!',
        '${capsule.title ?? "Your capsule"} is now ready to open!',
        scheduledDate,
        const NotificationDetails(
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
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
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

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool forceShow = false,
  }) async {
    if (!_initialized) await initialize();

    try {
      if (forceShow && onForegroundNotification != null) {
        onForegroundNotification!(title, body, payload);
        return;
      }

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
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          ),
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

  //Get all pending notifications
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

  // Cancel all notifications
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

  static Future<void> checkAndNotifyReadyCapsules(
    List<Capsule> capsules, {
    bool isAppInForeground = false,
  }) async {
    int notificationId = 1000; //unique ID for notifications

    for (final capsule in capsules) {
      if (!capsule.isLocked && !capsule.isOpened && !capsule.notificationSent) {
        await showImmediateNotification(
          id: notificationId++,
          title: ' Time Capsule Ready!',
          body: '${capsule.title ?? "Your capsule"} is now ready to open!',
          payload: capsule.id.toString(),
          forceShow: isAppInForeground,
        );

        _logger.info(
          'Showed ready notification for capsule',
          data: {'capsuleId': capsule.id, 'title': capsule.title},
        );
      }
    }
  }

  //Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }

      return true;
    } catch (e) {
      _logger.warning('Could not check notification status', error: e);
      return true;
    }
  }
}
