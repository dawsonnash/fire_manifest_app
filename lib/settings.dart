import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Stack(
        children: [
          Container(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover,
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
                        child: const Text('Quick Guide', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                      TextButton(
                        onPressed: () => null,
                        child: const Text('Submit feedback', style: TextStyle(color: Colors.white, fontSize: 20)),
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
                      TextButton(
                        onPressed: () => null,
                        child: const Text('Display', style: TextStyle(color: Colors.white, fontSize: 20)),
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
                            style: TextStyle(color: Colors.white, fontSize: 20),
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
