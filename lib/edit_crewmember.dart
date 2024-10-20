import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import 'package:hive/hive.dart';

class EditCrewmember extends StatefulWidget {

  // This page requires a crewmember to be passed to it - to edit it
  final CrewMember crewMember;
  final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const EditCrewmember({
    super.key,
    required this.crewMember,
    required this.onUpdate,
  });

  @override
  State<EditCrewmember> createState() => _EditCrewmemberState();
}
class _EditCrewmemberState extends State<EditCrewmember>{

  // Variables to store user input
  late TextEditingController nameController;
  late TextEditingController flightWeightController;
  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

  // Store old CrewMember info for ensuring user only can save if they change data
  late String oldCrewMemberName;
  late int oldCrewMemberFlightWeight;

  // initialize HiveBox for crewmember
  late final Box<CrewMember> crewmemberBox;

  @override
  void initState() {
    super.initState();

    // Initialize crewmemberBox variable here
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

    // Initializing the controllers with the current crew member's data to be edited
    nameController = TextEditingController(text: widget.crewMember.name);
    flightWeightController = TextEditingController(text: widget.crewMember.flightWeight.toString());

    // Store original crewmember data
    oldCrewMemberName = widget.crewMember.name;
    oldCrewMemberFlightWeight = widget.crewMember.flightWeight;

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
    final isNameChanged = nameController.text != oldCrewMemberName;
    final isFlightWeightChanged = flightWeightController.text != oldCrewMemberFlightWeight.toString();

    setState(() {
      // Need to adjust for position as well
      // Only enables saving if name is changed and is not empty
      isSaveButtonEnabled = (isNameValid && isFlightWeightValid) && (isNameChanged || isFlightWeightChanged);
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveData() {

    // Update exisiting data
    widget.crewMember.name = nameController.text;
    widget.crewMember.flightWeight = int.parse(flightWeightController.text);

    // Find the key for this item, if it's not a new item, update it in Hive
    final key = crewmemberBox.keys.firstWhere(
          (key) => crewmemberBox.get(key) == widget.crewMember,
      orElse: () => null,
    );
    if (key != null) {
      // Update existing Hive item
      crewmemberBox.put(key, widget.crewMember);
    } else {
      // Add new item to Hive
      crewmemberBox.add(widget.crewMember);
    }

    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crew Member Updated!',
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
    Navigator.of(context).pop();  // Return to previous screen
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

    return Scaffold(
      resizeToAvoidBottomInset: false,  // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Edit Crew Member',
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
                ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    // Blur effect
                    child: Image.asset('assets/images/logo1.png',
                      fit: BoxFit.cover, // Cover  entire background
                      width: double.infinity,
                      height: double.infinity,
                    )
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),

                      // Edit Name
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Edit name',
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

                      // Edit Flight Weight
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
                              labelText: 'Edit flight weight',
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
                      const Spacer(flex: 6),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(flex:2),

                            ElevatedButton(
                              onPressed: isSaveButtonEnabled ? () => saveData() : null,  // Button is only enabled if there is input
                              style: style, // Main button theme
                              child: const Text(
                                  'Save'
                              )
                          ),

                            const Spacer(flex:1),

                            IconButton(
                                icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 32
                                ),

                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Delete $oldCrewMemberName?',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        )
                                      ),
                                      content: Text('This crew member data ($oldCrewMemberName) will be erased!',
                                          style: const TextStyle(
                                            fontSize: 18,
                                          )),
                                      actions: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();  // Dismiss the dialog
                                              },
                                              child: const Text('Cancel',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                  )),
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
                                                  content: Text('$oldCrewMemberName Deleted!',
                                                    // Maybe change look
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 32,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  duration: Duration(seconds: 2),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );

                                              Navigator.of(context).pop();  // Dismiss the dialog
                                              Navigator.of(context).pop();  // Return to previous screen
                                            },
                                            child: const Text('OK',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                )),
                                          ),
                                        ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            )
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
    );
  }
}
