import 'package:flutter/material.dart';

class AppColors {
  // Primary brand teals (Header gradient, primary buttons, logo)
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color darkTeal = Color(0xFF115E59);
  static const Color tealDarkest = Color(0xFF0D5E56);
  static const Color mintAccent = Color(0xFF14B8A6);
  static const Color lightMint = Color(0xFFE6F4F1);
  static const Color mintTipBg = Color(0xFFE8F6F4);

  // Backgrounds & Surfaces (Light)
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusedBorder = Color(0xFF0F766E);

  // Typography (Light)
  static const Color textNavy = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Dark Mode Palette Tokens (Slate & Obsidian)
  static const Color darkScaffoldBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCardBg = Color(0xFF1E293B); // Slate 800
  static const Color darkCardBorder = Color(0xFF334155); // Slate 700
  static const Color darkSubSurface = Color(0xFF243247); // Slate 750
  static const Color darkInputBg = Color(0xFF0F172A); // Slate 900
  static const Color darkInputBorder = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextSubtle = Color(0xFF64748B); // Slate 500
  static const Color darkDivider = Color(0xFF334155);

  // Status & Accents
  static const Color successGreen = Color(0xFF10B981);
  static const Color whatsappGreen = Color(0xFF22C55E);
  static const Color whatsappDark = Color(0xFF16A34A);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Dashboard Overview Card Accents
  static const Color activeGreenBg = Color(0xFFDCFCE7);
  static const Color activeGreenIcon = Color(0xFF16A34A);
  static const Color todayPurpleBg = Color(0xFFF3E8FF);
  static const Color todayPurpleIcon = Color(0xFF9333EA);
  static const Color monthlyAmberBg = Color(0xFFFEF3C7);
  static const Color monthlyAmberIcon = Color(0xFFD97706);
  static const Color totalBlueBg = Color(0xFFE0F2FE);
  static const Color totalBlueIcon = Color(0xFF0284C7);

  // Dynamic Theme Adaptor Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? darkScaffoldBg : scaffoldBg;

  static Color card(BuildContext context) =>
      isDark(context) ? darkCardBg : cardWhite;

  static Color cardBorderColor(BuildContext context) =>
      isDark(context) ? darkCardBorder : cardBorder;

  static Color text(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textNavy;

  static Color textMutedColor(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color textSubtleColor(BuildContext context) =>
      isDark(context) ? darkTextSubtle : textSubtle;

  static Color subSurface(BuildContext context) =>
      isDark(context) ? darkSubSurface : const Color(0xFFF1F5F9);

  static Color inputBg(BuildContext context) =>
      isDark(context) ? darkInputBg : const Color(0xFFFBFDFF);

  static Color inputBorderColor(BuildContext context) =>
      isDark(context) ? darkInputBorder : inputBorder;

  static Color divider(BuildContext context) =>
      isDark(context) ? darkDivider : const Color(0xFFF1F5F9);

  // Live Status Hero Gradient (Image 11)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF0D9488), // Vibrant Teal
      Color(0xFF4338CA), // Deep Indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Top Screen Header Gradient (Images 1-4)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      Color(0xFF115E59),
      Color(0xFF0F766E),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // WhatsApp Community Gradient (Image 10)
  static const LinearGradient communityCardGradient = LinearGradient(
    colors: [
      Color(0xFF22C55E),
      Color(0xFF0D9488),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
