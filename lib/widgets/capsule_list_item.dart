import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/capsule.dart';

class CapsuleListItem extends StatefulWidget {
  final Capsule capsule;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const CapsuleListItem({
    super.key,
    required this.capsule,
    this.onTap,
    this.onShare,
    this.onDelete,
  });

  @override
  State<CapsuleListItem> createState() => _CapsuleListItemState();
}

class _CapsuleListItemState extends State<CapsuleListItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLocked = widget.capsule.openDate.isAfter(now);
    final difference = widget.capsule.openDate.difference(now);

    String timeText;
    String statusEmoji;
    Color statusColor;

    if (isLocked) {
      if (difference.inDays > 0) {
        timeText = '${difference.inDays} days left';
      } else if (difference.inHours > 0) {
        timeText = '${difference.inHours} hours left';
      } else {
        timeText = '${difference.inMinutes} minutes left';
      }
      statusEmoji = '🔒';
      statusColor = const Color(0xFFFDCB6E);
    } else {
      timeText = 'Ready to open!';
      statusEmoji = '✨';
      statusColor = Theme.of(context).colorScheme.tertiary;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color:
                        _isPressed
                            ? statusColor.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.06),
                    blurRadius: _isPressed ? 20 : 30,
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ],
                border:
                    _isPressed
                        ? Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 2,
                        )
                        : null,
              ),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.2),
                          statusColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.capsule.title ?? 'Untitled Capsule',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.2),
                                    statusColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isLocked ? 'Locked' : 'Ready',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          timeText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '📅 ${widget.capsule.openDate.day}/${widget.capsule.openDate.month}/${widget.capsule.openDate.year} at ${widget.capsule.openDate.hour}:${widget.capsule.openDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Column(
                    children: [
                      if (widget.onShare != null)
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: widget.onShare!,
                        ),

                      if (widget.onShare != null && widget.onDelete != null)
                        const SizedBox(height: 8),

                      if (widget.onDelete != null)
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: Theme.of(context).colorScheme.error,
                          onTap: widget.onDelete!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
