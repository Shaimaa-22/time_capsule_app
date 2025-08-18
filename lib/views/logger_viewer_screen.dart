import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../utils/logger.dart';
import '../utils/twested.dart';

class LoggerViewerScreen extends StatefulWidget {
  const LoggerViewerScreen({super.key});

  @override
  State<LoggerViewerScreen> createState() => _LoggerViewerScreenState();
}

class _LoggerViewerScreenState extends State<LoggerViewerScreen> {
  final List<Map<String, dynamic>> _logs = [];
  LogLevel _selectedLevel = LogLevel.debug;

  @override
  void initState() {
    super.initState();
    _loadRecentLogs();
  }

  void _loadRecentLogs() {
    _logs.addAll([
      {
        'level': LogLevel.info,
        'message': 'App initialized successfully',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'tag': 'APP',
      },
      {
        'level': LogLevel.debug,
        'message': 'Theme service initialized with mode: ThemeMode.system',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
        'tag': 'THEME',
      },
      {
        'level': LogLevel.info,
        'message': 'User authenticated successfully',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
        'tag': 'AUTH',
      },
      {
        'level': LogLevel.warning,
        'message': 'Network request took longer than expected',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
        'tag': 'NETWORK',
      },
      {
        'level': LogLevel.error,
        'message': 'Failed to load capsule image',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
        'tag': 'CAPSULE',
      },
    ]);
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs
        .where((log) => log['level'].index >= _selectedLevel.index)
        .toList();
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return ThemeService.getPrimaryColor(context);
      case LogLevel.info:
        return ThemeService.getSuccessColor(context);
      case LogLevel.warning:
        return ThemeService.getWarningColor(context);
      case LogLevel.error:
        return ThemeService.getDangerColor(context);
      case LogLevel.critical:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.code;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.critical:
        return Icons.dangerous;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('logger.title'),
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
        actions: [
          DropdownButton<LogLevel>(
            value: _selectedLevel,
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            underline: Container(),
            items:
                LogLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForLevel(level),
                          color: _getColorForLevel(level),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(level.name.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (level) {
              if (level != null) {
                setState(() => _selectedLevel = level);
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: context.tr('logger.clear_logs'),
            onPressed: () {
              setState(() => _logs.clear());
              TwistedSnackBar.showInfo(
                context,
                context.tr('logger.logs_cleared'),
              );
            },
          ),
        ],
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
            _filteredLogs.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('logger.no_logs'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('logger.no_logs_subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    final level = log['level'] as LogLevel;
                    final message = log['message'] as String;
                    final timestamp = log['timestamp'] as DateTime;
                    final tag = log['tag'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Theme.of(context).colorScheme.surface,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          _getIconForLevel(level),
                          color: _getColorForLevel(level),
                          size: 20,
                        ),
                        title: Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (tag != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorForLevel(
                                    level,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getColorForLevel(level),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.copy,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message));
                            TwistedSnackBar.showSuccess(
                              context,
                              'Log copied to clipboard',
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: ThemeService.getPrimaryGradient(context),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ThemeService.getPrimaryColor(
                context,
              ).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _logs.insert(0, {
                'level': LogLevel.info,
                'message': context.tr('logger.test_log_generated'),
                'timestamp': DateTime.now(),
                'tag': 'TEST',
              });
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
