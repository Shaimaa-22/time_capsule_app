import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../view_models/auth_view_model.dart';
import '../utils/logger.dart';
import '../utils/responsive_helper.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static final _logger = Logger.forClass('LoginScreen');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _focusEmail = FocusNode();
  final FocusNode _focusPassword = FocusNode();

  late final AnimationController _animController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    try {
      _animController = AnimationController(vsync: this);

      _focusEmail.addListener(() {
        try {
          if (_focusEmail.hasFocus) _animController.forward(from: 0);
          if (mounted) setState(() {});
        } catch (e, stackTrace) {
          _logger.error(
            'Error in email focus listener',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });

      _focusPassword.addListener(() {
        try {
          if (_focusPassword.hasFocus) _animController.forward(from: 0);
          if (mounted) setState(() {});
        } catch (e, stackTrace) {
          _logger.error(
            'Error in password focus listener',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing login screen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    try {
      _emailController.dispose();
      _passwordController.dispose();
      _focusEmail.dispose();
      _focusPassword.dispose();
      _animController.dispose();
    } catch (e, stackTrace) {
      _logger.error(
        'Error disposing login screen resources',
        error: e,
        stackTrace: stackTrace,
      );
    }
    super.dispose();
  }

  Widget buildTextField(
    String label,
    TextEditingController controller,
    FocusNode focusNode, {
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    try {
      return Container(
        decoration: BoxDecoration(
          boxShadow:
              focusNode.hasFocus
                  ? [
                    BoxShadow(
                      color: ThemeService.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: ThemeService.getPrimaryColor(context),
                width: 2.5,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error building text field',
        error: e,
        stackTrace: stackTrace,
      );
      return TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label),
      );
    }
  }

  bool _validateInputs() {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty) {
        _showErrorToast(context.tr('login.email_required'));
        return false;
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(email)) {
        _showErrorToast(context.tr('login.email_invalid'));
        return false;
      }

      if (password.isEmpty) {
        _showErrorToast(context.tr('login.password_required'));
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error validating inputs',
        error: e,
        stackTrace: stackTrace,
      );
      _showErrorToast(context.tr('login.validation_error'));
      return false;
    }
  }

  void _showErrorToast(String message) {
    try {
      if (mounted) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: ThemeService.getDangerColor(context),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Error showing toast', error: e, stackTrace: stackTrace);
    }
  }

  void _showSuccessToast(String message) {
    try {
      if (mounted) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: ThemeService.getSuccessColor(context),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error showing success toast',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleLogin() async {
    try {
      if (!_validateInputs()) return;

      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      final success = await authVM.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessToast(context.tr('login.login_successful'));

        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Error navigating to home screen',
            error: e,
            stackTrace: stackTrace,
          );
          _showErrorToast(context.tr('login.navigation_error'));
        }
      } else {
        String errorMsg =
            authVM.errorMessage ?? context.tr('login.login_failed');
        if (errorMsg.contains("user not found")) {
          errorMsg = context.tr('login.user_not_found');
        } else if (errorMsg.contains("wrong password")) {
          errorMsg = context.tr('login.wrong_password');
        }
        _showErrorToast(errorMsg);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error during login process',
        error: e,
        stackTrace: stackTrace,
      );
      _showErrorToast(context.tr('login.login_error'));
    }
  }

  void _navigateToRegister() {
    try {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error navigating to register screen',
        error: e,
        stackTrace: stackTrace,
      );
      _showErrorToast(context.tr('login.navigation_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final localizationService = LocalizationService();
      Logger.debug(
        "[v0] LoginScreen build - Localization initialized: ${localizationService.isInitialized}",
        tag: 'LOGIN_DEBUG',
      );
      Logger.debug(
        "[v0] LoginScreen build - Current language: ${localizationService.currentLanguageCode}",
        tag: 'LOGIN_DEBUG',
      );
      Logger.debug(
        "[v0] LoginScreen build - Testing welcome_back translation: ${context.tr('login.welcome_back')}",
        tag: 'LOGIN_DEBUG',
      );
      Logger.debug(
        "[v0] LoginScreen build - Testing subtitle translation: ${context.tr('login.subtitle')}",
        tag: 'LOGIN_DEBUG',
      );

      final authVM = Provider.of<AuthViewModel>(context);
      final screenHeight = ResponsiveHelper.screenHeight(context);
      final animationSize = ResponsiveHelper.animationSize(context);
      final containerWidth = ResponsiveHelper.containerWidth(context);

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: ThemeService.getPrimaryGradient(context),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.responsivePadding(context),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        screenHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: animationSize,
                          height: animationSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Lottie.asset(
                            'assets/animation/Panda.json',
                            controller: _animController,
                            onLoaded: (composition) {
                              try {
                                _animController.duration = composition.duration;
                              } catch (e, stackTrace) {
                                _logger.error(
                                  'Error setting animation duration',
                                  error: e,
                                  stackTrace: stackTrace,
                                );
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              _logger.error(
                                'Error loading Lottie animation',
                                error: error,
                                stackTrace: stackTrace,
                              );
                              return Icon(
                                Icons.access_time_rounded,
                                size: animationSize * 0.4,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.isMobile(context) ? 32 : 40,
                        ),
                        Builder(
                          builder: (context) {
                            final welcomeText = context.tr(
                              'login.welcome_back',
                            );
                            Logger.debug(
                              "[v0] Welcome text result: '$welcomeText'",
                              tag: 'LOGIN_DEBUG',
                            );
                            return Text(
                              welcomeText,
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.isMobile(context)
                                        ? 32
                                        : 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final subtitleText = context.tr('login.subtitle');
                            Logger.debug(
                              "[v0] Subtitle text result: '$subtitleText'",
                              tag: 'LOGIN_DEBUG',
                            );
                            return Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.isMobile(context)
                                        ? 16
                                        : 18,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          height: ResponsiveHelper.isMobile(context) ? 40 : 48,
                        ),
                        Container(
                          width: containerWidth,
                          constraints: BoxConstraints(
                            maxWidth:
                                ResponsiveHelper.isDesktop(context)
                                    ? 420
                                    : double.infinity,
                          ),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              buildTextField(
                                context.tr('login.email'),
                                _emailController,
                                _focusEmail,
                              ),
                              SizedBox(
                                height:
                                    ResponsiveHelper.isMobile(context)
                                        ? 20
                                        : 24,
                              ),
                              buildTextField(
                                context.tr('login.password'),
                                _passwordController,
                                _focusPassword,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    try {
                                      if (mounted) {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      }
                                    } catch (e, stackTrace) {
                                      _logger.error(
                                        'Error toggling password visibility',
                                        error: e,
                                        stackTrace: stackTrace,
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                height:
                                    ResponsiveHelper.isMobile(context)
                                        ? 28
                                        : 32,
                              ),
                              authVM.isLoading
                                  ? Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ThemeService.getPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  )
                                  : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient:
                                            ThemeService.getPrimaryGradient(
                                              context,
                                            ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ThemeService.getPrimaryColor(
                                              context,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          context.tr('login.sign_in'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: _navigateToRegister,
                                child: Text(
                                  context.tr('login.no_account'),
                                  style: TextStyle(
                                    color: ThemeService.getPrimaryColor(
                                      context,
                                    ),
                                    fontSize: ResponsiveHelper.bodyFontSize(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error building login screen',
        error: e,
        stackTrace: stackTrace,
      );
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading login screen'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (mounted) setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
