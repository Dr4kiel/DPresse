import 'package:flutter/material.dart';

/// DPresse brand color palette.
///
/// Built around a dark ink blue evoking traditional print/press,
/// paired with warm paper tones and functional accent colors.
class AppColors {
  AppColors._();

  // ── Primary: Ink Blue ──────────────────────────────────────────
  static const Color inkBlue = Color(0xFF0D1B3E);
  static const Color inkBlueDark = Color(0xFF081228);
  static const Color inkBlueLight = Color(0xFF1A2F5B);

  // ── Secondary: Warm Paper ──────────────────────────────────────
  static const Color paper = Color(0xFFF5F0E8);
  static const Color paperDark = Color(0xFFE8DFD2);
  static const Color paperLight = Color(0xFFFAF8F4);

  // ── Accent: Editorial Blue ─────────────────────────────────────
  static const Color accent = Color(0xFF2A5FCF);
  static const Color accentLight = Color(0xFF5B8AE5);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC62828);

  // ── Neutrals ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textTertiary = Color(0xFF8A7E6D);
  static const Color divider = Color(0xFFD5CBB8);
  static const Color surfaceLight = Color(0xFFF8F6F2);
  static const Color surfaceDark = Color(0xFF121212);
}
