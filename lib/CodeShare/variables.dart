import 'dart:collection';
import 'dart:ui';

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
  static Color get tabIconColor => isDarkMode ? Colors.grey[300]! : Colors.grey[800]!;
  static Color get borderPrimary => isDarkMode ? Colors.grey[900]! : Colors.black;
  static Color get saveButtonAllowableWeight => isDarkMode ? Colors.deepOrangeAccent : Colors.blue;
  static Color get toolBlue => isDarkMode ? Colors.blue[200]! : Colors.blue[100]!;
  static Color get gearYellow => isDarkMode ? Colors.orange[200]! : Colors.orange[100]!;
  static Color get loadAccoutrementBlueGrey => isDarkMode ? Colors.blueGrey[200]! : Colors.blueGrey[200]!;

  static Color get quickGuideSection => enableBackgroundImage ? Colors.deepOrangeAccent : Colors.deepOrangeAccent;
  static Color get quickGuideSubsection => enableBackgroundImage ? Colors.grey : Colors.grey;

  static Color get buttonStyle1 => Colors.green;
  static Color get cancelButton => isDarkMode ? Colors.white : Colors.grey;
  static Color get logoImageOverlay => Colors.black.withValues(alpha: 0.6);
  static Color get settingsTabs => Colors.white.withValues(alpha: 0.1);
  static bool isDarkMode = true; // This will be toggled based on SharedPreferences
  static bool enableBackgroundImage = false; // Default to background image disabled
}

class AppData {
  // Crew & User Data
  static String crewName = '';
  static String userName = '';
  static int safetyBuffer = 0;


  // Standardized Spacing & Max Constraints to be phased out
  static double inputFieldMax = 450;
  static double termsNConditionsMax = 500;
  static double buttonMax = 200;
  static double savedTripsMax = 450;

  // Screen Size & Orientation
  static Size _screenSize = Size.zero;
  static EdgeInsets _safePadding = EdgeInsets.zero;

  static void updateScreenData(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _safePadding = MediaQuery.of(context).padding;
  }

  // **Device Properties**
  static double get screenWidth => _screenSize.width;
  static double get screenHeight => _screenSize.height;
  static double get safeHeight => screenHeight - _safePadding.top - _safePadding.bottom;
  static bool get isLandscape => _screenSize.aspectRatio > 1;

// **Dynamic AppBar & TabBar Heights**
  static double get appBarHeight => 56 * scalingFactorAppBar;
  static double get tabBarHeight {
    double minHeight = 56;
    double maxHeight = 90;
    double textPadding = tabBarTextSize * 0.6; // Extra space for text positioning
    double computedHeight = (tabBarTextSize + tabBarIconSize + textPadding + 18); // Added extra buffer

    return computedHeight.clamp(minHeight, maxHeight).ceilToDouble(); // Round up to prevent fractional pixel issues
  }


  // **Dynamic Scaling Factor Based on Screen Width and Height**
  static double get tabBarScalingFactor => (screenWidth / 400).clamp(1.0, 1.3);
  static double get scalingFactorAppBar => (screenWidth / 400).clamp(1.0, 1.3);
  static double get _scalingFactorPadding => (screenWidth / 400).clamp(0.9, 1.5);
  static double get _scalingFactorSizedBox => (screenWidth / 400).clamp(0.9, 2);
  static double get _heightScalingFactor => (screenHeight / 800).clamp(0.9, 1.5);
  static double get _textScalingFactor => (screenWidth / 400).clamp(0.95, 1.75); // Normalized to 400 dp width
  static double get _userScalingFactor => 1; // Normalized to 400 dp width
  static double get _textOrientationFactor => isLandscape ? 0.9 : 1.0;
  static double get checkboxScalingFactor => (screenWidth / 400).clamp(0.9, 1.2);

  // **Dynamic Widths (Orientation+ScreenSize-Dependent)**
  static double get inputFieldWidth => isLandscape ? (screenWidth * 0.50) : (double.infinity);
  static double get buttonWidth => isLandscape ? (screenWidth * 0.2) : (screenWidth * 0.4);
  static double get termsAndConditionsWidth => isLandscape ? (screenWidth * 0.35) : (screenWidth * 1);
  static double get selectionDialogWidth => isLandscape ? (screenWidth * 0.5) : (screenWidth * 0.8);
  static double get miniSelectionDialogWidth => isLandscape ? (screenWidth * 0.4) : (screenWidth * 0.7);
  static double get quickGuideImageWidth => isLandscape ? screenWidth * 0.3 : screenWidth * 0.9;

  // **Dynamic Heights Based on Screen Height**
  static double get buttonHeight => isLandscape ? (screenHeight * 0.12) : (screenHeight * 0.1);
  static double get miniSelectionDialogHeight => isLandscape ? (screenHeight * 0.32) : (screenHeight * 0.2);
  static double get quickGuideContentHeight => 45 + quickGuideContentTextSize;

  // **Dynamic Spacing

  static double sizedBox10 = 10.0 * _scalingFactorSizedBox;
  static double spacingStandard = 12.0 * _scalingFactorSizedBox;
  static double sizedBox16 = 16.0 * _scalingFactorSizedBox;
  static double sizedBox18 = 18.0 * _scalingFactorSizedBox;
  static double sizedBox20 = 20.0 * _scalingFactorSizedBox;
  static double sizedBox22 = 22.0 * _scalingFactorSizedBox;

  // **Dynamic Padding Templates**
  static double get padding32 => 32.0 * _scalingFactorPadding;
  static double get padding20 => 20.0 * _scalingFactorPadding;
  static double get padding16 => 16.0 * _scalingFactorPadding;
  static double get padding12 => 12.0 * _scalingFactorPadding;
  static double get padding10 => 10.0 * _scalingFactorPadding;
  static double get padding8 => 8.0 * _scalingFactorPadding;
  static double get padding5 => 5.0 * _scalingFactorPadding;
  static double get bottomModalPadding => 16.0 * _scalingFactorPadding;


  // **Predefined Scaled Text Sizes**
  static double get text10 => 10 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text12 => 12 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text14 => 14 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text16 => 16 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text18 => 18 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text20 => 20 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text22 => 22 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text24 => 24 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text28 => 28 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text30 => 30 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text32 => 32 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text36 => 36 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get text48 => 48 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get tabBarTextSize => 14 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get tabBarIconSize => 24 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get bottomDialogTextSize => 14 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get dropDownArrowSize => 14 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get cupertinoPickerItemSize => 24 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get miniDialogTitleTextSize => 22 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get miniDialogBodyTextSize => 18 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get quickGuideContentTextSize => 16 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;
  static double get modalTextSize => 14 * _textScalingFactor * _textOrientationFactor * _userScalingFactor;

}

class ThemePreferences {
  static const _key = 'isDarkMode';
  static const _backgroundImageKey = 'enableBackgroundImage';
  static const _crewNameKey = 'crewName';
  static const _userNameKey = 'userName';
  static const _safetyBufferKey = 'safetyBuffer';

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
    return prefs.getString(_crewNameKey) ?? 'Crew Name Here';
  }

  static Future<void> setCrewName(String crewName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_crewNameKey, crewName);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  static Future<void> setUserName(String userName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
  }

  static Future<int> getSafetyBuffer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_safetyBufferKey) ?? 0;
  }

  static Future<void> setSafetyBuffer(int safetyBuffer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_safetyBufferKey, safetyBuffer);
  }
}

// Outlines a text using shadows.
List<Shadow> outlinedText({double strokeWidth = 1, Color strokeColor = Colors.black, int precision = 5}) {
  Set<Shadow> result = HashSet();
  for (int x = 1; x < strokeWidth + precision; x++) {
    for (int y = 1; y < strokeWidth + precision; y++) {
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

// Function for hiding background color on drag and drop widgets
Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double animValue = Curves.easeInOut.transform(animation.value);
      final double elevation = lerpDouble(0, 6, animValue)!;
      return Material(
        elevation: elevation,
        color: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        child: child,
      );
    },
    child: child,
  );
}
