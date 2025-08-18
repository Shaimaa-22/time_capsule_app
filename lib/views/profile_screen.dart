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
        foregroundColor: Colors.white,
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
          padding: ResponsiveHelper.responsivePadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  ResponsiveHelper.isDesktop(context) ? 600 : double.infinity,
            ),
            child: Center(
              child: Column(
                children: [
                  _buildUserCard(context),
                  SizedBox(
                    height: ResponsiveHelper.isMobile(context) ? 24 : 32,
                  ),
                  _buildMenuItems(context),
                  SizedBox(
                    height: ResponsiveHelper.isMobile(context) ? 16 : 20,
                  ),
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
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.responsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveHelper.isMobile(context) ? 70 : 80,
            height: ResponsiveHelper.isMobile(context) ? 70 : 80,
            decoration: BoxDecoration(
              gradient: ThemeService.getPrimaryGradient(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ThemeService.getPrimaryColor(
                    context,
                  ).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: ResponsiveHelper.isMobile(context) ? 35 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
          Text(
            AuthService.currentUserName ?? context.tr('profile.user_name'),
            style: TextStyle(
              fontSize: ResponsiveHelper.titleFontSize(context),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
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
                builder: (_) => const NotificationSettingsScreen(),
              ),
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
              builder:
                  (context) => AlertDialog(
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
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.isMobile(context) ? 50 : 56,
      decoration: BoxDecoration(
        gradient: ThemeService.dangerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeService.getDangerColor(context).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: ThemeService.dangerGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () {
                            AuthService.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
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
          borderRadius: BorderRadius.circular(16),
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
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.isMobile(context) ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.isMobile(context) ? 16 : 20,
          vertical: ResponsiveHelper.isMobile(context) ? 6 : 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ThemeService.getPrimaryColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: ThemeService.getPrimaryColor(context),
            size: ResponsiveHelper.isMobile(context) ? 22 : 24,
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
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: ResponsiveHelper.isMobile(context) ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
                : null,
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
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
      builder:
          (context) => Consumer<ThemeService>(
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
