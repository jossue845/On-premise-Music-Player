import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // 1. Scaffold
      scaffoldBackgroundColor: const Color.fromRGBO(69, 90, 100, 1),
      
      // 2. Primary colors
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
        ),
      ),
      
      // 3. Surfaces
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E), // Just a shade lighter than the background
        elevation: 8, // Gives a nice subtle shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.cyanAccent,
        textColor: Colors.white,
      ),
      
      // 4. Text
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.white, fontSize: 16), 
        bodyMedium: TextStyle(color: Colors.grey.shade400, fontSize: 14), 
        titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), 
        titleMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), 
        labelMedium: TextStyle(color: Colors.grey.shade500, fontSize: 12), 
      ),
      
      iconTheme: const IconThemeData(color: Colors.white),
      
      // 5. Navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.blueGrey.shade600, 
        selectedItemColor: Colors.grey.shade200, 
        unselectedItemColor: Colors.grey.shade200, 
      ),

      // 6. Player screen
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.cyanAccent,
        inactiveTrackColor: const Color(0xFF2A2A2A), // Very dark grey for the empty track
        thumbColor: Colors.cyanAccent,
        overlayColor: Colors.cyanAccent.withOpacity(0.2), // The glowing halo when dragged
        trackHeight: 4.0,
      ),

      // --- TEXT FIELD THEME ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E), // Dark card surface color
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: Colors.cyanAccent,
        suffixIconColor: Colors.grey.shade500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),

      // --- CHIP THEME ---
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1E1E), // Unselected dark surface
        selectedColor: Colors.cyanAccent, // Selected bright cyan
        showCheckmark: false,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),

      // --- ELEVATED BUTTON THEME ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black, // Text and icon color
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1E1E1E), // Your dark card surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),

      colorScheme: const ColorScheme.dark(
        primary: Colors.cyanAccent,
        error: Colors.redAccent, // The official color for destructive actions
        surfaceContainerHighest: Color(0xFF2A2A2A), // Perfect for image placeholders
      ),

    );
  }
}