import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../customer/profile/profile_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = SessionScope.of(context);
      session.loadOwnerShops();
    });
  }

  Future<void> _refresh() async {
    final session = SessionScope.of(context);
    final shopId = session.selectedOwnerShop?.id;
    if (shopId != null) {
      await session.loadOwnerTodayBookings(shopId, _today);
    } else {
      await session.loadOwnerShops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final bookings = session.ownerTodayBookings;
    final shop = session.selectedOwnerShop;

    final inQueue = bookings
        .where(
          (b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.accepted,
        )
        .length;
    final inBay = bookings
        .where((b) => b.status == BookingStatus.inProgress)
        .length;
    final done = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Bay Board', style: AppText.display(size: 26)),
                      Text(
                        shop?.name ?? 'Today · $_today',
                        style: GoogleFonts.figtree(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('In Queue', '$inQueue'),
                const SizedBox(width: 10),
                _stat('In Bay', '$inBay'),
                const SizedBox(width: 10),
                _stat('Done', '$done'),
              ],
            ),
            const SizedBox(height: 20),
            if (session.loadErrors['owner'] != null) ...[
              Text(
                session.loadErrors['owner']!,
                style: const TextStyle(color: Colors.redAccent),
              ),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ],
            if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: AppColors.mutedLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No bookings scheduled for today.',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pull down to refresh customer bookings.',
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...bookings.map((booking) => _buildBookingCard(booking, session)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, AppSession session) {
    final customerName = booking.customerName?.isNotEmpty == true
        ? booking.customerName!
        : 'Customer';
    final initial = customerName.characters.first.toUpperCase();

    final statusColor = switch (booking.status) {
      BookingStatus.pending => Colors.orange.shade800,
      BookingStatus.accepted || BookingStatus.upcoming => AppColors.primary,
      BookingStatus.inProgress => Colors.purple.shade700,
      BookingStatus.completed => AppColors.open,
      BookingStatus.cancelled || BookingStatus.rejected => AppColors.muted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initial,
                  style: GoogleFonts.figtree(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.figtree(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${booking.service} · ${booking.displayPrice}',
                      style: GoogleFonts.figtree(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (booking.vehicleRegistration != null)
                      Text(
                        booking.vehicleRegistration!,
                        style: GoogleFonts.figtree(fontSize: 12),
                      ),
                    if (booking.customerPhone != null)
                      Text(
                        booking.customerPhone!,
                        style: GoogleFonts.figtree(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking.startAt.isNotEmpty
                        ? booking.startAt
                        : booking.whenLabel,
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.status.label,
                      style: GoogleFonts.figtree(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (booking.status == BookingStatus.pending) ...[
                OutlinedButton(
                  onPressed: () =>
                      _updateStatus(session, booking.id, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _updateStatus(session, booking.id, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Accept'),
                ),
              ] else if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.upcoming) ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      _updateStatus(session, booking.id, 'in_progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Start Wash (In Bay)'),
                ),
              ] else if (booking.status == BookingStatus.inProgress) ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      _updateStatus(session, booking.id, 'completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.open,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark Completed'),
                ),
              ] else ...[
                Text(
                  booking.status.label,
                  style: GoogleFonts.figtree(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    AppSession session,
    String bookingId,
    String status,
  ) async {
    try {
      await session.updateBookingStatus(bookingId, status);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.figtree(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
