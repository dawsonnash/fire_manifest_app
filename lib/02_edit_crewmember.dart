import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import 'package:hive/hive.dart';

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
    final int? toolWeight = int.tryParse(newToolWeightController.text);

    if (toolName.isNotEmpty && toolWeight != null && toolWeight > 0) {
      setState(() {
        addedTools?.add(Gear(name: toolName, weight: toolWeight, quantity: 1, isPersonalTool: true));
        toolNameControllers.add(TextEditingController(text: toolName));
        toolWeightControllers.add(TextEditingController(text: toolWeight.toString()));
        newToolNameController.clear();
        newToolWeightController.clear();
      });
      _checkInput(); // Call _checkInput() to update the button state
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Enter all/correct tool info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black),
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void removeTool(int index) {
    setState(() {
      addedTools?.removeAt(index);
      toolNameControllers[index].dispose();
      toolWeightControllers[index].dispose();
      toolNameControllers.removeAt(index);
      toolWeightControllers.removeAt(index);
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

    // Check if new crew member name already exists in the crew list, but ignore current crew member's original name
    bool crewMemberNameExists = crew.crewMembers.any(
      (member) => member.name == newCrewMemberName && member.name != originalCrewMemberName,
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
      return; // Exit function if the crew member name is already used
    }

    // Update exisiting data
    widget.crewMember.name = nameController.text;
    widget.crewMember.flightWeight = int.parse(flightWeightController.text);
    widget.crewMember.position = selectedPosition!; // Update position

    // Update all personal tools
    List<Gear> updatedTools = addedTools?.asMap().entries.map((entry) {
          return Gear(
              name: toolNameControllers[entry.key].text,
              weight: int.parse(toolWeightControllers[entry.key].text),
              quantity: 1, // To be changed
              isPersonalTool: true);
        }).toList() ??
        [];
    widget.crewMember.personalTools = updatedTools;

    // Find the key for this item, if it's not a new item, update it in Hive
    final key = crewmemberBox.keys.firstWhere(
      (key) => crewmemberBox.get(key) == widget.crewMember,
      orElse: () => null,
    );
    if (key != null) {
      // Update existing Hive item
      crewmemberBox.put(key, widget.crewMember);
    } else {
      // Add new item to Hive
      crewmemberBox.add(widget.crewMember);
    }
    crew.updateTotalCrewWeight();
    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Crew Member Updated!',
            // Maybe change look
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
    Navigator.of(context).pop(); // Return to previous screen
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
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Edit Crew Member',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      // Blur effect
                      child: Image.asset(
                        'assets/images/logo1.png',
                        fit: BoxFit.cover, // Cover  entire background
                        width: double.infinity,
                        height: double.infinity,
                      )),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Edit Name
                        Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 4.0, left: 16.0, right: 16.0),
                            child: TextField(
                              controller: nameController,
                              maxLength: 12,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Edit name',
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                              ),
                            )),

                        // Edit Flight Weight
                        Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
                            child: TextField(
                              controller: flightWeightController,
                              maxLength: 3,
                              keyboardType: TextInputType.number,
                              // Only show numeric keyboard
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                // Allow only digits
                              ],
                              decoration: InputDecoration(
                                labelText: 'Edit flight weight',
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                hintText: 'Up to 500 lbs',
                                hintStyle: const TextStyle(
                                  color: Colors.black, // Optional: Customize the hint text color
                                  fontSize: 20, // Optional: Customize hint text size
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                              ),
                            )),

                        // Enter Position(s)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 16.0, right: 16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.black, width: 2.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedPosition,
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                ),
                                iconEnabledColor: Colors.black,
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

                        SizedBox(height: 16),

                        // Enter tool(s) & weight
                        Padding(
                          padding: const EdgeInsets.all(16.0),
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
                                        backgroundColor: Colors.white,
                                        title: const Text(
                                          '+ Add Personal Tool',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            DropdownButtonFormField<String>(
                                              value: selectedTool,
                                              decoration: InputDecoration(
                                                labelText: 'Select a Tool',
                                                filled: true,
                                                fillColor: Colors.grey[200],
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                                                ),
                                              ),
                                              items: [
                                                ...personalToolsList.map((tool) {
                                                  return DropdownMenuItem<String>(
                                                    value: tool.name,
                                                    child: Text(tool.name),
                                                  );
                                                }),
                                                const DropdownMenuItem<String>(
                                                  value: '+ Add/Edit Tool',
                                                  child: Text('+ Add/Edit Tool'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value == '+ Add/Edit Tool') {
                                                    // Open dialog to add a new tool
                                                    Navigator.of(context).pop(); // Close current dialog
                                                    _showAddToolDialog(
                                                        context, setState, newToolNameController, newToolWeightController, personalToolsList, addedTools, personalToolsBox); // Show Add Tool dialog
                                                  } else {
                                                    // Select existing tool and update weight
                                                    selectedTool = value;
                                                    newToolWeightController.text = personalToolsList.firstWhere((tool) => tool.name == value).weight.toString();
                                                    newToolNameController.text = personalToolsList.firstWhere((tool) => tool.name == value).name;
                                                  }
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            if (selectedTool != null && selectedTool != '+ Add/Edit Tool')
                                              TextField(
                                                controller: newToolWeightController,
                                                enabled: false, // Non-editable field
                                                decoration: InputDecoration(
                                                  labelText: 'Tool Weight (lbs)',
                                                  filled: true,
                                                  fillColor: Colors.grey[200],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                          if (selectedTool != null && selectedTool != '+ Add/Edit Tool')
                                            TextButton(
                                              onPressed: () {
                                                addTool(); // Save tool logic
                                                Navigator.of(context).pop(); // Close current dialog
                                              },
                                              child: const Text(
                                                'Add',
                                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black, // Black outline color
                                  width: 2.0, // Thickness of the outline
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '+ Add/Edit Tools',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

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
                                  color: Colors.white,
                                  child: Container(
                                    decoration: BoxDecoration(
                                    color: Colors.white, // Background color (optional)
                                    border: Border.all(
                                      color: Colors.black, // Border color
                                      width: 2.0,          // Border thickness
                                    ),
                                    borderRadius: BorderRadius.circular(12), // Rounded corners (optional)
                                  ),

                                    child: ListTile(
                                      title: Text(
                                        tool!.name,
                                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${tool.weight} lbs',
                                        style: const TextStyle(color: Colors.black, fontSize: 20),
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
                              const Spacer(flex: 2),
                              ElevatedButton(
                                  onPressed: isSaveButtonEnabled ? () => saveData() : null, // Button is only enabled if there is input
                                  style: style, // Main button theme
                                  child: const Text('Save')),
                              const Spacer(flex: 1),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 32),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Delete $oldCrewMemberName?',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        content: Text('This crew member data ($oldCrewMemberName) and any positional preference data containing them will be erased!',
                                            style: const TextStyle(
                                              fontSize: 18,
                                            )),
                                        actions: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Dismiss the dialog
                                                },
                                                child: const Text('Cancel',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                    )),
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
                                                child: const Text('OK',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              )
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
void _showAddToolDialog(
    BuildContext context,
    StateSetter parentSetState,
    TextEditingController toolNameController,
    TextEditingController toolWeightController,
    List<Gear> personalToolsList,
    List<Gear>? addedTools,
    Box<Gear> personalToolsBox, // Pass the Hive box
    ) {
  String? selectedTool = '+ New Tool'; // Default to "+ New Tool"
  String? toolNameErrorMessage;
  String? toolWeightErrorMessage;

  // Function to update fields based on selected tool
  void updateFields(String? toolName) {
    if (toolName != null && toolName != '+ New Tool') {
      final tool = personalToolsList.firstWhere((tool) => tool.name == toolName);
      toolNameController.text = tool.name;
      toolWeightController.text = tool.weight.toString();
    } else {
      toolNameController.clear();
      toolWeightController.clear();
    }
  }

  // Pre-fill fields initially
  updateFields(selectedTool);

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter dialogSetState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Add/Edit Tool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTool,
                  decoration: InputDecoration(
                    labelText: 'Select a Tool',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                  ),
                  items: [
                    ...personalToolsList.map((tool) {
                      return DropdownMenuItem<String>(
                        value: tool.name,
                        child: Text(tool.name),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: '+ New Tool',
                      child: Text('+ New Tool'),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Edit Tool Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: toolNameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 12,
                  decoration: InputDecoration(
                    labelText: 'Tool Name',
                    filled: true,
                    fillColor: Colors.grey[200],
                    errorText: toolNameErrorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: toolWeightController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Tool Weight (lbs)',
                    filled: true,
                    fillColor: Colors.grey[200],
                    errorText: toolWeightErrorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close only this dialog
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
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
                            title: const Text('Confirm Deletion'),
                            content: Text(
                              'The tool "$selectedTool" will be removed from all crew members who have it. Do you want to proceed?',
                              style: const TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the confirmation dialog
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Proceed with deletion
                                  // Delete from Hive and temporary page list and from addedTools if it exists
                                  crew.removePersonalTool(selectedTool!);
                                  personalToolsList.removeWhere((tool) => tool.name == selectedTool); // Remove from global tools
                                  addedTools?.removeWhere((tool) => tool.name == selectedTool); // Remove from addedTools
                                  // Iterate through all crew members and remove the tool from their personalTools list
                                  for (var crewMember in crew.crewMembers) {
                                    crewMember.personalTools?.removeWhere((tool) => tool.name == selectedTool);
                                  }

                                  // Close the confirmation dialog and the main dialog
                                  Navigator.of(context).pop(); // Close confirmation dialog
                                  Navigator.of(dialogContext).pop(); // Close main dialog

                                  // Update parent state
                                  parentSetState(() {});
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

                    final weight = int.parse(toolWeightText);

                    // Create new tool
                    final newTool = Gear(name: toolName, weight: weight, quantity: 1, isPersonalTool: true);

                    // Add to Hive and temporary page list
                    crew.addPersonalTool(newTool);
                    personalToolsList.add(newTool);

                    Navigator.of(dialogContext).pop(); // Close dialog
                    parentSetState(() {}); // Reflect changes in the parent state
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

                    if (existingTool != null && toolNameRaw.toLowerCase() == existingTool.name.toLowerCase() && int.parse(toolWeightText) == existingTool.weight) {
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
                          title: const Text('Confirm Update'),
                          content: Text(
                            'Updating $selectedTool will modify this tool for all crew members who have it, and will update it in your gear inventory if it exists. Do you want to proceed?',
                            style: const TextStyle(fontSize: 16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(confirmationContext).pop(); // Close the confirmation dialog
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
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
                                    ),
                                  );
                                }

                                // Update the tool in personalToolsList
                                final tool = personalToolsList.firstWhere(
                                      (tool) => tool.name.toLowerCase() == selectedTool!.toLowerCase(),
                                );
                                tool.name = toolNameRaw;
                                tool.weight = int.parse(toolWeightText);

                                // Update the tool in all crew members who have it
                                for (var crewMember in crew.crewMembers) {
                                  if (crewMember.personalTools != null) {
                                    for (var personalTool in crewMember.personalTools!) {
                                      if (personalTool.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                        personalTool.name = toolNameRaw;
                                        personalTool.weight = int.parse(toolWeightText);
                                      }
                                    }
                                  }
                                }
                                // Update the tool in all gear items
                                for (var gearItems in crew.gear) {
                                  if (gearItems.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                    gearItems.name = toolNameRaw;
                                    gearItems.weight = int.parse(toolWeightText);
                                  }
                                }

                                // Update the tool in addedTools
                                if (addedTools != null) {
                                  for (var tool in addedTools) {
                                    if (tool.name.toLowerCase() == selectedTool!.toLowerCase()) {
                                      tool.name = toolNameRaw;
                                      tool.weight = int.parse(toolWeightText);
                                    }
                                  }
                                }

                                Navigator.of(dialogContext).pop(); // Close the main dialog
                                parentSetState(() {}); // Reflect changes in the parent state
                                Navigator.of(dialogContext).pop(); // Close the main dialog
                              },
                              child: const Text(
                                'Update',
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
                  'Save',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
