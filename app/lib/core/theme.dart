import 'package:flutter/material.dart';

const seedColor = Color(0xFF2E7D32);
const arabicFontFamily = 'NotoKufiArabic';

ThemeData buildTheme({Brightness brightness = Brightness.light}) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: brightness,
      fontFamily: arabicFontFamily,
    );
