import 'dart:ui';

import 'package:fire_app/UI/02_add_crewmember.dart';
import 'package:fire_app/UI/02_crewmembers_view.dart';
import 'package:fire_app/UI/03_gear_view.dart';
import 'package:fire_app/UI/04_trip_preferences_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/trip_preferences.dart';
import '03_add_gear.dart';

class EditCrew extends StatefulWidget {
  const EditCrew({super.key});

  @override
  State<EditCrew> createState() => _EditCrewState();
}

class _EditCrewState extends State<EditCrew> {
  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];

  final TextEditingController toolNameController = TextEditingController();
  final TextEditingController toolWeightController = TextEditingController();
  bool isHazmat = false;
  String? toolNameErrorMessage;
  String? toolWeightErrorMessage;
  String? lastUsedLoadout;
  final FocusNode _toolWeightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadLastUsedLoadout();

    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    loadPersonalToolsList();
    // Lock the screen to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _loadLastUsedLoadout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUsedLoadout = prefs.getString('last_selected_loadout');
    });
  }

  // Function to load the list of tool items from the Hive box
  void loadPersonalToolsList() {
    setState(() {
      personalToolsList = personalToolsBox.values.toList();
    });
  }

  @override
  void dispose() {
    toolNameController.dispose();
    toolWeightController.dispose();
    // Reset to system default when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // Function to update fields based on selected tool
  void updateFields(String? toolName) {
    if (toolName != null && toolName != '+ New Tool') {
      final tool = personalToolsList.firstWhere((tool) => tool.name == toolName);
      toolNameController.text = tool.name;
      toolWeightController.text = tool.weight.toString();
      isHazmat = tool.isHazmat;
    } else {
      toolNameController.clear();
      toolWeightController.clear();
      isHazmat = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context); // Updates width and orientation

    final double panelWidth = AppData.screenWidth * 0.8; // 80% of the screen width
    final int topFlex = 2;
    final int middleFlex = 5;
    final int toolFlex = 2;
    final int tripPrefFlex = 2;

    BoxDecoration panelDecoration = BoxDecoration(
      color: AppColors.panelColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.black, // Outline color
        width: 2.0, // Outline width
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    TextStyle panelTextStyle = TextStyle(
      fontSize: AppData.text22,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
    );

    TextStyle headerTextStyle = TextStyle(
        fontSize: AppData.text28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        // decoration: TextDecoration.underline,
        // decorationColor: AppColors.primaryColor, // Set the color of the underlin
        shadows: outlinedText(strokeColor: Colors.black));

    TextStyle subHeaderTextStyle = TextStyle(fontSize: AppData.text18, color: Colors.white, shadows: outlinedText(strokeColor: Colors.black));
    return Stack(
      children: [
        // Background
        DefaultTabController(
          length: 2,
          child: Scaffold(
            resizeToAvoidBottomInset: true, // Allow resizing when keyboard opens

            appBar: AppBar(
              backgroundColor: AppColors.appBarColor,
              toolbarHeight: 0,
              bottom: TabBar(
                unselectedLabelColor: AppColors.tabIconColor,
                labelColor: AppColors.primaryColor,
                dividerColor: AppColors.appBarColor,
                indicatorColor: AppColors.primaryColor,
                tabs: [
                  Tab(text: 'Add', icon: Icon(Icons.add)),
                  Tab(text: 'Edit', icon: Icon(Icons.edit)),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Container(
                  color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
                  child: AppColors.isDarkMode
                      ? (AppColors.enableBackgroundImage
                          ? Stack(
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
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
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Always display in light mode
                          child: Image.asset(
                            'assets/images/logo1.png',
                            fit: BoxFit.cover, // Cover the entire background
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
                Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Column(
                    children: [
                      // Crew Name and Total Weight
                      Flexible(
                        flex: topFlex,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: (AppData.screenWidth - panelWidth) / 2, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end, // Aligns the text and underline to the right
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: AppColors.fireColor, width: 2.0),
                                        ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: AppData.screenWidth * 0.8, // Limit the maximum width
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown, // Shrinks text to fit without overflowing
                                                child: Text(
                                                  AppData.crewName,
                                                  style: headerTextStyle,
                                                  textAlign: TextAlign.right,
                                                  maxLines: 2,
                                                  // Limit to 2 lines
                                                  overflow: TextOverflow.ellipsis,
                                                  // Ellipsis if overflowed
                                                  softWrap: true, // Ensure wrapping
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Ensures both elements align from the top
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread elements apart
                                  children: [
                                    Expanded(
                                      flex: 2, // Allocate space for loadout text
                                      child: Align(
                                        alignment: Alignment.topLeft, // Ensures Loadout aligns with the top
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: AppData.screenWidth * 0.5, // Ensures it doesn’t take too much space
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown, // Shrinks text to fit without overflowing
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lastUsedLoadout != null ? 'Loadout:' : '',
                                                  style: subHeaderTextStyle,
                                                  textAlign: TextAlign.left,
                                                  // Allows wrapping up to two lines
                                                  overflow: TextOverflow.ellipsis,
                                                  // Use ellipsis if text is too long
                                                  softWrap: true,
                                                ),
                                                Text(
                                                  lastUsedLoadout != null ? '$lastUsedLoadout' : '',
                                                  style: subHeaderTextStyle,
                                                  textAlign: TextAlign.left,
                                                  maxLines: 2,
                                                  // Allows wrapping up to two lines
                                                  overflow: TextOverflow.ellipsis,
                                                  // Use ellipsis if text is too long
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Crew Info Column
                                    Align(
                                      alignment: Alignment.topRight, // Aligns the column with Loadout text
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown, // Shrinks text to fit without overflowing
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end, // Aligns text to the right
                                          mainAxisSize: MainAxisSize.min, // Prevents unnecessary stretching
                                          children: [
                                            Text(
                                              '${crew.crewMembers.length} persons',
                                              style: subHeaderTextStyle,
                                              textAlign: TextAlign.right,
                                            ),
                                            Text(
                                              '${crew.totalCrewWeight.toInt()} lb',
                                              style: subHeaderTextStyle,
                                              textAlign: TextAlign.right,
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
                        ),
                      ),

                      // Tab Bars: Add/Edit Crew/Gear
                      Flexible(
                        flex: middleFlex,
                        child: TabBarView(
                          children: [
                            // Add Tab
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: AppData.padding16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const AddCrewmember()),
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: panelWidth,
                                          decoration: panelDecoration,
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown, // Ensures content shrinks but never grows
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                              children: [
                                                Icon(
                                                  Icons.add, // Add icon
                                                  color: AppColors.primaryColor,
                                                  size: AppData.text32, // Adjust size as needed
                                                ),
                                                const SizedBox(width: 8), // Space between the icon and text
                                                Text(
                                                  'Add Crew Member',
                                                  style: panelTextStyle,
                                                  textAlign: TextAlign.center,
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: AppData.padding16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const AddGear()),
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: panelWidth,
                                          decoration: panelDecoration,
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown, // Ensures content shrinks but never grows
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                              children: [
                                                Icon(
                                                  Icons.add, // Add icon
                                                  color: AppColors.primaryColor,
                                                  size: AppData.text32, // Adjust size as needed
                                                ),
                                                const SizedBox(width: 8), // Space between the icon and text
                                                Text(
                                                  'Add Gear',
                                                  style: panelTextStyle,
                                                  textAlign: TextAlign.center,
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Edit Tab
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: AppData.padding16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const CrewmembersView()),
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: panelWidth,
                                          decoration: panelDecoration,
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown, // Ensures content shrinks but never grows
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                              children: [
                                                Icon(
                                                  Icons.edit, // Add icon
                                                  color: AppColors.primaryColor,
                                                  size: AppData.text32, // Adjust size as needed
                                                ),
                                                const SizedBox(width: 8), // Space between the icon and text
                                                Text(
                                                  'Edit Crew Member',
                                                  style: panelTextStyle,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: AppData.padding16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const GearView()),
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: panelWidth,
                                          decoration: panelDecoration,
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown, // Ensures content shrinks but never grows
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                              children: [
                                                Icon(
                                                  Icons.edit, // Add icon
                                                  color: AppColors.primaryColor,
                                                  size: AppData.text32, // Adjust size as needed
                                                ),
                                                const SizedBox(width: 8), // Space between the icon and text
                                                Text(
                                                  'Edit Gear',
                                                  style: panelTextStyle,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tools Panel
                      Flexible(
                        flex: toolFlex,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppData.padding16),
                          child: GestureDetector(
                            onTap: () {
                              String? selectedTool = '+ New Tool'; // Set default to "+ New Tool"

                              // Pre-fill fields initially for "+ New Tool"
                              toolNameController.clear();
                              toolWeightController.clear();
                              isHazmat = false;

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true, // Allows the sheet to expand with keyboard

                                builder: (BuildContext dialogContext) {
                                  return StatefulBuilder(
                                    builder: (BuildContext dialogContext, StateSetter dialogSetState) {
                                      return Container(
                                        padding: EdgeInsets.only(
                                          left: 24,
                                          right: 24,
                                          top: 16,
                                          bottom: MediaQuery.of(dialogContext).viewInsets.bottom + AppData.bottomModalPadding, // Adjust for keyboard
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.textFieldColor2,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              DropdownButtonFormField<String>(
                                                value: selectedTool,
                                                decoration: InputDecoration(
                                                  labelText: 'Select a Tool',
                                                  labelStyle: TextStyle(color: AppColors.textColorPrimary),
                                                  filled: true,
                                                  fillColor: AppColors.textFieldColor2,
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppColors.primaryColor,
                                                      // Border color when the TextField is focused
                                                      width: 2.0, // Border width
                                                    ),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                dropdownColor: AppColors.textFieldColor2,
                                                items: [
                                                  ...personalToolsList.map((tool) {
                                                    return DropdownMenuItem<String>(
                                                      value: tool.name,
                                                      child: Text(tool.name, style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16)),
                                                    );
                                                  }),
                                                  DropdownMenuItem<String>(
                                                    value: '+ New Tool',
                                                    child: Text('+ New Tool', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16)),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  dialogSetState(() {
                                                    selectedTool = value;
                                                    updateFields(value);
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              if (selectedTool != null && selectedTool != '+ New Tool')
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 8.0),
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'Edit Tool Details',
                                                      style: TextStyle(
                                                        fontSize: AppData.text18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textColorEditToolDetails,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Tool name
                                              TextField(
                                                controller: toolNameController,
                                                textCapitalization: TextCapitalization.words,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(12),
                                                ],
                                                decoration: InputDecoration(
                                                  labelText: 'Tool Name',
                                                  labelStyle: TextStyle(
                                                    color: AppColors.textColorPrimary,
                                                  ),
                                                  filled: true,
                                                  fillColor: AppColors.textFieldColor2,
                                                  errorText: toolNameErrorMessage,
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppColors.primaryColor,
                                                      // Border color when the TextField is focused
                                                      width: 2.0, // Border width
                                                    ),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16),
                                              ),

                                              SizedBox(height: AppData.spacingStandard),

                                              // Tool weight
                                              KeyboardActions(
                                                config: keyboardActionsConfig(
                                                  focusNodes: [_toolWeightFocusNode],
                                                ),
                                                disableScroll: true,
                                                child: TextField(
                                                  focusNode: _toolWeightFocusNode,
                                                  controller: toolWeightController,
                                                  keyboardType: TextInputType.number,
                                                  textInputAction: TextInputAction.done,
                                                  inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                                                  decoration: InputDecoration(
                                                    labelText: 'Tool Weight (lb)',
                                                    labelStyle: TextStyle(color: AppColors.textColorPrimary),
                                                    filled: true,
                                                    fillColor: AppColors.textFieldColor2,
                                                    errorText: toolWeightErrorMessage,
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: AppColors.primaryColor,
                                                        // Border color when the TextField is focused
                                                        width: 2.0, // Border width
                                                      ),
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                  ),
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16),
                                                ),
                                              ),

                                              SizedBox(height: AppData.spacingStandard),

                                              // HAZMAT
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.textFieldColor,
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  border: Border.all(color: AppColors.textColorPrimary, width: 2.0),
                                                ),
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'HAZMAT',
                                                      style: TextStyle(
                                                        fontSize: AppData.text20,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Text(
                                                      isHazmat ? 'Yes' : 'No', // Dynamic label
                                                      style: TextStyle(
                                                        fontSize: AppData.text16,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    // Toggle Switch
                                                    Switch(
                                                      value: isHazmat,
                                                      onChanged: (bool value) {
                                                        dialogSetState(() {
                                                          isHazmat = value; // Update the state
                                                        });
                                                      },
                                                      activeColor: Colors.red,
                                                      inactiveThumbColor: AppColors.textColorPrimary,
                                                      inactiveTrackColor: AppColors.textFieldColor,
                                                    ),
                                                    // HAZMAT Label
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 60),

                                              // Save/Cancel
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(dialogContext).pop(); // Close only this dialog
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: AppColors.cancelButton,
                                                        fontSize: AppData.bottomDialogTextSize,
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedTool != null && selectedTool != '+ New Tool')
                                                    TextButton(
                                                      onPressed: () {
                                                        if (selectedTool != null && selectedTool != '+ New Tool') {
                                                          // Show confirmation dialog
                                                          showDialog(
                                                            context: dialogContext,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                backgroundColor: AppColors.textFieldColor2,
                                                                title: Text(
                                                                  'Confirm Deletion',
                                                                  style: TextStyle(color: AppColors.textColorPrimary),
                                                                ),
                                                                content: Text(
                                                                  'The tool, $selectedTool, will be removed from all crew members who have it. Do you want to proceed?',
                                                                  style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop(); // Close the confirmation dialog
                                                                    },
                                                                    child: Text(
                                                                      'Cancel',
                                                                      style: TextStyle(
                                                                        color: AppColors.cancelButton,
                                                                        fontSize: AppData.bottomDialogTextSize,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      // Proceed with deletion
                                                                      // Delete from Hive and temporary page list and from addedTools if it exists
                                                                      crew.removePersonalTool(selectedTool!);
                                                                      personalToolsList.removeWhere((tool) => tool.name == selectedTool); // Remove from global tools
                                                                      // Iterate through all crew members and remove the tool from their personalTools list
                                                                      for (var crewMember in crew.crewMembers) {
                                                                        crewMember.personalTools?.removeWhere((tool) => tool.name == selectedTool);
                                                                      }

                                                                      // Close the confirmation dialog and the main dialog
                                                                      Navigator.of(context).pop(); // Close confirmation dialog
                                                                      Navigator.of(dialogContext).pop(); // Close main dialog

                                                                      // Update parent state
                                                                      setState(() {});
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Center(
                                                                            child: Text(
                                                                              'Tool deleted!',
                                                                              style: TextStyle(color: Colors.black, fontSize: AppData.text22, fontWeight: FontWeight.bold),
                                                                            ),
                                                                          ),
                                                                          duration: Duration(seconds: 1),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      'Delete',
                                                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: AppData.bottomDialogTextSize),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: AppData.bottomDialogTextSize),
                                                      ),
                                                    ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final toolNameRaw = toolNameController.text.trim();
                                                      final toolWeightText = toolWeightController.text.trim();

                                                      bool hasError = false;

                                                      // Adding New Tools Check
                                                      if (selectedTool == '+ New Tool') {
                                                        // Validate tool name
                                                        if (toolNameRaw.isEmpty) {
                                                          dialogSetState(() {
                                                            toolNameErrorMessage = 'Please enter tool name'; // Set error message
                                                          });

                                                          // Clear error after a delay
                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolNameErrorMessage = null; // Clear error message
                                                            });
                                                          });

                                                          hasError = true;
                                                        }

                                                        // Validate tool weight
                                                        if (toolWeightText.isEmpty || int.tryParse(toolWeightText) == null) {
                                                          dialogSetState(() {
                                                            toolWeightErrorMessage = 'Please enter valid tool weight'; // Set error message
                                                          });

                                                          // Clear error after a delay
                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolWeightErrorMessage = null; // Clear error message
                                                            });
                                                          });

                                                          hasError = true;
                                                        }

                                                        // If there are errors, stop further execution
                                                        if (hasError) return;

                                                        // Ensure the tool name is capitalized (first letter uppercase)
                                                        final toolName = toolNameRaw[0].toUpperCase() + toolNameRaw.substring(1).toLowerCase();

                                                        // Check for duplicate tool names (case-insensitive)
                                                        final isDuplicate = personalToolsList.any(
                                                          (tool) => tool.name.toLowerCase() == toolName.toLowerCase(),
                                                        );
                                                        final isDuplicateWithDifferentWeight = crew.gear.any(
                                                          (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.weight != int.parse(toolWeightText), // Check if weight is different
                                                        );

                                                        // Check for duplicate gear names with different hazmat values (case-insensitive)
                                                        final isDuplicateWithDifferentHazmat = crew.gear.any(
                                                          (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.isHazmat != isHazmat, // Check if hazmat value is different
                                                        );

                                                        if (isDuplicate) {
                                                          dialogSetState(() {
                                                            toolNameErrorMessage = 'Tool name already exists'; // Set error message
                                                          });

                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolNameErrorMessage = null; // Clear error message
                                                            });
                                                          });
                                                          return;
                                                        }
                                                        // Check for duplicate gear names with different weights (case-insensitive)

                                                        // Combine both checks
                                                        if (isDuplicateWithDifferentWeight || isDuplicateWithDifferentHazmat) {
                                                          String weightConflict = '';
                                                          String hazmatConflict = '';

                                                          // Add weight conflict message if applicable
                                                          if (isDuplicateWithDifferentWeight) {
                                                            final conflictingTool = crew.gear.firstWhere(
                                                              (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.weight != int.parse(toolWeightText),
                                                            );
                                                            weightConflict = 'This tool must match the same weight of the $toolName in your gear inventory: ${conflictingTool.weight} lb.';
                                                          }

                                                          // Add hazmat conflict message if applicable
                                                          if (isDuplicateWithDifferentHazmat) {
                                                            final conflictingTool = crew.gear.firstWhere(
                                                              (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.isHazmat != isHazmat,
                                                            );
                                                            hazmatConflict =
                                                                'This tool must match the same HAZMAT value of the $toolName in your gear inventory: ${conflictingTool.isHazmat ? 'TRUE' : 'FALSE'}.';
                                                          }

                                                          // Combine messages with the universal message
                                                          String combinedError = [weightConflict, hazmatConflict].where((msg) => msg.isNotEmpty).join('\n\n');
                                                          if (combinedError.isNotEmpty) {
                                                            combinedError = '$combinedError';
                                                          }

                                                          // Show a single AlertDialog
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                backgroundColor: AppColors.textFieldColor2,
                                                                title: Text(
                                                                  'Gear Conflict',
                                                                  style: TextStyle(color: AppColors.textColorPrimary),
                                                                ),
                                                                content: Text(
                                                                  combinedError,
                                                                  style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop();
                                                                    },
                                                                    child: Text(
                                                                      'Cancel',
                                                                      style: TextStyle(
                                                                        color: AppColors.cancelButton,
                                                                        fontSize: AppData.bottomDialogTextSize,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );

                                                          return; // Stop further execution
                                                        }

                                                        final weight = int.parse(toolWeightText);

                                                        // Create new tool
                                                        final newTool = Gear(name: toolName, weight: weight, quantity: 1, isPersonalTool: true, isHazmat: isHazmat);

                                                        // Add to Hive and temporary page list
                                                        crew.addPersonalTool(newTool);
                                                        personalToolsList.add(newTool);

                                                        Navigator.of(dialogContext).pop(); // Close dialog
                                                        setState(() {}); // Reflect changes in the parent state
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Center(
                                                              child: Text(
                                                                'Tool saved!',
                                                                style: TextStyle(color: Colors.black, fontSize: AppData.text22, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                            duration: Duration(seconds: 1),
                                                            backgroundColor: Colors.green,
                                                          ),
                                                        );
                                                      }

                                                      // Updating Tools Check
                                                      else {
                                                        // Validate tool name
                                                        if (toolNameRaw.isEmpty) {
                                                          dialogSetState(() {
                                                            toolNameErrorMessage = 'Please enter tool name'; // Set error message
                                                          });

                                                          // Clear error after a delay
                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolNameErrorMessage = null; // Clear error message
                                                            });
                                                          });

                                                          hasError = true;
                                                        }

                                                        // Validate tool weight
                                                        if (toolWeightText.isEmpty || int.tryParse(toolWeightText) == null || int.parse(toolWeightText) <= 0) {
                                                          dialogSetState(() {
                                                            toolWeightErrorMessage = 'Please enter tool weight'; // Set error message
                                                          });

                                                          // Clear error after a delay
                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolWeightErrorMessage = null; // Clear error message
                                                            });
                                                          });

                                                          hasError = true;
                                                        }

                                                        // Validate if tool name or weight are unchanged
                                                        final existingTool = personalToolsList.firstWhere(
                                                          (tool) => tool.name.toLowerCase() == selectedTool?.toLowerCase(),
                                                        );

                                                        if (toolNameRaw.toLowerCase() == existingTool.name.toLowerCase() &&
                                                            int.parse(toolWeightText) == existingTool.weight &&
                                                            isHazmat == existingTool.isHazmat) {
                                                          dialogSetState(() {
                                                            toolNameErrorMessage = 'Tool name is unchanged';
                                                            toolWeightErrorMessage = 'Tool weight is unchanged';
                                                          });

                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolNameErrorMessage = null;
                                                              toolWeightErrorMessage = null;
                                                            });
                                                          });

                                                          hasError = true;
                                                        }

                                                        // If there are errors, stop further execution
                                                        if (hasError) return;

                                                        // Show confirmation dialog
                                                        showDialog(
                                                          context: dialogContext,
                                                          builder: (BuildContext confirmationContext) {
                                                            return AlertDialog(
                                                              backgroundColor: AppColors.textFieldColor2,
                                                              title: Text(
                                                                'Confirm Update',
                                                                style: TextStyle(color: AppColors.textColorPrimary),
                                                              ),
                                                              content: Text(
                                                                'Updating $selectedTool will modify this tool for all crew members who have it, and will update it in your gear inventory if it exists. Do you want to proceed?',
                                                                style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(confirmationContext).pop(); // Close the confirmation dialog
                                                                  },
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                      color: AppColors.cancelButton,
                                                                      fontSize: AppData.bottomDialogTextSize,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(confirmationContext).pop(); // Close confirmation dialog

                                                                    // Update the tool in Hive
                                                                    final personalToolsBox = Hive.box<Gear>('personalToolsBox');
                                                                    final keyToUpdate = personalToolsBox.keys.firstWhere(
                                                                      (key) {
                                                                        final storedTool = personalToolsBox.get(key);
                                                                        return storedTool != null && storedTool.name.toLowerCase() == selectedTool!.toLowerCase();
                                                                      },
                                                                      orElse: () => null,
                                                                    );

                                                                    if (keyToUpdate != null) {
                                                                      personalToolsBox.put(
                                                                        keyToUpdate,
                                                                        Gear(name: toolNameRaw, weight: int.parse(toolWeightText), quantity: 1, isPersonalTool: true, isHazmat: isHazmat),
                                                                      );
                                                                    }

                                                                    // Update the tool in personalToolsList
                                                                    final tool = personalToolsList.firstWhere(
                                                                      (tool) => tool.name.toLowerCase() == selectedTool!.toLowerCase(),
                                                                    );
                                                                    tool.name = toolNameRaw;
                                                                    tool.weight = int.parse(toolWeightText);
                                                                    tool.isHazmat = isHazmat;

                                                                    // Update the tool in all crew members who have it
                                                                    for (var crewMember in crew.crewMembers) {
                                                                      if (crewMember.personalTools != null) {
                                                                        for (var personalTool in crewMember.personalTools!) {
                                                                          if (personalTool.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                                                            personalTool.name = toolNameRaw;
                                                                            personalTool.weight = int.parse(toolWeightText);
                                                                            personalTool.isHazmat = isHazmat;
                                                                          }
                                                                        }
                                                                      }
                                                                    }
                                                                    // Update the tool in all gear items
                                                                    for (var gearItems in crew.gear) {
                                                                      if (gearItems.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                                                        gearItems.name = toolNameRaw;
                                                                        gearItems.weight = int.parse(toolWeightText);
                                                                        gearItems.isHazmat = isHazmat;
                                                                      }
                                                                    }

                                                                    // Loop through all `TripPreferences` to update tools in `PositionalPreferences`
                                                                    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
                                                                    for (var tripPreference in tripPreferenceBox.values) {
                                                                      bool preferenceUpdated = false;

                                                                      for (var posPref in tripPreference.positionalPreferences) {
                                                                        for (int i = 0; i < posPref.crewMembersDynamic.length; i++) {
                                                                          var member = posPref.crewMembersDynamic[i];

                                                                          if (member is CrewMember) {
                                                                            // Update individual CrewMember's tools
                                                                            if (member.personalTools != null) {
                                                                              for (var personalTool in member.personalTools!) {
                                                                                if (personalTool.name.toLowerCase() == selectedTool?.toLowerCase()) {
                                                                                  personalTool.name = toolNameRaw;
                                                                                  personalTool.weight = int.parse(toolWeightText);
                                                                                  personalTool.isHazmat = isHazmat;
                                                                                  preferenceUpdated = true;
                                                                                }
                                                                              }
                                                                            }
                                                                          } else if (member is List<CrewMember>) {
                                                                            // Update tools for each CrewMember in Saw Teams (List<CrewMember>)
                                                                            for (var crewMember in member) {
                                                                              if (crewMember.personalTools != null) {
                                                                                for (var personalTool in crewMember.personalTools!) {
                                                                                  if (personalTool.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                                                                    personalTool.name = toolNameRaw;
                                                                                    personalTool.weight = int.parse(toolWeightText);
                                                                                    personalTool.isHazmat = isHazmat;
                                                                                    preferenceUpdated = true;
                                                                                  }
                                                                                }
                                                                              }
                                                                            }
                                                                          }
                                                                        }
                                                                      }
                                                                      // Save updated crew members to Hive
                                                                      var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
                                                                      for (var crewMember in crew.crewMembers) {
                                                                        crewMember.save();
                                                                      }

                                                                      // Save updated gear to Hive
                                                                      var gearBox = Hive.box<Gear>('gearBox');
                                                                      for (var gearItem in crew.gear) {
                                                                        gearItem.save();
                                                                      }

                                                                      // Save updated trip preference to Hive
                                                                      if (preferenceUpdated) {
                                                                        tripPreference.save();
                                                                      }
                                                                    }
                                                                    crew.updateTotalCrewWeight();
                                                                    Navigator.of(dialogContext).pop(); // Close the main dialog
                                                                    setState(() {}); // Reflect changes in the parent state
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        content: Center(
                                                                          child: Text(
                                                                            'Tool updated!',
                                                                            style: TextStyle(color: Colors.black, fontSize: AppData.text22, fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ),
                                                                        duration: Duration(seconds: 1),
                                                                        backgroundColor: Colors.green,
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    'Update',
                                                                    style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontWeight: FontWeight.bold, fontSize: AppData.bottomDialogTextSize),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      'Save',
                                                      style: TextStyle(
                                                        color: AppColors.saveButtonAllowableWeight,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: AppData.bottomDialogTextSize,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: AppData.screenWidth * 0.8,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.panelColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black, // Black outline color
                                  width: 2.0, // Thickness of the outline
                                ),
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // Ensures content shrinks but never grows

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally

                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: Transform.scale(
                                        scale: 2,
                                        child: SvgPicture.asset(
                                          'assets/icons/tools_icon.svg', // Your SVG file path
                                          width: 24, // Adjust size as needed
                                          height: 24,
                                          colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn), // Apply color dynamically
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' Tools',
                                      style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Trip Preferences Panel
                      Flexible(
                        flex: tripPrefFlex,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppData.padding16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TripPreferences()),
                              );
                            },
                            child: Container(
                              width: AppData.screenWidth * 0.9,
                              decoration: panelDecoration,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // Ensures content shrinks but never grows
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.sliders, // Add icon
                                      color: AppColors.primaryColor,
                                      size: AppData.text28, // Adjust size as needed
                                    ),
                                    const SizedBox(width: 8), // Space between the icon and text
                                    Text(
                                      'Trip Preferences',
                                      style: panelTextStyle,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
