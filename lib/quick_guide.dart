import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'CodeShare/colors.dart';

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
    {"number": "1.0", "title": "App Overview", "key": GlobalKey()},
    {"number": "2.0", "title": "Crew Management", "key": GlobalKey()},
    {"number": "2.1", "title": "Crew Members and Gear", "key": GlobalKey()},
    {"number": "2.2", "title": "Trip Preferences", "key": GlobalKey()},
    {"number": "2.3", "title": "Tools", "key": GlobalKey()},
    {"number": "2.4", "title": "Crew Sharing", "key": GlobalKey()},
    {"number": "3.0", "title": "Manifesting", "key": GlobalKey()},
    {"number": "3.1", "title": "Quick Manifest", "key": GlobalKey()},
    {"number": "3.2", "title": "Build Your Own", "key": GlobalKey()},
    {"number": "3.3", "title": "Editing Trips", "key": GlobalKey()},
    {"number": "3.4", "title": "Exporting Trips", "key": GlobalKey()},
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sectionKeys.map((section) {
              String sectionNumber = section["number"];
              bool isSubsection = sectionNumber.contains(".") && !sectionNumber.endsWith(".0");
              return ListTile(
                contentPadding: EdgeInsets.only(left: isSubsection ? AppData.padding32 : AppData.padding16, right: AppData.padding16), // Indent subsections
                title: Row(
                  children: [
                    Text(
                      section["number"], // Section number
                      style: TextStyle(
                        color: isSubsection ? Colors.grey : Colors.deepOrangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: AppData.text16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      section["title"], // Section title
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppData.text16,
                        fontWeight: isSubsection ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _hideDropdown();
                  _scrollToSection(section["title"]);
                },
              );
            }).toList(),
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
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

                        // 1.0 App Overview
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "App Overview", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("1.0", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSection)),
                                  Text("  App Overview", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText(
                                "\n Overview here...\n",
                                style: TextStyle(fontSize: AppData.text16, color: Colors.white),
                              ),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.0 Crew Management
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Management", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("2.0", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSection)),
                                  Text("  Crew Management ", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Icon(Icons.person, size: AppData.text24, color: AppColors.quickGuideSection,)
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.1 Crew Members and Gear
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Members and Gear", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                              )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("2.1", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Crew Members and Gear", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.2 Trip Preferences
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Trip Preferences", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("2.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Trip Preferences", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.3 Tools
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Tools", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("2.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Tools", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 2.4  Crew Sharing
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Crew Sharing", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("2.4", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Crew Sharing", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 3.0 Manifesting
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Manifesting", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("3.0", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSection)),
                                  Text("  Manifesting ", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Icon(Icons.person, size: AppData.text24, color: AppColors.quickGuideSection,)
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 3.1 Quick Manifest
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Quick Manifest", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("3.1", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Quick Manifest", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 3.2 BYOM
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Build Your Own", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("3.2", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Build Your Own", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 3.3 Editing Trips
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Editing Trips", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("3.3", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Editing Trips", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
                              SizedBox(height: AppData.sizedBox20),
                            ],
                          ),
                        ),

                        // 3.4  Exporting Trips
                        Container(
                          key: sectionKeys.firstWhere((item) => item["title"] == "Exporting Trips", orElse: () => {"key": GlobalKey()} // Fallback to avoid crashes
                          )["key"],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("3.4", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.quickGuideSubsection)),
                                  Text("  Exporting Trips", style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              SelectableText("\n Description here...\n ", style: TextStyle(fontSize: AppData.text16, color: Colors.white)),
                              SizedBox(height: AppData.sizedBox10),
                              Image.asset("assets/help_screenshot_2.png"),
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
