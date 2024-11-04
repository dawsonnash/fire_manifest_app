import 'dart:ui';
import 'package:flutter/services.dart';

import 'Data/crew.dart';
import 'Data/gear.dart';
import 'Data/saved_preferences.dart';
import 'Data/crewmember.dart';
import 'package:flutter/material.dart';

class AddLoadPreference extends StatefulWidget {
  // This page requires a Trip Preference object to be passed to it - to edit it
  final TripPreference tripPreference;
  final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const AddLoadPreference({
    super.key,
    required this.tripPreference,
    required this.onUpdate});

  @override
  State<AddLoadPreference> createState() => _AddLoadPreferenceState();
}

class _AddLoadPreferenceState extends State<AddLoadPreference>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // Variables to store user input
  // Priority decided as drag & drop in UI
  int? selectedPositionalLoadPreference;
  List<CrewMember> selectedCrewMembers = [];

  int? selectedGearLoadPreference;
  List<Gear> selectedGear = [];

  bool isPositionalSaveButtonEnabled = false; // Controls whether saving button is showing
  bool isGearSaveButtonEnabled = false; // Controls whether saving button is showing


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

  // Functions to open the multi-select dialog for crewmembers/gear
  void _showCrewMemberSelectionDialog() async {

    // Gets crew members already used in existing PositionalPreferences
    final usedCrewMembers = widget.tripPreference.positionalPreferences
        .expand((posPref) => posPref.crewMembers)
        .toSet();  // Convert to Set to avoid duplicates

    // Filters out used crew members for selection list
    final availableCrewMembers = crew.crewMembers
        .where((crewMember) => !usedCrewMembers.contains(crewMember))
        .toList();

    // If no crew members available, show a message
    if (availableCrewMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more crew members available',
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
      return;
    }

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
                  children: availableCrewMembers.map((crew) {
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
        _checkPositionalInput(); // Update button state
      });
    }
  }

  // Functions to open the multi-select dialog for crewmembers/gear
  void _showGearSelectionDialog() async {

    // Gets gear already used in existing GearPreferences
    final usedGear = widget.tripPreference.gearPreferences
        .expand((posPref) => posPref.gear)
        .toSet();  // Convert to Set to avoid duplicates

    // Filters out used gear for selection list
    final availableGear = crew.gear
        .where((gear) => !usedGear.contains(gear))
        .toList();

    // If no gear available, show a message
    if (availableGear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more gear available',
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
      return;
    }

    final List<Gear>? result = await showDialog(
      context: context,
      builder: (context) {
        List<Gear> tempSelectedGear = List.from(selectedGear);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Gears'),
              content: SingleChildScrollView(
                child: Column(
                  children: availableGear.map((gear) {
                    return CheckboxListTile(
                      title: Text(gear.name),
                      value: tempSelectedGear.contains(gear),
                      onChanged: (bool? isChecked) {
                        setState(() {
                          if (isChecked == true) {
                            tempSelectedGear.add(gear);
                          } else {
                            tempSelectedGear.remove(gear);
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
                    Navigator.of(context).pop(tempSelectedGear);
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
        selectedGear = result;
        _checkGearInput(); // Update button state
      });
    }
  }

  void _checkPositionalInput() {
    setState(() {
      isPositionalSaveButtonEnabled = selectedCrewMembers.isNotEmpty && selectedPositionalLoadPreference != null;
    });
  }

  void _checkGearInput() {
    setState(() {
      isGearSaveButtonEnabled = selectedGear.isNotEmpty && selectedGearLoadPreference != null;
    });
  }

  void savePositionalLoadPreference(TripPreference newTripPreference) {

    final newPositionalPreference = PositionalPreference(
        priority: 1,  // TO be changed and updated via UI drag n drop
        loadPreference: selectedPositionalLoadPreference!,
        crewMembers: selectedCrewMembers
    );

    // Add this new preference to the TripPreference object
    newTripPreference.positionalPreferences.add(newPositionalPreference);

    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preference saved!',
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

  void saveGearLoadPreference(TripPreference newTripPreference) {

    final newGearPreference = GearPreference(
        priority: 1,  // To be changed and updated via UI drag n drop
        loadPreference: selectedGearLoadPreference!,
        gear: selectedGear,
    );

    // Add this new preference to the TripPreference object
    newTripPreference.gearPreferences.add(newGearPreference);

    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preference saved!',
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
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Spacer(flex: 1),

                    // Choose Crew Member(s)
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
                            value: selectedPositionalLoadPreference,
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
                                  selectedPositionalLoadPreference = newValue;
                                  _checkPositionalInput();
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
                        onPressed: isPositionalSaveButtonEnabled ? () => savePositionalLoadPreference(widget.tripPreference) : null,
                        style: style,  // Main button theme
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gear Preference
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Spacer(flex: 1),

                    // Choose Gear
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: _showGearSelectionDialog,  // Trigger dialog on tap
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: Text(
                            selectedGear.isEmpty
                                ? 'Choose gear'
                                : selectedGear.map((e) => e.name).join(', '),
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
                            value: selectedGearLoadPreference,
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
                                  selectedGearLoadPreference = newValue;
                                  _checkGearInput();
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
                        onPressed: isGearSaveButtonEnabled ? () => saveGearLoadPreference(widget.tripPreference) : null,
                        style: style,  // Main button theme
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }
}
