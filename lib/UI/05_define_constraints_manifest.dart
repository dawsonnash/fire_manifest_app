import 'dart:math';

import 'package:fire_app/UI/05_build_your_own_manifest.dart';
import 'package:fire_app/UI/05_byom_external.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/gear.dart';
import '../Data/trip.dart';

class DesignNewManifest extends StatefulWidget {
  const DesignNewManifest({super.key});

  @override
  State<DesignNewManifest> createState() => _DesignNewManifestState();
}

class _DesignNewManifestState extends State<DesignNewManifest> {
  // Class-level Trip variable to persist data
  late Trip newTrip;

  // Variables to store user input
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController allowableController = TextEditingController();
  final TextEditingController availableSeatsController = TextEditingController();
  final TextEditingController keyboardController = TextEditingController();
  late TextEditingController safetyBufferController = TextEditingController(text: '0');

  double _sliderValue = 1000;
  String? tripNameErrorMessage;
  String? availableSeatsErrorMessage;
  String? safetyBufferErrorMessage;

  bool isCalculateButtonEnabled = false; // Controls whether the save button shows
  bool isExternalManifest = false; // Default to internal manifest (personnel + cargo)

  final FocusNode _allowableFocusNode = FocusNode();
  final FocusNode _safetyBufferFocusNode = FocusNode();
  final FocusNode _availableSeatsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    newTrip = Trip(tripName: '', allowable: 0, availableSeats: 0);

    // Listeners for TextControllers
    tripNameController.addListener(_updateTrip);
    allowableController.addListener(_updateTrip);
    availableSeatsController.addListener(_updateTrip);
    safetyBufferController = TextEditingController(text: AppData.safetyBuffer.toString());

    // Initialize allowableController with the default slider value
    allowableController.text = _sliderValue.toStringAsFixed(0);
  }

  // Track the last input source
  bool lastInputFromSlider = true;

  @override
  void dispose() {
    tripNameController.dispose();
    allowableController.dispose();
    availableSeatsController.dispose();
    keyboardController.dispose();
    super.dispose();
  }

  // Function to update trip based on input
  void _updateTrip() {
    setState(() {
      final String tripName = tripNameController.text;
// Validate trip name existence (case-insensitive)
      final bool isTripNameUnique = !savedTrips.savedTrips.any(
        (member) => member.tripName.toLowerCase() == tripName.toLowerCase(),
      );

      final bool isTripNameValid = tripName.isNotEmpty && isTripNameUnique;
      final isAllowableValid = allowableController.text.isNotEmpty && allowableController.text != '0';
      var isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && availableSeatsController.text != '0';

      if (isExternalManifest) {
        isAvailableSeatsValid = true;
      }
      setState(() {
        // Need to adjust for position as well
        isCalculateButtonEnabled = isTripNameValid && isAvailableSeatsValid;
      });

      // Update the trip instance if the button is enabled
      if (isCalculateButtonEnabled) {
        final String tripNameCapitalized = tripNameController.text
            .toLowerCase() // Ensure the rest of the string is lowercase
            .split(' ') // Split by spaces into words
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' '); // Join the words back with a space

        final int allowable = int.parse(allowableController.text);
        // Convert available seats text to integer. Available seats not necessary in External Manifesting
        final int availableSeats = isExternalManifest ? -1 : int.parse(availableSeatsController.text);
        int safetyBuffer = int.parse(safetyBufferController.text);

        if (!isExternalManifest) {
          safetyBuffer = 0;
        }
        // Creating a new Trip object
        newTrip = Trip(tripName: tripNameCapitalized, allowable: allowable, availableSeats: availableSeats, isExternal: isExternalManifest, safetyBuffer: safetyBuffer);
      }
    });
  }

  void _incrementSlider() {
    setState(() {
      _sliderValue = (_sliderValue + 5).clamp(1000, 5000);
      allowableController.text = _sliderValue.toStringAsFixed(0);
    });
  }

  void _decrementSlider() {
    setState(() {
      _sliderValue = (_sliderValue - 5).clamp(1000, 5000);
      allowableController.text = _sliderValue.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
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
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withValues(alpha: 0.05),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),

                      // Internal/External Manifest toggle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(
                              isExternalManifest ? "External" : "Internal",
                              style: TextStyle(
                                fontSize: AppData.text18,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min, // Keeps row from expanding
                              children: [
                                isExternalManifest
                                    ? Transform.scale(
                                        scale: 1.5,
                                        child: SvgPicture.asset(
                                          'assets/icons/sling_icon.svg', // Your SVG file path
                                          width: AppData.toolsIcon,
                                          height: AppData.toolsIcon,
                                          colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn), // Apply color dynamically
                                        ),
                                      )
                                    : Icon(
                                        FontAwesomeIcons.helicopter,
                                        color: AppColors.primaryColor,
                                        size: AppData.text24,
                                      ),
                                SizedBox(width: isExternalManifest ? 8 : 16), // Add spacing between icon and switch
                                Switch(
                                  value: isExternalManifest,
                                  activeColor: AppColors.primaryColor,
                                  inactiveThumbColor: AppColors.primaryColor,
                                  inactiveTrackColor: AppColors.textFieldColor,
                                  onChanged: (bool value) {
                                    setState(() {
                                      isExternalManifest = value;
                                    });
                                    _updateTrip();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: AppData.spacingStandard),
                      // Enter Trip Name Input Field
                      Padding(
                          padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                          child: Container(
                            width: AppData.inputFieldWidth,
                            child: TextField(
                              controller: tripNameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                              ],
                              textCapitalization: TextCapitalization.words,
                              onChanged: (value) {
                                setState(() {
                                  // Check if the trip name exists in the savedTrips list (case-insensitive)
                                  final String tripName = tripNameController.text;

                                  // Check if crew member name already exists
                                  bool tripNameExists = savedTrips.savedTrips.any(
                                    (member) => member.tripName.toLowerCase() == tripName.toLowerCase(),
                                  );

                                  // Validate the input and set error message
                                  if (tripNameExists) {
                                    tripNameErrorMessage = 'Trip name already used';
                                  } else {
                                    tripNameErrorMessage = null;
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Enter Trip Name',
                                errorText: tripNameErrorMessage,
                                errorStyle: TextStyle(
                                  fontSize: AppData.errorText,
                                  color: Colors.red,
                                ),
                                labelStyle: TextStyle(
                                  color: AppColors.textColorPrimary, // Label color when not focused
                                  fontSize: AppData.text18, // Label font size
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: AppData.text24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),

                      SizedBox(height: AppData.spacingStandard),

                      // Available Seats input field
                      if (!isExternalManifest)
                        Padding(
                            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                            child: Container(
                              width: AppData.inputFieldWidth,
                              child: KeyboardActions(
                                config: keyboardActionsConfig(
                                  focusNodes: [_availableSeatsFocusNode],
                                ),
                                disableScroll: true,
                                child: TextField(
                                  focusNode: _availableSeatsFocusNode,
                                  textInputAction: TextInputAction.done,
                                  controller: availableSeatsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(1),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      // Validate the input and set error message
                                      if (value == '0') {
                                        availableSeatsErrorMessage = 'Available seats cannot be 0';
                                      } else {
                                        availableSeatsErrorMessage = null;
                                      }
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Enter # of Available Seats',
                                    labelStyle: TextStyle(
                                      color: AppColors.textColorPrimary, // Label color when not focused
                                      fontSize: AppData.text18, // Label font size
                                    ),
                                    errorText: availableSeatsErrorMessage,
                                    errorStyle: TextStyle(
                                      fontSize: AppData.errorText,
                                      color: Colors.red,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.textFieldColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.borderPrimary,
                                        // Border color when the TextField is not focused
                                        width: 2.0, // Border width
                                      ),
                                      borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.primaryColor,
                                        // Border color when the TextField is focused
                                        width: 2.0, // Border width
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )),

                      // Safety Buffer
                      if (isExternalManifest)
                        Padding(
                            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                            child: Container(
                              width: AppData.inputFieldWidth,
                              child: KeyboardActions(
                                config: keyboardActionsConfig(
                                  focusNodes: [_safetyBufferFocusNode],
                                ),
                                disableScroll: true,
                                child: TextField(
                                  focusNode: _safetyBufferFocusNode,
                                  textInputAction: TextInputAction.done,
                                  controller: safetyBufferController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(3),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Enter Safety Buffer (lb)',
                                    labelStyle: TextStyle(
                                      color: AppColors.textColorPrimary, // Label color when not focused
                                      fontSize: AppData.text18, // Label font size
                                    ),
                                    errorText: safetyBufferErrorMessage,
                                    errorStyle: TextStyle(
                                      fontSize: AppData.errorText,
                                      color: Colors.red,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.textFieldColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.borderPrimary,
                                        // Border color when the TextField is not focused
                                        width: 2.0, // Border width
                                      ),
                                      borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.primaryColor,
                                        // Border color when the TextField is focused
                                        width: 2.0, // Border width
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontSize: AppData.text24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )),

                      SizedBox(height: AppData.spacingStandard),

                      // Choose Allowable Text Field
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          decoration: BoxDecoration(
                            color: AppColors.fireColor,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          // Reduced padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  'Choose Allowable',
                                  style: TextStyle(
                                    fontSize: AppData.text18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Clear the keyboardController before opening the dialog
                                  keyboardController.text = '';

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      // Save the original value in case of cancel
                                      String originalValue = allowableController.text;

                                      // Track if the Save button should be enabled
                                      bool isSaveEnabled = false;

                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          // Function to validate input and enable/disable Save button
                                          void validateInput(String value) {
                                            final int? parsedValue = int.tryParse(value);
                                            setState(() {
                                              isSaveEnabled = parsedValue != null && parsedValue >= 500 && parsedValue <= 10000;
                                            });
                                          }

                                          return AlertDialog(
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text('Enter Allowable Weight', style: TextStyle(color: AppColors.textColorPrimary)),
                                            content: KeyboardActions(
                                              config: keyboardActionsConfig(
                                                focusNodes: [_allowableFocusNode],
                                              ),
                                              disableScroll: true,
                                              child: TextField(
                                                focusNode: _allowableFocusNode,
                                                textInputAction: TextInputAction.done,
                                                controller: keyboardController,
                                                keyboardType: TextInputType.number,
                                                maxLength: 4,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                onChanged: (value) {
                                                  validateInput(value); // Validate the input
                                                  setState(() {
                                                    lastInputFromSlider = false;
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                  hintText: 'Up to 9,999 lb',
                                                  hintStyle: TextStyle(color: AppColors.textColorPrimary),
                                                  filled: true,
                                                  fillColor: AppColors.textFieldColor,
                                                  // Background color of the text field
                                                  counterText: '',
                                                  border: const OutlineInputBorder(),
                                                ),
                                                style: TextStyle(
                                                  color: AppColors.textColorPrimary, // Color of the typed text
                                                  fontSize: AppData.text18, // Font size for the typed text
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Revert to the original value on cancel
                                                  keyboardController.text = originalValue;
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel',
                                                    style: TextStyle(
                                                      color: AppColors.cancelButton,
                                                      fontSize: AppData.bottomDialogTextSize,
                                                    )),
                                              ),
                                              TextButton(
                                                onPressed: isSaveEnabled
                                                    ? () {
                                                        setState(() {
                                                          if (keyboardController.text.isNotEmpty) {
                                                            _sliderValue = double.parse(keyboardController.text).clamp(1000, 5000);
                                                            allowableController.text = keyboardController.text;
                                                          }
                                                        });
                                                        Navigator.of(context).pop();
                                                      }
                                                    : null, // Disable Save if input is invalid
                                                child: Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    color: isSaveEnabled ? AppColors.saveButtonAllowableWeight : Colors.grey, fontSize: AppData.bottomDialogTextSize,
                                                    // Show enabled/disabled state
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
                                icon: Icon(FontAwesomeIcons.keyboard, size: AppData.text32, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Choose Allowable Slider
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,

                          child: Stack(
                            children: [
                              // Background container with white background, black outline, and rounded corners
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor, // Background color
                                    border: Border.all(color: Colors.black, width: 2), // Black outline
                                    borderRadius: BorderRadius.circular(8), // Rounded corners
                                  ),
                                ),
                              ),
                              // Column with existing widgets
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Minus Button
                                          ElevatedButton(
                                            onPressed: _decrementSlider,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: AppColors.fireColor,
                                              padding: EdgeInsets.symmetric(horizontal: AppData.padding20, vertical: AppData.padding10),
                                              elevation: 15,
                                              shadowColor: Colors.black,
                                              side: BorderSide(color: Colors.black, width: 2),
                                              shape: CircleBorder(),
                                            ),
                                            child: Icon(Icons.remove, color: Colors.black, size: AppData.text32),
                                          ),

                                          const SizedBox(width: 20), // Spacer is too greedy for a FittedBox

                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Slider value
                                              Visibility(
                                                visible: lastInputFromSlider,
                                                child: Text(
                                                  '${_sliderValue.toStringAsFixed(0)} lb',
                                                  style: TextStyle(
                                                    fontSize: AppData.text32,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textColorPrimary,
                                                  ),
                                                ),
                                              ),
                                              // Keyboard input value
                                              Visibility(
                                                visible: !lastInputFromSlider,
                                                child: Text(
                                                  '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lb',
                                                  style: TextStyle(
                                                    fontSize: AppData.text32,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textColorPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(width: 20),

                                          // Add Button
                                          ElevatedButton(
                                            onPressed: _incrementSlider,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: AppColors.fireColor,
                                              padding: EdgeInsets.symmetric(horizontal: AppData.padding20, vertical: AppData.padding10),
                                              elevation: 15,
                                              shadowColor: Colors.black,
                                              side: BorderSide(color: Colors.black, width: 2),
                                              shape: CircleBorder(),
                                            ),
                                            child: Icon(Icons.add, color: Colors.black, size: AppData.text32),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Slider(
                                    value: _sliderValue,
                                    min: 1000,
                                    max: 5000,
                                    divisions: 40,
                                    label: null,
                                    onChanged: (double value) {
                                      setState(() {
                                        _sliderValue = value;
                                        lastInputFromSlider = true;
                                        allowableController.text = _sliderValue.toStringAsFixed(0);
                                      });
                                    },
                                    activeColor: AppColors.fireColor,
                                    // Color when the slider is active
                                    inactiveColor: Colors.grey, // Color for the inactive part
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppData.spacingStandard),

                      // Build Button
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: isCalculateButtonEnabled
                              ? () {
                                  _updateTrip();

                                  if (isExternalManifest) {
                                    final int allowable = int.parse(allowableController.text);
                                    final int safetyBuffer = int.parse(safetyBufferController.text);
                                    num remainingWeight = allowable - safetyBuffer;
                                    Gear? heaviestGearItem;
                                    num maxGearWeight = 0;

                                    if (crew.gear.isNotEmpty) {
                                      heaviestGearItem = crew.gear.reduce((a, b) => a.weight > b.weight ? a : b);
                                      maxGearWeight = heaviestGearItem.weight;
                                    }
                                    if (crew.gear.isEmpty) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'No Gear Available',
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
                                                ),
                                                content: Text('There is no existing gear. Create at least one to begin manifesting.', style: TextStyle(color: AppColors.textColorPrimary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text('OK', style: TextStyle(color: AppColors.textColorPrimary)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      return;
                                    }
                                    if (safetyBuffer >= allowable) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'Input Error',
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
                                                ),
                                                content: Text('Safety Buffer must be lower than the allowable load weight.', style: TextStyle(color: AppColors.textColorPrimary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text('OK', style: TextStyle(color: AppColors.textColorPrimary)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      return;
                                    }
                                    if (remainingWeight < maxGearWeight) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'Weight Error',
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
                                                ),
                                                content: Text(
                                                    'The remaining allowable weight with the safety buffer ($remainingWeight lb) is less than the heaviest gear item (${heaviestGearItem?.name}: ${heaviestGearItem?.weight} lb). Adjust values and try again.',
                                                    style: TextStyle(color: AppColors.textColorPrimary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text('OK', style: TextStyle(color: AppColors.textColorPrimary)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      return;
                                    }
                                  }

                                  isExternalManifest
                                      ? Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BuildYourOwnManifestExternal(trip: newTrip, safetyBuffer: int.parse(safetyBufferController.text)),
                                            settings: RouteSettings(name: 'BYOM_ExternalPage'),

                                          ),
                                        )
                                      : Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BuildYourOwnManifest(trip: newTrip),
                                            settings: RouteSettings(name: 'BYOM_InternalPage'),
                                          ),
                                        );
                                }
                              : null,
                          style: style,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Text('Build'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
