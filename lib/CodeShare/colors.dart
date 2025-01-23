import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dark Modes on left side
class AppColors {
  static Color get fireColor => Colors.deepOrangeAccent;
  static Color get primaryColor => isDarkMode ? Colors.deepOrangeAccent : Colors.black;
  static Color get appBarColor => isDarkMode ? Colors.grey[900]! : Colors.deepOrangeAccent;
  static Color get textFieldColor => isDarkMode ? Colors.grey[900]! : Colors.white;
  static Color get textFieldColor2 => isDarkMode ? Colors.grey[800]! : Colors.white;
  static Color get textColorPrimary => isDarkMode ? Colors.white : Colors.black;
  static Color get textColorSecondary => isDarkMode ? Colors.black : Colors.white;
  static Color get tabIconColor => isDarkMode ? Colors.grey[300]! :  Colors.grey[800]!;
  static Color get borderPrimary => isDarkMode ? Colors.grey[900]! : Colors.black;
  static Color get saveButtonAllowableWeight => isDarkMode ? Colors.deepOrangeAccent : Colors.blue;
  static Color get toolBlue => isDarkMode ? Colors.blue[200]! : Colors.blue[100]!;
  static Color get gearYellow => isDarkMode ? Colors.orange[200]! : Colors.orange[100]!;
  static Color get buttonStyle1 => Colors.green;
  static Color get cancelButton => isDarkMode ? Colors.white : Colors.grey;

  static bool isDarkMode = true; // This will be toggled based on SharedPreferences
}

class ThemePreferences {
  static const _key = 'isDarkMode';

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // Default to dark mode
  }

  static Future<void> setTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
