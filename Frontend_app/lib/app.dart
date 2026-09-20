import 'package:flutter/material.dart';

import 'core/models/shop.dart';
import 'core/services/app_session.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/role_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/customer/customer_shell.dart';
import 'features/customer/notifications/notifications_screen.dart';
import 'features/customer/shop_detail/shop_detail_screen.dart';
import 'features/vendor/onboarding/vendor_onboarding_screen.dart';
import 'features/vendor/vendor_shell.dart';

class CarWashApp extends StatefulWidget {
  const CarWashApp({super.key});

  @override
  State<CarWashApp> createState() => _CarWashAppState();
}

class _CarWashAppState extends State<CarWashApp> {
  final AppSession _session = AppSession();

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MaterialApp(
        title: 'Car Wash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          OnboardingScreen.route: (_) => const OnboardingScreen(),
          RoleScreen.route: (_) => const RoleScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          OtpScreen.route: (_) => const OtpScreen(),
          CustomerShell.route: (_) => const CustomerShell(),
          NotificationsScreen.route: (_) => const NotificationsScreen(),
          VendorOnboardingScreen.route: (_) => const VendorOnboardingScreen(),
          VendorShell.route: (_) => const VendorShell(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == ShopDetailScreen.route &&
              settings.arguments is Shop) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) =>
                  ShopDetailScreen(shop: settings.arguments! as Shop),
            );
          }
          return null;
        },
      ),
    );
  }
}
