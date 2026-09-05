import 'package:flutter/material.dart';

class PlayerSettings extends StatelessWidget {
  final Widget child;

  const PlayerSettings({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Base color exactly matches your new dark theme background
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        
        // The Dual-Shadow Neumorphic System
        boxShadow: const [
          // Bottom Right: The deep, dark shadow for elevation
          BoxShadow(
            color: Colors.black, // Pure black for the dark side
            offset: Offset(6, 6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          
          // Top Left: The subtle ambient light highlight
          BoxShadow(
            color: Color(0xFF262626), // A slightly lighter grey than the background
            offset: Offset(-6, -6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}