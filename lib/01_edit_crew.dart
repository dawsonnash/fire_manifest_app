import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fire_app/02_add_crewmember.dart';
import 'package:fire_app/02_crewmembers_view.dart';
import 'package:fire_app/03_gear_view.dart';
import 'package:fire_app/04_trip_preferences_view.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '03_add_gear.dart';
import 'CodeShare/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'Data/crew.dart';
import 'Data/gear.dart';

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

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    loadPersonalToolsList();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final double panelHeight = 125.0; // Height for the panels
    final double panelWidth = screenWidth * 0.8; // 80% of the screen width

    BoxDecoration panelDecoration = BoxDecoration(
      color: AppColors.panelColor,
      borderRadius: BorderRadius.circular(10),
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
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
    );

    TextStyle headerTextStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
      // decoration: TextDecoration.underline,
      // decorationColor: AppColors.primaryColor, // Set the color of the underline
      shadows: [
        Shadow(
          offset: Offset(0, 0),
          blurRadius: 80.0,
          color: Colors.black,
        ),
      ],
    );

    TextStyle subHeaderTextStyle = TextStyle(
      fontSize: 18,
      color: AppColors.textColorPrimary,
    );
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          // Background
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent,
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                    ? Stack(
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Image.asset(
                              'assets/images/logo1.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            color: AppColors.logoImageOverlay,
                          ),
                        ],
                      )
                    : null)
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),

          Scaffold(
            resizeToAvoidBottomInset: true, // Allow resizing when keyboard opens

            appBar: AppBar(
              backgroundColor: AppColors.appBarColor,
              toolbarHeight: 0,
              bottom: TabBar(
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.tabIconColor,
                indicatorColor: AppColors.primaryColor,
                tabs: [
                  Tab(text: 'Add', icon: Icon(Icons.add)),
                  Tab(text: 'Edit', icon: Icon(Icons.edit)),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            body: Container(
              color: Colors.white.withValues(alpha: 0.05),
              child: Column(
                children: [
                  // Crew Name and Total Weight
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: (screenWidth - panelWidth) / 2, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // children: [
                        //   GestureDetector(
                        //     onTap: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on tap
                        //       });
                        //     },
                        //     onDoubleTap: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on double-tap
                        //       });
                        //     },
                        //     onLongPress: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on long press
                        //       });
                        //     },
                        //     child: isEditing
                        //         ? TextField(
                        //       autofocus: true,
                        //       controller: TextEditingController(text: crewName),
                        //       style: headerTextStyle,
                        //       textAlign: TextAlign.center,
                        //       onSubmitted: (value) {
                        //         if (value.trim().isNotEmpty) {
                        //           setState(() {
                        //             crewName = value.trim(); // Update the crew name
                        //             isEditing = false; // Exit editing mode
                        //           });
                        //           widget.onCrewNameChanged(crewName); // Notify parent of the change
                        //         } else {
                        //           setState(() {
                        //             isEditing = false; // Exit editing mode without saving
                        //           });
                        //         }
                        //       },
                        //       onEditingComplete: () {
                        //         setState(() {
                        //           isEditing = false; // Exit editing mode
                        //         });
                        //       },
                        //       decoration: InputDecoration(
                        //         border: InputBorder.none, // No borders for a seamless look
                        //         hintText: 'Enter crew name',
                        //       ),
                        //     )
                        //         :
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // Aligns the text and underline to the right
                          children: [
                            IntrinsicWidth(
                              child: Container(
                                padding: EdgeInsets.only(bottom: 4.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.fireColor, width: 2.0),
                                  ),
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.8, // Limit the maximum width
                                  ),
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
                            ),
                          ],
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${crew.crewMembers.length} persons',
                            style: subHeaderTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          '${crew.totalCrewWeight.toInt()} lbs',
                          style: subHeaderTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: TabBarView(
                      children: [
                        // Add Tab
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddCrewmember()),
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.add, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Crew Member',
                                        style: panelTextStyle,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddGear()),
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.add, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Gear',
                                        style: panelTextStyle,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    ],
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
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CrewmembersView()),
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.edit, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Crew Member',
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GearView()),
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.edit, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Gear',
                                        style: panelTextStyle,
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

                  Container(
                    // color: Colors.white.withValues(alpha: 0.05),
                    width: double.infinity,
                    child: Column(
                      children: [
                        // Adding/Editing Tools
                        Padding(
                          padding: const EdgeInsets.all(16.0),
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
                                          bottom: MediaQuery.of(dialogContext).viewInsets.bottom, // Adjust for keyboard
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
                                                      child: Text(tool.name, style: TextStyle(color: AppColors.textColorPrimary, fontSize: 16)),
                                                    );
                                                  }),
                                                  DropdownMenuItem<String>(
                                                    value: '+ New Tool',
                                                    child: Text('+ New Tool', style: TextStyle(color: AppColors.textColorPrimary, fontSize: 16)),
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
                                                        fontSize: 18,
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
                                                style: TextStyle(color: AppColors.textColorPrimary, fontSize: 16),
                                              ),

                                               SizedBox(height: AppData.spacingStandard),

                                              // Tool weight
                                              TextField(
                                                controller: toolWeightController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(2),
                                                  FilteringTextInputFormatter.digitsOnly
                                                ],
                                                decoration: InputDecoration(
                                                  labelText: 'Tool Weight (lbs)',
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
                                                style: TextStyle(color: AppColors.textColorPrimary, fontSize: 16),
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
                                                        fontSize: 20,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Text(
                                                      isHazmat ? 'Yes' : 'No', // Dynamic label
                                                      style: TextStyle(
                                                        fontSize: 16,
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
                                                      style: TextStyle(color: AppColors.cancelButton),
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
                                                                  style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop(); // Close the confirmation dialog
                                                                    },
                                                                    child: Text(
                                                                      'Cancel',
                                                                      style: TextStyle(color: AppColors.cancelButton),
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
                                                                    },
                                                                    child: const Text(
                                                                      'Delete',
                                                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                                                        // Check for duplicate gear names with different weights (case-insensitive)
                                                        final isDuplicateWithDifferentWeight = crew.gear.any(
                                                          (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.weight != int.parse(toolWeightText), // Check if weight is different
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
                                                        if (isDuplicateWithDifferentWeight) {
                                                          // Find the first conflicting gear item to retrieve its weight
                                                          final conflictingGear = crew.gear.firstWhere(
                                                            (tool) => tool.name.toLowerCase() == toolName.toLowerCase() && tool.weight != int.parse(toolWeightText),
                                                          );
                                                          dialogSetState(() {
                                                            toolWeightErrorMessage = 'Must match gear weight: ${conflictingGear.weight} lbs'; // Set error message
                                                          });

                                                          Future.delayed(const Duration(seconds: 2), () {
                                                            dialogSetState(() {
                                                              toolWeightErrorMessage = null; // Clear error message
                                                            });
                                                          });
                                                          return;
                                                        }

                                                        final weight = int.parse(toolWeightText);

                                                        // Create new tool
                                                        final newTool = Gear(name: toolName, weight: weight, quantity: 1, isPersonalTool: true, isHazmat: isHazmat);

                                                        // Add to Hive and temporary page list
                                                        crew.addPersonalTool(newTool);
                                                        personalToolsList.add(newTool);

                                                        Navigator.of(dialogContext).pop(); // Close dialog
                                                        setState(() {}); // Reflect changes in the parent state
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

                                                        if (existingTool != null &&
                                                            toolNameRaw.toLowerCase() == existingTool.name.toLowerCase() &&
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
                                                                style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(confirmationContext).pop(); // Close the confirmation dialog
                                                                  },
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: TextStyle(color: AppColors.cancelButton),
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
                                                                        Gear(
                                                                          name: toolNameRaw,
                                                                          weight: int.parse(toolWeightText),
                                                                          quantity: 1,
                                                                          isPersonalTool: true,
                                                                          isHazmat: isHazmat
                                                                        ),
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

                                                                    Navigator.of(dialogContext).pop(); // Close the main dialog
                                                                    setState(() {}); // Reflect changes in the parent state
                                                                  },
                                                                  child: Text(
                                                                    'Update',
                                                                    style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontWeight: FontWeight.bold),
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
                                                      style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontWeight: FontWeight.bold),
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
                              width: screenWidth * 0.8,
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally

                                children: [
                                  Icon(
                                    Icons.handyman_outlined, // Add icon
                                    color: AppColors.primaryColor,
                                    size: 28, // Adjust size as needed
                                  ),
                                  Text(
                                    ' Tools',
                                    style: TextStyle(fontSize: 22, color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Trip Preferences Panel
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TripPreferences()),
                              );
                            },
                            child: Container(
                              width: screenWidth * 0.9,
                              height: panelHeight,
                              decoration: panelDecoration,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                children: [
                                  Icon(
                                    FontAwesomeIcons.sliders, // Add icon
                                    color: AppColors.primaryColor,
                                    size: 28, // Adjust size as needed
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
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
