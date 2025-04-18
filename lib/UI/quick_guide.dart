import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../CodeShare/variables.dart';

class QuickGuide extends StatefulWidget {
  const QuickGuide({super.key});

  @override
  State<QuickGuide> createState() => _QuickGuideState();
}

class _QuickGuideState extends State<QuickGuide> {
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _dropdownOverlay;
  final GlobalKey _contentButtonKey = GlobalKey();
  bool _isDropdownOpen = false;
  bool _showContentBar = true;

  final List<Map<String, dynamic>> sectionKeys = [
    {"number": "1.0", "title": "Crew Management", "key": GlobalKey()},
    {"number": "1.1", "title": "Crew Members", "key": GlobalKey()},
    {"number": "1.2", "title": "Gear", "key": GlobalKey()},
    {"number": "1.3", "title": "Tools", "key": GlobalKey()},
    {"number": "1.4", "title": "Trip Preferences", "key": GlobalKey()},
    {"number": "1.5", "title": "Crew Loadouts", "key": GlobalKey()},
    {"number": "1.6", "title": "Crew Sharing", "key": GlobalKey()},
    {"number": "2.0", "title": "Manifesting", "key": GlobalKey()},
    {"number": "2.1", "title": "Quick Manifest", "key": GlobalKey()},
    {"number": "2.1.1", "title": "Internal Manifesting", "key": GlobalKey()},
    {"number": "2.1.2", "title": "External Manifesting", "key": GlobalKey()},
    {"number": "2.2", "title": "Build Your Own", "key": GlobalKey()},
    {"number": "2.3", "title": "Editing Trips", "key": GlobalKey()},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showContentBar && !_isDropdownOpen) {
        setState(() {
          _showContentBar = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showContentBar) {
        setState(() {
          _showContentBar = true;
        });
      }
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    final RenderBox renderBox = _contentButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        width: width,
        top: position.dy + renderBox.size.height,
        child: Material(
          elevation: 4.0,
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          child:  ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sectionKeys.length,
              itemBuilder: (context, index) {
                final section = sectionKeys[index];
                final String sectionNumber = section["number"];
                final List<String> parts = sectionNumber.split('.');

                int depth = (parts.length == 1 || (parts.length == 2 && parts.last == '0')) ? 0 : parts.length - 1;
                double leftPadding = AppData.padding16 + (depth * AppData.padding16);

                return ListTile(
                  contentPadding: EdgeInsets.only(left: leftPadding, right: AppData.padding16),
                  title: Row(
                    children: [
                      Text(
                        sectionNumber,
                        style: TextStyle(
                          color: depth > 0 ? Colors.grey : Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: AppData.text16,
                        ),
                      ),
                      SizedBox(width: AppData.sizedBox8),
                      Text(
                        section["title"],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppData.text16,
                          fontWeight: depth > 0 ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _hideDropdown();
                    _scrollToSection(section["title"]);
                    // Log which section was clicked
                    FirebaseAnalytics.instance.logEvent(
                      name: 'quick_guide_section_viewed',
                      parameters: {
                        'section_title': section["title"],
                        'section_number': section["number"],
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_dropdownOverlay!);

    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _hideDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;

    setState(() {
      _isDropdownOpen = false;
    });
  }

  void _scrollToSection(String sectionTitle) {
    final section = sectionKeys.firstWhere(
      (item) => item["title"] == sectionTitle,
    );

    if (section != null) {
      final key = section["key"];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _closeDropdown() {
    if (_isDropdownOpen) {
      setState(() {
        _showContentBar = false;
        _isDropdownOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColorPrimary),
          onPressed: () {
            if (_isDropdownOpen) {
              _hideDropdown(); // Close the dropdown first
              Navigator.of(context).pop(); // Then navigate back
            } else {
              Navigator.of(context).pop(); // Then navigate back
            }
          },
        ),
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Quick Guide',
          style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
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
          Padding(
            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
            child: Column(
              children: [
                // **Animated Container for Smooth Transition**
                AnimatedContainer(
                  duration: Duration(milliseconds: 500), // Smooth transition time
                  height: _showContentBar ? AppData.quickGuideContentHeight : 0.0, // Animate height
                  curve: Curves.easeInOut, // Smooth animation curve
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300), // Smooth fade transition
                    opacity: _showContentBar ? 1.0 : 0.0, // Fade out when hidden
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
                      child: GestureDetector(
                        key: _contentButtonKey,
                        onTap: _toggleDropdown,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Contents", style: TextStyle(color: Colors.white, fontSize: AppData.quickGuideContentTextSize)),
                              Icon(
                                _isDropdownOpen ? Icons.close : Icons.list,
                                color: Colors.white,
                                size: AppData.text24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppData.padding16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Image
                        Center(
                          child: Image.asset(
                            'assets/images/quick_guide/quick_guide_overview.png',
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: AppData.sizedBox16),

                        // App Description Image
                        Center(
                          child: Image.asset(
                            'assets/images/quick_guide/app_overview.png',
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: AppData.sizedBox22),

                        // 1.0 Crew Management
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Management", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.0", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSection)),
                                    Text("  Crew Management ", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Icon(
                                      Icons.person,
                                      size: AppData.text24,
                                      color: AppColors.quickGuideSection,
                                    )
                                  ],
                                ),
                              ),
                              SelectableText("\nThe Fire Manifesting App allows you to manage your crew members, gear, and tools, all in a central location without the need for paper records. The crew is managed via the Crew page on the bottom navigation bar. The top section of the Crew Page shows you information on your current Crew Loadout. Listed on the top left is the specific loadout you are managing, and on the top right are the number of persons and total weight of your crew within that loadout. Throughout the app, different crew data types are signified by different colors: Crew Members: dark grey, Personal Tools: light blue, and Gear Items: yellow.\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        //1.1 Crew Members
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Members", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,

                                child: Row(
                                  children: [
                                    Text("1.1", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Crew Members", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nWhen adding or editing a crew member, required fields include their last name and flight weight (consisting of the total weight on their person when flying on the aircraft: body, helmet, pack, uniform weights, etc.). The flight weight should not include the crew member’s personal tool weights. More required fields include their primary position and all personal tools. If a crew member has more than one position, include the position that is the most crucial to fire and aviation operations. For example,  ‘Saw Team 1’ or ‘Medic/EMT’ are primary over ‘Camp/Facilities’ due to their critical role in active fire operations and safety. These positions are taken into account when using the Quick Manifest feature, which distributes and sorts crew members based on their positional skillsets.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/edit_crewmember.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 1.2 Gear
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Gear", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Gear", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nWhen adding gear items, include the name, weight, quantity, and whether the item is a hazardous material (anything potentially combustible). The hazardous material items will be placed in their designated slots in any generated manifest PDFs. Items from the Incident Response Pocket Guide (IRPG) can also be selected and added to your crew inventory; weights for these items can be adjusted.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/edit_gear.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 1.3 Tools
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Tools", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.3", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Tools", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nThe Tools panel allows you to create and manage personal tool templates for your crew. These are the tools that will constantly be with your person when you travel via helicopter. Once you add a personal tool to a crew member, it will always be attached to them so that whenever you create a new trip, it will accompany them on their load. If you wish to travel without a tool, you must first delete it within the Edit Crew Member page. Any edits to Tools must be done within the Tools panel. If an edit is made or a tool deleted, it will affect all crew members who have it listed in their personal tools.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/add_tool.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 1.4 Trip Preferences
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Trip Preferences", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.4", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Trip Preferences", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nTrip Preferences are your way to decide how you want your crew sorted into loads. Each Trip Preference can contain both positional and gear load preferences that can be defined based on the standard operating procedures that you or your crew follow.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SelectableText(
                                  "Trip Preferences are used within the Quick Manifest feature, which utilizes a built-in load-calculating algorithm. There are 3 ways to customize this algorithm: First, Last, and Balanced load preferences. Giving a crew member or gear item a 'First' preference places it on the first load available; if there is not enough weight it will place it on the next available load working from the first load to the last. The 'Last' preference does the exact same thing except in the opposite direction. When you select the 'Balanced' preference, all crew members and gear items in that load preference will be placed cyclically (e.g. 1, 2, 3, 1, 2, 3, ...) onto the loads in the order that you placed them in the preference. This allows for an even distribution of items and personnel. When Saw Teams are selected for load preferences, the algorithm will ensure that members of a Saw Teams stick together, unless not possible due to weight or available seat constraints. \n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SelectableText(
                                  "Below is an example of a Trip Preference for ‘Going to a Fire’, a situation where you may need certain gear items or positions to go on specific loads. This preference set up ensures a Superintendent (Ex. Burnham) and Assistant Superintendent (Ex. Burnett) go first to a fire to gain situational awareness, Saw Teams are distributed evenly, and food, water, and emergency gear are appropriately allocated to the right loads.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/trip_preference.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 1.5  Crew Loadouts
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Loadouts", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.5", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Crew Loadouts", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nCrew Loadouts are your way of quickly navigating between different crew set ups without affecting your original crew data. Each fire incident may require personnel or gear items that are different from your typical set up, so by switching to and working within a new loadout, you can generate manifests on the fly in changing operational circumstances without having to tediously re-input crew data.\n\nWhenever you edit a loadout, your updates will be tracked. A red out-of-sync icon will appear below your loadout in the Settings page. To view specific changes, just tap anywhere on the sync timestamp. If you want to revert your loadout back to the previous saved version, simply tap your loadout name, and select the yellow ‘Revert to Last Saved’ option. If you want to update your current loadout, tap the green sync icon. If you want to start a new loadout with the data from your current loadout, select the ‘Save New’ option. To edit a loadout name, tap and hold the loadout name in the Settings page. For non-crew fire personnel, the Crew Loadout feature also allows you to manage multiple crews, if need be, by saving a single crew to a loadout.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/crew_loadout.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 1.6  Crew Sharing
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Sharing", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("1.6", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Crew Sharing", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nThe Crew Sharing feature allows you to share your crew data with other crew members. You will find this feature within the Settings page. Crew Sharing allows you to have one person on your crew manage all the data you input. Once a crew is created, you may export your crew members, gear, and tools to a file that can be shared with other crew members.  To share on iOS, the easiest option is to simply export and AirDrop to other devices. On Android, you will need to export and send the file over the internet. To import a crew data file, you will need to have the file saved to your on-device storage or cloud storage. For iOS, to enable cloud storage (Google Drive, OneDrive, etc.) uploads from the Files app, first have the cloud storage app downloaded on your phone. Then, navigate to the Files app, select ‘Browse’ on the bottom navigation bar, tap the three-dot options icon on the top right, tap edit, and then enable your cloud storage with the toggle. For Android users, importing simply consists of selecting the crew data file wherever it's located on your device, selecting the “Open With’ or “Open In” option and selecting the Fire Manifesting App.\n\nImporting a crew data file will overwrite the current crew data you are managing. If you do not want to erase this data, first save it to a separate loadout. A good practice to never risk losing your crew data is to export the crew data file, rename it after your crew, and keep it saved somewhere safe in your file storage. This way if your data ever gets lost or edited beyond repair, you can simply import the original file back into the app.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.0 Manifesting
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Manifesting", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("2.0", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSection)),
                                    Text("  Manifesting ", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Icon(
                                      Icons.assignment,
                                      size: AppData.text24,
                                      color: AppColors.quickGuideSection,
                                    )
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nThere are two options for generating manifests: Quick Manifest or Build Your Own. Within each option you can create either Internal Manifests (personnel and gear flying within a helicopter) or External Manifests (no personnel, helicopter sling cargo).\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.1 Quick Manifest
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Quick Manifest", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,

                                child: Row(
                                  children: [
                                    Text("2.1", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Quick Manifest", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nThe Quick Manifest feature uses a load-calculating algorithm to automate the manifesting process. This algorithm generates the minimum number of loads required to get a crew to their destination. From a high-level overview, the algorithm simply takes in your Trip Preference, places those prioritized items and personnel on their respective loads, and then smartly sorts the remaining crew.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/quick_manifest.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.1.1 Internal Manifesting
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Internal Manifesting", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,

                                child: Row(
                                  children: [
                                    Text("2.1.1", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Internal Manifesting", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nFor manifesting internal loads, the algorithm begins by calculating the number of loads required based on the weight of the total selected crew, the allowable weight of the helicopter, and its available seats. The more seats that are available, the closer the algorithm can get to the allowable for each load’s weight. The algorithm then considers the Trip Preference selected. It loops through each Positional and Gear Preference and places the crew members and gear items into their respective loads. There are several considerations during this process. While placing Positional Preferences, it identifies whether there is an individual crew member or a team of crew members. If it’s a Saw Team, it ensures that they stay together. For example, if the Positional Preference is “Saw Team 1, Saw Team 2, Saw Team 3, Saw Team 4; Load Preference: Balanced”, it cyclically loops through each load placing entire saw teams on each load. This process is similar for Gear Preferences, whereas quantity can be thought of the same way – “QB (x2), MRE (x2); Load Preference: First” places sets of 2 QBs and 2 MREs on each load.\n\nOnce the algorithm has considered the Trip Preference, it then sorts the remaining crew members and gear. It does this by first shuffling the crew members by position to ensure distributed crew member skillsets among loads and avoid grouping identical positions on the same load. This is to avoid having scenarios like having all medics or crew leadership, for example, on the same load. Once positions have been shuffled, the algorithm then cyclically places the remaining crew members and gear onto loads. The cyclic approach guarantees that load weights will be as close as possible given the predefined preferences constraints. It also guarantees that, even if you don’t define it in your Trip Preference, gear items will be evenly distributed, which balances out critical items with larger quantities like food and water.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.1.2 External Manifesting
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "External Manifesting", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,

                                child: Row(
                                  children: [
                                    Text("2.1.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  External Manifesting", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText(
                                  "\nFor manifesting external loads, the algorithm begins by calculating the number of loads based on the allowable helicopter weight, safety buffer (this can be predefined within the Settings page), and total weight of selected gear to include the minimum required load accoutrements needed (nets, lead lines, swivels). Adjusting these three factors will readjust the minimum number of loads required. The algorithm for external manifesting works dissimilar to internal manifesting in that it will sequentially dump items as opposed to cyclic, keeping larger quantity items together when possible. The algorithm also focuses primarily on separating items into slings based on item quantity in respect to the total available net space in each load.\n\nWhen selecting Load Accoutrements, only include the nets, lead lines, and swivels that are being used to conduct sling operations. All excess should be placed inside your gear inventory; do not include it here. These numbers are used to generate sling configurations.  The minimum requirements for nets, lead lines, and swivels will always be initially selected, and you may not go below this number. The minimum requirement is that 1 net and 1 swivel are required per load, and any net must have a lead line. Any additional nets included will be daisy-chained together by the algorithm. When daisy-chaining, it will prioritize 20’x20’ nets to receive the greatest quantity of items, and will separate hazmat items when possible. The swivel will go to the net with the lightest load, assuming that the lightest load is attached directly to the belly hook of the helicopter. Any additional swivels will be placed into nets going from lightest to heaviest. The precise placement and distribution of load accoutrements can be edited within the Saved Trips page after the trip has been generated.\n ",
                                  style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.2 BYOM
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Build Your Own", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("2.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Build Your Own Manifest", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText("\nThe Build Your Own Manifest feature acts as a real time load-building-calculator that allows you to create a manifest from scratch without having to calculate weights in your head. When you create Internal Manifests, you can place both personnel and gear onto loads based on the allowable weight and available seats you input.  When you create External Manifests, you can only work with your gear items, and you can create slings within each load. To rearrange loads, simply tap and hold to drag loads around. To delete loads, swipe left. To delete crew members or gear items, either tap the delete icon or swipe to delete; to note: swipe-deleting gear items will remove the entire quantity.  Personal tools cannot be removed, as they are attached to their respective crew member. In each option, you will be notified of when you are either overweight, over the available seats, or over the safety buffer.\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/images/quick_guide/edit_trip.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.3 Editing Trips
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Editing Trips", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text("2.3", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                    Text("  Editing Trips", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              SelectableText("\nWhether you use the Quick Manifest or Build Your Own Manifest feature, your trips do not have to be final. They can be further edited and refined by tapping the more option on the top right after selecting your Trip in the Saved Trips page. Editing trips is identical to the Build Your Own Manifest Feature. It is also important to note that once a trip is created, all the crew member and gear data within it are unchangeable, meaning that any edits made to your crew data after creating a trip will not reflect within the trip itself and you will need to regenerate a new trip if you wish to see the changes reflected. \n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox20),
                            ],
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
