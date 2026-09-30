import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../customer/customer_shell.dart';
import 'money/money_screen.dart';
import 'onboarding/vendor_availability_screen.dart';
import 'onboarding/vendor_onboarding_screen.dart';
import 'today/today_screen.dart';
import 'walk_in/walk_in_screen.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});
  static const route = '/vendor';
  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = SessionScope.of(context);
      if (!session.ownerShopsLoaded && !session.loadingOwnerShops) {
        session.loadOwnerShops();
      }
    });
  }

  Future<void> _customer(AppSession session) async {
    try {
      await session.switchRole(UserRole.customer);
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(CustomerShell.route, (_) => false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to switch role. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final shop = session.selectedOwnerShop;
    final error = session.loadErrors['ownerShops'];
    if (!session.ownerShopsLoaded || error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your shop')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (session.loadingOwnerShops || error == null)
                  const CircularProgressIndicator(),
                if (error != null) ...[
                  Text(error),
                  TextButton(
                    onPressed: session.loadingOwnerShops
                        ? null
                        : session.loadOwnerShops,
                    child: const Text('Retry loading shop'),
                  ),
                ],
                TextButton(
                  onPressed: () => _customer(session),
                  child: const Text('Switch to customer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (shop == null) return const VendorOnboardingScreen();
    if (shop.status != 'active') {
      final title = switch (shop.status) {
        'pending_review' => 'Application under review',
        'rejected' => 'Changes requested',
        'suspended' => 'Shop suspended',
        _ => 'Shop unavailable',
      };
      final detail = switch (shop.status) {
        'pending_review' =>
          'Your application is saved. An admin must approve your shop before customers can find and book it. Check that your booking dates remain in the future.',
        'rejected' =>
          'Review the feedback below, correct your details and submit your shop again.',
        'suspended' =>
          'Bookings are unavailable while your shop is suspended. Contact the service team for help.',
        _ => 'Your shop cannot accept bookings at this time.',
      };
      return Scaffold(
        appBar: AppBar(title: const Text('Shop application')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.storefront_outlined, size: 64),
            const SizedBox(height: 20),
            Text(shop.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(detail),
            if (shop.reviewReason?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Review feedback: ${shop.reviewReason}'),
              ),
            const SizedBox(height: 20),
            if (shop.status == 'pending_review' || shop.status == 'rejected')
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VendorOnboardingScreen(shop: shop),
                  ),
                ),
                child: Text(
                  shop.status == 'rejected'
                      ? 'Edit and resubmit'
                      : 'Review or update application',
                ),
              ),
            if (shop.status == 'suspended')
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VendorAvailabilityScreen(shop: shop),
                  ),
                ),
                child: const Text('Manage booking dates'),
              ),
            OutlinedButton(
              onPressed: session.loadingOwnerShops
                  ? null
                  : session.loadOwnerShops,
              child: Text(
                session.loadingOwnerShops
                    ? 'Refreshing…'
                    : 'Refresh approval status',
              ),
            ),
            TextButton(
              onPressed: () => _customer(session),
              child: const Text('Switch to customer'),
            ),
          ],
        ),
      );
    }
    const pages = [TodayScreen(), WalkInScreen(), MoneyScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        actions: [
          IconButton(
            tooltip: 'Manage booking dates',
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VendorAvailabilityScreen(shop: shop),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh shop status',
            icon: const Icon(Icons.refresh),
            onPressed: session.loadingOwnerShops
                ? null
                : session.loadOwnerShops,
          ),
        ],
      ),
      body: pages[session.vendorTab],
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
