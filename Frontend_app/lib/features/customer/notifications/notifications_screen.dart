import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const route = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = SessionScope.of(context);
      session.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final items = session.notifications
        .where((n) => n.matches(_filter))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const AppBackCircle(),
                  Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: AppText.display(size: 22),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in NotificationFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(switch (filter) {
                            NotificationFilter.all => 'All',
                            NotificationFilter.bookings => 'Bookings',
                            NotificationFilter.offers => 'Offers',
                            NotificationFilter.updates => 'Updates',
                          }),
                          selected: filter == _filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.figtree(
                            color: filter == _filter
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFF1F4F8),
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Recent updates',
                    style: GoogleFonts.figtree(color: AppColors.muted),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => session.markAllNotificationsRead(),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        'Mark all read',
                        style: GoogleFonts.figtree(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (session.loadErrors['notifications'] != null) ...[
                Text(
                  session.loadErrors['notifications']!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                TextButton(
                  onPressed: () => session.loadNotifications(),
                  child: const Text('Retry'),
                ),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => session.loadNotifications(),
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  'No notifications here.',
                                  style: GoogleFonts.figtree(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return InkWell(
                              onTap: () =>
                                  session.markNotificationRead(item.id),
                              borderRadius: BorderRadius.circular(16),
                              child: _tile(item),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(AppNotification item) {
    final (icon, color) = switch (item.kind) {
      NotificationKind.completed => (Icons.check_circle, AppColors.open),
      NotificationKind.inProgress => (
        Icons.directions_car_filled,
        AppColors.warning,
      ),
      NotificationKind.booking => (Icons.event_available, AppColors.primary),
      NotificationKind.offer => (Icons.local_offer, AppColors.offer),
      NotificationKind.update => (Icons.info_outline, AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isRead
            ? const Color(0xFFF9FAFB)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? AppColors.border : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.figtree(
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: GoogleFonts.figtree(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.timeAgo,
            style: GoogleFonts.figtree(
              fontSize: 11,
              color: AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
