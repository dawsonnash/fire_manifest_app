import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';
import 'package:fire_app/05_build_your_own_manifest.dart';

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

  bool isCalculateButtonEnabled = false; // Controls whether the save button shows

  @override
  void initState() {
    super.initState();

    // Listeners for TextControllers
    tripNameController.addListener(_updateTrip);
    allowableController.addListener(_updateTrip);
    availableSeatsController.addListener(_updateTrip);
  }

  @override
  void dispose() {
    tripNameController.dispose();
    allowableController.dispose();
    availableSeatsController.dispose();
    super.dispose();
  }

  // Function to update trip based on input
  void _updateTrip() {
    setState(() {
      final isTripNameValid = tripNameController.text.isNotEmpty;
      final isAllowableValid = allowableController.text.isNotEmpty && allowableController.text != '0';
      final isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && availableSeatsController.text != '0';

      // Enable button only if all fields are valid
      isCalculateButtonEnabled = isTripNameValid && isAllowableValid && isAvailableSeatsValid;

      // Update the trip instance if the button is enabled
      if (isCalculateButtonEnabled) {
        final String tripName = tripNameController.text;
        final int allowable = int.parse(allowableController.text);
        final int availableSeats = int.parse(availableSeatsController.text);
        newTrip = Trip(
          tripName: tripName,
          allowable: allowable,
          availableSeats: availableSeats,
        );
      }
    });
  }

  // Slider functions
  double _currentSliderValue = 0;

  void _incrementSlider() {
    setState(() {
      _currentSliderValue = (_currentSliderValue + 5).clamp(0, 10000);
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
      elevation: 15,
      shadowColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Build Your Own Manifest',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background image
                Container(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                        child: _buildTextInputContainer('Enter Trip Name', tripNameController),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: TextField(
                          controller: tripNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(),
                          style: _textStyle(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                        child: _buildTextInputContainer('Enter # of Available Seats', availableSeatsController),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                        child: CupertinoTextField(
                          controller: availableSeatsController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: BoxDecoration(
                            color: CupertinoColors.white, // Set the background color to white
                            border: Border.all(color: CupertinoColors.black, width: 2),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                        child: _buildTextInputContainer('Choose Allowable', allowableController),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, right: 16.0, left: 16.0),
                        child: _buildSlider(),
                      ),
                      const Spacer(flex: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputContainer(String title, TextEditingController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.deepOrangeAccent,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), spreadRadius: 1, blurRadius: 8, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black, width: 2.0),
      borderRadius: BorderRadius.circular(4.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black, width: 2.0),
      borderRadius: BorderRadius.circular(4.0),
    ),
  );

  TextStyle _textStyle() => const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold);

  Widget _buildSlider() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8)),
          ),
        ),
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
                  Text('${_currentSliderValue.toStringAsFixed(0)} lbs', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                  allowableController.text = _currentSliderValue.toStringAsFixed(0);
                });
              },
              activeColor: Colors.deepOrange,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}

