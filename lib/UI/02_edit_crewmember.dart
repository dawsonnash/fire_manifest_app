import 'dart:ui';

import 'package:fire_app/Data/saved_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../../Data/crew.dart';
import '../../Data/crewmember.dart';
import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/custom_position.dart';
import '../Data/gear.dart';

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
  String? weightErrorMessage;
  final FocusNode _weightFocusNode = FocusNode();

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
    final isFlightWeightChanged = int.tryParse(flightWeightController.text) != null &&
        int.parse(flightWeightController.text) > 0 &&
        int.parse(flightWeightController.text) < 500 &&
        int.parse(flightWeightController.text) != oldCrewMemberFlightWeight;

    // Updated position logic
    final bool wasUndefined = oldCrewMemberPosition == 26;
    final bool isNowDefined = (selectedPosition != null && selectedPosition != 26);
    final bool isPositionChanged = ((selectedPosition ?? -1) != oldCrewMemberPosition) || (wasUndefined && isNowDefined);

    final areToolsChanged = !compareLists(oldCrewMemberTools.cast<Gear>(), addedTools);

    setState(() {
      isSaveButtonEnabled = (isNameValid && isFlightWeightValid) &&
          (isNameChanged || isFlightWeightChanged || isPositionChanged || areToolsChanged);
    });
  }


  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveData() {
    // Get updated crew member name
    final String newCrewMemberName = nameController.text;
    final String originalCrewMemberName = widget.crewMember.name;
    final int originalCrewMemberPosition = widget.crewMember.position;

    // Check if new crew member name already exists
    bool crewMemberNameExists = crew.crewMembers.any(
      (member) => member.name.toLowerCase() == newCrewMemberName.toLowerCase() && member.name.toLowerCase() != originalCrewMemberName.toLowerCase(),
    );

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
      return;
    }

    widget.crewMember.name = nameController.text;
    widget.crewMember.flightWeight = int.parse(flightWeightController.text);
    widget.crewMember.position = selectedPosition ?? widget.crewMember.position; // Keep old position if not changed
    widget.crewMember.personalTools = List.from(addedTools ?? []);

    // Update the CrewMember in the preferences
    savedPreferences.updateCrewMemberInPreferences(originalCrewMemberName, originalCrewMemberPosition, widget.crewMember);

    final key = crewmemberBox.keys.firstWhere(
      (key) => crewmemberBox.get(key) == widget.crewMember,
      orElse: () => null,
    );

    if (key != null) {
      crewmemberBox.put(key, widget.crewMember);
    } else {
      crewmemberBox.add(widget.crewMember);
    }

    crew.updateTotalCrewWeight();

    // Callback to update UI
    widget.onUpdate();

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Crew Member Updated!',
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

    Navigator.of(context).pop();
  }

  Future<void> _showAddNewPositionDialog() async {
    TextEditingController newPositionController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Add New Position',
                style: TextStyle(
                  color: AppColors.textColorPrimary,
                  fontSize: AppData.miniDialogTitleTextSize,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPositionController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: InputDecoration(
                      errorText: errorMessage,
                      errorStyle: TextStyle(
                        fontSize: AppData.errorText,
                        color: Colors.red,
                      ),
                      hintText: "Enter Position Name",
                      hintStyle: TextStyle(
                        color: AppColors.textColorPrimary,
                        fontSize: AppData.miniDialogBodyTextSize,
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.miniDialogBodyTextSize,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppColors.cancelButton,
                      fontSize: AppData.bottomDialogTextSize,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    String newTitle = newPositionController.text.trim();

                    if (newTitle.isEmpty) {
                      setDialogState(() {
                        errorMessage = "Cannot be empty";
                      });
                      return;
                    }

                    bool alreadyExists = positionMap.values.any((val) => val.toLowerCase() == newTitle.toLowerCase()) ||
                        Hive.box<CustomPosition>('customPositionsBox')
                            .values
                            .any((pos) => pos.title.toLowerCase() == newTitle.toLowerCase());

                    if (alreadyExists) {
                      setDialogState(() {
                        errorMessage = "Position already exists";
                      });
                      return;
                    }

                    await CustomPosition.addPosition(newTitle);
                    Navigator.of(context).pop();
                    // Show successful save popup
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            'Position Saved!',
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
                      name: 'custom_position_added',
                      parameters: {
                        'position_title': newTitle,
                      },
                    );
                  },
                  child: Text(
                    "Add",
                    style: TextStyle(
                      color: AppColors.saveButtonAllowableWeight,
                      fontSize: AppData.bottomDialogTextSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePosition(int code, String title) async {
    List<String> affectedCrew = crew.crewMembers
        .where((member) => member.position == code)
        .map((member) => member.name)
        .toList();

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Delete Position',
            style: TextStyle(
              color: AppColors.textColorPrimary,
              fontSize: AppData.miniDialogTitleTextSize,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (affectedCrew.isNotEmpty) ...[
                  Text(
                    'Cannot delete "$title" while it is assigned to the following crew member(s):',
                    style: TextStyle(
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.miniDialogBodyTextSize,
                    ),
                  ),
                  SizedBox(height: AppData.sizedBox8),
                  ...affectedCrew.map((name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '- $name',
                      style: TextStyle(
                        color: AppColors.textColorPrimary,
                        fontSize: AppData.miniDialogBodyTextSize,
                      ),
                    ),
                  )),
                  SizedBox(height: AppData.sizedBox10),
                  Text(
                    'Please update these crew members to a different position before deleting.',
                    style: TextStyle(
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.miniDialogBodyTextSize,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Are you sure you want to delete "$title"?',
                    style: TextStyle(
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.miniDialogBodyTextSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppColors.cancelButton,
                  fontSize: AppData.bottomDialogTextSize,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            if (affectedCrew.isEmpty)
              TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: AppData.bottomDialogTextSize,
                  ),
                ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    Navigator.of(context).pop();
                    // Show successful deletion popup
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            'Position Deleted!',
                            // Maybe change look
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppData.text32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.red,
                      ),
                    );
                    FirebaseAnalytics.instance.logEvent(
                      name: 'custom_position_deleted',
                      parameters: {
                        'position_title': title,
                      },
                    );
                  }
              ),
          ],
        );
      },
    ).then((confirm) async {
      if (confirm == true) {
        await CustomPosition.deletePosition(code);
        widget.onUpdate();
        setState(() {});
      }
    });
  }

  void _showPositionSelector() {
    TextEditingController searchController = TextEditingController();
    List<MapEntry<int, String>> allPositions = [
      ...positionMap.entries.where((entry) => entry.key != 26),
      ...Hive.box<CustomPosition>('customPositionsBox').values.map((custom) => MapEntry(custom.code, custom.title))
    ];

    List<MapEntry<int, String>> filteredPositions = List.from(allPositions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.textFieldColor2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void _filterPositions(String query) {
              setState(() {
                filteredPositions = allPositions
                    .where((entry) => entry.value.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,  // Keep modal 75% screen height
                  child: Column(
                    children: [

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: searchController,
                          onChanged: _filterPositions,
                          decoration: InputDecoration(
                            hintText: 'Search positions...',
                            filled: true,
                            fillColor: AppColors.textFieldColor,
                            prefixIcon: Icon(Icons.search, size: AppData.text18, color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                            ),
                            hintStyle: TextStyle(
                              color: AppColors.textColorPrimary.withOpacity(0.5),
                              fontSize: AppData.text20,
                            ),
                          ),
                          style: TextStyle(
                            color: AppColors.textColorPrimary,
                            fontSize: AppData.text22,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            children: [

                              ...filteredPositions.map((entry) {
                                bool isCustom = entry.key < 0;
                                return ListTile(
                                  title: Text(
                                    entry.value,
                                    style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                  ),
                                  trailing: isCustom
                                      ? IconButton(
                                    icon: Icon(Icons.delete, size: AppData.text22, color: Colors.red),
                                    onPressed: () => _confirmDeletePosition(entry.key, entry.value),
                                  )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      selectedPosition = entry.key;
                                      _checkInput();
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              }),

                              Divider(),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '+ Add New',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppData.text22,
                                        color: Colors.black,
                                      ),
                                    ),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _showAddNewPositionDialog();
                                      setState(() {});
                                    },
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
              ),
            );
          },
        );
      },
    );
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
        title: Text(
          'Edit Crew Member',
          style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppData.bottomModalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete Crew Member',
                              style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.modalTextSize),
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
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
                                    ),
                                    content: Text(
                                      'This crew member data ($oldCrewMemberName) and any positional preference data containing them will be erased!',
                                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog without deleting
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
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: AppData.text32,
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
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
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

                        // Edit Flight Weight
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
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(3),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.number,
                                // Only show numeric keyboard
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
                                  labelText: 'Edit flight weight',
                                  labelStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text22,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                  errorText: weightErrorMessage,
                                  errorStyle: TextStyle(
                                    fontSize: AppData.errorText,
                                    color: Colors.red,
                                  ),
                                  hintText: 'Up to 500 lb',
                                  hintStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text20, // Optional: Customize hint text size
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFieldColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.textFieldColor,
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
                            child: GestureDetector(
                              onTap: () => _showPositionSelector(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  selectedPosition != null
                                      ? getPositionTitleFromCode(selectedPosition!)
                                      : 'Primary Position',
                                  style: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text22,
                                  ),
                                ),
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
                                        title: Text(
                                          '+ Add Personal Tool',
                                          style: TextStyle(fontSize: AppData.text20, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            DropdownButtonFormField<String>(
                                              value: personalToolsList.isNotEmpty ? selectedTool : null, // Set to null if no tools are available
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
                                                        newToolWeightController.text = selectedGear.weight.toString();
                                                        newToolNameController.text = selectedGear.name;
                                                        isHazmatTool = selectedGear.isHazmat; // Correctly update isHazmatTool
                                                      });
                                                    }
                                                  : null, // Disable dropdown if no tools are available
                                              style: TextStyle(
                                                color: AppColors.textColorPrimary,
                                                fontSize: AppData.text16,
                                              ),
                                            ),
                                            SizedBox(height: AppData.spacingStandard),
                                            if (selectedTool != null)
                                              TextField(
                                                controller: newToolWeightController,
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
                              child: Text(
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
