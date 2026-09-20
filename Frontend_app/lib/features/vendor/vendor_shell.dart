import 'package:flutter/material.dart';

import '../../core/services/app_session.dart';
import '../../core/widgets/app_bottom_nav.dart';
import 'money/money_screen.dart';
import 'today/today_screen.dart';
import 'walk_in/walk_in_screen.dart';

class VendorShell extends StatelessWidget {
  const VendorShell({super.key});

  static const route = '/vendor';

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    const pages = [
      TodayScreen(),
      WalkInScreen(),
      MoneyScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: session.vendorTab, children: pages),
      bottomNavigationBar: AppBottomNav(
        index: session.vendorTab,
        onChanged: session.setVendorTab,
        labels: const ['Today', 'Walk-in', 'Money'],
        icons: const [
          Icons.today_outlined,
          Icons.directions_walk_outlined,
          Icons.account_balance_wallet_outlined,
        ],
        activeIcons: const [
          Icons.today,
          Icons.directions_walk,
          Icons.account_balance_wallet,
        ],
      ),
    );
  }
}
