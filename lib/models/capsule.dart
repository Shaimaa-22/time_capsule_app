class Capsule {
  final int id;
  final int ownerId;
  final String? recipientEmail;
  final String contentType;
  final String contentEncrypted;
  final DateTime openDate;
  final DateTime createdAt;
  final bool isOpened;
  final String? title;
  final DateTime? openedAt;
  final bool notificationSent;

  Capsule({
    required this.id,
    required this.ownerId,
    this.recipientEmail,
    required this.contentType,
    required this.contentEncrypted,
    required this.openDate,
    required this.createdAt,
    required this.isOpened,
    this.title,
    this.openedAt,
    required this.notificationSent,
  });

  bool get isLocked => DateTime.now().isBefore(openDate);

  Capsule copyWith({
    int? id,
    int? ownerId,
    String? recipientEmail,
    String? contentType,
    String? contentEncrypted,
    DateTime? openDate,
    DateTime? createdAt,
    bool? isOpened,
    String? title,
    DateTime? openedAt,
    bool? notificationSent,
  }) {
    return Capsule(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      contentType: contentType ?? this.contentType,
      contentEncrypted: contentEncrypted ?? this.contentEncrypted,
      openDate: openDate ?? this.openDate,
      createdAt: createdAt ?? this.createdAt,
      isOpened: isOpened ?? this.isOpened,
      title: title ?? this.title,
      openedAt: openedAt ?? this.openedAt,
      notificationSent: notificationSent ?? this.notificationSent,
    );
  }
}
