import 'package:flutter/material.dart';

class AppColors {
  // AppBar color example
  static Color appBarColor({required bool isDark}) {
    return isDark ? Colors.blue : Colors.yellow;
  }

  // Primary color
  static Color primary({required bool isDark}) {
    return isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  }

  // Background
  static Color background({required bool isDark}) {
    return isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
  }

  // Card color
  static Color card({required bool isDark}) {
    return isDark ? const Color(0xFF0F172A) : Colors.white;
  }

  // Text colors
  static Color textPrimary({required bool isDark}) {
    return isDark ? const Color(0xFFE5E7EB) : const Color(0xFF0F172A);
  }
}
