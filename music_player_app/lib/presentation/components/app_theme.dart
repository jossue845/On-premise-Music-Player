import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // The main background
      scaffoldBackgroundColor: Colors.blueGrey.shade900,
      
      // Makes default interactive elements deep purple
      primaryColor: Colors.deepPurpleAccent, 
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // THIS FIXES THE CARDS: Makes them a sleek, slightly lighter dark grey
      cardTheme: CardThemeData(
        color: Colors.blueGrey.shade900,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      // THIS FIXES THE LIST TILES: Automatically styles the text and icons inside them
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.deepPurpleAccent,
        textColor: Colors.white,
      ),
      
      // THIS FIXES THE TEXT: Provides a hierarchy of white and light grey text
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.white), // Main strings
        bodyMedium: TextStyle(color: Colors.grey.shade300), // Standard secondary text
        titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Headers
        titleMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Subheaders
        labelMedium: TextStyle(color: Colors.grey.shade400), // Small numbers/labels
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.blueGrey.shade900, // Matches the Scaffold
        selectedItemColor: Colors.deepPurpleAccent, // The active tab color
        unselectedItemColor: Colors.grey.shade500, // The inactive tabs
      ),
      
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}