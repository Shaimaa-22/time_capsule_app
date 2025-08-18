import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/theme_service.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onThemeToggle() async {
    HapticFeedback.mediumImpact();

    // Start animations
    _scaleController.forward().then((_) => _scaleController.reverse());
    _rotationController.forward().then((_) => _rotationController.reset());

    // Toggle theme
    await Provider.of<ThemeService>(context, listen: false).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        IconData icon;
        List<Color> gradientColors;

        switch (themeService.themeMode) {
          case ThemeMode.light:
            icon = Icons.light_mode_rounded;
            gradientColors = [
              ThemeService.getPrimaryColor(context),
              ThemeService.getSecondaryColor(context),
            ];
            break;
          case ThemeMode.dark:
            icon = Icons.dark_mode_rounded;
            gradientColors = [
              ThemeService.getPrimaryColor(context),
              ThemeService.getSecondaryColor(context).withValues(alpha: 0.8),
            ];
            break;
          case ThemeMode.system:
            icon = Icons.auto_mode_rounded;
            gradientColors = [
              ThemeService.getPrimaryColor(context),
              ThemeService.getSecondaryColor(context),
            ];
            break;
        }

        return GestureDetector(
          onTap: _onThemeToggle,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
