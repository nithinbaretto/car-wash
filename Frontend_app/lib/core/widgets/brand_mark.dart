import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppAssets {
  static const logo = 'assets/logo.png';
  static const splashBackground = 'assets/images/splash_bg.png';
  static const onboardingStep1 = 'assets/images/step_1.png';
  static const onboardingStep2 = 'assets/images/step_2.png';
  static const benefitVerified = 'assets/images/verified.png';
  static const benefitClock = 'assets/images/clock.png';
  static const benefitFav = 'assets/images/fav.png';
  static const benefitStar = 'assets/images/star.png';
  static const iconCar = 'assets/icons/car.png';
  static const iconShop = 'assets/icons/shop.png';
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandMark(size: 108),
        const SizedBox(height: 18),
        Text(
          'Car wash',
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
