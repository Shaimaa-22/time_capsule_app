import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class DateTimePickerWidget extends StatelessWidget {
  final DateTime? openDate;
  final VoidCallback onPickDate;
  final String Function(DateTime) getTimeUntilOpen;

  const DateTimePickerWidget({
    super.key,
    required this.openDate,
    required this.onPickDate,
    required this.getTimeUntilOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.responsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening Date',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When should this capsule be opened?',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date picker button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onPickDate();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    openDate != null
                        ? const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : LinearGradient(
                          colors: [
                            const Color(0xFF9B59B6).withValues(alpha: 0.1),
                            const Color(0xFF8E44AD).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      openDate != null
                          ? const Color(0xFF9B59B6)
                          : const Color(0xFF9B59B6).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow:
                    openDate != null
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF9B59B6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              openDate != null
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(
                                    0xFF9B59B6,
                                  ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          openDate != null
                              ? Icons.event_available_rounded
                              : Icons.event_rounded,
                          color:
                              openDate != null
                                  ? Colors.white
                                  : const Color(0xFF9B59B6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              openDate != null
                                  ? ' Selected Date & Time'
                                  : 'Tap to Select Date & Time',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(
                                  context,
                                ),
                                fontWeight: FontWeight.bold,
                                color:
                                    openDate != null
                                        ? Colors.white
                                        : const Color(0xFF2D3748),
                              ),
                            ),
                            if (openDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${openDate!.day}/${openDate!.month}/${openDate!.year} at ${openDate!.hour.toString().padLeft(2, '0')}:${openDate!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.bodyFontSize(
                                    context,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color:
                            openDate != null
                                ? Colors.white.withValues(alpha: .7)
                                : const Color(
                                  0xFF9B59B6,
                                ).withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ],
                  ),

                  if (openDate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⏳ ${getTimeUntilOpen(openDate!)}',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.bodyFontSize(context) - 1,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (openDate == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ' Choose a future date when you want this capsule to be opened',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
