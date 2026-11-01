import 'package:flutter/material.dart';

const kViolet = Color(0xFF7C4DFF);
const kPink = Color(0xFFFF6FB5);
const kGold = Color(0xFFFFC94D);
const kOrange = Color(0xFFFF8A3D);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kViolet,
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF241A4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
