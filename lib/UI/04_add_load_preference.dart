import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/gear.dart';
import '../Data/saved_preferences.dart';
import '../Data/gear_preferences.dart';
import '../Data/positional_preferences.dart';
import '../Data/trip_preferences.dart';
import '../Data/crewmember.dart';
import 'package:flutter/material.dart';

class AddLoadPreference extends StatefulWidget {
  // This page requires a Trip Preference object to be passed to it - to edit it
  final TripPreference tripPreference;
  final VoidCallback onUpdate; // Callback for deletion to update previous page

  const AddLoadPreference(
      {super.key, required this.tripPreference, required this.onUpdate});

  @override
  State<AddLoadPreference> createState() => _AddLoadPreferenceState();
}

class _AddLoadPreferenceState extends State<AddLoadPreference>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // Variables to store user input
  // Priority decided as drag & drop in UI
  int? selectedPositionalLoadPreference;
  List<dynamic> selectedCrewMembers = [];

  int? selectedGearLoadPreference;
  List<Gear> selectedGear = [];
  Map<Gear, int> selectedGearQuantities = {};

  bool isPositionalSaveButtonEnabled =
      false; // Controls whether saving button is showing
  bool isGearSaveButtonEnabled =
      false; // Controls whether saving button is showing

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

  // Function to open the multi-select dialog for crew members
  // overly logically complex - do not try to understand
  void _showCrewMemberSelectionDialog() async {
    List<Map<String, dynamic>> sawTeamOptions = [];
    List<Map<String, dynamic>> individualOptions = [];

    // Collect all used crew members (both individuals and members of Saw Teams)
    final usedCrewMembers = widget.tripPreference.positionalPreferences
        .expand((posPref) => posPref.crewMembersDynamic)
        .expand((member) => member is List<CrewMember> ? member : [member])
        .map((cm) => (cm as CrewMember).name + "_" + cm.position.toString()) // Store "name_position" key
        .toSet();


    // Populate saw team options
    for (int i = 1; i <= 6; i++) {
      List<CrewMember> sawTeam = crew.getSawTeam(i);

      // Only add the Saw Team if NONE of its members are in usedCrewMembers or selectedCrewMembers
      if (sawTeam.isNotEmpty &&
          sawTeam.every((member) =>
          !usedCrewMembers.contains(member.name + "_" + member.position.toString()) &&
              !selectedCrewMembers.any((selected) =>
              selected is CrewMember &&
                  selected.name == member.name &&
                  selected.position == member.position)
          )) {
        sawTeamOptions.add({'name': 'Saw Team $i', 'members': sawTeam});
      }
    }


    // Populate individual crew member options, so they remain visible and checked if selected
    for (var member in crew.crewMembers) {
      if (!usedCrewMembers.contains(member.name + "_" + member.position.toString())) {
        // only consider members not in usedCrewMembers
        bool isPartOfSelectedSawTeam = false;

        // Check if the member is part of a fully selected Saw Team
        for (int i = 1; i <= 6; i++) {
          List<CrewMember> sawTeam = crew.getSawTeam(i);
          if (sawTeam.contains(member) &&
              selectedCrewMembers.any(
                  (item) => item is Map && item['name'] == 'Saw Team $i')) {
            isPartOfSelectedSawTeam = true;
            break;
          }
        }

        // Add the crew member to individual options if they're not part of a fully selected Saw Team
        if (!isPartOfSelectedSawTeam) {
          individualOptions.add({
            'name': member.name,
            'members': [member],
            'isSelected': selectedCrewMembers.contains(member)
            // Check if the member is already selected
          });
        }
      }
    }

    if (sawTeamOptions.isEmpty && individualOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No crew members available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show the selection dialog
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateSelection() {
              // Clear and repopulate options based on the current selection
              sawTeamOptions.clear();
              individualOptions.clear();

              // Recollect usedCrewMembers
              final usedCrewMembers = widget.tripPreference.positionalPreferences
                  .expand((posPref) => posPref.crewMembersDynamic)
                  .expand((member) => member is List<CrewMember> ? member : [member])
                  .map((cm) => cm.name.trim().toLowerCase() + "_" + cm.position.toString()) // Normalize comparison
                  .toSet();

              // Repopulate Saw Team options
              for (int i = 1; i <= 6; i++) {
                List<CrewMember> sawTeam = crew.getSawTeam(i);
                List<String> sawTeamKeys = sawTeam.map((m) =>
                m.name.trim().toLowerCase() + "_" + m.position.toString()).toList();

                if (sawTeam.isNotEmpty &&
                    sawTeam.every((member) =>
                    !usedCrewMembers.contains(member.name.trim().toLowerCase() + "_" + member.position.toString()) &&
                        !selectedCrewMembers.any((selected) =>
                        selected is CrewMember &&
                            selected.name.trim().toLowerCase() == member.name.trim().toLowerCase() &&
                            selected.position == member.position))) {
                  sawTeamOptions.add({'name': 'Saw Team $i', 'members': sawTeam});
                }
              }

              // Repopulate individual crew member options
              for (var member in crew.crewMembers) {
                String memberKey = member.name.trim().toLowerCase() + "_" + member.position.toString();

                if (!usedCrewMembers.contains(memberKey)) {
                  bool isPartOfSelectedSawTeam = false;

                  for (int i = 1; i <= 6; i++) {
                    List<CrewMember> sawTeam = crew.getSawTeam(i);
                    List<String> sawTeamKeys = sawTeam.map((m) =>
                    m.name.trim().toLowerCase() + "_" + m.position.toString()).toList();

                    if (sawTeam.contains(member) &&
                        selectedCrewMembers.any((item) => item is Map && item['name'] == 'Saw Team $i')) {
                      isPartOfSelectedSawTeam = true;
                      break;
                    }
                  }

                  if (!isPartOfSelectedSawTeam) {
                    individualOptions.add({
                      'name': member.name,
                      'members': [member],
                      'isSelected': selectedCrewMembers.any((selected) =>
                      selected is CrewMember &&
                          selected.name.trim().toLowerCase() == member.name.trim().toLowerCase() &&
                          selected.position == member.position)
                    });
                  }
                }
              }

              setState(() {}); // Refresh UI
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title:  Text(
                'Select Crew Members',
                style: TextStyle(
                  color: AppColors.textColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...sawTeamOptions.map((option) {
                        bool isSelected = selectedCrewMembers.any((item) =>
                            item is Map && item['name'] == option['name']);
                        return CheckboxListTile(
                          activeColor: AppColors.textColorPrimary,
                          // Checkbox outline color when active
                          checkColor: AppColors.textColorSecondary,
                          side: BorderSide(
                            color: AppColors.textColorPrimary, // Outline color
                            width: 2.0, // Outline width
                          ),
                          title: Text(option['name'], style: TextStyle(color: AppColors.textColorPrimary),),
                          value: isSelected,
                          onChanged: (bool? isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                selectedCrewMembers.add(option);
                                for (var member in option['members']) {
                                  selectedCrewMembers.remove(member);
                                }
                              } else {
                                selectedCrewMembers.removeWhere((item) =>
                                    item is Map &&
                                    item['name'] == option['name']);
                              }
                              updateSelection();
                            });
                          },
                        );
                      }).toList(),
                      if (sawTeamOptions.isNotEmpty &&
                          individualOptions.isNotEmpty)
                         Divider(color: AppColors.textColorPrimary, thickness: 1),
                      ...sortCrewListByPosition(
                          individualOptions.map((option) => option['members'].first as CrewMember).toList()
                      ).map((CrewMember member) {
                        bool isSelected = selectedCrewMembers.contains(member);

                        return CheckboxListTile(
                          activeColor: AppColors.textColorPrimary,
                          checkColor: AppColors.textColorSecondary,
                          side: BorderSide(
                            color: AppColors.textColorPrimary,
                            width: 2.0,
                          ),
                          title: Text(
                            member.name,
                            style: TextStyle(
                              color: AppColors.textColorPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            member.getPositionTitle(member.position),
                            style: TextStyle(
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                selectedCrewMembers.add(member);
                              } else {
                                selectedCrewMembers.remove(member);
                              }
                              updateSelection();
                            });
                          },
                        );
                      }).toList(),

                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Save', style: TextStyle(color: AppColors.saveButtonAllowableWeight,     fontSize: AppData.bottomDialogTextSize,
                  ),),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      _checkPositionalInput();
    });
  }

  // Functions to open the multi-select dialog for gear
  void _showGearSelectionDialog() async {
    // Map to track the total used quantities for each gear item
    Map<String, int> totalQuantities = {
      for (var gear in crew.gear) gear.name: 0,
      // Use gear.name. Coudl make a unique key
    };

    // Calculate total used quantities from all existing gear preferences
    for (var gearPref in widget.tripPreference.gearPreferences) {
      for (var gear in gearPref.gear) {
        totalQuantities[gear.name] =
            (totalQuantities[gear.name] ?? 0) + gear.quantity;
      }
    }

    // List of gear items with updated available quantities
    final availableGear = crew.gear.where((gear) {
      int remainingQuantity = gear.quantity - (totalQuantities[gear.name] ?? 0);
      return remainingQuantity > 0;
    }).toList();

    // Initialize selected gear quantities if not already set
    if (selectedGearQuantities.isEmpty) {
      selectedGearQuantities = {
        for (var gear in selectedGear) gear: gear.quantity
      };
    }
    if (availableGear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No gear available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 1),
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
              backgroundColor: AppColors.textFieldColor2,
              title:  Text(
                'Select Gear',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
                child: SingleChildScrollView(
                  child: Column(
                    children: availableGear.map((gear) {
                      // Calculate the correct remaining quantity for this gear item
                      int remainingQuantity =
                          gear.quantity - (totalQuantities[gear.name] ?? 0);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    gear.name,
                                    style: TextStyle(
                                      fontSize: AppData.text16,
                                      color: AppColors.textColorPrimary,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Use ellipsis if text is too long
                                  ),
                                ),
                                Text(
                                  ' (x$remainingQuantity)  ',
                                  style: TextStyle(
                                    fontSize: AppData.text12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tempSelectedGear.contains(gear))
                            if (remainingQuantity > 1)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: AppColors.textFieldColor2,
                                        title: Text(
                                            'Select Quantity for ${gear.name}',
                                        style: TextStyle(color: AppColors.textColorPrimary),),
                                        content: Container(
                                          height: 150,
                                          child: CupertinoPicker(
                                            scrollController:
                                                FixedExtentScrollController(
                                                    initialItem:
                                                        (selectedGearQuantities[
                                                                    gear] ??
                                                                1) -
                                                            1),
                                            itemExtent: 32.0,
                                            // Height of each item
                                            onSelectedItemChanged: (int value) {
                                              setState(() {
                                                selectedGearQuantities[gear] =
                                                    value + 1;
                                              });
                                            },
                                            children: List<Widget>.generate(
                                                remainingQuantity, (int index) {
                                              return Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(fontSize: AppData.text20, color: AppColors.textColorPrimary),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child:  Text('Select', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize),),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'Qty: ${selectedGearQuantities[gear] ?? 1}',
                                      style: TextStyle(
                                        fontSize: AppData.text16,
                                        color: AppColors.textColorPrimary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.textColorPrimary
                                    ),
                                  ],
                                ),
                              ),
                          Checkbox(
                            activeColor: AppColors.textColorPrimary,
                            // Checkbox outline color when active
                            checkColor: AppColors.textColorSecondary,
                            side: BorderSide(
                              color: AppColors.textColorPrimary, // Outline color
                              width: 2.0, // Outline width
                            ),
                            value: tempSelectedGear.contains(gear),
                            onChanged: (bool? isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  tempSelectedGear.add(gear);
                                  selectedGearQuantities[gear] = 1;
                                } else {
                                  tempSelectedGear.remove(gear);
                                  selectedGearQuantities.remove(gear);
                                }
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    tempSelectedGear.forEach((gear) {
                      selectedGearQuantities[gear] =
                          selectedGearQuantities[gear] ?? 1;
                    });
                    Navigator.of(context).pop(tempSelectedGear);
                  },
                  child:  Text('Save', style: TextStyle(color: AppColors.saveButtonAllowableWeight,     fontSize: AppData.bottomDialogTextSize,
                  ),),
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
        _checkGearInput();
      });
    }
  }

  void _checkPositionalInput() {
    setState(() {
      isPositionalSaveButtonEnabled = selectedCrewMembers.isNotEmpty &&
          selectedPositionalLoadPreference != null;
    });
  }

  void _checkGearInput() {
    setState(() {
      isGearSaveButtonEnabled =
          selectedGear.isNotEmpty && selectedGearLoadPreference != null;
    });
  }

  void savePositionalLoadPreference(TripPreference newTripPreference) {
    // Create a new list to store crew members dynamically
    List<dynamic> crewMembersToSave = [];

    for (var member in selectedCrewMembers) {
      if (member is Map && member.containsKey('members')) {
        // Fully detach CrewMembers from Hive before saving
        List<CrewMember> copiedSawTeam = (member['members'] as List<CrewMember>)
            .map((crew) => CrewMember(
          name: crew.name,
          flightWeight: crew.flightWeight,
          position: crew.position,
          personalTools: crew.personalTools?.map((tool) => tool.copyWith()).toList(),
          id: crew.id, // Keep ID, but detach from Hive
        ))
            .toList();

        crewMembersToSave.add(copiedSawTeam); // Store detached List<CrewMember>
      } else if (member is CrewMember) {
        // Fully copy CrewMember to ensure it's detached from Hive
        crewMembersToSave.add(CrewMember(
          name: member.name,
          flightWeight: member.flightWeight,
          position: member.position,
          personalTools: member.personalTools?.map((tool) => tool.copyWith()).toList(),
          id: member.id, // Keep ID, but detach from Hive
        ));
      }
    }
    // Create a new PositionalPreference with the updated crew members list
    final newPositionalPreference = PositionalPreference(
      priority: 1, // Adjusted later through UI
      loadPreference: selectedPositionalLoadPreference!,
      crewMembersDynamic: crewMembersToSave,
    );

    // Add the new preference to the TripPreference object
    savedPreferences.addPositionalPreference(newTripPreference, newPositionalPreference);

    // Trigger the update callback
    widget.onUpdate();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preference saved!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Return to the previous screen
  }

  void saveGearLoadPreference(TripPreference newTripPreference) {
    // Create deep copies of Gear objects with updated quantities
    List<Gear> deepCopiedSelectedGear = selectedGear.map((gear) {
      return Gear(
        name: gear.name,
        weight: gear.weight,
        quantity: selectedGearQuantities[gear] ?? 1, // Copy new quantity
        isPersonalTool: gear.isPersonalTool,
        isHazmat: gear.isHazmat,
      );
    }).toList();

    // New GearPreference object with deep-copied Gear objects
    final newGearPreference = GearPreference(
      priority: 1, // To be updated through UI
      loadPreference: selectedGearLoadPreference!,
      gear: deepCopiedSelectedGear, // Now using deep copies
    );

    // Add to TripPreference object
    savedPreferences.addGearPreference(newTripPreference, newGearPreference);

    // Trigger the update callback
    widget.onUpdate();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preference saved!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: AppColors.fireColor,
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
      resizeToAvoidBottomInset: false,
      // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        backgroundColor: AppColors.appBarColor,
        title:  Text(
          'Add Load Preference',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        bottom: TabBar(
          unselectedLabelColor: AppColors.tabIconColor,
          labelColor: AppColors.primaryColor,
          dividerColor: AppColors.appBarColor,
          indicatorColor: AppColors.primaryColor,
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.person),
              text: 'Positional',
            ),
            Tab(icon: Icon(Icons.work_outline_outlined), text: 'Gear'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                ? Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.cover, // Cover the entire background
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Container(
                  color: AppColors.logoImageOverlay, // Semi-transparent overlay
                  width: double.infinity,
                  height: double.infinity,
                ),
              ],
            )
                : null) // No image if background is disabled
                : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Always display in light mode
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover, // Cover the entire background
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                // Positional Preference
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Choose Crew Member(s)
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: GestureDetector(
                          onTap: _showCrewMemberSelectionDialog,
                          // Trigger dialog on tap
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.textFieldColor,
                              borderRadius: BorderRadius.circular(12.0),
                              border:
                                  Border.all(color: AppColors.borderPrimary, width: 2.0),
                            ),
                            child: Text(
                              selectedCrewMembers.isEmpty
                                  ? 'Choose crew member(s)'
                                  : selectedCrewMembers.map((e) {
                                      if (e is Map &&
                                          e.containsKey('name') &&
                                          e['name'].startsWith('Saw Team')) {
                                        return e[
                                            'name']; // Display "Saw Team i"
                                      } else if (e is CrewMember) {
                                        return e
                                            .name; // Display individual crew member name
                                      }
                                      return '';
                                    }).join(', '),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.0),
                      // Choose Load Preference
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedPositionalLoadPreference,
                              hint: Text(
                                'Choose load preference',
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                ),
                              ),
                              dropdownColor: AppColors.textFieldColor2,
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 22,
                              ),
                              iconEnabledColor: AppColors.textColorPrimary,
                              items: loadPreferenceMap.entries.map((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.value, style: TextStyle(color: AppColors.textColorPrimary),),
                                      IconButton(
                                        icon: Icon(
                                          Icons.info_outline,
                                          color: AppColors.textColorPrimary,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          // Info dialog with loadpref explanation
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                    '${entry.value} Load Preference',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.textColorPrimary
                                                    )),
                                                content: Text(
                                                  getPreferenceInfo(entry
                                                      .key), //Load Preference explanation
                                                  style: TextStyle(color: AppColors.textColorPrimary),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child:  Text('Close', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
                          onPressed: isPositionalSaveButtonEnabled
                              ? () => savePositionalLoadPreference(
                                  widget.tripPreference)
                              : null,
                          style: style, // Main button theme
                          child:  Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Gear Preference
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                      SizedBox(height: 16),
                      // Choose Gear
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: GestureDetector(
                          onTap: _showGearSelectionDialog,
                          // Trigger dialog on tap
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.textFieldColor,
                              borderRadius: BorderRadius.circular(12.0),
                              border:
                                  Border.all(color: AppColors.borderPrimary, width: 2.0),
                            ),
                            child: Text(
                              selectedGear.isEmpty
                                  ? 'Choose gear'
                                  : selectedGear.map((e) {
                                      final quantity =
                                          selectedGearQuantities[e] ??
                                              1; // Use selected quantity
                                      return '${e.name} (x$quantity)';
                                    }).join(', '),
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Enter Load Preference
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedGearLoadPreference,
                              hint: Text(
                                'Choose load preference',
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                ),
                              ),
                              dropdownColor: AppColors.textFieldColor2,
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 22,
                              ),
                              iconEnabledColor: AppColors.textColorPrimary,
                              items: loadPreferenceMap.entries.map((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.value),
                                      IconButton(
                                        icon: Icon(
                                          Icons.info_outline,
                                          color: AppColors.textColorPrimary,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          // Info dialog with loadpref explanation
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                    '${entry.value} Load Preference',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.textColorPrimary
                                                    )),
                                                content: Text(
                                                  getPreferenceInfo(entry
                                                      .key), //Load Preference explanation
                                                  style: TextStyle(color: AppColors.textColorPrimary),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child:  Text('Close', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
                          onPressed: isGearSaveButtonEnabled
                              ? () =>
                                  saveGearLoadPreference(widget.tripPreference)
                              : null,
                          style: style, // Main button theme
                          child: const Text('Save'),
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

String getPreferenceInfo(int? preference) {
  switch (preference) {
    case 0:
      return "Places crew members/gear into the first load based on the order selected. If a crew member's or gear's weight exceeds the allowable load weight, they will be placed into the next available load.";
    case 1:
      return "Places crew members/gear into the last load based on the order selected. If a crew member's or gear's weight exceeds the allowable load weight, they will be placed in the next available load, working backward from the last load to the first.";
    case 2:
      return 'Distributes selected crew members/gear evenly across loads, working from the first load to the last.';
    default:
      return 'Select a preference to see more information.';
  }
}
