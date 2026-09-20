import 'package:flutter/material.dart';

import '../../core/services/app_session.dart';
import '../../core/widgets/app_bottom_nav.dart';
import 'bookings/bookings_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  static const route = '/customer';

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final pages = const [
      HomeScreen(),
      FavoritesScreen(),
      BookingsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: session.customerTab, children: pages),
      bottomNavigationBar: AppBottomNav(
        index: session.customerTab,
        onChanged: session.setCustomerTab,
      ),
    );
  }
}
