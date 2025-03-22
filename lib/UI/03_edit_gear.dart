import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../CodeShare/functions.dart';
import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/gear.dart';
import '../Data/saved_preferences.dart';

class EditGear extends StatefulWidget {
  // THis page requires a gear item to be passed to it - to edit it
  final Gear gear;
  final VoidCallback onUpdate; // Callback for deletion to update previous page

  const EditGear({
    super.key,
    required this.gear,
    required this.onUpdate,
  });

  @override
  State<EditGear> createState() => _EditGearState();
}

class _EditGearState extends State<EditGear> {
  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];
  String? weightErrorMessage;
  String? quantityErrorMessage;

  // Variables to store user input
  late TextEditingController gearNameController;
  late TextEditingController gearWeightController;
  late TextEditingController gearQuantityController;
  late bool newHazmatValue;
  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

  // Store old gear info for ensuring user only can save if they change data
  late String oldGearName;
  late int oldGearWeight;
  late int oldGearQuantity;
  late bool oldGearHazmatValue;

  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();

  // initialize HiveBox for Gear
  late final Box<Gear> gearBox;

  @override
  void initState() {
    super.initState();

    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    gearBox = Hive.box<Gear>('gearBox');

    loadPersonalToolsList();

    // Initializing the controllers with the current gears data to be edited
    gearNameController = TextEditingController(text: widget.gear.name);
    gearWeightController = TextEditingController(text: widget.gear.weight.toString());
    gearQuantityController = TextEditingController(text: widget.gear.quantity.toString());
    newHazmatValue = widget.gear.isHazmat;

    // Store original gear data
    oldGearName = widget.gear.name;
    oldGearWeight = widget.gear.weight;
    oldGearQuantity = widget.gear.quantity;
    oldGearHazmatValue = widget.gear.isHazmat;

    // Listeners to the TextControllers
    gearNameController.addListener(_checkInput);
    gearWeightController.addListener(_checkInput);
    gearQuantityController.addListener(_checkInput);
  }

  // Function to load the list of tool items from the Hive box
  void loadPersonalToolsList() {
    setState(() {
      personalToolsList = personalToolsBox.values.toList();
    });
  }

  @override
  void dispose() {
    gearNameController.dispose();
    gearWeightController.dispose();
    gearQuantityController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isNameValid = gearNameController.text.isNotEmpty;
    final isGearWeightValid =
        gearWeightController.text.isNotEmpty && int.tryParse(gearWeightController.text) != null && int.parse(gearWeightController.text) > 0 && int.parse(gearWeightController.text) <= 500;
    final isNameChanged = gearNameController.text != oldGearName;
    final isGearWeightChanged = gearWeightController.text != oldGearWeight.toString();
    final isGearQuantityValid =
        gearQuantityController.text.isNotEmpty && int.tryParse(gearQuantityController.text) != null && int.parse(gearQuantityController.text) >= 1 && int.parse(gearQuantityController.text) < 100;
    final isGearQuantityChanged = gearQuantityController.text != oldGearQuantity.toString();
    final isGearHazmatValueChanged = newHazmatValue != oldGearHazmatValue;

    setState(() {
      // Need to adjust for position as well
      // Only enables saving if name is changed and is not empty
      isSaveButtonEnabled = (isNameValid && isGearWeightValid && isGearQuantityValid) && (isNameChanged || isGearWeightChanged || isGearQuantityChanged || isGearHazmatValueChanged);
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveData() {
    // Get  updated gear name from the TextField
    final String newGearName = gearNameController.text;
    final String originalGearName = widget.gear.name;
    final String newGearQuantity = gearQuantityController.text;
    final String capitalizedGearName = capitalizeEveryWord(newGearName);

    // Check if the new gear name already exists in the crew's gear list,
    // but ignore the current gear's original name
    bool gearNameExists = crew.gear.any(
      (gear) => gear.name.toLowerCase() == newGearName.toLowerCase() && gear.name.toLowerCase() != originalGearName.toLowerCase(),
    );

    bool personalToolExists = personalToolsList.any((gear) => gear.name.toLowerCase() == newGearName.toLowerCase());

    bool onlyQuantityChanged = (oldGearName.toLowerCase() == newGearName.toLowerCase()) && (oldGearHazmatValue == newHazmatValue) && (oldGearQuantity.toString() != newGearQuantity);
    final matchingTool = personalToolsList.firstWhereOrNull(
      (tool) => tool.name.toLowerCase() == newGearName.toLowerCase(),
    );

    final bool weightMatches = matchingTool?.weight == int.tryParse(gearWeightController.text);
    final bool hazmatMatches = matchingTool?.isHazmat == newHazmatValue;
    final bool matchesPersonalToolValues = weightMatches && hazmatMatches;

    if (personalToolExists && !onlyQuantityChanged && !gearNameExists && !matchesPersonalToolValues) {
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
              '$capitalizedGearName also exists as a tool. Any gear that is also a personal tool can be added to your gear inventory, but it must be of the same weight (${matchingTool?.weight} lb) and HAZMAT value (${matchingTool?.isHazmat}).',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                ),
              ),
            ],
          );
        },
      );

      // Reset values for both conditions if applicable
      setState(() {
        gearNameController.text = oldGearName;
        gearWeightController.text = oldGearWeight.toString();
        gearQuantityController.text = oldGearQuantity.toString();
        newHazmatValue = oldGearHazmatValue;
        _checkInput(); // Re-validate inputs
      });

      return;
    }

    if (personalToolExists && !onlyQuantityChanged && gearNameExists) {
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
              '$capitalizedGearName exists both as a tool and item in your gear inventory. Any gear that is also a personal tool must be edited within the Tool panel under the Crew tab. If you would like to add more to your gear inventory, do so within the Edit Gear panel.',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                ),
              ),
            ],
          );
        },
      );

      // Reset values for both conditions if applicable
      setState(() {
        gearNameController.text = oldGearName;
        gearWeightController.text = oldGearWeight.toString();
        gearQuantityController.text = oldGearQuantity.toString();
        newHazmatValue = oldGearHazmatValue;
        _checkInput(); // Re-validate inputs
      });

      return;
    }

    if (gearNameExists) {
      String matchingGearName = crew.gear.firstWhere((gear) => gear.name.toLowerCase() == newGearName.toLowerCase()).name;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Text('Gear Conflict', style: TextStyle(color: AppColors.textColorPrimary)),
            content: Text(
              '$matchingGearName already exists in your gear inventory. If you would like to add more, edit the item quantity in the Edit Gear panel.',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                ),
              ),
            ],
          );
        },
      );
      setState(() {
        gearNameController.text = oldGearName;
        gearWeightController.text = oldGearWeight.toString();
        gearQuantityController.text = oldGearQuantity.toString();
        newHazmatValue = oldGearHazmatValue;

        _checkInput(); // Re-validate inputs
      });
      return; // Exit function if the gear name is already used
    }

    // Update the gear's attributes
    widget.gear.name = capitalizedGearName;
    widget.gear.weight = int.parse(gearWeightController.text);
    widget.gear.isHazmat = newHazmatValue;

    // Check if any GearPreference prevents reducing quantity
    bool quantityConflict = savedPreferences.updateGearInPreferences(oldGearName, newGearQuantity, widget.gear);

    if (quantityConflict) {
      // Show an error and prevent saving
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Text(
              'Quantity Reduction Not Allowed',
              style: TextStyle(color: AppColors.textColorPrimary),
            ),
            content: Text(
              'The quantity you are trying to set ($newGearQuantity) is less than the quantity used in an existing gear preference. '
              'You must first delete the affected gear preference before reducing the quantity. All other fields have been updated.',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('OK', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
              ),
            ],
          );
        },
      );

      // Reset value for quantity
      setState(() {
        gearQuantityController.text = oldGearQuantity.toString();
        // Update the gear's attributes
        oldGearName = capitalizedGearName;
        oldGearWeight = int.parse(gearWeightController.text);
        oldGearHazmatValue = newHazmatValue;
        _checkInput(); // Re-validate inputs
      });
    } else {
      widget.gear.quantity = int.parse(gearQuantityController.text);
    }

    // Find the key for this item, if it's not a new item, update it in Hive
    final key = gearBox.keys.firstWhere(
      (key) => gearBox.get(key) == widget.gear,
      orElse: () => null,
    );

    if (key != null) {
      // Update existing Hive item
      gearBox.put(key, widget.gear);
    } else {
      // Add new item to Hive
      gearBox.add(widget.gear);
    }

    crew.updateTotalCrewWeight();
    //  savedPreferences.saveAllTripPreferencesToHive();

    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    if (!quantityConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Gear Updated!',
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
    }

    if (!quantityConflict) {
      Navigator.of(context).pop(); // Return to previous screen
    }
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
          'Edit Gear',
          style: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
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
                              'Delete Gear',
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
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                    ),
                                    content: Text(
                                      'This gear data ($oldGearName) and any gear preference data containing it will be erased!',
                                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog without deleting
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Remove item from the Hive box
                                          final keyToRemove = gearBox.keys.firstWhere(
                                            (key) => gearBox.get(key) == widget.gear,
                                            orElse: () => null,
                                          );

                                          if (keyToRemove != null) {
                                            gearBox.delete(keyToRemove);
                                          }

                                          // Remove the crew member from local memory
                                          crew.removeGear(widget.gear);

                                          widget.onUpdate(); // Callback function to update UI with new data

                                          // Show deletion pop-up
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Center(
                                                child: Text(
                                                  '$oldGearName Deleted!',
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
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                            child: TextField(
                              controller: gearNameController,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(25),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Edit gear name',
                                labelStyle: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text22,
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

                        // Edit Weight
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                            child: KeyboardActions(
                              config: keyboardActionsConfig(
                                focusNodes: [_weightFocusNode],
                              ),
                              disableScroll: true,
                              child: TextField(
                                focusNode: _weightFocusNode,
                                controller: gearWeightController,
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
                                      weightErrorMessage = 'Weight must be less than 500.';
                                    } else if (weight == 0) {
                                      weightErrorMessage = 'Weight must be greater than 0.';
                                    } else {
                                      weightErrorMessage = null;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Edit weight',
                                  hintText: 'Up to 500 lb',
                                  hintStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text20,
                                  ),
                                  errorText: weightErrorMessage,
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

                        // Edit Quantity
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
                            child: KeyboardActions(
                              config: keyboardActionsConfig(
                                focusNodes: [_quantityFocusNode],
                              ),
                              disableScroll: true,
                              child: TextField(
                                focusNode: _quantityFocusNode,
                                controller: gearQuantityController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(2),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  int? weight = int.tryParse(value);
                                  setState(() {
                                    if (weight == 0) {
                                      quantityErrorMessage = 'Quantity must be greater than 0.';
                                    } else {
                                      quantityErrorMessage = null;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Edit quantity',
                                  hintText: 'Up to 99',
                                  hintStyle: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text20,
                                  ),
                                  errorText: quantityErrorMessage,
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

                        // HAZMAT
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.textFieldColor,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  'HAZMAT',
                                  style: TextStyle(
                                    fontSize: AppData.text22,
                                    color: AppColors.textColorPrimary,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  newHazmatValue ? 'Yes' : 'No', // Dynamic label
                                  style: TextStyle(
                                    fontSize: AppData.text18,
                                    color: AppColors.textColorPrimary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Toggle Switch
                                Switch(
                                  value: newHazmatValue,
                                  onChanged: (bool value) {
                                    setState(() {
                                      newHazmatValue = value; // Update the state
                                      _checkInput();
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
                        ),
                        const Spacer(flex: 6),

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
