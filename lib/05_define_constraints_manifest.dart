import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';
import 'package:fire_app/05_build_your_own_manifest.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'CodeShare/colors.dart';

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
  double _sliderValue = 1000;
  String? tripNameErrorMessage;
  String? availableSeatsErrorMessage;


  bool isCalculateButtonEnabled = false; // Controls whether the save button shows

  @override
  void initState() {
    super.initState();

    // Listeners for TextControllers
    tripNameController.addListener(_updateTrip);
    allowableController.addListener(_updateTrip);
    availableSeatsController.addListener(_updateTrip);

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
      final isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && availableSeatsController.text != '0';

      // Enable button only if all fields are valid
      isCalculateButtonEnabled = isTripNameValid && isAllowableValid && isAvailableSeatsValid;

      // Update the trip instance if the button is enabled
      if (isCalculateButtonEnabled) {
        final String tripNameCapitalized = tripNameController.text
            .toLowerCase() // Ensure the rest of the string is lowercase
            .split(' ') // Split by spaces into words
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' '); // Join the words back with a space

        final int allowable = int.parse(allowableController.text);
        final int availableSeats = int.parse(availableSeatsController.text);
        newTrip = Trip(
          tripName: tripNameCapitalized,
          allowable: allowable,
          availableSeats: availableSeats,
        );
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
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      backgroundColor: Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 15,
      shadowColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: Size(MediaQuery
          .of(context)
          .size
          .width / 2, MediaQuery
          .of(context)
          .size
          .height / 10),
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

                      // Enter Trip Name Input Field
                      Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: TextField(
                            controller: tripNameController,
                            maxLength: 20,
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
                              labelStyle: TextStyle(
                                color: AppColors.textColorPrimary, // Label color when not focused
                                fontSize: 18, // Label font size
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                      // Enter Available Seats Input Field
                      Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                          child: TextField(
                            controller: availableSeatsController,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            // Only show numeric keyboard
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              // Allow only digits
                            ],
                            onChanged: (value) {
                              setState(() {
                                // Validate the input and set error message
                                if (value == '0') {
                                  availableSeatsErrorMessage = 'Available seats cannot be 0.';
                                } else {
                                  availableSeatsErrorMessage = null;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Enter # of Available Seats',
                              errorText: availableSeatsErrorMessage,
                              labelStyle: TextStyle(
                                color: AppColors.textColorPrimary, // Label color when not focused
                                fontSize: 18, // Label font size
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                      // Choose Allowable Text Field
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                        child: Container(
                          width: double.infinity,
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
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), // Reduced padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  'Choose Allowable',
                                  style: TextStyle(
                                    fontSize: 18,
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
                                            content: TextField(
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
                                                hintText: 'Up to 9,999 lbs',
                                                hintStyle: TextStyle(color: AppColors.textColorPrimary),
                                                filled: true,
                                                fillColor: AppColors.textFieldColor,
                                                // Background color of the text field
                                                counterText: '',
                                                border: const OutlineInputBorder(

                                                ),
                                              ),
                                              style: TextStyle(
                                                color: AppColors.textColorPrimary, // Color of the typed text
                                                fontSize: 18, // Font size for the typed text
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Revert to the original value on cancel
                                                  keyboardController.text = originalValue;
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton)),
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
                                                    color: isSaveEnabled ? AppColors.saveButtonAllowableWeight : Colors.grey, // Show enabled/disabled state
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
                                icon: Icon(FontAwesomeIcons.keyboard, size: 32, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Choose Allowable Slider
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, right: 16.0, left: 16.0),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _decrementSlider,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: AppColors.fireColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          elevation: 15,
                                          shadowColor: Colors.black,
                                          side: const BorderSide(color: Colors.black, width: 2),
                                          shape: CircleBorder(),
                                        ),
                                        child: const Icon(Icons.remove, color: Colors.black, size: 32),
                                      ),
                                      const Spacer(),
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Slider value
                                          Visibility(
                                            visible: lastInputFromSlider,
                                            child: Text(
                                              '${_sliderValue.toStringAsFixed(0)} lbs',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textColorPrimary,
                                              ),
                                            ),
                                          ),
                                          // Keyboard input value
                                          Visibility(
                                            visible: !lastInputFromSlider,
                                            child: Text(
                                              '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lbs',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textColorPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: _incrementSlider,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: AppColors.fireColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          elevation: 15,
                                          shadowColor: Colors.black,
                                          side: const BorderSide(color: Colors.black, width: 2),
                                          shape: CircleBorder(),
                                        ),
                                        child: const Icon(Icons.add, color: Colors.black, size: 32),
                                      ),
                                    ],
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

                      SizedBox(height: 16.0),

                      // Build Button
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: isCalculateButtonEnabled
                              ? () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuildYourOwnManifest(trip: newTrip),
                              ),
                            );
                          }
                              : null,
                          style: style,
                          child: const Text('Build'),
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