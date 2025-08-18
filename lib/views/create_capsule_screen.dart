import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'dart:convert';
import '../services/capsule_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/logger.dart';
import '../utils/responsive_helper.dart';
import '../widgets/create_capsule/content_type_selector.dart';
import '../widgets/create_capsule/file_picker_widget.dart';
import '../widgets/create_capsule/datetime_picker_widget.dart';
import '../widgets/create_capsule/submit_buttons_widget.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  static final _logger = Logger.forClass('CreateCapsuleScreen');
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _contentController = TextEditingController();

  String contentType = "text";
  DateTime? openDate;
  bool isLoading = false;

  File? selectedFile;
  String? selectedFileName;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _logger.debug(
      'CreateCapsule screen initialized',
      data: {
        'currentUserId': AuthService.currentUserId,
        'isLoggedIn': AuthService.isLoggedIn,
        'currentUser': AuthService.currentUser,
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedFile = File(image.path);
          selectedFileName = image.name;
        });
        _logger.info('Image selected: ${image.name}');
      }
    } catch (e) {
      _logger.error('Error picking image: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error selecting image: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: ThemeService.getDangerColor(context),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedFile = File(image.path);
          selectedFileName = image.name;
        });
        _logger.info('Image captured: ${image.name}');
      }
    } catch (e) {
      _logger.error('Error capturing image: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error capturing image: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: ThemeService.getDangerColor(context),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'files',
        extensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'mp4',
          'mov',
          'avi',
          'pdf',
          'txt',
          'doc',
          'docx',
        ],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          selectedFile = File(file.path);
          selectedFileName = file.name;
        });
        _logger.info('File selected: ${file.name}');
      }
    } catch (e) {
      _logger.error('Error picking file: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error selecting file: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: ThemeService.getDangerColor(context),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  void _removeSelectedFile() {
    setState(() {
      selectedFile = null;
      selectedFileName = null;
    });
  }

  Future<String> _encodeFileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      _logger.error('Error encoding file to base64: $e');
      rethrow;
    }
  }

  Future<void> _pickOpenDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Select Open Date',
      cancelText: 'Cancel',
      confirmText: 'Next',
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: 'Select Open Time',
        cancelText: 'Cancel',
        confirmText: 'Select',
      );

      if (pickedTime != null) {
        setState(() {
          openDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitCapsule() async {
    _logger.debug(
      'Submit button pressed',
      data: {
        'currentUserId': AuthService.currentUserId,
        'isLoggedIn': AuthService.isLoggedIn,
      },
    );

    if (!_formKey.currentState!.validate()) return;

    if (openDate == null) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: " Please select an open date",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getWarningColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if ((contentType == "image" || contentType == "video") &&
        selectedFile == null) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Please select a $contentType file",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getWarningColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (!AuthService.isLoggedIn || AuthService.currentUserId == null) {
      _logger.warning('User not logged in - redirecting to login');
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Please login first",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getDangerColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      String contentToSave;
      if (contentType == "text") {
        contentToSave = _contentController.text;
      } else if (selectedFile != null) {
        final base64Content = await _encodeFileToBase64(selectedFile!);
        contentToSave = jsonEncode({
          'filename': selectedFileName,
          'data': base64Content,
          'description':
              _contentController.text.trim().isEmpty
                  ? null
                  : _contentController.text.trim(),
        });
      } else {
        contentToSave = _contentController.text;
      }

      await CapsuleService.createCapsule(
        ownerId: AuthService.currentUserId!,
        recipientEmail:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
        contentType: contentType,
        contentEncrypted: contentToSave,
        openDate: openDate!,
        title: _titleController.text,
      );

      if (!mounted) return;
      Fluttertoast.showToast(
        msg:
            "Time capsule created successfully!\n You'll be notified when it's ready to open",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getSuccessColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      _logger.error('Error creating capsule', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Error saving capsule: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: ThemeService.getDangerColor(context),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getTimeUntilOpen(DateTime openDate) {
    final now = DateTime.now();
    final difference = openDate.difference(now);

    if (difference.isNegative) {
      return "Ready to open!";
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return "$days days, $hours hours, $minutes minutes from now";
    } else if (hours > 0) {
      return "$hours hours, $minutes minutes from now";
    } else {
      return "$minutes minutes from now";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Time Capsule',
          style: TextStyle(
            fontSize: ResponsiveHelper.titleFontSize(context),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeService.getPrimaryGradient(context),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeService.getPrimaryColor(context).withValues(alpha: 0.08),
              ThemeService.getSecondaryColor(context).withValues(alpha: 0.03),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.2, 0.4],
          ),
        ),
        child: SingleChildScrollView(
          padding: ResponsiveHelper.responsivePadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  ResponsiveHelper.isDesktop(context) ? 600 : double.infinity,
            ),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: ResponsiveHelper.responsivePadding(context),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeService.getPrimaryColor(
                              context,
                            ).withValues(alpha: 0.15),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: ThemeService.getPrimaryGradient(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeService.getPrimaryColor(
                                        context,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
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
                                      'Capsule Details',
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveHelper.titleFontSize(
                                              context,
                                            ),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Give your capsule a name and recipient',
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveHelper.bodyFontSize(
                                              context,
                                            ) -
                                            2,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                ResponsiveHelper.isMobile(context) ? 20 : 24,
                          ),

                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.bodyFontSize(context),
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: ' Capsule Title',
                              labelStyle: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(
                                  context,
                                ),
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: ThemeService.getPrimaryGradient(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.title_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title for your capsule 📝';
                              }
                              return null;
                            },
                          ),

                          SizedBox(
                            height:
                                ResponsiveHelper.isMobile(context) ? 20 : 24,
                          ),

                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.bodyFontSize(context),
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: ' Recipient Email (Optional)',
                              labelStyle: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(
                                  context,
                                ),
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: 'someone@example.com',
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: ThemeService.successGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.email_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 24 : 32,
                    ),

                    ContentTypeSelector(
                      selectedType: contentType,
                      onTypeChanged: (type) {
                        setState(() {
                          contentType = type;
                          selectedFile = null;
                          selectedFileName = null;
                        });
                      },
                    ),

                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 24 : 32,
                    ),

                    if (contentType == "text") ...[
                      Container(
                        padding: ResponsiveHelper.responsivePadding(context),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeService.getSuccessColor(
                                context,
                              ).withValues(alpha: 0.15),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: ThemeService.successGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ThemeService.getSuccessColor(
                                          context,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.message_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Message',
                                        style: TextStyle(
                                          fontSize:
                                              ResponsiveHelper.titleFontSize(
                                                context,
                                              ),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Write something special for the future',
                                        style: TextStyle(
                                          fontSize:
                                              ResponsiveHelper.bodyFontSize(
                                                context,
                                              ) -
                                              2,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _contentController,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(
                                  context,
                                ),
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                              maxLines:
                                  ResponsiveHelper.isMobile(context) ? 8 : 10,
                              decoration: InputDecoration(
                                labelText:
                                    'Write your heartfelt message here... ',
                                labelStyle: TextStyle(
                                  fontSize: ResponsiveHelper.bodyFontSize(
                                    context,
                                  ),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please write your message ';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      FilePickerWidget(
                        contentType: contentType,
                        selectedFile: selectedFile,
                        selectedFileName: selectedFileName,
                        onPickImage: _pickImage,
                        onPickImageFromCamera: _pickImageFromCamera,
                        onPickFile: _pickFile,
                        onRemoveFile: _removeSelectedFile,
                      ),
                    ],

                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 32 : 40,
                    ),

                    DateTimePickerWidget(
                      openDate: openDate,
                      onPickDate: _pickOpenDate,
                      getTimeUntilOpen: _getTimeUntilOpen,
                    ),

                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 32 : 40,
                    ),

                    SubmitButtonsWidget(
                      isLoading: isLoading,
                      onSubmit: _submitCapsule,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
