import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme kuu - inafuata design ya mockup (rangi, radius, input style).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentYellow,
        brightness: Brightness.light,
      ),
      fontFamily: 'Arial',
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.white,
        color: AppColors.cardBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        // Bila hii, label (mfano "Jina la Kwanza") ilikuwa ikigongana na
        // thamani iliyojazwa tayari (mfano "Admin") - zote mbili
        // zikionekana sehemu moja. "always" inahakikisha label INAELEA
        // JUU KILA WAKATI, awe field ina thamani au la.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// Dark theme - inasimamia widgets za msingi za Flutter (Scaffold, Card,
  /// TextField, Buttons, AppBar/Sidebar text, n.k.) kupitia ThemeData.
  /// NB: baadhi ya custom widgets zinazotumia AppColors moja kwa moja
  /// (mfano background nyeupe iliyowekwa kwa nguvu kwenye baadhi ya
  /// dialogs/cards) huenda zisibadilike kikamilifu - hii ni msingi thabiti
  /// wa dark mode, siyo urekebishaji wa kila ukurasa/skrini.
  static ThemeData get dark {
    const darkBackground = Color(0xFF121412);
    const darkSurface = Color(0xFF1C1F1C);
    const darkBorder = Color(0xFF2E332E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentYellow,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      fontFamily: 'Arial',
      // Bila hii, baadhi ya maandishi yasiyo na rangi maalum (mfano
      // vichwa vya ListTile/SwitchListTile kwenye Mipangilio) yalikuwa
      // yanaonekana HAFIFU SANA (low-contrast gray) kwenye Dark Mode -
      // hii inahakikisha maandishi yote ya msingi ni meupe/mkali.
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: darkSurface,
        color: darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
      appBarTheme: const AppBarTheme(backgroundColor: darkSurface, foregroundColor: Colors.white, elevation: 0),
    );
  }
}
