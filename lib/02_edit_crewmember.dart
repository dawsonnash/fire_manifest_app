import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'CodeShare/colors.dart';
import 'Data/gear.dart';

class EditCrewmember extends StatefulWidget {
  // This page requires a crewmember to be passed to it - to edit it
  final CrewMember crewMember;
  final VoidCallback onUpdate; // Callback for deletion to update previous page

  const EditCrewmember({
    super.key,
    required this.crewMember,
    required this.onUpdate,
  });

  @override
  State<EditCrewmember> createState() => _EditCrewmemberState();
}

class _EditCrewmemberState extends State<EditCrewmember> {

  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];

  // Variables to store user input
  late TextEditingController nameController;
  late TextEditingController flightWeightController;

  late List<TextEditingController> toolNameControllers = [];
  late List<TextEditingController> toolWeightControllers = [];
  late TextEditingController newToolNameController;
  late TextEditingController newToolWeightController;
  late bool isHazmatTool;
  int? selectedPosition;
  List<Gear>? addedTools = [];

  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

  // Store old CrewMember info for ensuring user only can save if they change data
  late String oldCrewMemberName;
  late int oldCrewMemberFlightWeight;
  late int oldCrewMemberPosition;
  late List oldCrewMemberTools = List.from(widget.crewMember.personalTools ?? []); // Store old tools

  // initialize HiveBox for crewmember
  late final Box<CrewMember> crewmemberBox;

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    // Initialize crewmemberBox variable here
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    loadPersonalToolsList();

    // Set default isHazmatTool value
    if (personalToolsList.isNotEmpty) {
      isHazmatTool = personalToolsList.first.isHazmat; // Initialize from the first tool in the list
    } else {
      isHazmatTool = false; // Default to false if the list is empty
    }

    // Initializing the controllers with the current crew member's data to be edited
    nameController = TextEditingController(text: widget.crewMember.name);
    flightWeightController = TextEditingController(text: widget.crewMember.flightWeight.toString());
    selectedPosition = widget.crewMember.position; // Set initial position
    // Initialize tool controllers with each of the existing tools
    widget.crewMember.personalTools?.forEach((gearItem) {
      toolNameControllers.add(TextEditingController(text: gearItem.name));
      toolWeightControllers.add(TextEditingController(text: gearItem.weight.toString()));
    });

    // Store original crewmember data
    oldCrewMemberName = widget.crewMember.name;
    oldCrewMemberFlightWeight = widget.crewMember.flightWeight;
    oldCrewMemberPosition = widget.crewMember.position;

    // Listeners to the TextControllers
    nameController.addListener(_checkInput);
    flightWeightController.addListener(_checkInput);
    toolNameControllers.forEach((controller) => controller.addListener(_checkInput));
    toolWeightControllers.forEach((controller) => controller.addListener(_checkInput));

    // Initialize separate controllers for adding new tools
    newToolNameController = TextEditingController();
    newToolWeightController = TextEditingController();
    newToolNameController.addListener(_checkInput);
    newToolWeightController.addListener(_checkInput);

    addedTools = List.from(widget.crewMember.personalTools ?? []);
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
    toolNameControllers.forEach((controller) => controller.dispose());
    toolWeightControllers.forEach((controller) => controller.dispose());
    newToolNameController.dispose();
    newToolWeightController.dispose();
    super.dispose();
  }

  void addTool() {
    final String toolName = newToolNameController.text;
    final int toolWeight = int.parse(newToolWeightController.text);

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
        const SnackBar(
          content: Center(
            child: Text(
              'Tool Already Added',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black),
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
      newToolNameController.clear();
      newToolWeightController.clear();
      setState(() {});
    });
  }

  void removeTool(int index) {
    setState(() {
      addedTools?.removeAt(index);
      _checkInput();
    });
  }

  // Function to check if input is valid and update button state
  bool compareLists(List<Gear>? list1, List<Gear>? list2) {
    if (list1 == null && list2 == null) return true; // Both are null, so they are the same
    if (list1 == null || list2 == null) return false; // One is null, the other isn't
    if (list1.length != list2.length) return false; // Different lengths, so they are different

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].name != list2[i].name || list1[i].weight != list2[i].weight) {
        return false; // Lists differ
      }
    }
    return true; // Lists are the same
  }

  void _checkInput() {
    final isNameValid = nameController.text.isNotEmpty;
    final isFlightWeightValid = flightWeightController.text.isNotEmpty && int.tryParse(flightWeightController.text) != null;
    final isNameChanged = nameController.text != oldCrewMemberName;
    final isFlightWeightChanged =
        int.tryParse(flightWeightController.text) != null && // Ensure valid input
            int.parse(flightWeightController.text) > 0 &&       // Greater than zero
            int.parse(flightWeightController.text) < 500 &&     // Less than 500
            int.parse(flightWeightController.text) != oldCrewMemberFlightWeight;
    final isPositionChanged = (selectedPosition ?? -1) != oldCrewMemberPosition; // Assuming -1 as an invalid/initial value

    final areToolsChanged = !compareLists(oldCrewMemberTools.cast<Gear>(), addedTools);

    setState(() {
      isSaveButtonEnabled = (isNameValid && isFlightWeightValid) && (isNameChanged || isFlightWeightChanged || isPositionChanged || areToolsChanged);
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveData() {
    // Get updated crew member name
    final String newCrewMemberName = nameController.text;
    final String originalCrewMemberName = widget.crewMember.name;

    // Check if new crew member name already exists
    bool crewMemberNameExists = crew.crewMembers.any(
          (member) => member.name.toLowerCase() == newCrewMemberName.toLowerCase() &&
          member.name.toLowerCase() != originalCrewMemberName.toLowerCase(),
    );

    if (crewMemberNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Crew member name already used!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Update crew member details
    widget.crewMember.name = nameController.text;
    widget.crewMember.flightWeight = int.parse(flightWeightController.text);
    widget.crewMember.position = selectedPosition ?? widget.crewMember.position; // Keep old position if not changed

    // ✅ Directly update `personalTools` with `addedTools`
    widget.crewMember.personalTools = List.from(addedTools ?? []);

    // ✅ Update Hive with the new list of tools
    final key = crewmemberBox.keys.firstWhere(
          (key) => crewmemberBox.get(key) == widget.crewMember,
      orElse: () => null,
    );

    if (key != null) {
      crewmemberBox.put(key, widget.crewMember);
    } else {
      crewmemberBox.add(widget.crewMember);
    }

    // ✅ Ensure the total crew weight is updated
    crew.updateTotalCrewWeight();

    // Callback to update UI
    widget.onUpdate();

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Crew Member Updated!',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    // ✅ Navigate back to previous screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10));
    // Black style input field decoration

    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        title:  Text(
          'Edit Crew Member',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete Crew Member',
                            style: TextStyle(color: AppColors.textColorPrimary),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Close the dialog without deleting

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2,
                                  title: Text(
                                    'Confirm Deletion',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                  ),
                                  content: Text(
                                    'This crew member data ($oldCrewMemberName) and any positional preference data containing them will be erased!',
                                    style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog without deleting

                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: AppColors.cancelButton),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Remove item from the Hive box
                                        final keyToRemove = crewmemberBox.keys.firstWhere(
                                              (key) => crewmemberBox.get(key) == widget.crewMember,
                                          orElse: () => null,
                                        );

                                        if (keyToRemove != null) {
                                          crewmemberBox.delete(keyToRemove);
                                        }

                                        // Remove the crew member
                                        crew.removeCrewMember(widget.crewMember);

                                        widget.onUpdate(); // Callback function to update UI with new data

                                        // Show deletion pop-up
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Center(
                                              child: Text(
                                                '$oldCrewMemberName Deleted!',
                                                // Maybe change look
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            duration: Duration(seconds: 2),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        Navigator.of(context).pop(); // Dismiss the dialog
                                        Navigator.of(context).pop(); // Return to previous screen
                                      },

                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textColorPrimary,
              ))
        ],
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
                        // Edit Name
                        Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                            child: TextField(
                              controller: nameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(23),
                              ],
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Edit name',
                                labelStyle: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 28,
                              ),
                            )),

                        SizedBox(height: AppData.spacingStandard),

                        // Edit Flight Weight
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                            child: TextField(
                              controller: flightWeightController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(3),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              // Only show numeric keyboard

                              decoration: InputDecoration(
                                labelText: 'Edit flight weight',
                                labelStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                hintText: 'Up to 500 lbs',
                                hintStyle: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 20, // Optional: Customize hint text size
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.textFieldColor,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 28,
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
                                value: selectedPosition,
                                dropdownColor: AppColors.textFieldColor2,
                                style:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
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
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              String? selectedTool = personalToolsList.isNotEmpty ? personalToolsList.first.name : null; // Default to first tool
                              newToolWeightController.text = personalToolsList.isNotEmpty ? personalToolsList.first.weight.toString() : '';
                              newToolNameController.text = personalToolsList.isNotEmpty ? personalToolsList.first.name : '';

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return AlertDialog(
                                        backgroundColor: AppColors.textFieldColor2,
                                        title:  Text(
                                          '+ Add Personal Tool',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            DropdownButtonFormField<String>(
                                              value: personalToolsList.isNotEmpty ? selectedTool : null, // Set to null if no tools are available
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
                                                  newToolWeightController.text = selectedGear.weight.toString();
                                                  newToolNameController.text = selectedGear.name;
                                                  isHazmatTool = selectedGear.isHazmat; // Correctly update isHazmatTool
                                                });
                                              }
                                                  : null, // Disable dropdown if no tools are available
                                              style: TextStyle(
                                                color: AppColors.textColorPrimary,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: AppData.spacingStandard),
                                            if (selectedTool != null)
                                              TextField(
                                                controller: newToolWeightController,
                                                enabled: false, // Non-editable field
                                                decoration: InputDecoration(
                                                  labelText: 'Tool Weight (lbs)',
                                                  labelStyle: TextStyle(color: AppColors.textColorPrimary),
                                                  filled: true,
                                                  fillColor: AppColors.textFieldColor2,
                                                  disabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: AppColors.textColorPrimary, width: 2), // Border for disabled state
                                                  ),
                                                ),
                                                style:  TextStyle(
                                                    color: AppColors.textColorPrimary,
                                                    fontSize: 16
                                                ),
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child:  Text(
                                              'Cancel',
                                              style: TextStyle(color: AppColors.cancelButton),
                                            ),
                                          ),
                                          if (selectedTool != null)
                                            TextButton(
                                              onPressed: () {
                                                addTool(); // Save tool logic
                                                Navigator.of(context).pop(); // Close current dialog
                                              },
                                              child:  Text(
                                                'Add',
                                                style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontWeight: FontWeight.bold),                                              ),
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
                              child:  Text(
                                '+ Add Tools',
                                style: TextStyle(
                                  fontSize: 22,
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
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                            child: ListView.builder(
                              itemCount: addedTools?.length,
                              itemBuilder: (context, index) {
                                final tool = addedTools?[index];
                                return Card(
                                  elevation: 4,
                                  color: AppColors.textFieldColor,
                                  child: Container(
                                    decoration: BoxDecoration(
                                    color: AppColors.textFieldColor, // Background color (optional)
                                    border: Border.all(
                                      color: AppColors.borderPrimary, // Border color
                                      width: 2.0,          // Border thickness
                                    ),
                                    borderRadius: BorderRadius.circular(12), // Rounded corners (optional)
                                  ),

                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Text(
                                            tool!.name,
                                            style:  TextStyle(color: AppColors.textColorPrimary, fontSize: 20, fontWeight: FontWeight.bold),
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
                                                  size: 18, // Icon size
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${tool.weight} lbs',
                                        style:  TextStyle(color: AppColors.textColorPrimary, fontSize: 20),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                        onPressed: () {
                                          removeTool(index);
                                          _checkInput();
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Save Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                  onPressed: isSaveButtonEnabled ? () => saveData() : null, // Button is only enabled if there is input
                                  style: style, // Main button theme
                                  child: const Text('Save')),
                              const Spacer(),
                            ],
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

