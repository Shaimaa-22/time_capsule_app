import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../models/capsule.dart';
import '../services/capsule_service.dart';
import '../services/theme_service.dart';
import '../utils/logger.dart';

class CapsuleDetailScreen extends StatefulWidget {
  final Capsule capsule;

  const CapsuleDetailScreen({required this.capsule, super.key});

  @override
  State<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends State<CapsuleDetailScreen> {
  static final _logger = Logger.forClass('CapsuleDetailScreen');
  late Capsule _capsule;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
  }

  Future<void> _openCapsule() async {
    if (_capsule.isLocked) return;

    setState(() => _isOpening = true);

    try {
      await CapsuleService.openCapsule(_capsule.id);
      setState(() {
        _capsule = Capsule(
          id: _capsule.id,
          ownerId: _capsule.ownerId,
          recipientEmail: _capsule.recipientEmail,
          contentType: _capsule.contentType,
          contentEncrypted: _capsule.contentEncrypted,
          openDate: _capsule.openDate,
          createdAt: _capsule.createdAt,
          isOpened: true,
          title: _capsule.title,
          openedAt: DateTime.now(),
          notificationSent: _capsule.notificationSent,
        );
      });

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '🎉 Capsule opened successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getSuccessColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e, stackTrace) {
      _logger.error('Error opening capsule', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Error opening capsule: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getDangerColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _capsule.isLocked;
    final daysLeft =
        isLocked ? _capsule.openDate.difference(DateTime.now()).inDays : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _capsule.title ?? 'Time Capsule',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient:
                isLocked
                    ? ThemeService.warningGradient
                    : ThemeService.successGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isLocked
                      ? ThemeService.getWarningColor(context)
                      : ThemeService.getSuccessColor(context))
                  .withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: (isLocked
                              ? ThemeService.getWarningColor(context)
                              : ThemeService.getSuccessColor(context))
                          .withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.8, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient:
                                  isLocked
                                      ? ThemeService.warningGradient
                                      : ThemeService.successGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: (isLocked
                                          ? ThemeService.getWarningColor(
                                            context,
                                          )
                                          : ThemeService.getSuccessColor(
                                            context,
                                          ))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Icon(
                              isLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isLocked ? '🔒 Locked' : '🎉 Unlocked',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color:
                            isLocked
                                ? ThemeService.getWarningColor(context)
                                : ThemeService.getSuccessColor(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isLocked) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeService.getWarningColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          daysLeft > 0
                              ? '$daysLeft days remaining'
                              : 'Ready to open!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                daysLeft > 0
                                    ? ThemeService.getWarningColor(context)
                                    : ThemeService.getSuccessColor(context),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeService.getSuccessColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Opened on ${DateFormat.yMMMd().format(_capsule.openedAt ?? DateTime.now())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ThemeService.getSuccessColor(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capsule Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection('Title', _capsule.title ?? 'Untitled'),
                    _buildDetailSection(
                      'Content Type',
                      _capsule.contentType.toUpperCase(),
                    ),
                    _buildDetailSection(
                      'Created',
                      DateFormat.yMMMd().add_jm().format(_capsule.createdAt),
                    ),
                    _buildDetailSection(
                      'Opens On',
                      DateFormat.yMMMd().add_jm().format(_capsule.openDate),
                    ),
                    if (_capsule.recipientEmail != null)
                      _buildDetailSection(
                        'Recipient',
                        _capsule.recipientEmail!,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeService.getPrimaryColor(
                              context,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.message_rounded,
                            color: ThemeService.getPrimaryColor(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Content',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.visibility_off_rounded,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Content is locked',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Available on ${DateFormat.yMMMd().format(_capsule.openDate)} at ${DateFormat.jm().format(_capsule.openDate)}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildContentDisplay(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!isLocked && !_capsule.isOpened)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.9, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: ThemeService.successGradient,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeService.getSuccessColor(
                                context,
                              ).withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                _isOpening
                                    ? null
                                    : () {
                                      HapticFeedback.heavyImpact();
                                      _openCapsule();
                                    },
                            borderRadius: BorderRadius.circular(32),
                            child: Center(
                              child:
                                  _isOpening
                                      ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                      : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_open_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Open Capsule 🎁',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentDisplay() {
    try {
      if (_capsule.contentType.toLowerCase() == 'image') {
        final contentData = jsonDecode(_capsule.contentEncrypted);
        final base64Data = contentData['data'] as String;
        final filename = contentData['filename'] as String?;
        final description = contentData['description'] as String?;

        final Uint8List imageBytes = base64Decode(base64Data);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filename != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeService.getPrimaryColor(
                      context,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'File: $filename',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeService.getPrimaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ThemeService.getDangerColor(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_rounded,
                            color: ThemeService.getDangerColor(context),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading image',
                            style: TextStyle(
                              color: ThemeService.getDangerColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            _capsule.contentEncrypted,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.error('Error displaying content: $e');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeService.getWarningColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeService.getWarningColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: ThemeService.getWarningColor(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Content display error',
                  style: TextStyle(
                    color: ThemeService.getWarningColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _capsule.contentEncrypted,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }
  }
}
