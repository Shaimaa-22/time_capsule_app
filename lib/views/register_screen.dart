import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../view_models/auth_view_model.dart';
import '../utils/logger.dart';
import '../utils/responsive_helper.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static final _logger = Logger.forClass('RegisterScreen');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _focusName = FocusNode();
  final FocusNode _focusEmail = FocusNode();
  final FocusNode _focusPassword = FocusNode();
  final FocusNode _focusConfirmPassword = FocusNode();

  late final AnimationController _animController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    try {
      _animController = AnimationController(vsync: this);

      _focusName.addListener(() {
        try {
          if (_focusName.hasFocus) _animController.forward(from: 0);
          if (mounted) setState(() {});
        } catch (e, stackTrace) {
          _logger.error(
            'Error in name focus listener',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });

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

      _focusConfirmPassword.addListener(() {
        try {
          if (_focusConfirmPassword.hasFocus) _animController.forward(from: 0);
          if (mounted) setState(() {});
        } catch (e, stackTrace) {
          _logger.error(
            'Error in confirm password focus listener',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing register screen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    try {
      _nameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      _focusName.dispose();
      _focusEmail.dispose();
      _focusPassword.dispose();
      _focusConfirmPassword.dispose();
      _animController.dispose();
    } catch (e, stackTrace) {
      _logger.error(
        'Error disposing register screen resources',
        error: e,
        stackTrace: stackTrace,
      );
    }
    super.dispose();
  }

  InputDecoration inputDecoration(
    String label,
    FocusNode focusNode, {
    Widget? suffixIcon,
  }) {
    try {
      return InputDecoration(
        labelText: label,
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
        suffixIcon: suffixIcon,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error creating input decoration',
        error: e,
        stackTrace: stackTrace,
      );
      return const InputDecoration(border: OutlineInputBorder());
    }
  }

  Widget inputContainer(Widget child, FocusNode focusNode) {
    try {
      return Container(
        decoration: BoxDecoration(
          boxShadow:
              focusNode.hasFocus
                  ? [
                    BoxShadow(
                      color: ThemeService.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error creating input container',
        error: e,
        stackTrace: stackTrace,
      );
      return Container(child: child);
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller,
    FocusNode focusNode, {
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    try {
      return inputContainer(
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: inputDecoration(label, focusNode, suffixIcon: suffixIcon),
        ),
        focusNode,
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
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (name.isEmpty) {
        _showErrorToast(context.tr('register.validation.name_required'));
        return false;
      }

      if (name.length < 2) {
        _showErrorToast(context.tr('register.validation.name_min_length'));
        return false;
      }

      if (email.isEmpty) {
        _showErrorToast(context.tr('register.validation.email_required'));
        return false;
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(email)) {
        _showErrorToast(context.tr('register.validation.email_invalid'));
        return false;
      }

      if (password.isEmpty) {
        _showErrorToast(context.tr('register.validation.password_required'));
        return false;
      }

      if (password.length < 6) {
        _showErrorToast(context.tr('register.validation.password_min_length'));
        return false;
      }

      if (confirmPassword.isEmpty) {
        _showErrorToast(
          context.tr('register.validation.confirm_password_required'),
        );
        return false;
      }

      if (password != confirmPassword) {
        _showErrorToast(context.tr('register.validation.passwords_no_match'));
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error validating inputs',
        error: e,
        stackTrace: stackTrace,
      );
      _showErrorToast(context.tr('register.validation.error_occurred'));
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

  Future<void> _handleRegister() async {
    try {
      if (!_validateInputs()) return;

      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      final success = await authVM.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessToast(context.tr('register.success_message'));

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
          _showErrorToast(context.tr('register.navigation_error'));
        }
      } else {
        String errorMsg = authVM.errorMessage ?? context.tr('register.failed');
        if (errorMsg.contains("Email already exists")) {
          errorMsg = context.tr('register.email_exists');
        }
        _showErrorToast(errorMsg);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error during registration process',
        error: e,
        stackTrace: stackTrace,
      );
      _showErrorToast(context.tr('register.unexpected_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
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
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
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
                          height: ResponsiveHelper.isMobile(context) ? 24 : 32,
                        ),
                        Text(
                          context.tr('register.title'),
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.isMobile(context) ? 28 : 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('register.subtitle'),
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.isMobile(context) ? 14 : 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.isMobile(context) ? 32 : 40,
                        ),
                        Container(
                          width: containerWidth,
                          constraints: BoxConstraints(
                            maxWidth:
                                ResponsiveHelper.isDesktop(context)
                                    ? 400
                                    : double.infinity,
                          ),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              buildTextField(
                                context.tr('register.full_name'),
                                _nameController,
                                _focusName,
                              ),
                              SizedBox(
                                height:
                                    ResponsiveHelper.isMobile(context)
                                        ? 16
                                        : 20,
                              ),
                              buildTextField(
                                context.tr('register.email'),
                                _emailController,
                                _focusEmail,
                              ),
                              SizedBox(
                                height:
                                    ResponsiveHelper.isMobile(context)
                                        ? 16
                                        : 20,
                              ),
                              buildTextField(
                                context.tr('register.password'),
                                _passwordController,
                                _focusPassword,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
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
                                        ? 16
                                        : 20,
                              ),
                              buildTextField(
                                context.tr('register.confirm_password'),
                                _confirmPasswordController,
                                _focusConfirmPassword,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    try {
                                      if (mounted) {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      }
                                    } catch (e, stackTrace) {
                                      _logger.error(
                                        'Error toggling confirm password visibility',
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
                                        ? 24
                                        : 28,
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
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _handleRegister,
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
                                          context.tr('register.create_account'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                ResponsiveHelper.bodyFontSize(
                                                  context,
                                                ),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  context.tr('register.already_have_account'),
                                  style: TextStyle(
                                    color: ThemeService.getPrimaryColor(
                                      context,
                                    ),
                                    fontSize: ResponsiveHelper.bodyFontSize(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w500,
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
        'Error building register screen',
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
              Text(context.tr('register.error_loading')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (mounted) setState(() {});
                },
                child: Text(context.tr('register.retry')),
              ),
            ],
          ),
        ),
      );
    }
  }
}
