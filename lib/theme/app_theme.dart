import 'package:flutter/material.dart';

ThemeData railTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF173348),
    primary: const Color(0xFF173348),
    secondary: const Color(0xFF916000),
    surface: const Color(0xFFF8F7F2),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F7F2),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8F7F2),
    foregroundColor: Color(0xFF173348),
    centerTitle: false,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 50)),
  ),
);
