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

    // Initialize crewmemberBox variable here
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

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
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.9),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
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
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                  //fontWeight: FontWeight.bold,
                                ),
                                hintText: 'Up to 500 lbs',
                                hintStyle: const TextStyle(
                                  color: Colors.grey, // Optional: Customize the hint text color
                                  fontSize: 20, // Optional: Customize hint text size
                                  fontStyle: FontStyle.italic, // Optional: Italicize the hint
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.9),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
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
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedPosition,
                                dropdownColor: Colors.black,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                ),
                                iconEnabledColor: Colors.white,
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

                        // Enter tool(s) & weight
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16.0, right: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: newToolNameController,
                                  maxLength: 12,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'Tool Name',
                                    labelStyle: const TextStyle(color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.9),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.black, width: 2.0),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white, fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: newToolWeightController,
                                  maxLength: 2,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    labelText: 'Tool Weight',
                                    labelStyle: const TextStyle(color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic),
                                    hintText: 'Up to 99 lbs',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey, // Optional: Customize the hint text color
                                      fontSize: 20, // Optional: Customize hint text size
                                      fontStyle: FontStyle.italic, // Optional: Italicize the hint
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.9),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.black, width: 2.0),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white, fontSize: 28),
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.black, size: 24),
                                ),
                                onPressed: addTool,
                              ),
                            ],
                          ),
                        ),

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
                                  color: Colors.black,
                                  child: ListTile(
                                    title: Text(
                                      tool!.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${tool.weight} lbs',
                                      style: const TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                      onPressed: () {
                                        removeTool(index);
                                        _checkInput();
                                      },
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
                                        content: Text('This crew member data ($oldCrewMemberName) will be erased!',
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
