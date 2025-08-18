import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final IconData? icon;
  final Color? iconColor;
  final double iconSize;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.icon,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return PopupMenuButton<String>(
          icon: Icon(
            icon ?? Icons.language,
            color: iconColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          ),
          tooltip: context.tr('common.language'),
          onSelected: (String languageCode) {
            localizationService.setLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return localizationService.getSupportedLocales().map((
              Locale locale,
            ) {
              final isSelected =
                  locale.languageCode ==
                  localizationService.currentLanguageCode;
              return PopupMenuItem<String>(
                value: locale.languageCode,
                child: Row(
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(
                      localizationService.getLanguageDisplayName(
                        locale.languageCode,
                      ),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}

class LanguageToggleButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;

  const LanguageToggleButton({
    super.key,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return GestureDetector(
          onTap: () => localizationService.toggleLanguage(),
          child: Container(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  backgroundColor ??
                  Theme.of(context).primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Theme.of(context).primaryColor.withAlpha(77),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 16,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  localizationService.getLanguageDisplayName(
                    localizationService.currentLanguageCode,
                  ),
                  style: TextStyle(
                    color: textColor ?? Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
