import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0E1013);        // near-black
  static const surface = Color(0xFF171A20);   // cards
  static const accent = Color(0xFF7C4DFF);    // purple accent
  static const accent2 = Color(0xFF00E5FF);   // cyan accent
}

BoxDecoration glassCard([double radius = 24]) => BoxDecoration(
  color: AppColors.surface.withOpacity(0.85),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withOpacity(0.06)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    ),
  ],
);

Widget neonDivider() => Container(
  height: 2,
  decoration: const BoxDecoration(
    gradient: LinearGradient(colors: [
      AppColors.accent,
      AppColors.accent2,
    ]),
  ),
);
