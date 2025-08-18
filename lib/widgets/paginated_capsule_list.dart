import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/capsule_view_model.dart';
import '../models/capsule.dart';
import 'capsule_list_item.dart';
import 'dart:async';

class PaginatedCapsuleList extends StatefulWidget {
  final List<Capsule> capsules;
  final bool showLoadMore;
  final Widget Function(Capsule)? itemBuilder;
  final VoidCallback? onRefresh;
  final String emptyMessage;
  final ScrollController? scrollController;
  final bool enableAutoRefresh;
  final Duration refreshInterval;

  const PaginatedCapsuleList({
    super.key,
    required this.capsules,
    this.showLoadMore = false,
    this.itemBuilder,
    this.onRefresh,
    this.emptyMessage = 'No capsules found',
    this.scrollController,
    this.enableAutoRefresh = true,
    this.refreshInterval = const Duration(minutes: 1),
  });

  @override
  State<PaginatedCapsuleList> createState() => _PaginatedCapsuleListState();
}

class _PaginatedCapsuleListState extends State<PaginatedCapsuleList> {
  late ScrollController _scrollController;
  bool _isScrollControllerInternal = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _isScrollControllerInternal = true;
    }

    if (widget.showLoadMore) {
      _scrollController.addListener(_onScroll);
    }

    if (widget.enableAutoRefresh && widget.onRefresh != null) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_isScrollControllerInternal) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      if (mounted && widget.onRefresh != null) {
        widget.onRefresh!();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final capsuleVM = Provider.of<CapsuleViewModel>(context, listen: false);
      if (capsuleVM.hasNextPage && !capsuleVM.isLoadingMore) {
        capsuleVM.loadMoreCapsules();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CapsuleViewModel>(
      builder: (context, capsuleVM, child) {
        if (widget.capsules.isEmpty && !capsuleVM.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  widget.emptyMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first time capsule!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        Widget listView = ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              widget.capsules.length +
              (widget.showLoadMore &&
                      (capsuleVM.hasNextPage || capsuleVM.isLoadingMore)
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            if (widget.showLoadMore && index == widget.capsules.length) {
              if (capsuleVM.isLoadingMore) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              const CircularProgressIndicator(
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading more capsules...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (capsuleVM.hasNextPage) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => capsuleVM.loadMoreCapsules(),
                        icon: const Icon(
                          Icons.expand_more_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Load More',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            final capsule = widget.capsules[index];

            if (widget.itemBuilder != null) {
              return widget.itemBuilder!(capsule);
            }

            return CapsuleListItem(capsule: capsule, onTap: () {});
          },
        );

        if (widget.onRefresh != null) {
          return RefreshIndicator(
            onRefresh: () async {
              widget.onRefresh!();
            },
            color: const Color(0xFF6366F1),
            backgroundColor: Colors.white,
            child: listView,
          );
        }

        return listView;
      },
    );
  }
}
