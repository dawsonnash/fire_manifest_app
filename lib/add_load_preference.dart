import 'dart:ui';
import 'package:flutter/services.dart';

import 'Data/crew.dart';
import 'Data/saved_preferences.dart';
import 'Data/crewmember.dart';
import 'package:flutter/material.dart';

class AddLoadPreference extends StatefulWidget {
  const AddLoadPreference({super.key});

  @override
  State<AddLoadPreference> createState() => _AddLoadPreferenceState();
}

class _AddLoadPreferenceState extends State<AddLoadPreference>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // Variables to store user input
  // Priority decided as drag & drop
  int? selectedLoadPreference;
  // CrewMember controller? Or this
  //List<CrewMember>? selectedCrewMember = [];
  CrewMember? selectedCrewMember;

  List<CrewMember> selectedCrewMembers = [];

  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to open the multi-select dialog
  void _showCrewMemberSelectionDialog() async {
    final List<CrewMember>? result = await showDialog(
      context: context,
      builder: (context) {
        List<CrewMember> tempSelectedCrew = List.from(selectedCrewMembers);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Crew Members'),
              content: SingleChildScrollView(
                child: Column(
                  children: crew.crewMembers.map((crew) {
                    return CheckboxListTile(
                      title: Text(crew.name),
                      value: tempSelectedCrew.contains(crew),
                      onChanged: (bool? isChecked) {
                        setState(() {
                          if (isChecked == true) {
                            tempSelectedCrew.add(crew);
                          } else {
                            tempSelectedCrew.remove(crew);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(tempSelectedCrew);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCrewMembers = result;
        _checkInput(); // Update button state
      });
    }
  }

  void _checkInput() {
    setState(() {
      isSaveButtonEnabled = selectedCrewMembers.isNotEmpty;
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
    final InputDecorationTheme blackInputFieldTheme = InputDecorationTheme(
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
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Add Load Preference',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.black,
          dividerColor: Colors.black,
          indicatorColor: Colors.black,
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.person),
              text: 'Positional',
            ),
            Tab(
              icon: Icon(Icons.work_outline_outlined),
              text: 'Gear'
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
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
          TabBarView(
          controller: _tabController,
          children: <Widget>[

            // Positional Preference
// Positional Preference
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Spacer(flex: 1),

                    // Choose Crew Member(s) with GestureDetector for multi-select dialog
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: _showCrewMemberSelectionDialog,  // Trigger dialog on tap
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: Text(
                            selectedCrewMembers.isEmpty
                                ? 'Choose crew member(s)'
                                : selectedCrewMembers.map((e) => e.name).join(', '),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Enter Load Preference
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
                            value: selectedLoadPreference,
                            hint: const Text(
                              'Choose load preference',
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
                            items: loadPreferenceMap.entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedLoadPreference = newValue;
                                  // _checkInput();
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
                        onPressed: isSaveButtonEnabled ? () => _saveLoadPreference() : null,
                        style: style,  // Main button theme
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gear Preference
            const Center(
              child: Text("It's rainy here"),
            ),
          ],
        ),
      ],
      ),
    );
  }
  void _saveLoadPreference() {
    // Implement the save logic here, using selectedCrewMembers
    //print('Selected Crew Members: ${selectedCrewMembers.map((e) => e.name).join(', ')}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preference saved!')),
    );
  }
}
