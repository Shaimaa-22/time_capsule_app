import 'package:share_plus/share_plus.dart';
import '../models/capsule.dart';
import '../utils/logger.dart';
import 'capsule_service.dart';

class SharingService {
  static final _logger = Logger.forClass('SharingService');
  static const String appDomain =
      'https://timecapsule.app'; 

  /// Share a capsule with another user by email
  static Future<void> shareCapsuleWithUser(
    Capsule capsule,
    String recipientEmail,
  ) async {
    _logger.info('Sharing capsule with user: ${capsule.id} -> $recipientEmail');

    try {
      // Add recipient to the capsule
      await CapsuleService.addRecipientToCapsule(capsule.id, recipientEmail);

      // Generate shareable link
      final shareLink = CapsuleService.generateShareableLink(
        capsule.id,
        appDomain,
      );

      // Create invitation message
      final invitationMessage = _createInvitationMessage(capsule, shareLink);

      // Share the invitation
      await Share.share(
        invitationMessage,
        subject:
            'Invitation to view Time Capsule: ${capsule.title ?? 'Time Capsule'}',
      );

      _logger.info(
        'Capsule shared successfully',
        data: {'capsuleId': capsule.id, 'recipientEmail': recipientEmail},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to share capsule with user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Share capsule as text (original functionality)
  static Future<void> shareCapsuleAsText(Capsule capsule) async {
    _logger.info('Sharing capsule as text: ${capsule.id}');

    try {
      final shareText = _createShareText(capsule);
      await Share.share(shareText);

      _logger.info(
        'Capsule shared as text successfully',
        data: {'capsuleId': capsule.id},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to share capsule as text',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create invitation message for shared capsule
  static String _createInvitationMessage(Capsule capsule, String shareLink) {
    final openDate = _formatDate(capsule.openDate);
    final status = capsule.isOpened ? 'Opened' : 'Locked';

    return '''
You have been invited to view a Time Capsule.

Title: ${capsule.title ?? 'Time Capsule'}
Open Date: $openDate
Status: $status

${capsule.isOpened ? 'The capsule is now open and you can view its content.' : 'This capsule will open at the same time for both of us on $openDate.'}

Click the link to access:
$shareLink

#TimeCapsule #Memories #Sharing
''';
  }

  /// Create share text (original functionality)
  static String _createShareText(Capsule capsule) {
    final openDate = _formatDate(capsule.openDate);
    final status = capsule.isOpened ? 'Opened' : 'Locked';

    return '''
Time Capsule: ${capsule.title ?? 'Time Capsule'}

Open Date: $openDate
Status: $status

${capsule.isOpened ? 'This capsule has been opened and its content is ready to view.' : 'Waiting to open this capsule on $openDate.'}

#TimeCapsule #Memories
''';
  }

  /// Format date for display in English
  static String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
