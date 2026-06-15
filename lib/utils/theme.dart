import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF66BB6A);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color takenColor = Color(0xFF4CAF50);
  static const Color missedColor = Color(0xFFEF5350);
  static const Color pendingColor = Color(0xFFFFA726);
  static const Color skippedColor = Color(0xFF9E9E9E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'taken':
        return takenColor;
      case 'missed':
        return missedColor;
      case 'pending':
        return pendingColor;
      case 'skipped':
        return skippedColor;
      default:
        return textSecondary;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'taken':
        return '已服用';
      case 'missed':
        return '已漏服';
      case 'pending':
        return '待服用';
      case 'skipped':
        return '已跳过';
      default:
        return '未知';
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      case 'skipped':
        return Icons.skip_next;
      default:
        return Icons.help_outline;
    }
  }

  // Predefined medication colors
  static const List<Color> medicationColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFFF5722), // Deep Orange
  ];

  // Predefined medication icons
  static const List<IconData> medicationIcons = [
    Icons.medication,
    Icons.local_pharmacy,
    Icons.healing,
    Icons.vaccines,
    Icons.science,
    Icons.medical_services,
    Icons.favorite,
    Icons.star,
    Icons.brightness_1, // pill shape
    Icons.circle,
  ];
}
