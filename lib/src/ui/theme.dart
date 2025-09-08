import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0E1013); // near-black (app background)
  static const surface = Color(0xFF171A20); // cards
  static const accent = Color.fromARGB(255, 73, 68, 88); // purple accent
  static const accent2 = Color.fromARGB(255, 73, 68, 88); // cyan accent
}

BoxDecoration glassCard([double radius = 24]) => BoxDecoration(
      color: AppColors.surface.withOpacity(0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.40),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 10),
        ),
      ],
    );

Widget neonDivider({Color? a, Color? b}) => Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          a ?? AppColors.accent,
          b ?? AppColors.accent2,
        ]),
      ),
    );
