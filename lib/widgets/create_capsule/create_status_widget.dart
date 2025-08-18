import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthStatusWidget extends StatelessWidget {
  const AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AuthService.isLoggedIn
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AuthService.isLoggedIn ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            AuthService.isLoggedIn ? Icons.check_circle : Icons.error,
            color: AuthService.isLoggedIn ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AuthService.isLoggedIn
                  ? "Logged in as: ${AuthService.currentUserName} (ID: ${AuthService.currentUserId})"
                  : "Not logged in - Please login first",
              style: TextStyle(
                color: AuthService.isLoggedIn
                    ? Colors.green[700]
                    : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
