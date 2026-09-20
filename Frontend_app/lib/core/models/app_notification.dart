enum NotificationKind { completed, inProgress, booking, offer }

enum NotificationFilter { all, bookings, offers, updates }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.section,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String timeAgo;
  final String section;

  bool matches(NotificationFilter filter) {
    return switch (filter) {
      NotificationFilter.all => true,
      NotificationFilter.bookings =>
        kind == NotificationKind.booking || kind == NotificationKind.inProgress,
      NotificationFilter.offers => kind == NotificationKind.offer,
      NotificationFilter.updates => kind == NotificationKind.completed,
    };
  }
}
