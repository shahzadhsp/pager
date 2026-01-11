import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  primaryColor: const Color(0xFF2563EB),
  cardColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF0F172A)),
    bodyMedium: TextStyle(color: Color(0xFF64748B)),
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF020617),
  cardColor: const Color(0xFF0F172A),
  primaryColor: const Color(0xFF3B82F6),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
    bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
  ),
);
