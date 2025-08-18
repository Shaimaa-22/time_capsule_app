import 'package:bcrypt/bcrypt.dart';
import '../utils/logger.dart';
import 'remote_db.dart';

class AuthService {
  static final _logger = Logger.forClass('AuthService');

  static int? currentUserId;
  static String? currentUserEmail;
  static String? currentUserName;

  Future<String> register(String name, String email, String password) async {
    _logger.info('Registration attempt for email: $email');

    try {
      if (name.trim().isEmpty) {
        return "Error: Name cannot be empty";
      }

      if (email.trim().isEmpty || !_isValidEmail(email)) {
        return "Error: Invalid email address";
      }

      if (password.length < 6) {
        return "Error: Password must be at least 6 characters";
      }

      final connection = await RemoteDB.getConnection();
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      _logger.debug('Password hashed successfully');

      final result = await _logger.logExecutionTime(
        'User registration query',
        () async {
          return await connection.query(
            '''
          INSERT INTO users (name, email, password_hash)
          VALUES (@name, @mail, @pass)
          RETURNING id
          ''',
            substitutionValues: {
              'name': name.trim(),
              'mail': email.trim().toLowerCase(),
              'pass': hashedPassword,
            },
          );
        },
      );

      if (result.isNotEmpty) {
        currentUserId = result.first[0] as int;
        currentUserEmail = email.trim().toLowerCase();
        currentUserName = name.trim();

        Logger.auth(
          'User registered and auto-logged in',
          data: {
            'userId': currentUserId,
            'email': currentUserEmail,
            'name': currentUserName,
          },
        );
      }

      return "success: registered";
    } catch (e, stackTrace) {
      if (e.toString().contains('duplicate key value')) {
        _logger.warning('Registration failed: Email already exists', error: e);
        return "Error: Email already exists";
      }

      if (e.toString().contains('connection')) {
        _logger.error(
          'Registration failed: Database connection error',
          error: e,
          stackTrace: stackTrace,
        );
        return "Error: Unable to connect to server. Please try again later.";
      }

      _logger.error(
        'Registration failed with unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return "Error: Registration failed. Please try again.";
    }
  }

  Future<String> login(String email, String password) async {
    _logger.info('Login attempt for email: $email');

    try {
      if (email.trim().isEmpty || !_isValidEmail(email)) {
        return "Error: Invalid email address";
      }

      if (password.isEmpty) {
        return "Error: Password cannot be empty";
      }

      final connection = await RemoteDB.getConnection();

      final result = await _logger.logExecutionTime(
        'User login query',
        () async {
          return await connection.query(
            '''
          SELECT id, name, password_hash
          FROM users
          WHERE email = @mail
          ''',
            substitutionValues: {'mail': email.trim().toLowerCase()},
          );
        },
      );

      if (result.isEmpty) {
        _logger.warning('Login failed: User not found for email: $email');
        return "Error: user not found";
      }

      final userId = result.first[0] as int;
      final userName = result.first[1] as String;
      final storedPassword = result.first[2] as String;

      _logger.debug('User found, verifying password');

      bool isPasswordCorrect;
      try {
        isPasswordCorrect = BCrypt.checkpw(password, storedPassword);
      } catch (e, stackTrace) {
        _logger.error(
          'Password verification failed',
          error: e,
          stackTrace: stackTrace,
        );
        return "Error: Authentication failed. Please try again.";
      }

      if (isPasswordCorrect) {
        currentUserId = userId;
        currentUserEmail = email.trim().toLowerCase();
        currentUserName = userName;

        Logger.auth(
          'User logged in successfully',
          data: {
            'userId': currentUserId,
            'email': currentUserEmail,
            'name': currentUserName,
          },
        );

        return "success: logged in";
      } else {
        _logger.warning('Login failed: Incorrect password for email: $email');
        return "Error: wrong password";
      }
    } catch (e, stackTrace) {
      if (e.toString().contains('connection')) {
        _logger.error(
          'Login failed: Database connection error',
          error: e,
          stackTrace: stackTrace,
        );
        return "Error: Unable to connect to server. Please try again later.";
      }

      _logger.error(
        'Login failed with unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return "Error: Login failed. Please try again.";
    }
  }

  static void logout() {
    try {
      Logger.auth(
        'User logging out',
        data: {'userId': currentUserId, 'email': currentUserEmail},
      );

      currentUserId = null;
      currentUserEmail = null;
      currentUserName = null;

      Logger.auth('User logged out successfully');
    } catch (e, stackTrace) {
      Logger.forClass(
        'AuthService',
      ).error('Error during logout', error: e, stackTrace: stackTrace);

      // Force clear user data even if logging fails
      currentUserId = null;
      currentUserEmail = null;
      currentUserName = null;
    }
  }

  static bool get isLoggedIn {
    try {
      final loggedIn = currentUserId != null;
      Logger.debug('Checking login status: $loggedIn', tag: 'AuthService');
      return loggedIn;
    } catch (e) {
      Logger.forClass(
        'AuthService',
      ).error('Error checking login status', error: e);
      return false;
    }
  }

  static Map<String, dynamic>? get currentUser {
    try {
      if (currentUserId == null) return null;
      return {
        'id': currentUserId,
        'email': currentUserEmail,
        'name': currentUserName,
      };
    } catch (e) {
      Logger.forClass(
        'AuthService',
      ).error('Error getting current user', error: e);
      return null;
    }
  }

  static bool _isValidEmail(String email) {
    try {
      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    } catch (e) {
      return false;
    }
  }
}
