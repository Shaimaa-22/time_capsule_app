import 'package:flutter/material.dart';
import '../models/capsule.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/capsule_list_item.dart';

class OpenCapsulesScreen extends StatelessWidget {
  final List<Capsule> capsules;

  const OpenCapsulesScreen({super.key, required this.capsules});

  @override
  Widget build(BuildContext context) {
    if (capsules.isEmpty) {
      return Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('open_capsules.no_capsules'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('open_capsules.no_capsules_subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: capsules.length,
        itemBuilder: (context, index) {
          final capsule = capsules[index];
          return CapsuleListItem(capsule: capsule);
        },
      ),
    );
  }
}
