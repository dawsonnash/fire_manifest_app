import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

// Tester data
enum PositionLabel {
  none('None'),
  crewboss('Crew Boss'),
  assistantCrewBoss('Assistant Crew Boss'),
  dig('Dig'),
  medic('Medic'),
  foreman('Foreman'),
  sawteam1('Saw Team 1'),
  sawteam2('Saw Team 2'),
  sawteam3('Saw Team 3'),
  sawteam4('Saw Team 4');

  const PositionLabel(this.label);
  final String label;
}
class AddCrewmember extends StatefulWidget {
  const AddCrewmember({super.key});



  @override
  State<AddCrewmember> createState() => _AddCrewmemberState();
}
  class _AddCrewmemberState extends State<AddCrewmember>{

  // For selecting position
    PositionLabel? selectedPosition;

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
                        child: DropdownMenu<PositionLabel>(
                          width: double.infinity,
                          initialSelection: PositionLabel.none,
                          label: const Text('Position'),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                          // Theme/design for the input field
                          inputDecorationTheme: inputDecorationTheme,
                          // Design for the dropdown menu
                          menuStyle: const MenuStyle(
                            backgroundColor: WidgetStatePropertyAll<Color>(Colors.deepOrangeAccent),

                          ),
                          onSelected: (PositionLabel? position) {
                            setState(() {
                              selectedPosition = position;
                            });
                          },
                          dropdownMenuEntries: PositionLabel.values
                              .map<DropdownMenuEntry<PositionLabel>>(
                                  (PositionLabel position) {
                                return DropdownMenuEntry<PositionLabel>(
                                  value: position,
                                  label: position.label,
                                  // Theme for each entry
                                  style: MenuItemButton.styleFrom(
                                    foregroundColor: Colors.black, // Default color for positions
                                    backgroundColor: Colors.white,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const Spacer(flex: 6),
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
