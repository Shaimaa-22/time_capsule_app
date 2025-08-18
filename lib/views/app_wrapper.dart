import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/theme_service.dart';
import '../services/onboarding_service.dart';
import '../services/app_initialization_service.dart';
import '../services/localization_service.dart';
import '../utils/logger.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AppWrapper extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppWrapper({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeService, OnboardingService, LocalizationService>(
      builder: (
        context,
        themeService,
        onboardingService,
        localizationService,
        child,
      ) {
        try {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: localizationService.getString('app_title'),
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            locale: localizationService.currentLocale,
            supportedLocales: localizationService.getSupportedLocales(),
            localizationsDelegates: const [
              AppLocalizationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute:
                '/splash', // Placeholder for async route determination
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/splash': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
            },
            navigatorObservers: [_LoggingNavigatorObserver()],
            onGenerateRoute: _generateRoute,
            builder: (context, child) {
              try {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    AppInitializationService.handleAutoStartAfterBoot();
                  } catch (error, stackTrace) {
                    Logger.error(
                      'Failed to handle auto start after boot: $error',
                      stackTrace: stackTrace,
                    );
                  }
                });
              } catch (error, stackTrace) {
                Logger.error(
                  'Failed to add post frame callback: $error',
                  stackTrace: stackTrace,
                );
              }

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    themeService.isDarkMode
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark,
                child: Directionality(
                  textDirection:
                      localizationService.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
          );
        } catch (error, stackTrace) {
          Logger.error(
            'Failed to build MaterialApp: $error',
            stackTrace: stackTrace,
          );
          return _buildErrorApp(error.toString());
        }
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case '/splash':
          return _createFadeRoute(settings, const SplashScreen());
        case '/onboarding':
          return _createFadeRoute(settings, const OnboardingScreen());
        case '/login':
          return _createSlideRoute(settings, const LoginScreen());
        case '/home':
          return _createScaleRoute(settings, const HomeScreen());
        default:
          return null;
      }
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to generate route for ${settings.name}: $error',
        stackTrace: stackTrace,
      );
      return _createErrorRoute(settings, error.toString());
    }
  }

  PageRouteBuilder _createFadeRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  PageRouteBuilder _createSlideRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  PageRouteBuilder _createScaleRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
    );
  }

  MaterialPageRoute _createErrorRoute(RouteSettings settings, String error) {
    return MaterialPageRoute(
      builder:
          (context) => Scaffold(
            appBar: AppBar(title: Text(context.tr('common.error'))),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Failed to load ${settings.name}'),
                  const SizedBox(height: 8),
                  Text('Error: $error'),
                ],
              ),
            ),
          ),
    );
  }

  MaterialApp _buildErrorApp(String error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App Build Error'),
              const SizedBox(height: 8),
              Text(error),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      super.didPush(route, previousRoute);
      Logger.navigation(
        route.settings.name ?? 'Unknown',
        from: previousRoute?.settings.name,
      );
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to log navigation push: $error',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      super.didPop(route, previousRoute);
      Logger.navigation(
        'Popped: ${route.settings.name ?? 'Unknown'}',
        from: previousRoute?.settings.name,
      );
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to log navigation pop: $error',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    try {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      Logger.navigation(
        'Replaced: ${newRoute?.settings.name ?? 'Unknown'}',
        from: oldRoute?.settings.name,
      );
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to log navigation replace: $error',
        stackTrace: stackTrace,
      );
    }
  }
}

class AppWrapperWithAsyncRoute extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppWrapperWithAsyncRoute({super.key, required this.navigatorKey});

  @override
  State<AppWrapperWithAsyncRoute> createState() =>
      _AppWrapperWithAsyncRouteState();
}

class _AppWrapperWithAsyncRouteState extends State<AppWrapperWithAsyncRoute> {
  String? _initialRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;

      if (!languageSelected) {
        _initialRoute = '/language-selection';
      } else {
        _initialRoute =
            onboardingService.isOnboardingCompleted ? '/splash' : '/onboarding';
      }
    } catch (e) {
      _initialRoute = '/language-selection'; // Safe fallback
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case '/splash':
          return _createFadeRoute(settings, const SplashScreen());
        case '/onboarding':
          return _createFadeRoute(settings, const OnboardingScreen());
        case '/login':
          return _createSlideRoute(settings, const LoginScreen());
        case '/home':
          return _createScaleRoute(settings, const HomeScreen());
        default:
          return null;
      }
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to generate route for ${settings.name}: $error',
        stackTrace: stackTrace,
      );
      return _createErrorRoute(settings, error.toString());
    }
  }

  PageRouteBuilder _createFadeRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  PageRouteBuilder _createSlideRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  PageRouteBuilder _createScaleRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
    );
  }

  MaterialPageRoute _createErrorRoute(RouteSettings settings, String error) {
    return MaterialPageRoute(
      builder:
          (context) => Scaffold(
            appBar: AppBar(title: Text(context.tr('common.error'))),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Failed to load ${settings.name}'),
                  const SizedBox(height: 8),
                  Text('Error: $error'),
                ],
              ),
            ),
          ),
    );
  }

  MaterialApp _buildErrorApp(String error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App Build Error'),
              const SizedBox(height: 8),
              Text(error),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer3<ThemeService, OnboardingService, LocalizationService>(
      builder: (
        context,
        themeService,
        onboardingService,
        localizationService,
        child,
      ) {
        try {
          return MaterialApp(
            navigatorKey: widget.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: localizationService.getString('app_title'),
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            locale: localizationService.currentLocale,
            supportedLocales: localizationService.getSupportedLocales(),
            localizationsDelegates: const [
              AppLocalizationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: _initialRoute,
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/onboarding': (_) => const OnboardingScreen(),
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
            },
            navigatorObservers: [_LoggingNavigatorObserver()],
            onGenerateRoute: _generateRoute,
            builder: (context, child) {
              try {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    AppInitializationService.handleAutoStartAfterBoot();
                  } catch (error, stackTrace) {
                    Logger.error(
                      'Failed to handle auto start after boot: $error',
                      stackTrace: stackTrace,
                    );
                  }
                });
              } catch (error, stackTrace) {
                Logger.error(
                  'Failed to add post frame callback: $error',
                  stackTrace: stackTrace,
                );
              }

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    themeService.isDarkMode
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark,
                child: Directionality(
                  textDirection:
                      localizationService.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
          );
        } catch (error, stackTrace) {
          Logger.error(
            'Failed to build MaterialApp: $error',
            stackTrace: stackTrace,
          );
          return _buildErrorApp(error.toString());
        }
      },
    );
  }
}
