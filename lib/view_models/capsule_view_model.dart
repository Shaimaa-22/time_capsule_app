import 'package:flutter/material.dart';
import '../services/capsule_service.dart';
import '../services/auth_service.dart';
import '../models/capsule.dart';
import '../utils/logger.dart';

class CapsuleViewModel extends ChangeNotifier {
  static final _logger = Logger.forClass('CapsuleViewModel');

  List<Capsule> _capsules = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _disposed = false;

  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasNextPage = true;
  int _totalCount = 0;

  List<Capsule> get capsules => _capsules;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasNextPage => _hasNextPage;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;

  Future<void> loadUserCapsules(int userId, {bool refresh = false}) async {
    if (_disposed) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _hasNextPage = true;
        _capsules.clear();
      }

      _setLoading(true);
      _clearError();

      if (userId <= 0) {
        throw ArgumentError('Invalid user ID: $userId');
      }

      _logger.info('Loading capsules for user: $userId, page: $_currentPage');

      final paginatedResult = await CapsuleService.getUserCapsules(
        userId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _totalCount = paginatedResult.totalCount;
      _hasNextPage = paginatedResult.hasNextPage;

      if (refresh || _currentPage == 1) {
        _capsules = paginatedResult.capsules;
      } else {
        _capsules.addAll(paginatedResult.capsules);
      }

      _logger.info(
        'Loaded ${paginatedResult.capsules.length} capsules successfully. Total: $_totalCount',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load user capsules',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to load capsules. Please try again.');
      if (_currentPage == 1) {
        _capsules = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreCapsules() async {
    if (_disposed || _isLoadingMore || !_hasNextPage) return;

    try {
      _setLoadingMore(true);
      _clearError();

      int? userId;
      if (_capsules.isNotEmpty) {
        userId = _capsules.first.ownerId;
      } else if (AuthService.isLoggedIn && AuthService.currentUserId != null) {
        userId = AuthService.currentUserId!;
      }

      if (userId == null) {
        throw Exception('No user ID available for loading more');
      }

      _currentPage++;
      _logger.info(
        'Loading more capsules for user: $userId, page: $_currentPage',
      );

      final paginatedResult = await CapsuleService.getUserCapsules(
        userId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _hasNextPage = paginatedResult.hasNextPage;
      _capsules.addAll(paginatedResult.capsules);

      _logger.info(
        'Loaded ${paginatedResult.capsules.length} more capsules. Total loaded: ${_capsules.length}',
      );
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load more capsules',
        error: e,
        stackTrace: stackTrace,
      );
      _currentPage--; // Revert page increment on error
      _setError('Failed to load more capsules. Please try again.');
    } finally {
      _setLoadingMore(false);
    }
  }

  Future<void> refreshCapsules() async {
    if (_disposed) return;

    try {
      _clearError();

      int? userId;
      if (_capsules.isNotEmpty) {
        userId = _capsules.first.ownerId;
      } else if (AuthService.isLoggedIn && AuthService.currentUserId != null) {
        userId = AuthService.currentUserId!;
      }

      if (userId == null) {
        throw Exception('No user ID available for refresh');
      }

      _logger.info('Refreshing capsules for user: $userId');

      await loadUserCapsules(userId, refresh: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to refresh capsules',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to refresh capsules. Please try again.');
    }
  }

  Future<bool> createCapsule({
    required String contentType,
    required String contentEncrypted,
    required DateTime openDate,
    String? title,
    String? recipientEmail,
  }) async {
    if (_disposed) return false;

    try {
      _setLoading(true);
      _clearError();

      if (contentType.trim().isEmpty) {
        _setError('Content type cannot be empty');
        return false;
      }

      if (contentEncrypted.trim().isEmpty) {
        _setError('Content cannot be empty');
        return false;
      }

      if (openDate.isBefore(DateTime.now())) {
        _setError('Open date must be in the future');
        return false;
      }

      if (!AuthService.isLoggedIn || AuthService.currentUserId == null) {
        _setError('You must be logged in to create a capsule');
        return false;
      }

      _logger.info('Creating new capsule');

      final capsule = await CapsuleService.createCapsule(
        ownerId: AuthService.currentUserId!,
        recipientEmail: recipientEmail?.trim(),
        contentType: contentType.trim(),
        contentEncrypted: contentEncrypted,
        openDate: openDate,
        title: title?.trim(),
      );

      addCapsule(capsule);
      _logger.info('Capsule created successfully with ID: ${capsule.id}');
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create capsule',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to create capsule. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> openCapsule(int capsuleId) async {
    if (_disposed) return false;

    try {
      _clearError();

      if (capsuleId <= 0) {
        _setError('Invalid capsule ID');
        return false;
      }

      _logger.info('Opening capsule: $capsuleId');

      await CapsuleService.openCapsule(capsuleId);

      final index = _capsules.indexWhere((c) => c.id == capsuleId);
      if (index != -1) {
        final updatedCapsule = _capsules[index].copyWith(
          isOpened: true,
          openedAt: DateTime.now(),
        );
        _capsules[index] = updatedCapsule;
        _safeNotifyListeners();
      }

      _logger.info('Capsule opened successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to open capsule', error: e, stackTrace: stackTrace);
      _setError('Failed to open capsule. Please try again.');
      return false;
    }
  }

  void addCapsule(Capsule capsule) {
    if (_disposed) return;

    try {
      _capsules.insert(0, capsule);
      _totalCount++;
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      _logger.error(
        'Error adding capsule to list',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void updateCapsule(Capsule updatedCapsule) {
    if (_disposed) return;

    try {
      final index = _capsules.indexWhere((c) => c.id == updatedCapsule.id);
      if (index != -1) {
        _capsules[index] = updatedCapsule;
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error updating capsule in list',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void removeCapsule(int capsuleId) {
    if (_disposed) return;

    try {
      final countBefore = _capsules.length;
      _capsules.removeWhere((c) => c.id == capsuleId);
      final countAfter = _capsules.length;
      final removed = countBefore - countAfter;

      if (removed > 0) {
        _totalCount = (_totalCount - removed).clamp(0, _totalCount).toInt();
      }
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      _logger.error(
        'Error removing capsule from list',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setLoadingMore(bool loading) {
    if (_disposed) return;
    _isLoadingMore = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_disposed) return;
    _errorMessage = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _errorMessage = null;
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e, stackTrace) {
        _logger.error(
          'Error notifying listeners',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  void clearError() {
    _clearError();
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
