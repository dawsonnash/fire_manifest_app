import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dark Modes on left side
class AppColors {
  static Color get fireColor => Colors.deepOrangeAccent;
  static Color get primaryColor => isDarkMode ? Colors.deepOrangeAccent : Colors.black;
  static Color get appBarColor => isDarkMode ? Colors.grey[900]! : Colors.deepOrangeAccent;
  static Color get panelColor => isDarkMode ? Colors.grey[900]!.withValues(alpha: 0.9) : Colors.deepOrangeAccent;
  static Color get textFieldColor => isDarkMode ? Colors.grey[900]!.withValues(alpha: 0.9) : Colors.white;
  static Color get textFieldColor2 => isDarkMode ? Colors.grey[900]! : Colors.white;
  static Color get textColorPrimary => isDarkMode ? Colors.white : Colors.black;
  static Color get textColorPrimary2 => isDarkMode ? Colors.white : Colors.grey;
  static Color get textColorSecondary => isDarkMode ? Colors.black : Colors.white;
  static Color get textColorEditToolDetails => isDarkMode ? Colors.white : Colors.blue;
  static Color get tabIconColor => isDarkMode ? Colors.grey[300]! :  Colors.grey[800]!;
  static Color get borderPrimary => isDarkMode ? Colors.grey[900]! : Colors.black;
  static Color get saveButtonAllowableWeight => isDarkMode ? Colors.deepOrangeAccent : Colors.blue;
  static Color get toolBlue => isDarkMode ? Colors.blue[200]! : Colors.blue[100]!;
  static Color get gearYellow => isDarkMode ? Colors.orange[200]! : Colors.orange[100]!;
  static Color get buttonStyle1 => Colors.green;
  static Color get cancelButton => isDarkMode ? Colors.white : Colors.grey;
  static Color get logoImageOverlay => Colors.black.withValues(alpha: 0.6);
  static Color get settingsTabs => Colors.white.withValues(alpha: 0.1);


  static bool isDarkMode = true; // This will be toggled based on SharedPreferences
  static bool enableBackgroundImage = false; // Default to background image disabled
}

class AppData {
  static String crewName = 'Crew Name';
  static double spacingStandard = 12.0;
}


class ThemePreferences {
  static const _key = 'isDarkMode';
  static const _backgroundImageKey = 'enableBackgroundImage';
  static const _crewNameKey = '';

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // Default to dark mode
  }

  static Future<void> setTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<bool> getBackgroundImagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundImageKey) ?? false; // Default to disabled
  }

  static Future<void> setBackgroundImagePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundImageKey, value);
  }

  static Future<String> getCrewName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_crewNameKey) ?? '';
  }

  static Future<void> setCrewName(String crewName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_crewNameKey, crewName);
  }


}

// Outlines a text using shadows.
List<Shadow> outlinedText({double strokeWidth = 1, Color strokeColor = Colors.black, int precision = 5}) {
  Set<Shadow> result = HashSet();
  for (int x = 1; x < strokeWidth + precision; x++) {
    for(int y = 1; y < strokeWidth + precision; y++) {
      double offsetX = x.toDouble();
      double offsetY = y.toDouble();
      result.add(Shadow(offset: Offset(-strokeWidth / offsetX, -strokeWidth / offsetY), color: strokeColor));
      result.add(Shadow(offset: Offset(-strokeWidth / offsetX, strokeWidth / offsetY), color: strokeColor));
      result.add(Shadow(offset: Offset(strokeWidth / offsetX, -strokeWidth / offsetY), color: strokeColor));
      result.add(Shadow(offset: Offset(strokeWidth / offsetX, strokeWidth / offsetY), color: strokeColor));
    }
  }
  return result.toList();
}
