import 'package:flutter/material.dart';

class AppColors {
  // Primary & Core (New Modern Palette)
  static const teal = Color(0xFF0C4C51);        // Main Brand Teal
  static const tealLight = Color(0xFFE2EFF0);   // Teal Light (Secondary)
  static const navy = Color(0xFF2F4156);        // Navy (Deep Accent)
  static const beige = Color(0xFFF1ECE4);       // Beige (Warm Neutral)
  
  static const tealDark = Color(0xFF0A3B3F);    // Derived from Teal
  
  // Backgrounds
  static const bgGrey = Color(0xFFF1ECE4);      // Warm beige background
  static const cardBg = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);
  
  // Accents
  static const accentBlue = Color(0xFF0C4C51);  // Aligning with main palette
  static const accentPurple = Color(0xFF6B5B95);
  static const accentGold = Color(0xFFD4AF37);
  
  // Neutral / Border
  static const border = Color(0xFFE5E5E5);
  static const labelGrey = Color(0xFFAAB4BF);
  static const textLight = Color(0xFF0C4C51);
  static const textDark = Color(0xFF0C4C51);     // Dark text uses the primary dark green
  static const hintGrey = Color(0xFFB0BCC9);
  static const footerGrey = Color(0xFFAAB4BF);
  
  // Status
  static const danger = Color(0xFFF05D51);
  static const success = Color(0xFF81C784);
  static const warning = Color(0xFFFFB74D);
  
  // Specialized Status
  static const pendingBg = Color(0xFFFBEAEA);
  static const pendingBorder = Color(0xFFFBEAEA);
  static const pendingText = Color(0xFFF05D51);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [teal, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [teal, tealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
