import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/widgets/brand_mark.dart';
import '../customer/customer_shell.dart';
import '../vendor/vendor_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';
  static const loadDuration = Duration(milliseconds: 2500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  AppSession? _session;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (_session != session) {
      _session?.removeListener(_navigateWhenReady);
      _session = session;
      session.addListener(_navigateWhenReady);
    }
  }

  void _navigateWhenReady() {
    final session = _session;
    if (!mounted ||
        _navigated ||
        !_loader.isCompleted ||
        session == null ||
        !session.isInitialized) {
      return;
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextRoute = !session.loggedIn
          ? OnboardingScreen.route
          : session.role == UserRole.vendor
          ? VendorShell.route
          : CustomerShell.route;
      Navigator.of(context).pushReplacementNamed(nextRoute);
    });
  }

  @override
  void initState() {
    super.initState();
    _loader =
        AnimationController(vsync: this, duration: SplashScreen.loadDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _navigateWhenReady();
          });
    _loader.forward();
  }

  @override
  void dispose() {
    _session?.removeListener(_navigateWhenReady);
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.splashBackground,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.3',
                    style: GoogleFonts.figtree(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const SplashWordmark(),
                  const SizedBox(height: 10),
                  Text(
                    'A clean wash\nfor a smooth drive',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _loader,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _loader.value,
                          minHeight: 3,
                          color: Colors.white,
                          backgroundColor: const Color(0x66FFFFFF),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading your cleaner tomorrow...',
                    style: GoogleFonts.figtree(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
