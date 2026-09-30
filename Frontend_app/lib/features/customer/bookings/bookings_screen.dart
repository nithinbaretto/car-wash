import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_mark.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = SessionScope.of(context);
      session.loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final upcomingList = session.bookings
        .where((b) => b.status.isOngoing)
        .toList();
    final pastList = session.pastBookings.isNotEmpty
        ? session.pastBookings
        : session.bookings.where((b) => b.status.isPast).toList();

    final filtered = _tab == 0 ? upcomingList : pastList;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bookings', style: AppText.display()),
            const SizedBox(height: 4),
            Text(
              'Your upcoming and past washes',
              style: GoogleFonts.figtree(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _seg('Upcoming (${upcomingList.length})', 0),
                  _seg('Past (${pastList.length})', 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (session.loadErrors['bookings'] != null) ...[
              Text(
                session.loadErrors['bookings']!,
                style: const TextStyle(color: Colors.redAccent),
              ),
              TextButton(
                onPressed: () => session.loadBookings(),
                child: const Text('Retry'),
              ),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => session.loadBookings(),
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text(
                                _tab == 0
                                    ? 'No upcoming bookings.\nExplore nearby shops to book a wash.'
                                    : 'No past booking history yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.figtree(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _BookingCard(
                          booking: filtered[index],
                          onCancel: () =>
                              _confirmCancel(context, session, filtered[index]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    AppSession session,
    Booking booking,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure you want to cancel your booking at ${booking.shopName}? The reserved time slot will be released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await session.cancelBooking(booking.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _seg(String label, int value) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.onCancel});

  final Booking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final color = switch (booking.status) {
      BookingStatus.pending => Colors.orange.shade800,
      BookingStatus.accepted || BookingStatus.upcoming => AppColors.primary,
      BookingStatus.inProgress => Colors.purple.shade700,
      BookingStatus.completed => AppColors.open,
      BookingStatus.cancelled || BookingStatus.rejected => AppColors.muted,
    };

    final bgBadgeColor = color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppAssets.carWashCard,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.shopName,
                      style: GoogleFonts.figtree(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.service,
                      style: GoogleFonts.figtree(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.whenLabel,
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking.displayPrice,
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgBadgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.label,
                      style: GoogleFonts.figtree(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (booking.canCancel) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
