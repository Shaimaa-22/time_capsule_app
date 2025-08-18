import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import '../utils/logger.dart';

class RemoteDB {
  static final _logger = Logger.forClass('RemoteDB');
  static PostgreSQLConnection? _connection;
  static int _retryCount = 0;
  static const int _maxRetries = 3;

  static Future<PostgreSQLConnection> getConnection() async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await _createConnection();
      }
      return _connection!;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get database connection',
        error: e,
        stackTrace: stackTrace,
      );

      if (_retryCount < _maxRetries) {
        _retryCount++;
        _logger.info(
          'Retrying database connection (attempt $_retryCount/$_maxRetries)',
        );
        await Future.delayed(Duration(seconds: _retryCount * 2));
        return getConnection();
      }

      _retryCount = 0;
      rethrow;
    }
  }

  static Future<void> _createConnection() async {
    try {
      final dbHost = dotenv.env['DB_HOST'] ?? 'localhost';
      final dbPort = int.tryParse(dotenv.env['DB_PORT'] ?? '5432') ?? 5432;
      final dbName = dotenv.env['DB_NAME'] ?? '';
      final dbUser = dotenv.env['DB_USER'] ?? '';
      final dbPassword = dotenv.env['DB_PASSWORD'] ?? '';
      final useSSL = dotenv.env['DB_USE_SSL'] == 'true';

      if (dbName.isEmpty || dbUser.isEmpty) {
        throw Exception(
          'Database configuration incomplete: DB_NAME and DB_USER are required',
        );
      }

      _logger.info('Creating database connection to $dbHost:$dbPort/$dbName');

      _connection = PostgreSQLConnection(
        dbHost,
        dbPort,
        dbName,
        username: dbUser,
        password: dbPassword,
        useSSL: useSSL,
      );

      await _connection!.open();
      _retryCount = 0;
      Logger.database('Connected to database successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create database connection',
        error: e,
        stackTrace: stackTrace,
      );
      _connection = null;
      rethrow;
    }
  }

  static Future<void> closeConnection() async {
    try {
      if (_connection != null && !_connection!.isClosed) {
        await _connection!.close();
        _logger.info('Database connection closed successfully');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to close database connection',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _connection = null;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final connection = await getConnection();
      await connection.query('SELECT 1');
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Database connection test failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
