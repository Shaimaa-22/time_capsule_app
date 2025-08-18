import 'package:flutter/material.dart';
import '../services/simple_notification_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../services/capsule_service.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../models/capsule.dart';
import '../utils/logger.dart';
import '../utils/twested.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static final _logger = Logger.forClass('NotificationSettingsScreen');
  List<Map<String, dynamic>> _pendingNotifications = [];
  List<Capsule> _scheduledCapsules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await SimpleNotificationService.getPendingNotifications();
      final currentUser = AuthService.currentUser;
      List<Capsule> scheduledCapsules = [];

      if (currentUser != null) {
        final allCapsules = await CapsuleService.getAllUserCapsules(
          currentUser['id'],
        );

        _logger.info('Total capsules found: ${allCapsules.length}');

        for (var capsule in allCapsules) {
          _logger.info(
            'Capsule: ${capsule.title}, isOpened: ${capsule.isOpened}, openDate: ${capsule.openDate}, now: ${DateTime.now()}',
          );
          _logger.info(
            'Is future: ${capsule.openDate.isAfter(DateTime.now())}, Should include: ${!capsule.isOpened && capsule.openDate.isAfter(DateTime.now())}',
          );
        }

        scheduledCapsules =
            allCapsules
                .where(
                  (capsule) =>
                      !capsule.isOpened &&
                      capsule.openDate.isAfter(DateTime.now()),
                )
                .toList();

        _logger.info(
          'Filtered scheduled capsules: ${scheduledCapsules.length}',
        );
      }

      setState(() {
        _pendingNotifications =
            pending
                .map(
                  (notification) => {
                    'id': notification.id,
                    'title': notification.title ?? 'Time Capsule Ready',
                    'body':
                        notification.body ?? 'Your capsule is ready to open!',
                    'payload': notification.payload,
                    'type': 'system',
                  },
                )
                .toList();
        _scheduledCapsules = scheduledCapsules;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load pending notifications',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() => _isLoading = false);
    }
  }

  int get _totalNotificationCount =>
      _pendingNotifications.length + _scheduledCapsules.length;

  Future<void> _testNotification() async {
    await SimpleNotificationService.showImmediateNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification from Time Capsule app!',
    );

    if (!mounted) return;
    TwistedSnackBar.showSuccess(context, context.tr('notifications.test_sent'));
  }

  Future<void> _checkReadyCapsules() async {
    try {
      setState(() => _isLoading = true);

      // Check for ready capsules and send notifications
      await BackgroundService.checkAndNotifyReadyCapsules();

      // Reload the notifications list
      await _loadPendingNotifications();

      if (!mounted) return;
      TwistedSnackBar.showSuccess(
        context,
        'Checked for ready capsules and sent notifications',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to check ready capsules',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      TwistedSnackBar.showError(
        context,
        'Failed to check ready capsules: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fixOverdueCapsules() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        TwistedSnackBar.showError(context, 'No user logged in');
        return;
      }

      final allCapsules = await CapsuleService.getAllUserCapsules(
        currentUser['id'],
      );
      final now = DateTime.now();

      // Find capsules that are past their open date but still locked
      final overdueCapsules =
          allCapsules
              .where(
                (capsule) =>
                    !capsule.isOpened && capsule.openDate.isBefore(now),
              )
              .toList();

      _logger.info('Found ${overdueCapsules.length} overdue capsules');

      int fixedCount = 0;
      for (var capsule in overdueCapsules) {
        try {
          // Open the capsule
          await CapsuleService.openCapsule(capsule.id);

          await SimpleNotificationService.showImmediateNotification(
            id: capsule.id.hashCode,
            title: ' Time Capsule Opened!',
            body:
                'Your capsule "${capsule.title}" was ready and has been opened!',
          );

          fixedCount++;
          _logger.info('Fixed overdue capsule: ${capsule.title}');
        } catch (e) {
          _logger.error('Failed to fix capsule ${capsule.title}: $e');
        }
      }

      await BackgroundService.registerPeriodicTask();

      await _loadPendingNotifications();

      if (!mounted) return;
      if (fixedCount > 0) {
        TwistedSnackBar.showSuccess(
          context,
          'Fixed $fixedCount overdue capsules. Background service restarted for automatic checking.',
        );
      } else {
        TwistedSnackBar.showInfo(
          context,
          'No overdue capsules found. Background service restarted.',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to fix overdue capsules',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      TwistedSnackBar.showError(
        context,
        'Failed to fix overdue capsules: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reregisterBackgroundService() async {
    try {
      setState(() => _isLoading = true);

      await BackgroundService.registerPeriodicTask();
      await BackgroundService.checkAndNotifyReadyCapsules();

      await _loadPendingNotifications();

      if (!mounted) return;
      TwistedSnackBar.showSuccess(
        context,
        'Background service restarted and checked for ready capsules',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to re-register background service',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      TwistedSnackBar.showError(
        context,
        'Failed to restart background service: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final hasPermissions = await NotificationService.requestPermissions();
      final areEnabled = await NotificationService.areNotificationsEnabled();

      final currentUser = AuthService.currentUser;
      String capsuleDetails = 'No user logged in';

      if (currentUser != null) {
        final allCapsules = await CapsuleService.getAllUserCapsules(
          currentUser['id'],
        );
        capsuleDetails = 'Total Capsules: ${allCapsules.length}\n';

        for (var capsule in allCapsules) {
          final timeRemaining = capsule.openDate.difference(DateTime.now());
          capsuleDetails +=
              '• ${capsule.title}: ${capsule.isOpened ? "Opened" : "Locked"}, ';
          capsuleDetails += 'Opens in ${timeRemaining.inMinutes} minutes\n';
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Notification Status',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions Granted: ${hasPermissions ? "✅ Yes" : "❌ No"}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Notifications Enabled: ${areEnabled ? "✅ Yes" : "❌ No"}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'System Notifications: ${_pendingNotifications.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scheduled Capsules: ${_scheduledCapsules.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Capsule Details:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capsuleDetails,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: ThemeService.getPrimaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to check notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      TwistedSnackBar.showError(
        context,
        'Failed to check permissions: ${e.toString()}',
      );
    }
  }

  Future<void> _cancelAllNotifications() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              context.tr('notifications.cancel_all_confirm'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              context.tr('notifications.cancel_all_message'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('common.cancel'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: ThemeService.dangerGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await SimpleNotificationService.cancelAllNotifications();
                    await _loadPendingNotifications();

                    if (!mounted) return;
                    TwistedSnackBar.showInfo(
                      this.context,
                      this.context.tr('notifications.all_cancelled'),
                    );
                  },
                  child: Text(
                    context.tr('notifications.confirm'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${context.tr('notifications.title')} ($_totalNotificationCount)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeService.getPrimaryGradient(context),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeService.getPrimaryColor(context).withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: ThemeService.getPrimaryColor(context),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: ThemeService.getPrimaryColor(
                          context,
                        ).withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: ThemeService.getPrimaryGradient(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('notifications.total_pending'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '$_totalNotificationCount',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeService.getPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_totalNotificationCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeService.getWarningColor(
                                      context,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    context.tr('notifications.active'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeService.getWarningColor(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Diagnostic Tools',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: ThemeService.getPrimaryGradient(
                                  context,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _checkReadyCapsules,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Check Ready',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _reregisterBackgroundService,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                icon: const Icon(
                                  Icons.settings_backup_restore,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Fix Background',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red, Colors.redAccent],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _fixOverdueCapsules,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                icon: const Icon(
                                  Icons.update,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Fix Overdue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal, Colors.cyan],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _checkNotificationPermissions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                icon: const Icon(
                                  Icons.info,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Check Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        context.tr('notifications.title'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          leading: Icon(
                            Icons.notifications_active,
                            color: ThemeService.getPrimaryColor(context),
                          ),
                          title: Text(
                            context.tr('notifications.test_notification'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            context.tr('notifications.test_subtitle'),
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              gradient: ThemeService.getPrimaryGradient(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              onPressed: _testNotification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(
                                context.tr('notifications.test_button'),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.tr(
                                  'notifications.scheduled_notifications_title',
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ThemeService.getPrimaryColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_totalNotificationCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_totalNotificationCount > 0)
                            TextButton(
                              onPressed: _cancelAllNotifications,
                              child: Text(
                                context.tr('notifications.cancel_all'),
                                style: TextStyle(
                                  color: ThemeService.getDangerColor(context),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_totalNotificationCount == 0)
                        Card(
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.tr('notifications.no_scheduled'),
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ...(_pendingNotifications.map(
                          (notification) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Theme.of(context).colorScheme.surface,
                            child: ListTile(
                              leading: Icon(
                                Icons.schedule,
                                color: ThemeService.getWarningColor(context),
                              ),
                              title: Text(
                                notification['title'] as String,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                notification['body'] as String,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.cancel,
                                  color: ThemeService.getDangerColor(context),
                                ),
                                onPressed: () async {
                                  await SimpleNotificationService.cancelCapsuleNotification(
                                    notification['id'] as int,
                                  );
                                  await _loadPendingNotifications();

                                  if (!mounted) return;
                                  TwistedSnackBar.showInfo(
                                    this.context,
                                    this.context.tr(
                                      'notifications.notification_cancelled',
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )),

                        ...(_scheduledCapsules.map(
                          (capsule) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Theme.of(context).colorScheme.surface,
                            child: ListTile(
                              leading: Icon(
                                Icons.access_time,
                                color: ThemeService.getPrimaryColor(context),
                              ),
                              title: Text(
                                capsule.title ?? 'Time Capsule',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Opens: ${_formatDateTime(capsule.openDate)}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _getTimeRemaining(capsule.openDate),
                                    style: TextStyle(
                                      color: ThemeService.getPrimaryColor(
                                        context,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.schedule_send,
                                color: ThemeService.getPrimaryColor(context),
                              ),
                            ),
                          ),
                        )),
                      ],

                      const SizedBox(height: 24),

                      Text(
                        context.tr('notifications.about_notifications'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                Icons.schedule,
                                context.tr('notifications.auto_scheduling'),
                                context.tr(
                                  'notifications.auto_scheduling_desc',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.battery_saver,
                                context.tr('notifications.background_checks'),
                                context.tr(
                                  'notifications.background_checks_desc',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.settings,
                                context.tr('notifications.system_settings'),
                                context.tr(
                                  'notifications.system_settings_desc',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        color: ThemeService.getPrimaryColor(
                          context,
                        ).withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: ThemeService.getPrimaryColor(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr(
                                      'notifications.notification_status',
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('notifications.status_message'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: ThemeService.getPrimaryGradient(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            title: Text(
                                              context.tr(
                                                'notifications.help_title',
                                              ),
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            content: Text(
                                              context.tr(
                                                'notifications.help_message',
                                              ),
                                              style: TextStyle(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  context.tr('common.ok'),
                                                  style: TextStyle(
                                                    color:
                                                        ThemeService.getPrimaryColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  icon: const Icon(
                                    Icons.help_outline,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    context.tr('notifications.troubleshooting'),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTimeRemaining(DateTime openDate) {
    final now = DateTime.now();
    final difference = openDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes remaining';
    } else {
      return 'Opening soon';
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ThemeService.getPrimaryColor(context), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
