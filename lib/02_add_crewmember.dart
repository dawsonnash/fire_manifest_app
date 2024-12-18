import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Data/crew.dart';
import 'Data/crewmember.dart';
import 'Data/gear.dart';

class AddCrewmember extends StatefulWidget {
  const AddCrewmember({super.key});

  @override
  State<AddCrewmember> createState() => _AddCrewmemberState();
}
  class _AddCrewmemberState extends State<AddCrewmember>{

    // Variables to store user input
    final TextEditingController nameController = TextEditingController();
    final TextEditingController flightWeightController = TextEditingController();
    final TextEditingController toolNameController = TextEditingController();
    final TextEditingController toolWeightController = TextEditingController();
    bool isSaveButtonEnabled = false; // Controls whether saving button is showing
    int? selectedPosition;
    List<Gear>? addedTools = []; // List to hold added Gear objects, i.e., personal tools


    @override
  void initState() {
      super.initState();

      // Listeners to the TextControllers
      nameController.addListener(_checkInput);
      flightWeightController.addListener(_checkInput);
      toolNameController.addListener(_checkInput);
      toolWeightController.addListener(_checkInput);
    }
    @override
    void dispose() {
      nameController.dispose();
      flightWeightController.dispose();
      toolNameController.dispose();
      toolWeightController.dispose();
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

    void addTool() {
      final String toolName = toolNameController.text;
      final int toolWeight = int.parse(toolWeightController.text);

      if (toolName.isNotEmpty && toolWeight > 0) {
        setState(() {
          addedTools?.add(Gear(name: toolName, weight: toolWeight, quantity: 1, isPersonalTool: true));
          toolNameController.clear();
          toolWeightController.clear();
          setState(() {});
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter all tool info'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Saved Tools');
      for (var tools in addedTools!){
        print('${tools.name}, ${tools.weight}');
      }
    }

    void removeTool(int index) {
      setState(() {
        addedTools?.removeAt(index);
      });
    }


    // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
    void saveCrewMemberData() {

      // Take what the name contrller has saved
      final String name = nameController.text;

      // Check if crew member name already exists
      bool crewMemberNameExists = crew.crewMembers.any((member) => member.name == name);

      if (crewMemberNameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Crew member name already used!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return; // Exit function if the gear name is already used
      }
      // Convert flight weight text to integer
      final int flightWeight = int.parse(flightWeightController.text);

      final List<Gear> personalTools = List.from(addedTools!);

      // Creating a new CrewMember object. Dont have positioin yet
      CrewMember newCrewMember = CrewMember(name: name, flightWeight: flightWeight, position: selectedPosition ?? 26, personalTools: personalTools);

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

      // Clear all input fields (reset them to empty), so you can add more ppl
      clearInputs();
    }

    void clearInputs() {
      nameController.text = '';
      flightWeightController.text = '';
      toolNameController.text = '';
      toolWeightController.text = '';
      selectedPosition = null;
      // THis destroys everything
      addedTools?.clear();
      setState(() {}); // Rebuild UI to reflect changes
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

                      // Enter Name
                      Padding(
                          padding: const EdgeInsets.only(top:16.0, bottom: 4.0, left: 16.0, right:16.0),
                          child: TextField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
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
                          padding: const EdgeInsets.only(top:4.0, bottom: 4.0, left: 16.0, right:16.0),
                          child: TextField(
                            controller: flightWeightController,
                            keyboardType: TextInputType.number,
                            // Only show numeric keyboard
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              // Allow only digits
                            ],
                            decoration: InputDecoration(
                              labelText: 'Flight Weight',
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
                        padding: const EdgeInsets.only(top:4.0, bottom: 4.0, left: 16.0, right:16.0),
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
                                'Primary Position',
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

                      // Enter tool(s) & weight
                      Padding(
                        padding: const EdgeInsets.only(top:4.0, bottom: 4.0, left: 16.0, right:16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: toolNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Tool Name',
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white, fontSize: 28),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: toolWeightController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Tool Weight',
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white, fontSize: 28),
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black),
                                ),
                                child: const Icon(Icons.add, color: Colors.black, size: 24),
                              ),
                              onPressed: addTool,
                            ),
                          ],
                        ),
                      ),

                      // Display added tools
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: ListView.builder(
                            itemCount: addedTools?.length,
                            itemBuilder: (context, index) {
                              final tool = addedTools?[index];
                              return Card(
                                elevation: 4,
                                color: Colors.black,
                                child: ListTile(
                                  title: Text(
                                    tool!.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${tool.weight} lbs',
                                    style: const TextStyle(color: Colors.white, fontSize: 20),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                    onPressed: () => removeTool(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),


                      // Save Button
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                              onPressed: isSaveButtonEnabled ? () => saveCrewMemberData() : null,  // Button is only enabled if there is input
                              style: style, // Main button theme
                              child: const Text(
                                  'Save'
                              )
                          ),
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
