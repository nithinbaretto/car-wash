import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final filtered = session.bookings.where((booking) {
      if (_tab == 0) {
        return booking.status == BookingStatus.upcoming ||
            booking.status == BookingStatus.inProgress;
      }
      return booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.cancelled;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings',
              style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Your upcoming and past washes',
              style: GoogleFonts.montserrat(color: AppColors.muted),
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
                  _seg('Upcoming', 0),
                  _seg('Past', 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings here yet.',
                        style: GoogleFonts.montserrat(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _BookingCard(booking: filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
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
            style: GoogleFonts.montserrat(
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
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final color = switch (booking.status) {
      BookingStatus.upcoming => AppColors.primary,
      BookingStatus.inProgress => AppColors.warning,
      BookingStatus.completed => AppColors.open,
      BookingStatus.cancelled => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(booking.shopImageUrl, width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.shopName,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                ),
                Text(booking.service, style: GoogleFonts.montserrat(color: AppColors.muted, fontSize: 13)),
                Text(booking.whenLabel, style: GoogleFonts.montserrat(fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${booking.price}\$', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                booking.status.name,
                style: GoogleFonts.montserrat(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
