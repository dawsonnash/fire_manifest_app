import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:fire_app/Data/load_accoutrement_manager.dart';
import 'package:fire_app/UI/01_edit_crew.dart';
import 'package:fire_app/UI/05_create_new_manifest.dart';
import 'package:fire_app/UI/06_saved_trips.dart';
import 'package:fire_app/UI/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import 'Analytics/analytics_observer.dart';
import 'CodeShare/variables.dart';
import 'Data/crew.dart';
import 'Data/crewMemberList.dart';
import 'Data/crew_loadout.dart';
import 'Data/customItem.dart';
import 'Data/gear_preferences.dart';
import 'Data/load.dart';
import 'Data/load_accoutrements.dart';
import 'Data/positional_preferences.dart';
import 'Data/saved_preferences.dart';
import 'Data/sling.dart';
import 'Data/trip.dart';
import 'Data/trip_preferences.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Set up for Hive that needs to run before starting app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Disable landscape mode temporarily, until UI is implemented
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Declare a variable to store the initial file path
  String? initialJsonFilePath;

  // Retrieve the file path before Flutter initializes
  List<SharedMediaFile> sharedFiles = await ReceiveSharingIntent.instance.getInitialMedia();
  if (sharedFiles.isNotEmpty) {
    initialJsonFilePath = sharedFiles.first.path;
  }

  // Disable Impeller
  PlatformDispatcher.instance.onPlatformConfigurationChanged = null;
  await Hive.initFlutter();

  // Register the Gear adapters
  Hive.registerAdapter(GearAdapter());
  Hive.registerAdapter(CrewMemberAdapter());
  Hive.registerAdapter(CrewMemberListAdapter());
  Hive.registerAdapter(LoadAdapter());
  Hive.registerAdapter(SlingAdapter());
  Hive.registerAdapter(TripAdapter());
  Hive.registerAdapter(CustomItemAdapter());
  Hive.registerAdapter(TripPreferenceAdapter());
  Hive.registerAdapter(PositionalPreferenceAdapter());
  Hive.registerAdapter(GearPreferenceAdapter());
  Hive.registerAdapter(LoadAccoutrementAdapter());

  // Open a Hive boxes to store objects
  await Hive.openBox<Gear>('gearBox');
  await Hive.openBox<CrewMember>('crewmemberBox');
  await Hive.openBox<CrewMemberList>('crewMemberListBox');
  await Hive.openBox<Load>('loadBox');
  await Hive.openBox<Load>('slingBox');
  await Hive.openBox<Trip>('tripBox');
  await Hive.openBox<TripPreference>('tripPreferenceBox');
  await Hive.openBox<Gear>('personalToolsBox');
  await Hive.openBox<LoadAccoutrement>('loadAccoutrementBox');

  // Load data from Hive
  await crew.loadCrewDataFromHive();
  await savedPreferences.loadPreferencesFromHive();
  await savedTrips.loadTripDataFromHive();
  await loadAccoutrementManager.loadLoadAccoutrementsFromHive();


  // Test data for user testing
  // if (crew.crewMembers.isEmpty && crew.gear.isEmpty) {
  //   initializeTestData();
  // }

  // Load all preferences and update them
  //await updateAllTripPreferencesFromBoxes();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool agreedToTerms = prefs.getBool('agreedToTerms') ?? false;
  // Initialize the dark mode and background image setting
  AppColors.isDarkMode = await ThemePreferences.getTheme();
  AppColors.enableBackgroundImage = await ThemePreferences.getBackgroundImagePreference();
  AppData.crewName = await ThemePreferences.getCrewName(); // Initialize AppData.crewName
  AppData.userName = await ThemePreferences.getUserName();
  AppData.safetyBuffer = await ThemePreferences.getSafetyBuffer();
  AppData.textScale = await ThemePreferences.getTextScale();

  // start app
  runApp(MyApp(showDisclaimer: !agreedToTerms, initialJsonFilePath: initialJsonFilePath));
}

class MyApp extends StatelessWidget {
  final bool showDisclaimer;
  final String? initialJsonFilePath;

  const MyApp({super.key, required this.showDisclaimer, this.initialJsonFilePath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,    // Debug label
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Fire Manifest App',
      navigatorObservers: [AnalyticsRouteObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.fireColor),
        useMaterial3: true,
        // for theme based text-> style: Theme.of(context).textTheme.headlineMedium,
      ),
      home: showDisclaimer
          ? const DisclaimerScreen()
          : MyHomePage(initialJsonFilePath: initialJsonFilePath),
    );
  }
}

final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

class MyHomePage extends StatefulWidget {
  final String? initialJsonFilePath;
  const MyHomePage({super.key, this.initialJsonFilePath});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // To track the currently selected tab
  bool _isLoading = true; // Show loading screen initially for opening JSONs on cold start

  // Use a getter to dynamically create the pages list
  List<Widget> get _pages => [
    CreateNewManifest(onSwitchTab: _onItemTapped), // Pass the callback
    SavedTripsView(),
    EditCrew(
    ),
    SettingsView(
      isDarkMode: AppColors.isDarkMode,
      enableBackgroundImage: AppColors.enableBackgroundImage,
      crewName: AppData.crewName,
      userName: AppData.userName,
      safetyBuffer: AppData.safetyBuffer,
      textScale: AppData.textScale,
      onThemeChanged: _toggleTheme,
      onBackgroundImageChange: _toggleBackgroundImage,
      onCrewNameChanged: _changeCrewName,
      onUserNameChanged: _changeUserName,
      onSafetyBufferChange: _changeSafetyBuffer,
      onTextScaleChange: _changeTextScale,
    ),
  ];

  StreamSubscription<List<SharedMediaFile>>? _intentSubscription; // Store the subscription
  String? _jsonFilePath;

  List<String> loadoutNames = [];
  String? selectedLoadout;

  @override
  void initState() {
    super.initState();
    _loadLoadoutNames();

    // Step 1: Listen for shared files while the app is running
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
          (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleIncomingFile(value.first.path);  // Ensures sync check happens
        }
      },
      onError: (err) {},
    );

    // Step 2: Handle cold start with a shared JSON file
    if (widget.initialJsonFilePath != null) {
      _jsonFilePath = widget.initialJsonFilePath;

      // Delay execution until UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _jsonFilePath == null) return;

        // Show loading indicator
        _showLoadingDialog();

        bool outOfSync = await _checkSyncStatus();

        // Hide loading indicator
        Navigator.of(context).pop();

        if (outOfSync) {
          bool confirmProceed = await _showUnsavedChangesDialog(context);
          if (!confirmProceed) {
            return;
          }
        }

        _promptNewLoadoutName();
      });
    }
  }


  void _handleIncomingFile(String filePath) async {
    if (!mounted) return;

    setState(() {
      _jsonFilePath = filePath;
    });

    // Show loading indicator
    _showLoadingDialog();

    await Future.delayed(Duration(milliseconds: 300));

    // Check sync status before proceeding
    bool outOfSync = await _checkSyncStatus();

    // Hide loading indicator
    Navigator.of(context).pop(); // Close the loading dialog

    if (outOfSync) {
      bool confirmProceed = await _showUnsavedChangesDialog(context);
      if (!confirmProceed) {
        return; // Stop if user cancels
      }
    }

    // Now proceed to prompt for a new loadout name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _promptNewLoadoutName();
      }
    });
  }

// Show a loading dialog while checking sync status
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from closing it manually
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 10),
                Text("Checking sync status...", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }



  void _promptNewLoadoutName() {
    TextEditingController nameController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Save New Loadout',
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: InputDecoration(
                      errorText: errorMessage,
                      hintText: "Enter Loadout Name",
                      hintStyle: TextStyle(color: AppColors.textColorPrimary),
                    ),
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel", style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                ),
                TextButton(
                  onPressed: () async {
                    String loadoutName = nameController.text.trim();

                    if (loadoutName.isEmpty) {
                      setDialogState(() {
                        errorMessage = "Loadout name cannot be empty";
                      });
                      return;
                    }

                    // Check if name already exists
                    List<String> existingLoadouts = await CrewLoadoutStorage.getAllLoadoutNames();
                    if (existingLoadouts.contains(loadoutName)) {
                      setDialogState(() {
                        errorMessage = "Loadout name already exists";
                      });
                      return;
                    }

                    // Save new loadout
                    Navigator.of(context).pop(); // Close input dialog
                    _saveNewLoadout(loadoutName, _jsonFilePath!);
                  },
                  child: Text("Save", style: TextStyle(color: AppColors.saveButtonAllowableWeight)),
                ),


              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without action
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Unsaved Changes Detected',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Importing this loadout will erase any unsaved changes to your current crew loadout. View specific changes by tapping the red Out of Sync icon within the Settings page. Do you want to continue?',
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Return false
              child: Text("Cancel", style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Return true
              child: Text("Continue", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false; // Default return false if dialog is dismissed
  }

  Future<bool> _checkSyncStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastUsedLoadout = prefs.getString('last_selected_loadout');

    if (lastUsedLoadout == null) {
      return true;
    }

    Map<String, dynamic>? lastSavedData = await CrewLoadoutStorage.loadLoadout(lastUsedLoadout);

    if (lastSavedData == null) {
      return true;
    }

    // Convert saved crew and preferences to JSON
    String lastSavedCrewJson = jsonEncode(lastSavedData["crew"]);
    String lastSavedPreferencesJson = jsonEncode(lastSavedData["savedPreferences"]);

    // Convert current crew and preferences to JSON (global state)
    Map<String, dynamic> currentCrewData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
    };
    String currentCrewJson = jsonEncode(currentCrewData["crew"]);
    String currentPreferencesJson = jsonEncode(currentCrewData["savedPreferences"]);

    // Compare Crew and Preferences JSONs
    bool crewDiffers = (lastSavedCrewJson != currentCrewJson);
    bool preferencesDiffers = (lastSavedPreferencesJson != currentPreferencesJson);

    if (crewDiffers || preferencesDiffers) {
      return true; // Data is out of sync
    }

    return false;
  }


  Future<void> _saveNewLoadout(String loadoutName, String filePath) async {
    String timestamp = DateFormat('EEE, dd MMM yy, h:mm a').format(DateTime.now());

    // Read JSON file
    String jsonString = await File(filePath).readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // Save to storage
    Map<String, dynamic> loadoutData = {
      "crew": jsonData["crew"],
      "savedPreferences": jsonData["savedPreferences"],
      "lastSaved": timestamp,
    };

    await CrewLoadoutStorage.saveLoadout(loadoutName, loadoutData);

    // Apply the new loadout to update UI and persist the selection
    await _applyLoadout(loadoutName, loadoutData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Saved $loadoutName',
            style: TextStyle(color: Colors.black, fontSize: AppData.text22, fontWeight: FontWeight.bold),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _applyLoadout(String loadoutName, Map<String, dynamic> loadoutData) async {
    try {
      // Convert JSON back to objects
      Crew importedCrew = Crew.fromJson(loadoutData["crew"]);
      SavedPreferences importedPreferences = SavedPreferences.fromJson(loadoutData["savedPreferences"]);

      // Save the last selected loadout persistently
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_loadout', loadoutName);

      // Clear existing data
      await Hive.box<CrewMember>('crewmemberBox').clear();
      await Hive.box<Gear>('gearBox').clear();
      await Hive.box<Gear>('personalToolsBox').clear();
      await Hive.box<TripPreference>('tripPreferenceBox').clear();
      savedPreferences.deleteAllTripPreferences();

      // Save new Crew Data
      var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
      for (var member in importedCrew.crewMembers) {
        await crewMemberBox.add(member);
      }

      var gearBox = Hive.box<Gear>('gearBox');
      for (var gearItem in importedCrew.gear) {
        await gearBox.add(gearItem);
      }

      var personalToolsBox = Hive.box<Gear>('personalToolsBox');
      for (var tool in importedCrew.personalTools) {
        await personalToolsBox.add(tool);
      }

      // Save new Trip Preferences
      var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
      for (var tripPref in importedPreferences.tripPreferences) {
        await tripPreferenceBox.add(tripPref);
      }
      savedPreferences.tripPreferences = tripPreferenceBox.values.toList();

      // Reload data from Hive
      await crew.loadCrewDataFromHive();
      await savedPreferences.loadPreferencesFromHive();

      // // Update last saved timestamp
      // await _loadLastSavedTimestamp(loadoutName);

      // // Re-check sync status after applying the loadout
      // await _checkSyncStatus(loadoutName);
      // Update state
      selectedIndexNotifier.value = 0;

      setState(() {
        selectedLoadout = loadoutName;
      });
    } catch (e) {
      showErrorDialog("Error loading loadout: $e");
    }
  }

  Future<void> _loadLoadoutNames() async {
    List<String> savedLoadouts = await CrewLoadoutStorage.getAllLoadoutNames();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastUsedLoadout = prefs.getString('last_selected_loadout');

    setState(() {
      loadoutNames = savedLoadouts;

      if (lastUsedLoadout != null && loadoutNames.contains(lastUsedLoadout)) {
        // If there was a previous selection, restore it
        selectedLoadout = lastUsedLoadout;
      } else {
        // If no valid previous selection, keep it null (Select a Loadout)
        selectedLoadout = null;

      }
    });
  }

  void confirmDataWipe(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent users from dismissing without action
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Warning',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Importing this file will overwrite all existing crew data (Crew Members, Gear, Tools, Trip Preferences). Proceed?',
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the warning dialog
                importCrewData(filePath); // Pass filePath instead of callback
                FirebaseAnalytics.instance.logEvent(
                  name: 'crewDataFile_imported',
                  parameters: {
                    'file_name': filePath,
                  },
                );
              },
              child: Text('Confirm', style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize)),
            ),
          ],
        );
      },
    );
  }

  void importCrewData(String filePath) async {
    try {
      // Read file contents
      String jsonString = await File(filePath).readAsString();
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      if (!jsonData.containsKey("crew") || !jsonData.containsKey("savedPreferences")) {
        showErrorDialog("Invalid JSON format. Missing required fields.");

        FirebaseAnalytics.instance.logEvent(
          name: 'import_error',

          parameters: {
            'error_message': "Invalid JSON format. Missing required fields.",
          },
        );
        return;
      }

      // Import Crew Data
      Crew importedCrew = Crew.fromJson(jsonData["crew"]);
      SavedPreferences importedSavedPreferences = SavedPreferences.fromJson(jsonData["savedPreferences"]);

      setState(() {});

      // Clear old data
      await Hive.box<CrewMember>('crewmemberBox').clear();
      await Hive.box<Gear>('gearBox').clear();
      await Hive.box<Gear>('personalToolsBox').clear();
      await Hive.box<TripPreference>('tripPreferenceBox').clear();
      savedPreferences.deleteAllTripPreferences();

      // Save Crew Data
      var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
      for (var member in importedCrew.crewMembers) {
        await crewMemberBox.add(member);
      }

      var gearBox = Hive.box<Gear>('gearBox');
      for (var gearItem in importedCrew.gear) {
        await gearBox.add(gearItem);
      }

      var personalToolsBox = Hive.box<Gear>('personalToolsBox');
      for (var tool in importedCrew.personalTools) {
        await personalToolsBox.add(tool);
      }

      // Save Trip Preferences to Hive
      var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
      for (var tripPref in importedSavedPreferences.tripPreferences) {
        await tripPreferenceBox.add(tripPref);
      }
      savedPreferences.tripPreferences = tripPreferenceBox.values.toList();

      // Reload data from Hive
      await crew.loadCrewDataFromHive();
      await savedPreferences.loadPreferencesFromHive();

      setState(() {});

      // Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Crew Imported!',
              style: TextStyle(color: Colors.black, fontSize: AppData.text22, fontWeight: FontWeight.bold),
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      showErrorDialog("Unexpected error during import: $e");
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade900,
          title: Text(
            'Import Error',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    _intentSubscription = null; // Prevents re-triggering on reopening
    super.dispose();
  }

  void switchTab(int index) {
    if (!mounted) return;
    selectedIndexNotifier.value = index;

    FirebaseAnalytics.instance.logScreenView(
      screenName: _getScreenName(index),
      screenClass: _getScreenClass(index),
    );
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0:
        return 'ManifestPage';
      case 1:
        return 'SavedTripsPage';
      case 2:
        return 'EditCrewPage';
      case 3:
        return 'SettingsPage';
      default:
        return 'UnknownTab';
    }
  }

  String _getScreenClass(int index) {
    return _pages[index].runtimeType.toString(); // Gets the class name of the Widget
  }


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
  void _changeCrewName(String crewName) async {

    setState(() {
      AppData.crewName = crewName;
    });
    await ThemePreferences.setCrewName(crewName);

    // Verify if it's saved correctly
    String savedCrewName = await ThemePreferences.getCrewName();

  }
  void _changeUserName(String userName) async {
    setState(() {
      AppData.userName = userName;
    });
    await ThemePreferences.setUserName(userName);
  }
  void _changeSafetyBuffer(int safetyBuffer) async {
    setState(() {
      AppData.safetyBuffer = safetyBuffer;
    });
    await ThemePreferences.setSafetyBuffer(safetyBuffer);
  }
  void _changeTextScale(double textScale) async {
    setState(() {
      AppData.textScale = textScale;
    });
    await ThemePreferences.setTextScale(textScale);
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }




  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndexNotifier,
      builder: (context, index, child) {
        return Scaffold(
          body: _pages[index], // Use the selected page
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => switchTab(i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.tabIconColor,
            backgroundColor: AppColors.appBarColor,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Manifest'),
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.helicopter), label: 'Trips'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Crew'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
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
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      bool shouldShow = _scrollController.offset < _scrollController.position.maxScrollExtent;
      if (_showScrollIndicator != shouldShow) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context);
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child:  Text('Terms and Conditions', style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary)),
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
            child: Center(
              child: Container(
                width: AppData.termsAndConditionsWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),

                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'This application is designed to assist wildland fire personnel in creating detailed manifests for internal and external aviation operations. '
                                  'The calculations and information provided and generated by this app are for INFORMATIONAL PURPOSES ONLY and should not be solely relied upon for ANY operational, legal, safety, or decision-making purpose.\n\n'
                                  'While reasonable efforts have been made to ensure accuracy in weight calculations, the developers, distributors, and associated entities make no warranties, express or implied, regarding the reliability, completeness, or correctness of the data generated. '
                                  'Users assume full responsibility for independently verifying and validating all outputs before use.\n\n'
                                  'By proceeding, you expressly acknowledge and agree that the developers and associated entities shall not be held liable for any direct, indirect, incidental, consequential, or special damages, including but not limited to financial loss, or injury, arising from or related to the use or misuse of this application.'
                                  ' Continued use constitutes acceptance of these terms and an agreement to waive any claims against the developers or associated parties.',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: AppData.text16,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                    if (_showScrollIndicator)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 30,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                              Text(' More', style: TextStyle(fontSize: AppData.text16, color: Colors.black),)
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: AppData.checkboxScalingFactor, // Scales dynamically based on screen width
                          child: Checkbox(
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
                        ),
                        Flexible(
                          child: Text(
                            'I agree to the terms and conditions',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppData.text16,
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
                            MaterialPageRoute(builder: (context) => const MyHomePage(),
                              settings: RouteSettings(name: 'HomePage'),
                            ),
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
                        child:  Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: AppData.text20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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