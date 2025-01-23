import 'dart:ui';

import 'package:fire_app/05_create_new_manifest.dart';
import 'package:fire_app/06_saved_trips.dart';
import 'package:fire_app/settings.dart';
import 'package:flutter/material.dart';
import '../01_edit_crew.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Data/gear.dart';
import '../Data/crewmember.dart';
import 'Data/crew.dart';
import 'Data/customItem.dart';
import 'Data/load.dart';
import 'Data/trip.dart';
import 'Data/trip_preferences.dart';
import 'Data/positional_preferences.dart';
import 'Data/gear_preferences.dart';
import 'Data/saved_preferences.dart';
import 'Data/crewMemberList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'CodeShare/colors.dart'; // Your colors.dart.dart file

void main() async {
  // Set up for Hive that needs to run before starting app
  WidgetsFlutterBinding.ensureInitialized();
  // Disable Impeller
  PlatformDispatcher.instance.onPlatformConfigurationChanged = null;
  await Hive.initFlutter();

  // Register the Gear adapters
  Hive.registerAdapter(GearAdapter());
  Hive.registerAdapter(CrewMemberAdapter());
  Hive.registerAdapter(CrewMemberListAdapter());
  Hive.registerAdapter(LoadAdapter());
  Hive.registerAdapter(TripAdapter());
  Hive.registerAdapter(CustomItemAdapter());
  Hive.registerAdapter(TripPreferenceAdapter());
  Hive.registerAdapter(PositionalPreferenceAdapter());
  Hive.registerAdapter(GearPreferenceAdapter());

  // Open a Hive boxes to store objects
  await Hive.openBox<Gear>('gearBox');
  await Hive.openBox<CrewMember>('crewmemberBox');
  await Hive.openBox<CrewMemberList>('crewMemberListBox');
  await Hive.openBox<Load>('loadBox');
  await Hive.openBox<Trip>('tripBox');
  await Hive.openBox<TripPreference>('tripPreferenceBox');
  await Hive.openBox<Gear>('personalToolsBox');

  // Load data from Hive
  crew.loadCrewDataFromHive();
  savedPreferences.loadPreferencesFromHive();
  savedTrips.loadTripDataFromHive(); // do we need to load trip data as well?

  // Test data for user testing
  if (crew.crewMembers.isEmpty && crew.gear.isEmpty) {
    initializeTestData();
  }

  // Load all preferences and update them
  //await updateAllTripPreferencesFromBoxes();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool agreedToTerms = prefs.getBool('agreedToTerms') ?? false;
  // Initialize the dark mode and background image setting
  AppColors.isDarkMode = await ThemePreferences.getTheme();
  AppColors.enableBackgroundImage = await ThemePreferences.getBackgroundImagePreference();

  // start app
  runApp(MyApp(showDisclaimer: !agreedToTerms));
}

class MyApp extends StatelessWidget {
  final bool showDisclaimer;

  const MyApp({super.key, required this.showDisclaimer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Manifest App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.fireColor),
        useMaterial3: true,
        // for theme based text-> style: Theme.of(context).textTheme.headlineMedium,
      ),
      home: showDisclaimer ? const DisclaimerScreen() : const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // To track the currently selected tab

  // Use a getter to dynamically create the pages list
  List<Widget> get _pages => [
        CreateNewManifest(onSwitchTab: _onItemTapped), // Pass the callback
        SavedTripsView(),
        EditCrew(),
        SettingsView(
          isDarkMode: AppColors.isDarkMode,
          enableBackgroundImage: AppColors.enableBackgroundImage,
          onThemeChanged: _toggleTheme,
          onBackgroundImageChange: _toggleBackgroundImage,
        ),
      ];

  void _toggleTheme(bool isDarkMode) async {
    setState(() {
      AppColors.isDarkMode = isDarkMode;
    });
    await ThemePreferences.setTheme(isDarkMode);
  }
  void _toggleBackgroundImage(bool enableBackgroundImage) async {
    setState(() {
      AppColors.enableBackgroundImage = enableBackgroundImage;
    });
    await ThemePreferences.setBackgroundImagePreference(enableBackgroundImage);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        // Ensures all icons are visible
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.tabIconColor,
        backgroundColor: AppColors.appBarColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Manifest',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.helicopter),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Crew',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool userAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child:  Text('Terms and Conditions', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary)),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                // Blur effect
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover  entire background
                  width: double.infinity,
                  height: double.infinity,
                )),
          ),
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child:  Text(
                        'The calculations provided by this app are intended for informational purposes only. '
                        'While every effort has been made to ensure accuracy, users must independently verify and validate '
                        'all data before relying on it for operational or decision-making purposes. The developers assume no '
                        'liability for errors, omissions, or any outcomes resulting from the use of this app. By continuing, '
                        'you acknowledge and accept full responsibility for reviewing and confirming all calculations.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: Colors.black, // Outline color
                          width: 2.0, // Outline width
                        ),//
                        value: userAgreed,
                        onChanged: (value) {
                          setState(() {
                            userAgreed = value!;
                          });
                        },
                      ),
                      Flexible(
                        child: Text(
                          'I agree to the terms and conditions',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            // fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: userAgreed
                          ? () async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('agreedToTerms', true);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MyHomePage()),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        backgroundColor: AppColors.textFieldColor,
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

Future<void> updateAllTripPreferencesFromBoxes() async {
  var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
  var gearBox = Hive.box<Gear>('gearBox');
  var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');

  // Iterate through all TripPreference objects in the box
  for (var tripPreference in tripPreferenceBox.values) {
    // Update PositionalPreferences
    for (var posPref in tripPreference.positionalPreferences) {
      for (int i = 0; i < posPref.crewMembersDynamic.length; i++) {
        var member = posPref.crewMembersDynamic[i];

        if (member is CrewMember) {
          // Match by name and update attributes
          var updatedMember = crewMemberBox.values.firstWhere(
            (cm) => cm.name == member.name,
            orElse: () => member, // Fallback to the current member if not found
          );

          posPref.crewMembersDynamic[i] = updatedMember;
        } else if (member is List<CrewMember>) {
          // If it's a group (like a Saw Team), update each member
          for (int j = 0; j < member.length; j++) {
            var updatedMember = crewMemberBox.values.firstWhere(
              (cm) => cm.name == member[j].name,
              orElse: () => member[j],
            );
            member[j] = updatedMember;
          }
        }
      }
    }

    // Update GearPreferences
    for (var gearPref in tripPreference.gearPreferences) {
      for (int i = 0; i < gearPref.gear.length; i++) {
        var gearItem = gearPref.gear[i];

        // Match by name and update attributes
        var updatedGear = gearBox.values.firstWhere(
          (g) => g.name == gearItem.name,
          orElse: () => gearItem, // Fallback to the current gear if not found
        );

        gearPref.gear[i] = updatedGear.copyWith(
          quantity: gearItem.quantity, // Retain the quantity from the preference
        );
      }
    }

    // Save the updated trip preference back to Hive
    await tripPreference.save();
  }
}

Future<void> resetAgreeToTerms() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('agreedToTerms', false);
}
