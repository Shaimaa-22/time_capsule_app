import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/onboarding_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/language_switcher.dart';
import '../utils/logger.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  List<OnboardingPage> _getPages(BuildContext context) {
    Logger.ui(
      "Getting onboarding pages for language: ${context.localization.currentLanguageCode}",
    );

    return [
      OnboardingPage(
        title: context.tr('onboarding.page1.title'),
        description: context.tr('onboarding.page1.description'),
        icon: Icons.access_time_rounded,
        gradient: ThemeService.primaryGradient,
      ),
      OnboardingPage(
        title: context.tr('onboarding.page2.title'),
        description: context.tr('onboarding.page2.description'),
        icon: Icons.add_circle_outline_rounded,
        gradient: ThemeService.successGradient,
      ),
      OnboardingPage(
        title: context.tr('onboarding.page3.title'),
        description: context.tr('onboarding.page3.description'),
        icon: Icons.schedule_rounded,
        gradient: ThemeService.warningGradient,
      ),
      OnboardingPage(
        title: context.tr('onboarding.page4.title'),
        description: context.tr('onboarding.page4.description'),
        icon: Icons.rocket_launch_rounded,
        gradient: ThemeService.dangerGradient,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startPageAnimations();
    _pulseController.repeat(reverse: true);
  }

  void _startPageAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final pages = _getPages(context);
    if (_currentPage < pages.length - 1) {
      _resetAnimations();
      _pageController
          .nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            _startPageAnimations();
          });
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _resetAnimations();
      _pageController
          .previousPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            _startPageAnimations();
          });
    }
  }

  void _completeOnboarding() async {
    try {
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.completeOnboarding();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to complete onboarding: $error',
        stackTrace: stackTrace,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        Logger.ui(
          "Building onboarding screen with language: ${localizationService.currentLanguageCode}",
        );
        final pages = _getPages(context);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const LanguageToggleButton(),
                              Row(
                                children: List.generate(
                                  pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentPage == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color:
                                          _currentPage == index
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                      boxShadow:
                                          _currentPage == index
                                              ? [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedScale(
                                scale:
                                    _currentPage == pages.length - 1
                                        ? 0.0
                                        : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: TextButton(
                                  onPressed: _skipOnboarding,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('onboarding.skip'),
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _buildOnboardingPage(pages[index]);
                      },
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Previous button with slide animation
                              AnimatedSlide(
                                offset:
                                    _currentPage > 0
                                        ? Offset.zero
                                        : const Offset(-1, 0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: AnimatedOpacity(
                                  opacity: _currentPage > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: TextButton.icon(
                                    onPressed:
                                        _currentPage > 0 ? _previousPage : null,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_rounded,
                                    ),
                                    label: Text(
                                      context.tr('onboarding.previous'),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Next/Complete button with pulse animation
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale:
                                        _currentPage == pages.length - 1
                                            ? _pulseAnimation.value
                                            : 1.0,
                                    child: ElevatedButton.icon(
                                      onPressed: _nextPage,
                                      icon: Icon(
                                        _currentPage == pages.length - 1
                                            ? Icons.rocket_launch_rounded
                                            : Icons.arrow_forward_ios_rounded,
                                      ),
                                      label: Text(
                                        _currentPage == pages.length - 1
                                            ? context.tr('onboarding.start')
                                            : context.tr('onboarding.next'),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 8,
                                        shadowColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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
      },
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: page.gradient,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: page.gradient.colors.first.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: page.gradient.colors.last.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 40,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Icon(page.icon, size: 60, color: Colors.white),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
                    ),
                  ),
                  child: Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
