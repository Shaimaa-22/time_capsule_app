import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/capsule_view_model.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/paginated_capsule_list.dart';
import '../widgets/pagination_info.dart';
import 'capsule_detail_screen.dart';

class CapsulesListScreen extends StatefulWidget {
  const CapsulesListScreen({super.key});

  @override
  State<CapsulesListScreen> createState() => _CapsulesListScreenState();
}

class _CapsulesListScreenState extends State<CapsulesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CapsuleViewModel>(
      builder: (context, capsuleVM, child) {
        final allCapsules = capsuleVM.capsules;
        final lockedCapsules = allCapsules.where((c) => c.isLocked).toList();
        final unlockedCapsules = allCapsules.where((c) => !c.isLocked).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr('capsule.my_capsules'),
              style: TextStyle(
                fontSize: 24,
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  text: context.trParams('capsule.all_count', {
                    'count': capsuleVM.totalCount.toString(),
                  }),
                ),
                Tab(
                  text: context.trParams('capsule.locked_count', {
                    'count': lockedCapsules.length.toString(),
                  }),
                ),
                Tab(
                  text: context.trParams('capsule.unlocked_count', {
                    'count': unlockedCapsules.length.toString(),
                  }),
                ),
              ],
            ),
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
            child:
                capsuleVM.isLoading && allCapsules.isEmpty
                    ? Center(
                      child: CircularProgressIndicator(
                        color: ThemeService.getPrimaryColor(context),
                      ),
                    )
                    : Column(
                      children: [
                        const PaginationInfo(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              PaginatedCapsuleList(
                                capsules: allCapsules,
                                showLoadMore: true,
                                onRefresh: () => capsuleVM.refreshCapsules(),
                                itemBuilder:
                                    (capsule) => _buildCapsuleItem(capsule),
                                emptyMessage: context.tr('capsule.no_capsules'),
                              ),
                              PaginatedCapsuleList(
                                capsules: lockedCapsules,
                                onRefresh: () => capsuleVM.refreshCapsules(),
                                itemBuilder:
                                    (capsule) => _buildCapsuleItem(capsule),
                                emptyMessage: context.tr(
                                  'capsule.no_locked_capsules',
                                ),
                              ),
                              PaginatedCapsuleList(
                                capsules: unlockedCapsules,
                                onRefresh: () => capsuleVM.refreshCapsules(),
                                itemBuilder:
                                    (capsule) => _buildCapsuleItem(capsule),
                                emptyMessage: context.tr(
                                  'capsule.no_unlocked_capsules',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  Widget _buildCapsuleItem(capsule) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CapsuleDetailScreen(capsule: capsule),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      capsule.isLocked
                          ? [
                            ThemeService.getWarningColor(
                              context,
                            ).withValues(alpha: 0.2),
                            ThemeService.getWarningColor(
                              context,
                            ).withValues(alpha: 0.1),
                          ]
                          : [
                            ThemeService.getSuccessColor(
                              context,
                            ).withValues(alpha: 0.2),
                            ThemeService.getSuccessColor(
                              context,
                            ).withValues(alpha: 0.1),
                          ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                capsule.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color:
                    capsule.isLocked
                        ? ThemeService.getWarningColor(context)
                        : ThemeService.getSuccessColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capsule.title ?? context.tr('capsule.untitled'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          capsule.isLocked
                              ? ThemeService.getWarningColor(
                                context,
                              ).withValues(alpha: 0.1)
                              : ThemeService.getSuccessColor(
                                context,
                              ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      capsule.isLocked
                          ? context.trParams('capsule.opens_on', {
                            'date': capsule.openDate.toString().split(' ')[0],
                          })
                          : context.trParams('capsule.opened_on', {
                            'date':
                                capsule.openedAt?.toString().split(' ')[0] ??
                                'Unknown',
                          }),
                      style: TextStyle(
                        color:
                            capsule.isLocked
                                ? ThemeService.getWarningColor(context)
                                : ThemeService.getSuccessColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
