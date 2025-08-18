import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class SubmitButtonsWidget extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const SubmitButtonsWidget({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<SubmitButtonsWidget> createState() => _SubmitButtonsWidgetState();
}

class _SubmitButtonsWidgetState extends State<SubmitButtonsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onButtonPressed() async {
    if (widget.isLoading) return;

    HapticFeedback.heavyImpact();
    await _animationController.forward();
    await _animationController.reverse();
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isMobile(context) ? 20 : 24,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        widget.isLoading
                            ? LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                            )
                            : const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFF9B59B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isMobile(context) ? 16 : 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Creating...',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.titleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Create Time Capsule',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.titleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
