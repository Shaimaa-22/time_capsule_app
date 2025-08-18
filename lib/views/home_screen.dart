import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../view_models/capsule_view_model.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../services/background_service.dart';
import '../models/capsule.dart';
import '../utils/responsive_helper.dart';
import 'create_capsule_screen.dart';
import 'capsule_list_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import '../services/capsule_service.dart';
import 'dart:async';
import '../utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabFadeAnimation;
  Timer? _refreshTimer;

  final List<Widget> _screens = [
    const DashboardTab(),
    const CapsulesListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );

    _tabAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.currentUserId != null) {
        Provider.of<CapsuleViewModel>(
          context,
          listen: false,
        ).loadUserCapsules(AuthService.currentUserId!);
      }

      _ensureBackgroundServiceRunning();
      _startPeriodicRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _ensureBackgroundServiceRunning();
      _startPeriodicRefresh();
      _refreshData();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && AuthService.currentUserId != null) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      final capsuleViewModel = Provider.of<CapsuleViewModel>(
        context,
        listen: false,
      );
      await capsuleViewModel.refreshCapsules();

      if (mounted) {
        await BackgroundService.checkAndNotifyReadyCapsules();
      }
    } catch (e) {
      Logger.error('Refresh failed: $e');
    }
  }

  Future<void> _ensureBackgroundServiceRunning() async {
    try {
      await BackgroundService.registerPeriodicTask();
      await BackgroundService.checkAndNotifyReadyCapsules();
    } catch (e) {
      Logger.error('Background service check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _tabFadeAnimation,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_rounded,
                  context.tr('home.dashboard'),
                ),
                _buildNavItem(
                  1,
                  Icons.inbox_rounded,
                  context.tr('home.capsules'),
                ),
                _buildNavItem(
                  2,
                  Icons.person_rounded,
                  context.tr('home.profile'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          _currentIndex == 0 || _currentIndex == 1
              ? Container(
                decoration: BoxDecoration(
                  gradient: ThemeService.getPrimaryGradient(context),
                  borderRadius: BorderRadius.circular(28),
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
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const CreateCapsuleScreen(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 800),
                      ),
                    );
                    if (result == true && AuthService.currentUserId != null) {
                      if (mounted) {
                        Provider.of<CapsuleViewModel>(
                          this.context,
                          listen: false,
                        ).loadUserCapsules(AuthService.currentUserId!);
                      }
                    }
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Text(
                    context.tr('home.create'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _tabAnimationController.reset();
        setState(() => _currentIndex = index);
        _tabAnimationController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.bounceOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      ThemeService.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.2),
                      ThemeService.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.1),
                    ],
                  )
                  : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: ThemeService.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? ThemeService.getPrimaryColor(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
                color:
                    isSelected
                        ? ThemeService.getPrimaryColor(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  late List<Animation<Offset>> _slideAnimations;

  void _shareCapsule(Capsule capsule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('home.share_capsule'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _buildShareOption(
                  icon: Icons.copy_rounded,
                  title: context.tr('home.copy_details'),
                  subtitle: context.tr('home.copy_details_subtitle'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyToClipboard(capsule);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.person_add_rounded,
                  title: context.tr('home.invite_someone'),
                  subtitle: context.tr('home.invite_someone_subtitle'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInviteDialog(capsule);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _copyToClipboard(Capsule capsule) async {
    final shareText =
        '''
🕰️ Time Capsule: ${capsule.title}

📅 Open Date: ${capsule.openDate.day}/${capsule.openDate.month}/${capsule.openDate.year}
⏰ Time: ${capsule.openDate.hour}:${capsule.openDate.minute.toString().padLeft(2, '0')}

${capsule.isOpened ? '✅ Opened' : '🔒 Locked'}

#TimeCapsule #Memories
    '''.trim();

    await Clipboard.setData(ClipboardData(text: shareText));

    if (mounted) {
      Fluttertoast.showToast(
        msg: context.tr('home.details_copied'),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getSuccessColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _showInviteDialog(Capsule capsule) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              context.tr('home.invite_someone'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('home.invite_dialog_content'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('auth.email'),
                    hintText: 'example@email.com',
                    prefixIcon: Icon(
                      Icons.email_rounded,
                      color: ThemeService.getPrimaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('common.cancel'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: ThemeService.getPrimaryGradient(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      try {
                        await CapsuleService.addRecipientToCapsule(
                          capsule.id,
                          emailController.text.trim(),
                        );
                        if (mounted) {
                          Fluttertoast.showToast(
                            msg: this.context.tr('home.invitation_sent'),
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: ThemeService.getSuccessColor(
                              this.context,
                            ),
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Fluttertoast.showToast(
                            msg: this.context.tr('home.invitation_error'),
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: ThemeService.getDangerColor(
                              this.context,
                            ),
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    context.tr('home.send_invitation'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeService.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ThemeService.getPrimaryColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: -0.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _cardControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardAnimations =
        _cardControllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();

    _slideAnimations =
        _cardControllers
            .map(
              (controller) => Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();

    for (var controller in _cardControllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CapsuleViewModel>(
      builder: (context, capsuleVM, child) {
        final lockedCapsules =
            capsuleVM.capsules.where((c) => c.isLocked).toList();
        final unlockedCapsules =
            capsuleVM.capsules.where((c) => !c.isLocked).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr('home.dashboard'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: ThemeService.getPrimaryGradient(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
            ),
            foregroundColor: Colors.white,
          ),
          body:
              capsuleVM.isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: ThemeService.getPrimaryColor(context),
                    ),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeService.getPrimaryColor(
                            context,
                          ).withValues(alpha: 0.05),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: ResponsiveHelper.responsivePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child:
                                ResponsiveHelper.isMobile(context)
                                    ? Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SlideTransition(
                                                position: _slideAnimations[0],
                                                child: FadeTransition(
                                                  opacity: _cardAnimations[0],
                                                  child: _buildStatCard(
                                                    context.tr(
                                                      'home.total_capsules',
                                                    ),
                                                    capsuleVM.capsules.length
                                                        .toString(),
                                                    Icons.inbox_rounded,
                                                    ThemeService.getPrimaryColor(
                                                      context,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: SlideTransition(
                                                position: _slideAnimations[1],
                                                child: FadeTransition(
                                                  opacity: _cardAnimations[1],
                                                  child: _buildStatCard(
                                                    context.tr('home.locked'),
                                                    lockedCapsules.length
                                                        .toString(),
                                                    Icons.lock_rounded,
                                                    ThemeService
                                                        .warningGradient
                                                        .colors
                                                        .first,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SlideTransition(
                                                position: _slideAnimations[2],
                                                child: FadeTransition(
                                                  opacity: _cardAnimations[2],
                                                  child: _buildStatCard(
                                                    context.tr('home.unlocked'),
                                                    unlockedCapsules.length
                                                        .toString(),
                                                    Icons.lock_open_rounded,
                                                    ThemeService.getSuccessColor(
                                                      context,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: SlideTransition(
                                                position: _slideAnimations[3],
                                                child: FadeTransition(
                                                  opacity: _cardAnimations[3],
                                                  child: _buildStatCard(
                                                    context.tr(
                                                      'home.ready_soon',
                                                    ),
                                                    _getCapsulesReadySoon(
                                                      lockedCapsules,
                                                    ).toString(),
                                                    Icons.schedule_rounded,
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                    : GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount:
                                          ResponsiveHelper.isTablet(context)
                                              ? 2
                                              : 4,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      childAspectRatio:
                                          ResponsiveHelper.isTablet(context)
                                              ? 1.2
                                              : 1.0,
                                      children: [
                                        SlideTransition(
                                          position: _slideAnimations[0],
                                          child: FadeTransition(
                                            opacity: _cardAnimations[0],
                                            child: _buildStatCard(
                                              context.tr('home.total_capsules'),
                                              capsuleVM.capsules.length
                                                  .toString(),
                                              Icons.inbox_rounded,
                                              ThemeService.getPrimaryColor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SlideTransition(
                                          position: _slideAnimations[1],
                                          child: FadeTransition(
                                            opacity: _cardAnimations[1],
                                            child: _buildStatCard(
                                              context.tr('home.locked'),
                                              lockedCapsules.length.toString(),
                                              Icons.lock_rounded,
                                              ThemeService
                                                  .warningGradient
                                                  .colors
                                                  .first,
                                            ),
                                          ),
                                        ),
                                        SlideTransition(
                                          position: _slideAnimations[2],
                                          child: FadeTransition(
                                            opacity: _cardAnimations[2],
                                            child: _buildStatCard(
                                              context.tr('home.unlocked'),
                                              unlockedCapsules.length
                                                  .toString(),
                                              Icons.lock_open_rounded,
                                              ThemeService.getSuccessColor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SlideTransition(
                                          position: _slideAnimations[3],
                                          child: FadeTransition(
                                            opacity: _cardAnimations[3],
                                            child: _buildStatCard(
                                              context.tr('home.ready_soon'),
                                              _getCapsulesReadySoon(
                                                lockedCapsules,
                                              ).toString(),
                                              Icons.schedule_rounded,
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 32),
                          if (unlockedCapsules.isNotEmpty) ...[
                            FadeTransition(
                              opacity: _cardAnimations[0],
                              child: Text(
                                context.tr('home.recently_unlocked'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: unlockedCapsules.take(5).length,
                                itemBuilder: (context, index) {
                                  return _buildCapsuleCard(
                                    context,
                                    unlockedCapsules[index],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (lockedCapsules.isNotEmpty) ...[
                            FadeTransition(
                              opacity: _cardAnimations[0],
                              child: Text(
                                context.tr('home.upcoming_capsules'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...lockedCapsules.take(3).map((capsule) {
                              return _buildUpcomingCapsuleItem(
                                context,
                                capsule,
                              );
                            }),
                          ],
                          if (capsuleVM.capsules.isEmpty) ...[
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Icon(
                                          Icons.inbox_outlined,
                                          size: 80,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.tr('home.no_capsules'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('home.create_first_capsule'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.9, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<int>(
                  duration: const Duration(milliseconds: 1200),
                  tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                  builder: (context, animatedValue, child) {
                    return Text(
                      animatedValue.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapsuleCard(BuildContext context, Capsule capsule) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeService.getSuccessColor(
                        context,
                      ).withValues(alpha: 0.2),
                      ThemeService.getSuccessColor(
                        context,
                      ).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  color: ThemeService.getSuccessColor(context),
                  size: 24,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _shareCapsule(capsule),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            capsule.title ?? context.tr('capsule.untitled'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeService.getSuccessColor(context).withValues(alpha: 0.2),
                  ThemeService.getSuccessColor(context).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.tr('home.opened'),
              style: TextStyle(
                color: ThemeService.getSuccessColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCapsuleItem(BuildContext context, Capsule capsule) {
    final now = DateTime.now();
    final difference = capsule.openDate.difference(now);
    final daysLeft = difference.inDays;
    final hoursLeft = difference.inHours % 24;

    String timeLeftText;
    if (difference.isNegative) {
      timeLeftText = 'Ready to open!';
    } else if (daysLeft > 0) {
      timeLeftText = '$daysLeft days, $hoursLeft hours left';
    } else if (difference.inHours > 0) {
      timeLeftText =
          '${difference.inHours} hours, ${difference.inMinutes % 60} minutes left';
    } else {
      timeLeftText = '${difference.inMinutes} minutes left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ThemeService.warningGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title ?? 'Untitled',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLeftText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _shareCapsule(capsule),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.share_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCapsulesReadySoon(List<Capsule> capsules) {
    return capsules.where((capsule) {
      final difference = capsule.openDate.difference(DateTime.now());
      return difference.inDays <= 7 && difference.inDays >= 0;
    }).length;
  }
}
