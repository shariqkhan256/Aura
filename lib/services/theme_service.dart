import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeService with ChangeNotifier {
  // --- CORE PALETTE ---
  // Premium Gray (Slate-based for depth)
  static const Color slate950 = Color(0xFF0F172A); // Background
  static const Color slate800 = Color(0xFF1E293B); // Surface
  static const Color slate700 = Color(0xFF334155); // Borders/Dividers
  static const Color slate400 = Color(0xFF94A3B8); // Secondary Text
  
  // Premium Accents
  static const Color accentOrange = Color(0xFFF97316); // Dark mode accent
  static const Color softSkyBlue = Color(0xFF38BDF8); // Light mode accent (Sky 400)
  static const Color softSkyBlueLight = Color(0xFFE0F2FE); // Very soft background for "glass" look

  bool _isDarkMode = true; // Default to Dark for that "Premium AI" look
  bool get isDarkMode => _isDarkMode;

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: slate950,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate-50 look
      colorScheme: const ColorScheme.light(
        primary: slate950,
        secondary: softSkyBlue,
        surface: Colors.white,
        onSurface: slate950,
        onPrimary: Colors.white,
        secondaryContainer: softSkyBlueLight,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: slate950),
        titleTextStyle: TextStyle(
          color: slate950,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardColor: Colors.white,
      dividerColor: slate700.withValues(alpha: 0.1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: softSkyBlue, width: 2),
        ),
        hintStyle: TextStyle(color: slate950.withValues(alpha: 0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softSkyBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          elevation: 2,
          shadowColor: softSkyBlue.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: slate950),
        bodyMedium: TextStyle(color: slate950),
        titleLarge: TextStyle(color: slate950, fontWeight: FontWeight.bold),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory, // Smoother touch feedback
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(), // Modern Android transition
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: slate950,
      scaffoldBackgroundColor: slate950,
      colorScheme: const ColorScheme.dark(
        primary: slate950,
        secondary: accentOrange,
        surface: slate800,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardColor: slate800,
      dividerColor: slate700,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B), // Slate 800
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentOrange, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          elevation: 8,
          shadowColor: accentOrange.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
       textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCBD5E1)), // Slate 300
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory, // Smoother touch feedback
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(), // Modern Android transition
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}


