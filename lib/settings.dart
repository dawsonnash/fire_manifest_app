import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'CodeShare/colors.dart';


class SettingsView extends StatefulWidget {
  final bool isDarkMode;
  final bool enableBackgroundImage;
  final Function(bool) onThemeChanged;
  final Function(bool) onBackgroundImageChange;
  final String crewName;
  final Function(String) onCrewNameChanged;

  const SettingsView({super.key, required this.isDarkMode, required this.onThemeChanged, required this.enableBackgroundImage, required this.onBackgroundImageChange, required this.crewName, required this.onCrewNameChanged});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {
  late bool isDarkMode;
  late bool enableBackgroundImage;
  late TextEditingController crewNameController;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    enableBackgroundImage = widget.enableBackgroundImage;
    crewNameController = TextEditingController(text: widget.crewName); // Initialize with the current crew name

  }
  @override
  void dispose() {
    crewNameController.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor,
          title: Text(
            'Report Bugs',
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          content: TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Describe any bugs you've experienced here...",
              hintStyle: TextStyle(color: AppColors.textColorPrimary),
              filled: true,
              fillColor: AppColors.textFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textColorPrimary, width: 1),
              ),
            ),
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton),
              ),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  final String subject = Uri.encodeComponent('FIRE MANIFESTING APP: Bug Fixes');
                  final String body = Uri.encodeComponent(feedback);

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'dawsonak85@gmail.com', // Replace with your email address
                    query: 'subject=$subject&body=$body',
                  );

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      throw 'Could not launch $emailUri';
                    }
                  } catch (e) {
                    print('Error launching email: $e');
                  }
                }

                Navigator.of(context).pop(); // Close the dialog after submission
              },
              child: Text(
                'Send',
                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                ? Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.cover, // Cover the entire background
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Container(
                  color: AppColors.logoImageOverlay, // Semi-transparent overlay
                  width: double.infinity,
                  height: double.infinity,
                ),
              ],
            )
                : null) // No image if background is disabled
                : Stack(
                  children: [

                  ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Always display in light mode
                                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover the entire background
                  width: double.infinity,
                  height: double.infinity,
                                ),
                              ),
                    Container(
                      color: AppColors.logoImageOverlay, // Semi-transparent overlay
                      width: double.infinity,
                      height: double.infinity,
                    ),
      ],
                ),
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Padding(
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
                          onPressed: _sendFeedback,
                          child: const Text('Report Bugs', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                        // Display Dropdown
                        ExpansionTile(
                          title:  Text(
                            'Display',
                            style: TextStyle(fontSize: 18, color: Colors.white), // White text for the label
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white,       // Match the arrow color with the text color
                            size: 24,                  // Set a fixed size for consistency
                          ),
                          children: [
                            // Dark Mode Toggle
                            ListTile(
                              title: const Text(
                                'Dark Mode',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                              trailing: Switch(
                                value: isDarkMode,
                                onChanged: (value) {
                                  widget.onThemeChanged(value); // Notify parent widget
                                  setState(() {
                                    isDarkMode = value;
                                    if (!isDarkMode) {
                                      widget.onBackgroundImageChange(value); // Notify parent widget
                                      enableBackgroundImage = false;
                                      ThemePreferences.setBackgroundImagePreference(value);
                                    }
                                    ThemePreferences.setTheme(value); // Save dark mode preference
                                  });
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.white24,
                              ),
                            ),
                            // Enable Background Image Toggle (Visible only if Dark Mode is ON)
                            if (isDarkMode)
                              ListTile(
                                title: const Text(
                                  'Enable Background Image',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                trailing: Switch(
                                  value: enableBackgroundImage,
                                  onChanged: (value) {
                                    widget.onBackgroundImageChange(value); // Notify parent widget
                                    setState(() {
                                      enableBackgroundImage = value;
                                    });
                                    ThemePreferences.setBackgroundImagePreference(value); // Save preference
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.white24,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Crew Name
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crew Name Section

                        ExpansionTile(
                          title: Text('Crew Name', style: TextStyle(color: Colors.white, fontSize: 18),),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white,       // Match the arrow color with the text color
                            size: 24,                  // Set a fixed size for consistency
                          ),
                          children: [
                            ListTile(
                            title:  TextField(
                              controller: crewNameController, // Pre-fill with current crew name
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              maxLength: 30,
                              decoration: InputDecoration(

                                hintText: 'Enter Crew Name',
                                hintStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                focusedBorder:  UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.fireColor),
                                ),
                              ),
                              onSubmitted: (value) {
                                setState(() {
                                  if (value.trim().isNotEmpty) {
                                    widget.onCrewNameChanged(value.trim()); // Notify parent widget of the change
                                  }
                                });
                                // Call a callback or save preference
                                ThemePreferences.setCrewName(value.trim()); // Save crew name preference (optional)
                              },
                            ),
                          ),
            ],
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
                                    backgroundColor: AppColors.textFieldColor, // Dark grey background
                                    title: Text(
                                      'Terms and Conditions',
                                      style: TextStyle(color: AppColors.textColorPrimary),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'The calculations provided by this app are intended for informational purposes only. '
                                            'While every effort has been made to ensure accuracy, users must independently verify and validate '
                                            'all data before relying on it for operational or decision-making purposes. The developers assume no '
                                            'liability for errors, omissions, or any outcomes resulting from the use of this app. By continuing, '
                                            'you acknowledge and accept full responsibility for reviewing and confirming all calculations.',
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: 18),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text(
                                          'Close',
                                          style: TextStyle(color: AppColors.textColorPrimary),
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
          ),
        ],
      ),
    );
  }
}
