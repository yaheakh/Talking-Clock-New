import 'package:flutter/material.dart';

class AppPalette {
  final String id;
  final Color background;
  final Color accent;   // primary accent (seconds, "today", etc.)
  final Color accent2;  // secondary accent (minutes)
  final Color textMain;
  final Color textSub;
  final Color panelBg;
  final Color panelBorder;
  final bool aurora; // whether to show the animated aurora blobs

  const AppPalette({
    required this.id,
    required this.background,
    required this.accent,
    required this.accent2,
    required this.textMain,
    required this.textSub,
    required this.panelBg,
    required this.panelBorder,
    this.aurora = false,
  });
}

const Map<String, AppPalette> appPalettes = {
  'aurora': AppPalette(
    id: 'aurora',
    background: Color(0xFF0A0612),
    accent: Color(0xFFEC4899),
    accent2: Color(0xFF8B5CF6),
    textMain: Color(0xFFF2F2F7),
    textSub: Color(0xFF93A4C9),
    panelBg: Color(0x1AFFFFFF),
    panelBorder: Color(0x33FFFFFF),
    aurora: true,
  ),
  'cyan': AppPalette(
    id: 'cyan',
    background: Color(0xFF040B0D),
    accent: Color(0xFF0AAFE6),
    accent2: Color(0xFF37E0C4),
    textMain: Color(0xFFEAFBFF),
    textSub: Color(0xFF6FA9B8),
    panelBg: Color(0x1A0AAFE6),
    panelBorder: Color(0x330AAFE6),
  ),
  'amber': AppPalette(
    id: 'amber',
    background: Color(0xFF120C06),
    accent: Color(0xFFFFB74D),
    accent2: Color(0xFFFF7043),
    textMain: Color(0xFFFFF3E0),
    textSub: Color(0xFFBFA07A),
    panelBg: Color(0x1AFFB74D),
    panelBorder: Color(0x33FFB74D),
  ),
  'minimal': AppPalette(
    id: 'minimal',
    background: Color(0xFF000000),
    accent: Color(0xFFFFFFFF),
    accent2: Color(0xFFBFBFBF),
    textMain: Color(0xFFFFFFFF),
    textSub: Color(0xFF9A9A9A),
    panelBg: Color(0x14FFFFFF),
    panelBorder: Color(0x26FFFFFF),
  ),
};
