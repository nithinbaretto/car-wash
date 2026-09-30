enum NotificationKind { completed, inProgress, booking, offer, update }

enum NotificationFilter { all, bookings, offers, updates }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.section,
    this.type = 'update',
    this.bookingId,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final type = json['type']?.toString() ?? 'update';
    final title = json['title']?.toString() ?? '';
    final body = json['body']?.toString() ?? '';
    final isRead = json['isRead'] as bool? ?? false;
    final bookingId = json['bookingId']?.toString();
    final createdAt = json['createdAt'];

    final kind = switch (type.toLowerCase()) {
      'booking' => title.toLowerCase().contains('progress')
          ? NotificationKind.inProgress
          : (title.toLowerCase().contains('complet')
              ? NotificationKind.completed
              : NotificationKind.booking),
      'offer' => NotificationKind.offer,
      'update' => NotificationKind.update,
      _ => NotificationKind.booking,
    };

    String timeAgo = 'Just now';
    if (createdAt != null) {
      if (createdAt is Map<String, dynamic>) {
        final seconds = (createdAt['_seconds'] as num?)?.toInt() ??
            (createdAt['seconds'] as num?)?.toInt();
        if (seconds != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes > 0 ? diff.inMinutes : 1} min ago';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours} hr ago';
          } else {
            timeAgo = '${diff.inDays} day ago';
          }
        }
      } else if (createdAt is String) {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) {
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes > 0 ? diff.inMinutes : 1} min ago';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours} hr ago';
          } else {
            timeAgo = '${diff.inDays} day ago';
          }
        }
      }
    }

    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      timeAgo: timeAgo,
      section: 'Today',
      type: type,
      bookingId: bookingId,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String timeAgo;
  final String section;
  final String type;
  final String? bookingId;
  final bool isRead;
  final dynamic createdAt;

  bool matches(NotificationFilter filter) {
    return switch (filter) {
      NotificationFilter.all => true,
      NotificationFilter.bookings =>
        type == 'booking' || kind == NotificationKind.booking || kind == NotificationKind.inProgress,
      NotificationFilter.offers => type == 'offer' || kind == NotificationKind.offer,
      NotificationFilter.updates =>
        type == 'update' || kind == NotificationKind.update || kind == NotificationKind.completed,
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationKind? kind,
    String? title,
    String? body,
    String? timeAgo,
    String? section,
    String? type,
    String? bookingId,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      section: section ?? this.section,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
