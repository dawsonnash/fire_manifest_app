import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';

class AddCrewmember extends StatefulWidget {
  const AddCrewmember({super.key});

  @override
  State<AddCrewmember> createState() => _AddCrewmemberState();
}

class _AddCrewmemberState extends State<AddCrewmember> {
  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];
  String? weightErrorMessage;
  final FocusNode _weightFocusNode = FocusNode();

  // Variables to store user input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController flightWeightController = TextEditingController();
  final TextEditingController toolNameController = TextEditingController();
  final TextEditingController toolWeightController = TextEditingController();
  bool isSaveButtonEnabled = false; // Controls whether saving button is showing
  int? selectedPosition;
  late bool isHazmatTool;
  List<Gear>? addedTools = []; // List to hold added Gear objects, i.e., personal tools

  @override
  void initState() {
    super.initState();

    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    loadPersonalToolsList();

    // Set default isHazmatTool value
    if (personalToolsList.isNotEmpty) {
      isHazmatTool = personalToolsList.first.isHazmat; // Initialize from the first tool in the list
    } else {
      isHazmatTool = false; // Default to false if the list is empty
    }
    // Listeners to the TextControllers
    nameController.addListener(_checkInput);
    flightWeightController.addListener(_checkInput);
    toolNameController.addListener(_checkInput);
    toolWeightController.addListener(_checkInput);
  }

  // Function to load the list of tool items from the Hive box
  void loadPersonalToolsList() {
    setState(() {
      personalToolsList = personalToolsBox.values.toList();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    flightWeightController.dispose();
    toolNameController.dispose();
    toolWeightController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isNameValid = nameController.text.isNotEmpty;
    final isFlightWeightValid =
        flightWeightController.text.isNotEmpty && int.tryParse(flightWeightController.text) != null && int.parse(flightWeightController.text) > 0 && int.parse(flightWeightController.text) < 500;

    final isPositionSelected = selectedPosition != null;

    setState(() {
      // Need to adjust for position as well
      isSaveButtonEnabled = isNameValid && isFlightWeightValid && isPositionSelected;
    });
  }

  void addTool() {
    final String toolName = toolNameController.text;
    final int toolWeight = int.parse(toolWeightController.text);

    // Find the selected tool in the personalToolsList
    final Gear selectedGear = personalToolsList.firstWhere(
      (tool) => tool.name == toolName,
      orElse: () => Gear(name: toolName, weight: toolWeight, quantity: 1, isPersonalTool: true, isHazmat: false),
    );

    // Check for duplicate tool names
    final bool isDuplicate = addedTools?.any(
          (tool) => tool.name.toLowerCase() == toolName.toLowerCase(),
        ) ??
        false;

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Center(
            child: Text(
              'Tool Already Added',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text28, color: Colors.black),
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit function if the tool is a duplicate
    }

    setState(() {
      addedTools?.add(Gear(name: toolName, weight: toolWeight, quantity: 1, isPersonalTool: true, isHazmat: selectedGear.isHazmat));
      toolNameController.clear();
      toolWeightController.clear();
      setState(() {});
    });
  }

  void removeTool(int index) {
    setState(() {
      addedTools?.removeAt(index);
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveCrewMemberData() {
    // Take what the name contrller has saved
    final String name = nameController.text;

    // Check if crew member name already exists (case-insensitive)
    bool crewMemberNameExists = crew.crewMembers.any((member) => member.name.toLowerCase() == name.toLowerCase());

    if (crewMemberNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Center(
            child: Text(
              'Crew member name already used!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: AppData.text28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return; // Exit function if the gear name is already used
    }
    // Convert flight weight text to integer
    final int flightWeight = int.parse(flightWeightController.text);

    final List<Gear> personalTools = List.from(addedTools!);

    // Creating a new CrewMember object. Dont have positioin yet
    CrewMember newCrewMember = CrewMember(name: name, flightWeight: flightWeight, position: selectedPosition ?? 26, personalTools: personalTools);

    // Add the new crewmember to the global crew object
    crew.addCrewMember(newCrewMember);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Crew Member Saved!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
    FirebaseAnalytics.instance.logEvent(
      name: 'crewmember_added',
      parameters: {
        'crew_member' : newCrewMember.name.trim(),
        'position_title': newCrewMember.getPositionTitle(newCrewMember.position),
      },
    );



    // Clear all input fields (reset them to empty), so you can add more ppl
    clearInputs();
  }

  void clearInputs() {
    nameController.text = '';
    flightWeightController.text = '';
    toolNameController.text = '';
    toolWeightController.text = '';
    selectedPosition = null;
    // THis destroys everything
    addedTools?.clear();
    setState(() {}); // Rebuild UI to reflect changes
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10));

    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Add Crew Member',
          style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        onVerticalDragStart: (_) {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard on vertical swipe
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              // Takes up all available space
              child: Stack(
                children: [
                  // Background image
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
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Enter Name
                        Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                            child: TextField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: AppData.text28,
                              ),
                            )),
                        SizedBox(height: AppData.spacingStandard),
                        // Enter Flight Weight
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                            child: KeyboardActions(
                              config: keyboardActionsConfig(
                                focusNodes: [_weightFocusNode],
                              ),
                              disableScroll: true,
                              child: TextField(
                                focusNode: _weightFocusNode,
                                controller: flightWeightController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(3),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  int? weight = int.tryParse(value);
                                  setState(() {
                                    // Validate the input and set error message
                                    if (weight! > 500) {
                                      weightErrorMessage = 'Weight must be less than 500';
                                    } else if (weight == 0) {
                                      weightErrorMessage = 'Weight must be greater than 0';
                                    } else {
                                      weightErrorMessage = null;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Flight Weight',
                                  hintText: 'Up to 500 lb',
                                  hintStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text20,
                                  ),
                                  errorText: weightErrorMessage,
                                  errorStyle: TextStyle(
                                    fontSize: AppData.errorText,
                                    color: Colors.red,
                                  ),
                                  labelStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text22,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFieldColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.borderPrimary,
                                      // Border color when the TextField is not focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      // Border color when the TextField is focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text28,
                                ),
                              ),
                            )),
                        SizedBox(height: AppData.spacingStandard),

                        // Enter Position(s)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.textFieldColor,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                itemHeight: null,
                                value: selectedPosition,
                                hint: Text(
                                  'Primary Position',
                                  style: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text22,
                                  ),
                                ),
                                dropdownColor: AppColors.textFieldColor2,
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text22,
                                ),
                                iconEnabledColor: AppColors.textColorPrimary,
                                items: positionMap.entries.map((entry) {
                                  return DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      selectedPosition = newValue;
                                      _checkInput();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppData.spacingStandard),

                        // Enter tool(s) & weight
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, left: 16.0, right: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              String? selectedTool = personalToolsList.isNotEmpty ? personalToolsList.first.name : null; // Default to first tool
                              toolWeightController.text = personalToolsList.isNotEmpty ? personalToolsList.first.weight.toString() : '';
                              toolNameController.text = personalToolsList.isNotEmpty ? personalToolsList.first.name : '';

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return AlertDialog(
                                        backgroundColor: AppColors.textFieldColor2,
                                        title: Text(
                                          '+ Add Personal Tool',
                                          style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            DropdownButtonFormField<String>(
                                              value: personalToolsList.isNotEmpty ? selectedTool : null,
                                              // Set to null if no tools are available
                                              decoration: InputDecoration(
                                                labelText: 'Select a Tool',
                                                labelStyle: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16),
                                                filled: true,
                                                fillColor: AppColors.textFieldColor2,
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: AppColors.primaryColor,
                                                    width: 2.0,
                                                  ),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                              ),
                                              dropdownColor: AppColors.textFieldColor2,
                                              items: personalToolsList.isNotEmpty
                                                  ? personalToolsList.map((tool) {
                                                      return DropdownMenuItem<String>(
                                                        value: tool.name,
                                                        child: Text(tool.name),
                                                      );
                                                    }).toList()
                                                  : [
                                                      DropdownMenuItem<String>(
                                                        value: null,
                                                        child: Text(
                                                          'No tools available',
                                                          style: TextStyle(color: Colors.grey), // Optional styling for "No tools" message
                                                        ),
                                                      ),
                                                    ],
                                              onChanged: personalToolsList.isNotEmpty
                                                  ? (value) {
                                                      setState(() {
                                                        // Select existing tool and update weight
                                                        selectedTool = value;
                                                        final selectedGear = personalToolsList.firstWhere((tool) => tool.name == value);
                                                        toolWeightController.text = selectedGear.weight.toString();
                                                        toolNameController.text = selectedGear.name;
                                                        isHazmatTool = selectedGear.isHazmat; // Correctly update isHazmatTool
                                                      });
                                                    }
                                                  : null,
                                              // Disable dropdown if no tools are available
                                              style: TextStyle(
                                                color: AppColors.textColorPrimary,
                                                fontSize: AppData.text16,
                                              ),
                                            ),
                                            SizedBox(height: AppData.spacingStandard),
                                            if (selectedTool != null)
                                              TextField(
                                                controller: toolWeightController,
                                                enabled: false, // Non-editable field
                                                decoration: InputDecoration(
                                                  labelText: 'Tool Weight (lb)',
                                                  labelStyle: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16),
                                                  filled: true,
                                                  fillColor: AppColors.textFieldColor2,
                                                  disabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2), // Border for disabled state
                                                  ),
                                                ),
                                                style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16),
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppColors.cancelButton,
                                                fontSize: AppData.bottomDialogTextSize,
                                              ),
                                            ),
                                          ),
                                          if (selectedTool != null)
                                            TextButton(
                                              onPressed: () {
                                                addTool(); // Save tool logic
                                                Navigator.of(context).pop(); // Close current dialog
                                              },
                                              child: Text(
                                                'Add',
                                                style: TextStyle(
                                                  color: AppColors.saveButtonAllowableWeight,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: AppData.bottomDialogTextSize,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.toolBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black, // Black outline color
                                  width: 2.0, // Thickness of the outline
                                ),
                              ),
                              alignment: Alignment.center,
                              child:   Text(
                                '+ Add Tools',
                                style: TextStyle(
                                  fontSize: AppData.text22,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: AppData.spacingStandard),

                        // Display added tools
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                            child: ListView.builder(
                              itemCount: addedTools?.length,
                              itemBuilder: (context, index) {
                                final tool = addedTools?[index];
                                return Card(
                                  elevation: 4,
                                  color: AppColors.textFieldColor,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.borderPrimary, // Border color
                                        width: 2.0, // Border thickness
                                      ),
                                      borderRadius: BorderRadius.circular(12), // Rounded corners (optional)
                                    ),
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Text(
                                            tool!.name,
                                            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text20, fontWeight: FontWeight.bold),
                                          ),
                                          if (tool.isHazmat)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0), // Add spacing between text and icon
                                              child: Tooltip(
                                                message: 'HAZMAT', // The hint displayed on long-press
                                                waitDuration: const Duration(milliseconds: 500), // Time before the tooltip shows
                                                child: Icon(
                                                  FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                  color: Colors.red, // Red color for hazard
                                                  size: AppData.text18, // Icon size
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${tool.weight} lb',
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text20),
                                      ),
                                      trailing: IconButton(
                                        icon:   Icon(Icons.delete, color: Colors.red, size: AppData.text28),
                                        onPressed: () => removeTool(index),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Save Button
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                                onPressed: isSaveButtonEnabled ? () => saveCrewMemberData() : null, // Button is only enabled if there is input
                                style: style, // Main button theme
                                child: const Text('Save')),
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
      ),
    );
  }
}
