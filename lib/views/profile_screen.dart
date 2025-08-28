import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/logger_viewer_button.dart';
import '../widgets/language_switcher.dart';
import '../utils/responsive_helper.dart';
import '../utils/twested.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';
import 'logger_viewer_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.responsivePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('profile.title'),
          style: TextStyle(
            fontSize: ResponsiveHelper.titleFontSize(context),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeService.getPrimaryGradient(context),
          ),
        ),
        actions: const [
          LanguageSwitcher(),
          LoggerViewerButton(),
          ThemeToggleButton(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeService.getPrimaryColor(context).withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.containerWidth(context),
            ),
            child: Center(
              child: Column(
                children: [
                  _buildUserCard(context),
                  SizedBox(
                      height: ResponsiveHelper.responsiveValue(
                          context, base: 24)),
                  _buildMenuItems(context),
                  SizedBox(
                      height: ResponsiveHelper.responsiveValue(
                          context, base: 16)),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final size = ResponsiveHelper.responsiveValue(context, base: 80);
    final spacing = ResponsiveHelper.responsiveValue(context, base: 24);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.responsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveValue(context, base: 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: ResponsiveHelper.responsiveValue(context, base: 20),
            offset: Offset(0, ResponsiveHelper.responsiveValue(context, base: 5)),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: ThemeService.getPrimaryGradient(context),
              borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveValue(context, base: 20)),
              boxShadow: [
                BoxShadow(
                  color: ThemeService.getPrimaryColor(context)
                      .withValues(alpha: 0.3),
                  blurRadius: ResponsiveHelper.responsiveValue(context, base: 20),
                  offset: Offset(0, ResponsiveHelper.responsiveValue(context, base: 8)),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: ResponsiveHelper.responsiveValue(context, base: 40),
              color: Colors.white,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            AuthService.currentUserName ?? context.tr('profile.user_name'),
            style: TextStyle(
              fontSize: ResponsiveHelper.titleFontSize(context),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.responsiveValue(context, base: 8)),
          Text(
            AuthService.currentUserEmail ?? context.tr('profile.no_email'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: ResponsiveHelper.bodyFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context: context,
          icon: Icons.palette_rounded,
          title: context.tr('profile.theme_settings'),
          subtitle: context.tr('profile.theme_subtitle'),
          onTap: () => _showThemeDialog(context),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.bug_report_rounded,
          title: context.tr('profile.logger_viewer'),
          subtitle: context.tr('profile.logger_subtitle'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoggerViewerScreen()),
            );
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.notifications_rounded,
          title: context.tr('profile.notifications'),
          subtitle: context.tr('profile.notifications_subtitle'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            );
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.settings_rounded,
          title: context.tr('profile.settings'),
          subtitle: context.tr('profile.settings_subtitle'),
          onTap: () {
            TwistedSnackBar.showInfo(
              context,
              context.tr('profile.settings_coming_soon'),
            );
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.help_rounded,
          title: context.tr('profile.help'),
          subtitle: context.tr('profile.help_subtitle'),
          onTap: () {
            TwistedSnackBar.showInfo(
              context,
              context.tr('profile.help_coming_soon'),
            );
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.info_rounded,
          title: context.tr('profile.about'),
          subtitle: context.tr('profile.about_subtitle'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text(
                  context.tr('profile.about_title'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  context.tr('profile.about_content'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      context.tr('profile.ok'),
                      style: TextStyle(
                        color: ThemeService.getPrimaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final height = ResponsiveHelper.responsiveValue(context, base: 56);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: ThemeService.dangerGradient,
        borderRadius:
            BorderRadius.circular(ResponsiveHelper.responsiveValue(context, base: 16)),
        boxShadow: [
          BoxShadow(
            color: ThemeService.getDangerColor(context).withValues(alpha: 0.3),
            blurRadius: ResponsiveHelper.responsiveValue(context, base: 20),
            offset: Offset(0, ResponsiveHelper.responsiveValue(context, base: 8)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text(
                  context.tr('profile.logout'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  context.tr('profile.logout_confirm'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      context.tr('profile.cancel'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: ThemeService.dangerGradient,
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.responsiveValue(context, base: 8)),
                    ),
                    child: TextButton(
                      onPressed: () {
                        AuthService.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        context.tr('profile.logout'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(
              ResponsiveHelper.responsiveValue(context, base: 16)),
          child: Center(
            child: Text(
              context.tr('profile.logout'),
              style: TextStyle(
                fontSize: ResponsiveHelper.bodyFontSize(context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final horizontalPadding =
        ResponsiveHelper.responsiveValue(context, base: 20);
    final verticalPadding = ResponsiveHelper.responsiveValue(context, base: 8);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.responsiveValue(context, base: 16),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(ResponsiveHelper.responsiveValue(context, base: 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: ResponsiveHelper.responsiveValue(context, base: 20),
            offset: Offset(0, ResponsiveHelper.responsiveValue(context, base: 5)),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        leading: Container(
          padding: EdgeInsets.all(ResponsiveHelper.responsiveValue(context, base: 10)),
          decoration: BoxDecoration(
            color: ThemeService.getPrimaryColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
                ResponsiveHelper.responsiveValue(context, base: 12)),
          ),
          child: Icon(
            icon,
            color: ThemeService.getPrimaryColor(context),
            size: ResponsiveHelper.responsiveValue(context, base: 24),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.bodyFontSize(context),
            letterSpacing: -0.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: ResponsiveHelper.responsiveValue(context, base: 14),
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: Container(
          padding: EdgeInsets.all(ResponsiveHelper.responsiveValue(context, base: 8)),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
                ResponsiveHelper.responsiveValue(context, base: 8)),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: ResponsiveHelper.responsiveValue(context, base: 16),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              context.tr('profile.choose_theme'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(
                    context.tr('profile.light_theme'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('profile.light_subtitle'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: ThemeMode.light,
                  groupValue: themeService.themeMode,
                  activeColor: ThemeService.getPrimaryColor(context),
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(
                    context.tr('profile.dark_theme'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('profile.dark_subtitle'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: ThemeMode.dark,
                  groupValue: themeService.themeMode,
                  activeColor: ThemeService.getPrimaryColor(context),
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(
                    context.tr('profile.system_theme'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('profile.system_subtitle'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: ThemeMode.system,
                  groupValue: themeService.themeMode,
                  activeColor: ThemeService.getPrimaryColor(context),
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('profile.cancel'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
