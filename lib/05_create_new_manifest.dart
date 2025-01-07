import 'dart:ui';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';
import 'Data/load_calculator.dart';
import 'Data/trip_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateNewManifest extends StatefulWidget {
  const CreateNewManifest({super.key});

  @override
  State<CreateNewManifest> createState() => _CreateNewManifestState();
}

class _CreateNewManifestState extends State<CreateNewManifest> {
  // Variables to store user input
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController allowableController = TextEditingController();
  final TextEditingController availableSeatsController = TextEditingController();
  final TextEditingController keyboardController = TextEditingController();
  double _sliderValue = 1000;

  // Can be null as a "None" option is available where user doesn't select a Load Preference
  TripPreference? selectedTripPreference;

  bool isCalculateButtonEnabled = false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();

    // Listeners to the TextControllers
    tripNameController.addListener(_checkInput);
    allowableController.addListener(_checkInput);
    availableSeatsController.addListener(_checkInput);
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

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isTripNameValid = tripNameController.text.isNotEmpty;
    final isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && int.tryParse(availableSeatsController.text) != null && int.parse(availableSeatsController.text) > 0;

    setState(() {
      // Need to adjust for position as well
      isCalculateButtonEnabled = isTripNameValid && isAvailableSeatsValid;
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveTripData() {
    // Take what the trip name contrller has saved
    final String tripName = tripNameController.text;

    // Check if crew member name already exists
    bool tripNameExists = savedTrips.savedTrips.any((member) => member.tripName == tripName);

    if (tripNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Trip name already used!',
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
      return; // Exit function if the trip name is already used
    }
    // Convert flight weight text to integer
    final int allowable = int.parse(allowableController.text);
    // Convert available seats text to integer
    final int availableSeats = int.parse(availableSeatsController.text);

    // Creating a new Trip object
    Trip newTrip = Trip(tripName: tripName, allowable: allowable, availableSeats: availableSeats);

    // Add the new trip to the global crew object
    savedTrips.addTrip(newTrip);

    // Manifest that load, baby
    loadCalculator(context, newTrip, selectedTripPreference);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Trip Saved!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Clear the text fields (reset them to empty), so we can add more trips
    tripNameController.text = '';
    availableSeatsController.text = '';

    // Reset the slider value back to 0
    setState(() {
      _sliderValue = 1000;
      allowableController.text = _sliderValue.toStringAsFixed(0); // Sync the allowableController with the slider
    });

    // // Debug for LogCat
    // print("--------------------------");
    // print("Trip Name: $tripName");
    // print("Allowable: $allowable");
    // print("--------------------------");
    // savedTrips.printTripDetails();
  }

  void _incrementSlider() {
    setState(() {
      _sliderValue = (_sliderValue + 5).clamp(1000, 5000); // Prevents from going past boundaries
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
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Create New Manifest',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            // Takes up all available space
            child: Stack(
              children: [
                // Background image
                Container(
                  child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      // Blur effect
                      child: Image.asset(
                        'assets/images/logo1.png',
                        fit: BoxFit.cover, // Cover  entire background
                        width: double.infinity,
                        height: double.infinity,
                      )),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),

                      // Enter Trip Name text box
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0, bottom: 0.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Enter Trip Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Trip Name input field
                      Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: TextField(
                            controller: tripNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              // hintText: 'Enter trip name',
                              // hintStyle: TextStyle(color: Colors.black),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.9),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is not focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(4.0), // Rounded corners
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                      // Choose Trip Preference text box
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0, bottom: 0.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Choose Trip Preference',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Choose Trip Preference
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 16.0, right: 16.0, bottom: 5.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: Colors.black, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<TripPreference?>(
                            value: selectedTripPreference,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            iconEnabledColor: Colors.black,
                            items: [
                              DropdownMenuItem<TripPreference?>(
                                value: null, // Represents the "None" option
                                child: const Text("None"),
                              ),
                              ...savedPreferences.tripPreferences.map((entry) {
                                return DropdownMenuItem<TripPreference>(
                                  value: entry,
                                  child: Text(entry.tripPreferenceName),
                                );
                              }),
                            ],
                            onChanged: (TripPreference? newValue) {
                              setState(() {
                                selectedTripPreference = newValue;
                                _checkInput();
                              });
                            },
                          )),
                        ),
                      ),

                      // Enter Available Seats text box
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0, bottom: 0.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Enter # of Available Seats',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Available Seats input field
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
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.9),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is not focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(4.0), // Rounded corners
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                      // Choose allowable text box
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
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
                                  style: const TextStyle(
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
                                            title: const Text('Enter Allowable Weight'),
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
                                              decoration: const InputDecoration(
                                                hintText: 'Up to 9,999 lbs',
                                                counterText: '',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Revert to the original value on cancel
                                                  keyboardController.text = originalValue;
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
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
                                                    color: isSaveEnabled ? Colors.blue : Colors.grey, // Show enabled/disabled state
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
                                icon: const Icon(FontAwesomeIcons.keyboard, size: 32, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Allowable Slider
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, right: 16.0, left: 16.0),
                        child: Stack(
                          children: [
                            // Background container with white background, black outline, and rounded corners
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, // Background color
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
                                          backgroundColor: Colors.deepOrangeAccent,
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
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Keyboard input value
                                          Visibility(
                                            visible: !lastInputFromSlider,
                                            child: Text(
                                              '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lbs',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
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
                                          backgroundColor: Colors.deepOrangeAccent,
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
                                  activeColor: Colors.deepOrange,
                                  // Color when the slider is active
                                  inactiveColor: Colors.grey, // Color for the inactive part
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 6),

                      // Calculate Button
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0),
                        child: ElevatedButton(
                          onPressed: isCalculateButtonEnabled
                              ? () {
                                  saveTripData(); // Call saveTripData first
                                }
                              : null, // Button is only enabled if there is input
                          style: style, // Main button theme
                          child: const Text('Calculate'),
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
    );
  }
}
