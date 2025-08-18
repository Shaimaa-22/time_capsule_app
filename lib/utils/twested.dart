import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TwistedSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => _TwistedSnackBarWidget(
            message: message,
            backgroundColor: backgroundColor,
            duration: duration,
            icon: icon,
            onDismiss: () => overlayEntry.remove(),
          ),
    );

    overlay.insert(overlayEntry);
  }

  static void showError(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showInfo(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showWarning(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

class _TwistedSnackBarWidget extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Duration duration;
  final IconData? icon;
  final VoidCallback onDismiss;

  const _TwistedSnackBarWidget({
    required this.message,
    this.backgroundColor,
    required this.duration,
    this.icon,
    required this.onDismiss,
  });

  @override
  State<_TwistedSnackBarWidget> createState() => _TwistedSnackBarWidgetState();
}

class _TwistedSnackBarWidgetState extends State<_TwistedSnackBarWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _twistController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _twistAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _twistController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _twistAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _twistController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _twistController.forward();

    Future.delayed(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() async {
    if (mounted) {
      await _slideController.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _twistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _twistAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _twistAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _dismiss,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
