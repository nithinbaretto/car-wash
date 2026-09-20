import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
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
  Widget build(BuildContext context) {
    final items = MockData.notifications.where((n) => n.matches(_filter)).toList();

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
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: NotificationFilter.values.map((filter) {
                    final selected = filter == _filter;
                    final label = switch (filter) {
                      NotificationFilter.all => 'All',
                      NotificationFilter.bookings => 'Bookings',
                      NotificationFilter.offers => 'Offers',
                      NotificationFilter.updates => 'Updates',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.montserrat(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: const Color(0xFFF1F4F8),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Today', style: GoogleFonts.montserrat(color: AppColors.muted)),
                  const Spacer(),
                  Text(
                    'Mark all read',
                    style: GoogleFonts.montserrat(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _tile(items[index]),
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
      NotificationKind.inProgress => (Icons.directions_car_filled, AppColors.warning),
      NotificationKind.booking => (Icons.event_available, AppColors.primary),
      NotificationKind.offer => (Icons.local_offer, AppColors.offer),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
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
                Text(item.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                Text(item.body, style: GoogleFonts.montserrat(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Text(item.timeAgo, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.mutedLight)),
              const Icon(Icons.chevron_right, color: AppColors.mutedLight),
            ],
          ),
        ],
      ),
    );
  }
}
