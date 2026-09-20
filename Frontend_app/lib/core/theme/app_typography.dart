import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppText {
  static TextStyle display({
    double size = 36,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.12,
    double letterSpacing = -0.6,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  static TextStyle ui({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.45,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }
}
