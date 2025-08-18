import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../utils/responsive_helper.dart';

class FilePickerWidget extends StatelessWidget {
  final String contentType;
  final File? selectedFile;
  final String? selectedFileName;
  final VoidCallback onPickImage;
  final VoidCallback onPickImageFromCamera;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const FilePickerWidget({
    super.key,
    required this.contentType,
    required this.selectedFile,
    required this.selectedFileName,
    required this.onPickImage,
    required this.onPickImageFromCamera,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  Color _getContentTypeColor() {
    switch (contentType) {
      case 'image':
        return const Color(0xFFFF6B9D); // Cute pink
      case 'video':
        return const Color(0xFF9B59B6); // Soft purple
      case 'audio':
        return const Color(0xFFFFD93D); // Sunny yellow
      default:
        return const Color(0xFF4ECDC4); // Mint green
    }
  }

  IconData _getContentTypeIcon() {
    switch (contentType) {
      case 'image':
        return Icons.photo_camera_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'audio':
        return Icons.mic_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  String _getContentTypeEmoji() {
    switch (contentType) {
      case 'image':
        return '📸';
      case 'video':
        return '🎬';
      case 'audio':
        return '🎵';
      default:
        return '📎';
    }
  }

  String _getContentTypeTitle() {
    switch (contentType) {
      case 'image':
        return 'Photo Memory';
      case 'video':
        return 'Video Message';
      case 'audio':
        return 'Voice Note';
      default:
        return 'File Attachment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getContentTypeColor();

    return Container(
      padding: ResponsiveHelper.responsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
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
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getContentTypeIcon(),
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
                      '${_getContentTypeEmoji()} ${_getContentTypeTitle()}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose or capture your ${contentType.toLowerCase()}',
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

          // File selection area
          if (selectedFile == null) ...[
            // Action buttons
            if (contentType == 'image') ...[
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.photo_library_rounded,
                      label: '📱 Gallery',
                      color: color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onPickImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      label: '📷 Camera',
                      color: color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onPickImageFromCamera();
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildActionButton(
                context: context,
                icon: Icons.folder_rounded,
                label: ' Choose ${contentType.toUpperCase()} File',
                color: color,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPickFile();
                },
                fullWidth: true,
              ),
            ],

            const SizedBox(height: 20),

            // Drag and drop area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getContentTypeIcon(), size: 32, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the buttons above to select your ${contentType.toLowerCase()}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.bodyFontSize(context),
                      color: const Color(0xFF718096),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: ${_getSupportedFormats()}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                      color: const Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Selected file display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File Selected',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(
                                  context,
                                ),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedFileName ?? 'Unknown file',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.bodyFontSize(context) - 2,
                                color: const Color(0xFF718096),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onRemoveFile();
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE53E3E,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFE53E3E),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (contentType == 'image' && selectedFile != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedFile!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.bodyFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSupportedFormats() {
    switch (contentType) {
      case 'image':
        return 'JPG, PNG, GIF';
      case 'video':
        return 'MP4, MOV, AVI';
      case 'audio':
        return 'MP3, WAV, M4A';
      default:
        return 'Various formats';
    }
  }
}
