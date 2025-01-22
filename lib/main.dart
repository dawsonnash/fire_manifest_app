import 'dart:ui';

import 'package:fire_app/05_manifest.dart';
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
  // do we need to load trip data as well?

  // Test data for user testing
  if (crew.crewMembers.isEmpty && crew.gear.isEmpty) {
    initializeTestData();
  }

  // Load all preferences and update them
  //await updateAllTripPreferencesFromBoxes();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool agreedToTerms = prefs.getBool('agreedToTerms') ?? false;

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        // for theme based text-> style: Theme.of(context).textTheme.headlineMedium,
      ),
      home: showDisclaimer ? const DisclaimerScreen() : const MyHomePage(),
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
          child: const Text('Terms and Conditions', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.deepOrangeAccent,
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
                      child: const Text(
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
                        value: userAgreed,
                        onChanged: (value) {
                          setState(() {
                            userAgreed = value!;
                          });
                        },
                      ),
                      Flexible(
                        child: const Text(
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
                        backgroundColor: Colors.deepOrangeAccent,
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Home Page UI
  @override
  Widget build(BuildContext context) {
    // Style for elevated buttons. Should probably figure out a way
    // to make this universal so we don't have to declare it in every page
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 1.7, MediaQuery.of(context).size.height / 10));

    return Scaffold(
      // appBar: AppBar(
      //
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //
      //   title: Text(widget.title),
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3, // Scales based on 30% of screen height
            color: Colors.deepOrangeAccent,
            child: const Center(
              // Fitted box automatically scales text based on available space
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Fire Manifesting',
                        textAlign: TextAlign.center,
                        // style: Theme.of(context).textTheme.headlineLarge,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'App',
                        textAlign: TextAlign.center,
                        // style: Theme.of(context).textTheme.headlineLarge,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.cover, // Cover  entire background
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Manifest
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ManifestHome()),
                              );
                            },
                            style: style,
                            child: const Text(
                              'Manifest',
                            )),
                      ),

                      // View Trips
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SavedTripsView()),
                              );
                            },
                            style: style,
                            child: const Text('View Trips')),
                      ),

                      // Edit Crew
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditCrew()),
                              );
                            },
                            style: style,
                            child: const Text('Edit Crew')),
                      ),

                      // ElevatedButton(
                      //   onPressed: () async {
                      //     await resetAgreeToTerms();
                      //   },
                      //   child: Text('Reset Agree to Terms'),
                      // ),
                    ],
                  ),
                ),

                // Settings Icon at Bottom Right
                Positioned(
                  bottom: 16.0, // Distance from the bottom
                  right: 16.0, // Distance from the right
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.grey),
                        iconSize: 40.0, // Size of the icon
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsView()),
                          );
                        },
                      ),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.grey, // Matches the icon color
                          fontSize: 16.0, // Adjust font size as needed
                        ),
                      ),
                    ],
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
