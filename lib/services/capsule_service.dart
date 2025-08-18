import '../models/capsule.dart';
import '../utils/logger.dart';
import 'remote_db.dart';
import 'notification_service.dart';

class PaginatedCapsules {
  final List<Capsule> capsules;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;

  PaginatedCapsules({
    required this.capsules,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasNextPage = (currentPage * pageSize) < totalCount;
}

class CapsuleService {
  static final _logger = Logger.forClass('CapsuleService');

  /// Get paginated capsules for a specific user
  static Future<PaginatedCapsules> getUserCapsules(
    int userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _logger.info(
      'Getting paginated capsules for user: $userId, page: $page, pageSize: $pageSize',
    );

    try {
      if (userId <= 0) {
        throw ArgumentError('Invalid user ID: $userId');
      }

      final connection = await RemoteDB.getConnection();

      final countResult = await _logger.logExecutionTime(
        'Get capsules count query',
        () async {
          return await connection.query(
            '''
            SELECT COUNT(*) 
            FROM capsules 
            WHERE owner_id = @userId OR recipient_email = (
              SELECT email FROM users WHERE id = @userId
            )
            ''',
            substitutionValues: {'userId': userId},
          );
        },
      );

      final totalCount = countResult.first[0] as int;

      final offset = (page - 1) * pageSize;
      final result = await _logger.logExecutionTime(
        'Get paginated capsules query',
        () async {
          return await connection.query(
            '''
            SELECT id, owner_id, recipient_email, content_type, content_encrypted, 
                   open_date, created_at, is_opened, title, opened_at, notification_sent
            FROM capsules 
            WHERE owner_id = @userId OR recipient_email = (
              SELECT email FROM users WHERE id = @userId
            )
            ORDER BY created_at DESC
            LIMIT @pageSize OFFSET @offset
            ''',
            substitutionValues: {
              'userId': userId,
              'pageSize': pageSize,
              'offset': offset,
            },
          );
        },
      );

      final capsules = <Capsule>[];

      for (int i = 0; i < result.length; i++) {
        try {
          final row = result[i];

          if (row.length < 11) {
            _logger.warning('Incomplete row data at index $i, skipping');
            continue;
          }

          final capsule = Capsule(
            id: _safeParseInt(row[0], 'id'),
            ownerId: _safeParseInt(row[1], 'ownerId'),
            recipientEmail: _safeParseString(row[2]),
            contentType: _safeParseString(row[3]) ?? 'text',
            contentEncrypted: _safeParseString(row[4]) ?? '',
            openDate: _safeParseDateTime(row[5], 'openDate'),
            createdAt: _safeParseDateTime(row[6], 'createdAt'),
            isOpened: _safeParseBool(row[7], 'isOpened'),
            title: _safeParseString(row[8]),
            openedAt: _safeParseDateTime(row[9]),
            notificationSent: _safeParseBool(row[10], 'notificationSent'),
          );

          capsules.add(capsule);
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to parse capsule at index $i, skipping',
            error: e,
            stackTrace: stackTrace,
          );
          continue;
        }
      }

      final paginatedResult = PaginatedCapsules(
        capsules: capsules,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
      );

      _logger.info(
        'Retrieved paginated capsules successfully',
        data: {
          'userId': userId,
          'page': page,
          'pageSize': pageSize,
          'totalCount': totalCount,
          'returnedCount': capsules.length,
          'hasNextPage': paginatedResult.hasNextPage,
        },
      );

      return paginatedResult;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get paginated user capsules',
        error: e,
        stackTrace: stackTrace,
      );

      if (e is ArgumentError) {
        throw Exception('Validation error: ${e.message}');
      } else if (e.toString().contains('connection')) {
        throw Exception(
          'Database connection error. Please check your internet connection and try again.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception('Database operation timed out. Please try again.');
      }

      rethrow;
    }
  }

  /// Get all capsules for a specific user (legacy method - use getUserCapsules with pagination instead)
  static Future<List<Capsule>> getAllUserCapsules(int userId) async {
    final result = await getUserCapsules(
      userId,
      pageSize: 1000,
    ); // Large page size for "all"
    return result.capsules;
  }

  /// Create a new capsule
  static Future<Capsule> createCapsule({
    required int ownerId,
    String? recipientEmail,
    required String contentType,
    required String contentEncrypted,
    required DateTime openDate,
    String? title,
  }) async {
    _logger.info(
      'Creating new capsule',
      data: {
        'ownerId': ownerId,
        'title': title,
        'contentType': contentType,
        'openDate': openDate.toIso8601String(),
        'hasRecipient': recipientEmail != null,
      },
    );

    try {
      if (ownerId <= 0) {
        throw ArgumentError('Invalid owner ID: $ownerId');
      }

      if (title != null && title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }

      if (contentType.trim().isEmpty) {
        throw ArgumentError('Content type cannot be empty');
      }

      if (contentEncrypted.trim().isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }

      if (openDate.isBefore(DateTime.now())) {
        throw ArgumentError('Open date must be in the future');
      }

      if (recipientEmail != null && recipientEmail.trim().isNotEmpty) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(recipientEmail.trim())) {
          throw ArgumentError('Invalid recipient email format');
        }
      }

      final connection = await RemoteDB.getConnection();

      final result = await _logger.logExecutionTime(
        'Create capsule query',
        () async {
          try {
            return await connection.query(
              '''
              INSERT INTO capsules (owner_id, recipient_email, content_type, content_encrypted, 
                                  open_date, title, created_at, is_opened, notification_sent)
              VALUES (@ownerId, @recipientEmail, @contentType, @contentEncrypted, 
                      @openDate, @title, @createdAt, false, false)
              RETURNING id, owner_id, recipient_email, content_type, content_encrypted, 
                        open_date, created_at, is_opened, title, opened_at, notification_sent
              ''',
              substitutionValues: {
                'ownerId': ownerId,
                'recipientEmail': recipientEmail?.trim(),
                'contentType': contentType.trim(),
                'contentEncrypted': contentEncrypted,
                'openDate': openDate.toUtc(),
                'title': title?.trim(),
                'createdAt': DateTime.now().toUtc(),
              },
            );
          } catch (e) {
            if (e.toString().contains('foreign key constraint')) {
              throw Exception('Invalid owner ID - user does not exist');
            } else if (e.toString().contains('unique constraint')) {
              throw Exception('A capsule with similar details already exists');
            } else if (e.toString().contains('check constraint')) {
              throw Exception('Invalid data provided for capsule creation');
            }
            rethrow;
          }
        },
      );

      if (result.isEmpty) {
        throw Exception('Failed to create capsule - no result returned');
      }

      final row = result.first;
      final capsule = Capsule(
        id: row[0] as int,
        ownerId: row[1] as int,
        recipientEmail: row[2] as String?,
        contentType: row[3] as String,
        contentEncrypted: row[4] as String,
        openDate: row[5] as DateTime,
        createdAt: row[6] as DateTime,
        isOpened: row[7] as bool,
        title: row[8] as String?,
        openedAt: row[9] as DateTime?,
        notificationSent: row[10] as bool,
      );

      try {
        await NotificationService.scheduleCapsuleNotification(capsule);
        _logger.info(
          'Notification scheduled successfully for capsule',
          data: {
            'capsuleId': capsule.id,
            'scheduledFor': openDate.toIso8601String(),
          },
        );
      } catch (e, stackTrace) {
        _logger.warning(
          'Failed to schedule notification for capsule - capsule created but notification may not work',
          error: e,
          stackTrace: stackTrace,
        );
      }

      _logger.info(
        'Capsule created successfully',
        data: {
          'capsuleId': capsule.id,
          'ownerId': ownerId,
          'title': title,
          'openDate': openDate.toIso8601String(),
        },
      );

      return capsule;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create capsule',
        error: e,
        stackTrace: stackTrace,
      );

      if (e is ArgumentError) {
        throw Exception('Validation error: ${e.message}');
      } else if (e.toString().contains('connection')) {
        throw Exception(
          'Database connection error. Please check your internet connection and try again.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception('Database operation timed out. Please try again.');
      }

      rethrow;
    }
  }

  /// Open a capsule (mark as opened)
  static Future<void> openCapsule(int capsuleId) async {
    _logger.info('Opening capsule: $capsuleId');

    try {
      if (capsuleId <= 0) {
        throw ArgumentError('Invalid capsule ID: $capsuleId');
      }

      final connection = await RemoteDB.getConnection();

      final checkResult = await connection.query(
        '''
        SELECT id, is_opened, open_date
        FROM capsules
        WHERE id = @id
        ''',
        substitutionValues: {'id': capsuleId},
      );

      if (checkResult.isEmpty) {
        throw Exception('Capsule not found with ID: $capsuleId');
      }

      final isAlreadyOpened = checkResult.first[1] as bool;
      if (isAlreadyOpened) {
        _logger.warning('Attempted to open already opened capsule: $capsuleId');
        throw Exception('Capsule is already opened');
      }

      final openDate = checkResult.first[2] as DateTime;
      if (openDate.isAfter(DateTime.now())) {
        throw Exception(
          'Capsule is not yet ready to be opened. Available on: ${openDate.toLocal()}',
        );
      }

      await _logger.logExecutionTime('Open capsule query', () async {
        await connection.query(
          '''
          UPDATE capsules 
          SET is_opened = true, opened_at = @openedAt
          WHERE id = @capsuleId AND is_opened = false
          ''',
          substitutionValues: {
            'capsuleId': capsuleId,
            'openedAt': DateTime.now().toUtc(),
          },
        );
      });

      _logger.info(
        'Capsule opened successfully',
        data: {
          'capsuleId': capsuleId,
          'openedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to open capsule', error: e, stackTrace: stackTrace);

      if (e is ArgumentError) {
        throw Exception('Validation error: ${e.message}');
      } else if (e.toString().contains('connection')) {
        throw Exception(
          'Database connection error. Please check your internet connection and try again.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception('Database operation timed out. Please try again.');
      }

      rethrow;
    }
  }

  /// Get capsules that are ready to open (for notifications)
  static Future<List<Capsule>> getReadyCapsules() async {
    _logger.info('Getting capsules ready to open');

    try {
      final connection = await RemoteDB.getConnection();

      final result = await _logger.logExecutionTime(
        'Get ready capsules query',
        () async {
          return await connection.query(
            '''
            SELECT id, owner_id, recipient_email, content_type, content_encrypted, 
                   open_date, created_at, is_opened, title, opened_at, notification_sent
            FROM capsules 
            WHERE open_date <= @now AND is_opened = false AND notification_sent = false
            ''',
            substitutionValues: {'now': DateTime.now()},
          );
        },
      );

      final capsules =
          result.map((row) {
            return Capsule(
              id: row[0] as int,
              ownerId: row[1] as int,
              recipientEmail: row[2] as String?,
              contentType: row[3] as String,
              contentEncrypted: row[4] as String,
              openDate: row[5] as DateTime,
              createdAt: row[6] as DateTime,
              isOpened: row[7] as bool,
              title: row[8] as String?,
              openedAt: row[9] as DateTime?,
              notificationSent: row[10] as bool,
            );
          }).toList();

      _logger.info(
        'Retrieved ready capsules',
        data: {'count': capsules.length},
      );

      return capsules;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get ready capsules',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get capsules that are ready to open and mark notifications as sent
  static Future<List<Capsule>> getAndProcessReadyCapsules() async {
    _logger.info('Getting and processing ready capsules');

    try {
      final readyCapsules = await getReadyCapsules();

      if (readyCapsules.isNotEmpty) {
        // تحديث حالة الإشعار لجميع الكبسولات الجاهزة
        final connection = await RemoteDB.getConnection();
        final capsuleIds = readyCapsules.map((c) => c.id).toList();

        await _logger.logExecutionTime(
          'Mark notifications as sent for ready capsules',
          () async {
            await connection.query(
              '''
              UPDATE capsules 
              SET notification_sent = true
              WHERE id = ANY(@capsuleIds)
              ''',
              substitutionValues: {'capsuleIds': capsuleIds},
            );
          },
        );

        _logger.info(
          'Marked notifications as sent for ready capsules',
          data: {'capsuleIds': capsuleIds},
        );
      }

      return readyCapsules;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get and process ready capsules',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Mark notification as sent for a capsule
  static Future<void> markNotificationSent(int capsuleId) async {
    _logger.info('Marking notification as sent for capsule: $capsuleId');

    try {
      final connection = await RemoteDB.getConnection();

      await _logger.logExecutionTime('Mark notification sent query', () async {
        await connection.query(
          '''
            UPDATE capsules 
            SET notification_sent = true
            WHERE id = @capsuleId
            ''',
          substitutionValues: {'capsuleId': capsuleId},
        );
      });

      _logger.info(
        'Notification marked as sent',
        data: {'capsuleId': capsuleId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to mark notification as sent',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Add a recipient to an existing capsule for sharing
  static Future<void> addRecipientToCapsule(
    int capsuleId,
    String recipientEmail,
  ) async {
    _logger.info(
      'Adding recipient to capsule: $capsuleId, recipient: $recipientEmail',
    );

    try {
      final connection = await RemoteDB.getConnection();

      await _logger.logExecutionTime(
        'Add recipient to capsule query',
        () async {
          await connection.query(
            '''
            UPDATE capsules 
            SET recipient_email = @recipientEmail
            WHERE id = @capsuleId
            ''',
            substitutionValues: {
              'capsuleId': capsuleId,
              'recipientEmail': recipientEmail,
            },
          );
        },
      );

      _logger.info(
        'Recipient added to capsule successfully',
        data: {'capsuleId': capsuleId, 'recipientEmail': recipientEmail},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to add recipient to capsule',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate a shareable link for a capsule
  static String generateShareableLink(int capsuleId, String appDomain) {
    // Create a deep link that can be used to access the shared capsule
    return '$appDomain/shared-capsule/$capsuleId';
  }

  /// Get capsule by ID (for shared access)
  static Future<Capsule?> getCapsuleById(int capsuleId) async {
    _logger.info('Getting capsule by ID: $capsuleId');

    try {
      final connection = await RemoteDB.getConnection();

      final result = await _logger.logExecutionTime(
        'Get capsule by ID query',
        () async {
          return await connection.query(
            '''
            SELECT id, owner_id, recipient_email, content_type, content_encrypted, 
                   open_date, created_at, is_opened, title, opened_at, notification_sent
            FROM capsules 
            WHERE id = @capsuleId
            ''',
            substitutionValues: {'capsuleId': capsuleId},
          );
        },
      );

      if (result.isEmpty) {
        _logger.info('Capsule not found', data: {'capsuleId': capsuleId});
        return null;
      }

      final row = result.first;
      final capsule = Capsule(
        id: row[0] as int,
        ownerId: row[1] as int,
        recipientEmail: row[2] as String?,
        contentType: row[3] as String,
        contentEncrypted: row[4] as String,
        openDate: row[5] as DateTime,
        createdAt: row[6] as DateTime,
        isOpened: row[7] as bool,
        title: row[8] as String?,
        openedAt: row[9] as DateTime?,
        notificationSent: row[10] as bool,
      );

      _logger.info(
        'Capsule retrieved successfully',
        data: {'capsuleId': capsuleId},
      );
      return capsule;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get capsule by ID',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a capsule
  static Future<void> deleteCapsule(int capsuleId, int ownerId) async {
    _logger.info('Deleting capsule: $capsuleId for owner: $ownerId');

    try {
      if (capsuleId <= 0) {
        throw ArgumentError('Invalid capsule ID: $capsuleId');
      }

      if (ownerId <= 0) {
        throw ArgumentError('Invalid owner ID: $ownerId');
      }

      final conn = await RemoteDB.getConnection();

      final ownershipCheck = await conn.query(
        '''
        SELECT owner_id FROM capsules WHERE id = @id
        ''',
        substitutionValues: {'id': capsuleId},
      );

      if (ownershipCheck.isEmpty) {
        throw Exception('Capsule not found with ID: $capsuleId');
      }

      final actualOwnerId = ownershipCheck.first[0] as int;
      if (actualOwnerId != ownerId) {
        throw Exception('Access denied: You can only delete your own capsules');
      }

      final deleteResult = await conn.query(
        '''
        DELETE FROM capsules WHERE id = @id AND owner_id = @owner_id
        RETURNING id
        ''',
        substitutionValues: {'id': capsuleId, 'owner_id': ownerId},
      );

      if (deleteResult.isEmpty) {
        throw Exception(
          'Failed to delete capsule - it may have been deleted already',
        );
      }

      try {
        await NotificationService.cancelCapsuleNotification(capsuleId);
      } catch (e, stackTrace) {
        _logger.warning(
          'Failed to cancel notification for deleted capsule $capsuleId',
          error: e,
          stackTrace: stackTrace,
        );
      }

      _logger.info(
        'Capsule deleted successfully',
        data: {'capsuleId': capsuleId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to delete capsule',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Helper methods for safe parsing
  static int _safeParseInt(dynamic value, String fieldName) {
    if (value == null) {
      throw Exception('Required field $fieldName is null');
    }
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw Exception('Invalid integer value for $fieldName: $value');
      }
      return parsed;
    }
    throw Exception('Unexpected type for $fieldName: ${value.runtimeType}');
  }

  static String? _safeParseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static DateTime _safeParseDateTime(dynamic value, [String? fieldName]) {
    if (value == null) {
      if (fieldName != null) {
        throw Exception('Required field $fieldName is null');
      }
      return DateTime.now();
    }
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw Exception(
          'Invalid datetime value for ${fieldName ?? 'field'}: $value',
        );
      }
    }
    throw Exception(
      'Unexpected type for ${fieldName ?? 'datetime field'}: ${value.runtimeType}',
    );
  }

  static bool _safeParseBool(dynamic value, String fieldName) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) {
      return value != 0;
    }
    throw Exception('Unexpected type for $fieldName: ${value.runtimeType}');
  }
}
