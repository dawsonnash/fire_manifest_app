import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

// Tester data
class AddGear extends StatefulWidget {
  const AddGear({super.key});


  @override
  State<AddGear> createState() => _AddGearState();
}
class _AddGearState extends State<AddGear>{

  // Variables to store user input
  final TextEditingController gearNameController = TextEditingController();
  final TextEditingController gearWeightController = TextEditingController();
  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();

    // Listeners to the TextControllers
    gearNameController.addListener(_checkInput);
    gearWeightController.addListener(_checkInput);
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isGearNameValid = gearNameController.text.isNotEmpty;
    final isGearWeightValid = gearWeightController.text.isNotEmpty;

    setState(() {
      // Need to adjust for position as well
      isSaveButtonEnabled = isGearNameValid && isGearWeightValid;
    });
  }

  // Function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveData() {

    final String gearName = gearNameController.text;

    // Convert flight weight text to integer
    final int gearWeight = int.parse(gearWeightController.text);

    //final String position = selectedPosition?.label ?? 'None';

    // Debug for LogCat
    print("Gear Name: $gearName");
    print("Gear Weight: $gearWeight");
    //print("Position: $position");

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gear Saved!',
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery
            .of(context)
            .size
            .width / 2, MediaQuery
            .of(context)
            .size
            .height / 10)
    );
    // Black style input field decoration
    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
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
        borderRadius: BorderRadius.circular(
            12.0), // Rounded corners
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Colors.black,
          // Border color when the TextField is focused
          width: 2.0, // Border width
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),

    );

    return Scaffold(
      resizeToAvoidBottomInset: false,  // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Add Gear',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded( // Takes up all available space
            child: Stack(
              children: [
                // Background image
                Container(
                  child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      // Blur effect
                      child: Image.asset('assets/images/logo1.png',
                        fit: BoxFit.cover, // Cover  entire background
                        width: double.infinity,
                        height: double.infinity,
                      )
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

                      // Enter Name
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: gearNameController,
                            decoration: InputDecoration(
                              labelText: 'Enter gear name',
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
                                borderRadius: BorderRadius.circular(
                                    12.0), // Rounded corners
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
                          )

                      ),

                      // Enter Flight Weight
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: gearWeightController,
                            keyboardType: TextInputType.number,
                            // Only show numeric keyboard
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              // Allow only digits
                            ],
                            decoration: InputDecoration(
                              labelText: 'Enter gear weight',
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
                                borderRadius: BorderRadius.circular(
                                    12.0), // Rounded corners
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
                          )

                      ),

                      const Spacer(flex: 6),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: isSaveButtonEnabled ? () => saveData() : null,  // Button is only enabled if there is input
                            style: style, // Main button theme
                            child: const Text(
                                'Save'
                            )
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