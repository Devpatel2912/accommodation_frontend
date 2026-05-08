import 'package:flutter/material.dart';

class AppColors {
  // Primary & Core (New Modern Palette)
  static const teal = Color(0xFF567C8D);        // Main Brand Teal
  static const tealLight = Color(0xFFC8D9E6);   // Sky Blue (Secondary/Light)
  static const navy = Color(0xFF2F4156);        // Navy (Deep Accent)
  static const beige = Color(0xFFF5EFEB);       // Beige (Warm Neutral)
  
  static const tealDark = Color(0xFF3E5A68);    // Derived from Teal
  
  // Backgrounds
  static const bgGrey = Color(0xFFC8D9E6);      // Using Sky Blue as primary BG
  static const cardBg = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);
  
  // Accents
  static const accentBlue = Color(0xFF567C8D);  // Aligning with main palette
  static const accentPurple = Color(0xFF6B5B95);
  static const accentGold = Color(0xFFD4AF37);
  
  // Neutral / Border
  static const border = Color(0xFFD1D9E0);
  static const labelGrey = Color(0xFF708090);
  static const textLight = Color(0xFF567C8D);
  static const textDark = Color(0xFF2F4156);     // Using Navy for dark text
  static const hintGrey = Color(0xFFB0BCC9);
  static const footerGrey = Color(0xFFAAB4BF);
  
  // Status
  static const danger = Color(0xFFE57373);
  static const success = Color(0xFF81C784);
  static const warning = Color(0xFFFFB74D);
  
  // Specialized Status
  static const pendingBg = Color(0xFFFFE7D6);
  static const pendingBorder = Color(0xFFF8C7A6);
  static const pendingText = Color(0xFFA85B2D);
  
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
