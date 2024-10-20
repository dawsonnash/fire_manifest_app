import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';
import 'Data/load_calculator.dart';

class CreateNewManifest extends StatefulWidget {
  const CreateNewManifest({super.key});

  @override
  State<CreateNewManifest> createState() => _CreateNewManifestState();
}

class _CreateNewManifestState extends State<CreateNewManifest> {
  // Variables to store user input
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController allowableController = TextEditingController();
  bool isCalculateButtonEnabled =
      false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();

    // Listeners to the TextControllers
    tripNameController.addListener(_checkInput);
    allowableController.addListener(_checkInput);
  }

  @override
  void dispose() {
    tripNameController.dispose();
    allowableController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isTripNameValid = tripNameController.text.isNotEmpty;
    final isAllowableValid =
        allowableController.text.isNotEmpty && allowableController.text != '0';

    setState(() {
      // Need to adjust for position as well
      isCalculateButtonEnabled = isTripNameValid && isAllowableValid;
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveTripData() {
    // Take what the trip name contrller has saved
    final String tripName = tripNameController.text;

    // Convert flight weight text to integer
    final int allowable = int.parse(allowableController.text);

    // Creating a new Trip object
    Trip newTrip =
        Trip(tripName: tripName, allowable: allowable);

    // Add the new trip to the global crew object
    savedTrips.addTrip(newTrip);

    // Manifest that load, baby
    loadCalculator(newTrip);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Trip Saved!',
          // Maybe change look
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Clear the text fields (reset them to empty), so we can add more trips
    tripNameController.text = '';

    // Reset the slider value back to 0
    setState(() {
      _currentSliderValue = 0;
      allowableController.text = _currentSliderValue.toStringAsFixed(0); // Sync the allowableController with the slider
    });


    // Debug for LogCat
    print("--------------------------");
    print("Trip Name: $tripName");
    print("Allowable: $allowable");
    print("--------------------------");
    savedTrips.printTripDetails();


  }

  double _currentSliderValue = 0;

  void _incrementSlider() {
    setState(() {
      _currentSliderValue = (_currentSliderValue + 5)
          .clamp(0, 10000); // Prevents from going past boundaries
      allowableController.text = _currentSliderValue.toStringAsFixed(0);
    });
  }

  void _decrementSlider() {
    setState(() {
      _currentSliderValue = (_currentSliderValue - 5).clamp(0, 10000);
      allowableController.text = _currentSliderValue.toStringAsFixed(0);
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
        fixedSize: Size(MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 10));

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
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
                  color: Colors.white.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),

                      // Enter Trip Name text box
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 5.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Enter Trip Name',
                            style: const TextStyle(
                              fontSize: 24,
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
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is not focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    8.0), // Rounded corners
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  // Border color when the TextField is focused
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                      // Choose allowable text box
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Choose Allowable',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Allowable Slider
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, right: 16.0, left: 16.0),
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
                                      Spacer(),
                                      Text(
                                        '${_currentSliderValue.toStringAsFixed(0)} lbs',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Spacer(),
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
                                  value: _currentSliderValue,
                                  min: 0,
                                  max: 10000,
                                  divisions: 400,
                                  label: null,
                                  onChanged: (double value) {
                                    setState(() {
                                      _currentSliderValue = value;
                                      allowableController.text = _currentSliderValue.toStringAsFixed(0);
                                    });
                                  },
                                  activeColor: Colors.deepOrange, // Color when the slider is active
                                  inactiveColor: Colors.grey, // Color for the inactive part
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),


                      const Spacer(flex: 6),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
