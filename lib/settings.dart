import 'dart:ui';
import 'package:flutter/material.dart';
import 'CodeShare/colors.dart';


class SettingsView extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsView({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black.withValues(alpha: 0.90) : Colors.transparent, // Black background in dark mode
            child: AppColors.isDarkMode
                ? null // No child if dark mode is enabled
                : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover, // Cover the entire background
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                // Help Section
                ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.white),
                  title: const Text(
                    'HELP',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () => null,
                        child: const Text('Quick Guide', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      TextButton(
                        onPressed: () => null,
                        child: const Text('Submit feedback', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white),
                // Settings Section
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: const Text(
                    'SETTINGS',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(fontSize: 18, color: Colors.white), // White text for the label
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Ensure the row takes only as much space as needed
                          children: [
                            Text(
                              isDarkMode ? 'ON' : 'OFF', // Display ON or OFF
                              style: const TextStyle(fontSize: 16, color: Colors.white), // White text for ON/OFF
                            ),
                            const SizedBox(width: 8), // Add some space between text and switch
                            Switch(
                              value: isDarkMode,
                              onChanged: (value) {
                                widget.onThemeChanged(value); // Notify parent widget
                                setState(() {
                                  isDarkMode = value;
                                });
                              },
                              activeColor: Colors.green, // Green when ON
                              inactiveThumbColor: Colors.grey, // Grey thumb when OFF
                              inactiveTrackColor: Colors.white24, // Lighter grey for the track
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
                Divider(color: Colors.white),
                // Legal Section
                ListTile(
                  leading: Icon(Icons.gavel, color: Colors.white),
                  title: const Text(
                    'LEGAL',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white, // Dark grey background
                                  title: const Text(
                                    'Terms and Conditions',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  content: SingleChildScrollView(
                                    child: const Text(
                                      'The calculations provided by this app are intended for informational purposes only. '
                                          'While every effort has been made to ensure accuracy, users must independently verify and validate '
                                          'all data before relying on it for operational or decision-making purposes. The developers assume no '
                                          'liability for errors, omissions, or any outcomes resulting from the use of this app. By continuing, '
                                          'you acknowledge and accept full responsibility for reviewing and confirming all calculations.',
                                      style: TextStyle(color: Colors.black, fontSize: 18),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(color: Colors.deepOrangeAccent),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Terms and Conditions',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
