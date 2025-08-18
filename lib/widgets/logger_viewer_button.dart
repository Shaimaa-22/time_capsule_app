import 'package:flutter/material.dart';
import '../views/logger_viewer_screen.dart';

class LoggerViewerButton extends StatelessWidget {
  const LoggerViewerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoggerViewerScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.bug_report,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
