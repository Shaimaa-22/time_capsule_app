import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class ContentTypeSelector extends StatefulWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const ContentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  State<ContentTypeSelector> createState() => _ContentTypeSelectorState();
}

class _ContentTypeSelectorState extends State<ContentTypeSelector>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  final List<Map<String, dynamic>> contentTypes = [
    {
      'type': 'text',
      'label': 'Text Message',
      'icon': Icons.text_fields_rounded,
      'color': const Color(0xFFFE9F52),
      'description': 'Write a message',
    },
    {
      'type': 'image',
      'label': 'Photo Memory',
      'icon': Icons.photo_camera_rounded,
      'color': const Color(0xFFFF6B9D),
      'description': 'Capture a special moment',
    },
    {
      'type': 'video',
      'label': 'Video Message',
      'icon': Icons.videocam_rounded,
      'color': const Color(0xFFD67AFA),
      'description': 'Record a video for the future',
    },
    {
      'type': 'audio',
      'label': 'Voice Note',
      'icon': Icons.mic_rounded,
      'color': const Color(0xFF3CECFF),
      'description': 'Leave a voice message',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      contentTypes.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _scaleAnimations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 1.0, end: 0.95).animate(
                CurvedAnimation(parent: controller, curve: Curves.elasticOut),
              ),
            )
            .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTypePressed(int index, String type) async {
    HapticFeedback.mediumImpact();
    await _controllers[index].forward();
    await _controllers[index].reverse();
    widget.onTypeChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.responsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
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
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.category_rounded,
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
                      'Content Type',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose what to include in your capsule',
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
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 24),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.1 : 1.2,
            ),
            itemCount: contentTypes.length,
            itemBuilder: (context, index) {
              final contentType = contentTypes[index];
              final isSelected = widget.selectedType == contentType['type'];

              return AnimatedBuilder(
                animation: _scaleAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: GestureDetector(
                      onTap: () => _onTypePressed(index, contentType['type']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    colors: [
                                      contentType['color'],
                                      contentType['color'].withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : LinearGradient(
                                    colors: [
                                      contentType['color'].withValues(
                                        alpha: 0.1,
                                      ),
                                      contentType['color'].withValues(
                                        alpha: 0.05,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isSelected
                                    ? contentType['color']
                                    : contentType['color'].withValues(
                                      alpha: 0.2,
                                    ),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: contentType['color'].withValues(
                                alpha: isSelected ? 0.4 : 0.1,
                              ),
                              blurRadius: isSelected ? 20 : 8,
                              offset: Offset(0, isSelected ? 8 : 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : contentType['color'].withValues(
                                            alpha: 0.15,
                                          ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  contentType['icon'],
                                  size:
                                      ResponsiveHelper.isMobile(context)
                                          ? 24
                                          : 32,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : contentType['color'],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Label
                              Text(
                                contentType['label'],
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.isMobile(context)
                                          ? 12
                                          : 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : const Color(0xFF2D3748),
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Description
                              Text(
                                contentType['description'],
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.isMobile(context)
                                          ? 10
                                          : 11,
                                  color:
                                      isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF718096),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Selection indicator
                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
