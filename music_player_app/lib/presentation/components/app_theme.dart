import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // Global Font
      fontFamily: 'Roboto',
      
      // Scaffold
      scaffoldBackgroundColor: Colors.black,
      
      // Primary colors
      primaryColor: Colors.cyanAccent, 
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 22, 
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontFamily: 'Roboto',
        ),
      ),
      

      cardTheme: CardThemeData(
        color: const Color(0xFF16213E), // Dark blue widget background
        elevation: 8, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.cyanAccent,
        textColor: Colors.white,
      ),
      
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16), 
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14), 
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), 
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), 
        labelMedium: TextStyle(color: Colors.white60, fontSize: 12), 
      ),
      
      iconTheme: const IconThemeData(color: Colors.white),
      
      // Navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, 
        selectedItemColor: Colors.cyanAccent, 
        unselectedItemColor: Colors.white70, 
      ),

      // Player screen
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.cyanAccent,
        inactiveTrackColor: const Color(0xFF1F2E54), // Lighter dark blue for empty track
        thumbColor: Colors.cyanAccent,
        overlayColor: Colors.cyanAccent.withOpacity(0.2),
        trackHeight: 4.0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16213E), // Dark blue surface
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIconColor: Colors.cyanAccent,
        suffixIconColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF16213E), // Dark blue surface
        selectedColor: Colors.cyanAccent, 
        showCheckmark: false,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black, 
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF16213E), // Dark blue surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),

      colorScheme: const ColorScheme.dark(
        primary: Colors.cyanAccent,
        surface: Color(0xFF16213E), // Dark blue
        error: Colors.redAccent, 
        surfaceContainerHighest: Color(0xFF1F2E54), // Image placeholders
      ),
    );
  }
}