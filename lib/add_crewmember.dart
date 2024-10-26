import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Data/crew.dart';
import 'Data/crewmember.dart';

class AddCrewmember extends StatefulWidget {
  const AddCrewmember({super.key});

  @override
  State<AddCrewmember> createState() => _AddCrewmemberState();
}
  class _AddCrewmemberState extends State<AddCrewmember>{

    // Variables to store user input
    final TextEditingController nameController = TextEditingController();
    final TextEditingController flightWeightController = TextEditingController();
    bool isSaveButtonEnabled = false; // Controls whether saving button is showing
    int? selectedPosition;

    @override
  void initState() {
      super.initState();

      // Listeners to the TextControllers
      nameController.addListener(_checkInput);
      flightWeightController.addListener(_checkInput);
    }
    @override
    void dispose() {
      nameController.dispose();
      flightWeightController.dispose();
      super.dispose();
    }

    // Function to check if input is valid and update button state
    void _checkInput() {
      final isNameValid = nameController.text.isNotEmpty;
      final isFlightWeightValid = flightWeightController.text.isNotEmpty;
      final isPositionSelected = selectedPosition != null;

      setState(() {
        // Need to adjust for position as well
        isSaveButtonEnabled = isNameValid && isFlightWeightValid && isPositionSelected;
      });
    }

    // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
    void saveData() {

      // Take what the name contrller has saved
      final String name = nameController.text;

      // Convert flight weight text to integer
      final int flightWeight = int.parse(flightWeightController.text);

      //final String position = selectedPosition?.label ?? 'None';

      // Creating a new CrewMember object. Dont have positioin yet
      CrewMember newCrewMember = CrewMember(name: name, flightWeight: flightWeight, position: selectedPosition ?? 23);

      // Add the new crewmember to the global crew object
      crew.addCrewMember(newCrewMember);

      // Show successful save popup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crew Member Saved!',
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

      // Clear the text fields (reset them to empty), so you can add more ppl
      nameController.text = '';
      flightWeightController.text = '';
      selectedPosition = null;

      // Debug for LogCat
      print("Name: $name");
      print("Flight Weight: $flightWeight");
      print("--------------------------");
      crew.printCrewDetails();
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
          'Add Crew Member',
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
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Enter last name',
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
                            controller: flightWeightController,
                            keyboardType: TextInputType.number,
                            // Only show numeric keyboard
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              // Allow only digits
                            ],
                            decoration: InputDecoration(
                              labelText: 'Enter flight weight',
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

                      // Enter Position(s)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
                              hint: const Text(
                                'Choose position',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
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
