import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.labels = const ['Home', 'Favourites', 'Bookings', 'Profile'],
    this.icons = const [
      Icons.home_rounded,
      Icons.favorite_border,
      Icons.calendar_today_outlined,
      Icons.person_outline,
    ],
    this.activeIcons = const [
      Icons.home_rounded,
      Icons.favorite,
      Icons.calendar_month,
      Icons.person,
    ],
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          final color = selected ? AppColors.primary : AppColors.mutedLight;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? activeIcons[i] : icons[i], color: color),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
