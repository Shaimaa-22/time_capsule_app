import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/logger.dart';
import '../utils/responsive_helper.dart';
import '../services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static final _logger = Logger.forClass('SplashScreen');

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    try {
      _initializeAnimations();
      _startAnimations();
      _scheduleNavigation();
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing splash screen',
        error: e,
        stackTrace: stackTrace,
      );
      _navigateNext();
    }
  }

  void _initializeAnimations() {
    try {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _scaleController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _slideController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
      );

      _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      );

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing animations',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _startAnimations() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _fadeController.forward();

      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _scaleController.forward();

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _slideController.forward();
    } catch (e, stackTrace) {
      _logger.error(
        'Error starting animations',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _scheduleNavigation() {
    try {
      _navigationTimer = Timer(const Duration(seconds: 3), () {
        _navigateNext();
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Error scheduling navigation',
        error: e,
        stackTrace: stackTrace,
      );
      _navigateNext();
    }
  }

  void _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    try {
      _navigationTimer?.cancel();
      _fadeController.dispose();
      _scaleController.dispose();
      _slideController.dispose();
    } catch (e, stackTrace) {
      _logger.error(
        'Error disposing splash screen resources',
        error: e,
        stackTrace: stackTrace,
      );
    }
    super.dispose();
  }

  Widget _buildErrorFallback() {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              context.tr('splash.loading_error'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('splash.restart_message'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateNext,
              child: Text(context.tr('splash.continue')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final animationSize = ResponsiveHelper.animationSize(context);

      return Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                try {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 2000),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(
                            0xFF00B4DB,
                          ).withValues(alpha: _fadeAnimation.value),
                          Color(
                            0xFF8E2DE2,
                          ).withValues(alpha: _fadeAnimation.value),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                } catch (e, stackTrace) {
                  _logger.error(
                    'Error building gradient background',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  return Container(color: Colors.blue);
                }
              },
            ),

            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                try {
                  return Positioned(
                    top: -50 + (_slideAnimation.value.dy * -20),
                    left: -50 + (_slideAnimation.value.dx * -20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RotationTransition(
                        turns: _scaleController,
                        child: Image.asset(
                          'assets/icons/icon.png',
                          width: ResponsiveHelper.isMobile(context) ? 150 : 200,
                          errorBuilder: (context, error, stackTrace) {
                            _logger.error(
                              'Error loading icon image',
                              error: error,
                              stackTrace: stackTrace,
                            );
                            return Icon(
                              Icons.apps,
                              size:
                                  ResponsiveHelper.isMobile(context)
                                      ? 150
                                      : 200,
                              color: Colors.white30,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                } catch (e, stackTrace) {
                  _logger.error(
                    'Error building decorative shape',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  return const SizedBox.shrink();
                }
              },
            ),

            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeController,
                  _scaleController,
                  _slideController,
                ]),
                builder: (context, child) {
                  try {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.isMobile(context) ? 25 : 30,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.3 * _fadeAnimation.value,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.isMobile(context) ? 25 : 30,
                                ),
                                child: Image.asset(
                                  'assets/icons/splash.jpg',
                                  width: animationSize,
                                  height: animationSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    _logger.error(
                                      'Error loading splash image',
                                      error: error,
                                      stackTrace: stackTrace,
                                    );
                                    return Container(
                                      width: animationSize,
                                      height: animationSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          ResponsiveHelper.isMobile(context)
                                              ? 25
                                              : 30,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.access_time,
                                        size: animationSize * 0.3,
                                        color: Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e, stackTrace) {
                    _logger.error(
                      'Error building main logo',
                      error: e,
                      stackTrace: stackTrace,
                    );
                    return const Icon(
                      Icons.access_time,
                      size: 100,
                      color: Colors.white,
                    );
                  }
                },
              ),
            ),

            Positioned(
              bottom: ResponsiveHelper.isMobile(context) ? 80 : 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 16 : 20,
                    ),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        context.tr('splash.loading'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.bodyFontSize(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error building splash screen',
        error: e,
        stackTrace: stackTrace,
      );
      return _buildErrorFallback();
    }
  }
}
