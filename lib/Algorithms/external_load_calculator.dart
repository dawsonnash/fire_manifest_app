import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/Data/positional_preferences.dart';
import 'package:flutter/material.dart';

import '../CodeShare/colors.dart';
import '../UI/main.dart';
import '../Data/crew.dart';
import '../Data/gear_preferences.dart';
import '../Data/trip.dart';
import 'dart:math';
import '../Data/load.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/trip_preferences.dart';

Future<void> externalLoadCalculator(
    BuildContext context,
    Trip trip, TripPreference?
    tripPreference,
    int safetyBuffer,
    LoadAccoutrement cargoNet12x12,
    LoadAccoutrement cargoNet20x20,
    LoadAccoutrement swivel,
    LoadAccoutrement leadLine) async {

  // Get max load weight
  int maxLoadWeight = trip.allowable - safetyBuffer;

  // Get Total Gear Weight
  int totalGearWeight = trip.totalCrewWeight ?? 0;

  // Calculate Total Accoutrement Weight
  int totalAccoutrementWeight = (cargoNet12x12.quantity * cargoNet12x12.weight) +
      (cargoNet20x20.quantity * cargoNet20x20.weight) +
      (swivel.quantity * swivel.weight) +
      (leadLine.quantity * leadLine.weight);

  // Calculate Total Weight (Gear + Accoutrements)
  int totalWeight = totalGearWeight + totalAccoutrementWeight;

  // Get  number of loads based on allowable
  int numLoads = (totalWeight / maxLoadWeight).ceil();

  // This treats quantities as individual items
  var gearCopy = <Gear>[];
  for (var gear in trip.gear) {
    for (int i = 0; i < gear.quantity; i++) {
      // Create copy of gear item for each quantity
      gearCopy.add(Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
    }
  }

  // Initialize all Loads
  List<Load> loads = List.generate(
      numLoads,
          (index) => Load(
        loadNumber: index + 1,
        weight: 0,
        loadPersonnel: [],
        loadGear: [],
      ));

  // TripPreference can be "None", i.e., null
  if (tripPreference != null) {
    // Clean the tripPreference before evaluation
    var tripPreferenceCopy = cleanTripPreference(tripPreference, trip);


    // Loop through all Gear Preferences, not based on Priority yet
    for (var gearPref in tripPreferenceCopy.gearPreferences) {
      switch (gearPref.loadPreference) {
        case 0: // First load preference
          for (var gear in gearPref.gear) {
            int quantityToAdd = gear.quantity;
            int addedQuantity = 0;

            // Loop through loads to distribute gear based on the quantity
            for (var load in loads) {
              while (addedQuantity < quantityToAdd) {
                if (gearCopy.isNotEmpty &&
                    load.weight + gear.weight <= maxLoadWeight) {
                  // Add the gear item to the load
                  load.loadGear.add(
                      Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
                  load.weight += gear.weight;
                  addedQuantity++;
                  // Remove one instance of the gear from gearCopy
                  gearCopy.removeAt(
                      gearCopy.indexWhere((item) => item.name == gear.name));
                } else {
                  break;
                }
              }
              if (addedQuantity >= quantityToAdd) break;
            }
          }
          break;

        case 1: // Last load preference
          for (var gear in gearPref.gear) {
            int quantityToAdd = gear.quantity;
            int addedQuantity = 0;

            // Loop through loads in reverse order to distribute gear
            for (var load in loads.reversed) {
              while (addedQuantity < quantityToAdd) {
                if (gearCopy.isNotEmpty &&
                    load.weight + gear.weight <= maxLoadWeight) {
                  load.loadGear.add(
                      Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
                  load.weight += gear.weight;
                  addedQuantity++;
                  gearCopy.removeAt(
                      gearCopy.indexWhere((item) => item.name == gear.name));
                } else {
                  break;
                }
              }
              if (addedQuantity >= quantityToAdd) break;
            }
          }
          break;

        case 2: // Balanced load preference
          int loadIndex = 0;

          // Loop through each gear item in the gear preference
          for (var gear in gearPref.gear) {
            // Continue until there are no more items of this specific gear type in gearCopy
            while (gearCopy.any((item) => item.name == gear.name)) {
              int quantityToAdd = gear.quantity;
              int addedQuantity = 0;

              // Continue placing gear items on loads until the preferred quantity is added
              while (addedQuantity < quantityToAdd) {
                var load = loads[loadIndex];

                // Try to add as many items of this specific gear type as possible
                while (addedQuantity < quantityToAdd &&
                    load.weight + gear.weight <= maxLoadWeight &&
                    gearCopy.any((item) => item.name == gear.name)) {
                  // Add one item of this specific gear type to the current load
                  load.loadGear.add(
                      Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
                  load.weight += gear.weight;
                  addedQuantity++;

                  // Remove one instance of this specific gear type from gearCopy
                  int indexToRemove =
                  gearCopy.indexWhere((item) => item.name == gear.name);
                  if (indexToRemove != -1) {
                    gearCopy.removeAt(indexToRemove);
                  }
                }

                // Move to the next load after placing the preferred quantity (or as much as possible)
                loadIndex = (loadIndex + 1) % loads.length;
              }
            }
          }
          break;
      }
    }
  }

  // Filling in the remainder of crew members and gear
  int loadIndex = 0; // To track current load index

  bool noMoreGearCanBeAdded = false;

  // Distribute Gear across loads
  while (
      (gearCopy.isNotEmpty && !noMoreGearCanBeAdded)) {
    Load currentLoad = loads[loadIndex];
    num currentLoadWeight = currentLoad.weight;

    bool itemAdded = false;

    // Add gear if space allows
    if (!itemAdded &&
        gearCopy.isNotEmpty &&
        currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {
      currentLoadWeight += gearCopy.first.weight;
      currentLoad.loadGear.add(gearCopy.first);
      gearCopy.removeAt(0);
      itemAdded = true;
    } else if (gearCopy.isNotEmpty &&
        loads.every((load) =>
        load.weight + gearCopy.first.weight > maxLoadWeight)) {
      noMoreGearCanBeAdded = true; // No more gear can be added to any load
    }

    // Update load weight
    currentLoad.weight = currentLoadWeight.toInt();

    // Move to the next load in a cyclic manner
    loadIndex = (loadIndex + 1) % loads.length;
  }

  // Combine identical gear items within each load
  for (var load in loads) {
    List<Gear> consolidatedGear = [];

    for (var gear in load.loadGear) {
      var existingGear = consolidatedGear.firstWhere(
            (item) => item.name == gear.name && item.isPersonalTool == gear.isPersonalTool,
        orElse: () => Gear(
          name: gear.name,
          weight: gear.weight,
          quantity: 0,
          isPersonalTool: gear.isPersonalTool, // Keep the personal tool flag
          isHazmat: gear.isHazmat,
        ),
      );

      if (existingGear.quantity == 0) {
        consolidatedGear.add(existingGear);
      }
      existingGear.quantity += gear.quantity;
    }

    load.loadGear = consolidatedGear;
  }

  // Sort load contents: crew first, then personal tools, then general gear
  for (var load in loads) {
    // Sort the loadGear list
    load.loadGear.sort((a, b) {
      if (a.isPersonalTool && !b.isPersonalTool) return -1; // Personal tools come first
      if (!a.isPersonalTool && b.isPersonalTool) return 1;  // General gear comes after personal tools
      return a.name.compareTo(b.name); // Otherwise, sort alphabetically by name
    });
  }


  loads.removeWhere((load) => load.weight == 0); // Remove loads with zero weight
  // Re-consolidate load numbers
  for (int i = 0; i < loads.length; i++) {
    loads[i].loadNumber = i + 1; // Reassign sequential load numbers starting from 1
  }

  // Ensure the trip object reflects the updated loads
  for (var load in loads) {
    trip.addLoad(trip, load);
  }


// Find duplicate gear
  Set<String> gearNames = {}; // Store unique gear names
  List<String> duplicateGear = [];
  for (var item in crew.gear) {
    if (!gearNames.add(item.name)) {
      duplicateGear.add(item.name); // Add to duplicate list if already exists
    }
  }

// Error messaging: gear didn't get allocated or there were duplicates
  if ( gearCopy.isNotEmpty || duplicateGear.isNotEmpty) {
    String errorMessage =  "Not all gear items were allocated to a load due to tight weight constraints. Try again or pick a higher allowable.";

    if ( duplicateGear.isNotEmpty) {
      errorMessage += "\nAdditionally, duplicate items were detected.";
    }

    // Show error dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            "Load Calculation Error",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$errorMessage\n", style: TextStyle(color: AppColors.textColorPrimary)),

              if (gearCopy.isNotEmpty) const SizedBox(height: 8), // Add spacing

              if (gearCopy.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Remaining gear items:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColorPrimary,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: gearCopy.map((item) => item.name).join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (duplicateGear.isNotEmpty) const SizedBox(height: 8), // Add spacing

              if (duplicateGear.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Duplicate gear items detected:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Highlight duplicates
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: duplicateGear.join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary)),
            ),
          ],
        );
      },
    );
  }


  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => MyHomePage(),
    ),
        (Route<dynamic> route) => false, // This clears all the previous routes
  );
}


TripPreference cleanTripPreference(TripPreference originalPreference, Trip trip) {
  // Create a deep copy of the original TripPreference
  TripPreference tripPreferenceCopy = TripPreference(
    tripPreferenceName: originalPreference.tripPreferenceName,
  );

  // Filter and copy positional preferences
  tripPreferenceCopy.positionalPreferences = originalPreference.positionalPreferences.map((posPref) {
    // Filter crew members based on trip.crewMembers
    var validCrewMembersDynamic = posPref.crewMembersDynamic.map((crewDynamic) {
      if (crewDynamic is CrewMember) {
        // Check if the crew member exists in the trip
        return trip.crewMembers.any((member) => member.name == crewDynamic.name) ? crewDynamic : null;
      } else if (crewDynamic is List<CrewMember>) {
        // Filter the group to include only members that exist in the trip
        var validGroup = crewDynamic.where((member) =>
            trip.crewMembers.any((tripMember) => tripMember.name == member.name)).toList();

        return validGroup.isNotEmpty ? validGroup : null;
      }
      return null;
    }).where((item) => item != null).toList(); // Remove null entries

    return PositionalPreference(
      priority: posPref.priority,
      loadPreference: posPref.loadPreference,
      crewMembersDynamic: validCrewMembersDynamic,
    );
  }).toList();

  // Filter and copy gear preferences
  tripPreferenceCopy.gearPreferences = originalPreference.gearPreferences.map((gearPref) {
    // Filter gear items based on trip.gear
    var validGear = gearPref.gear.where((gearItem) {
      return trip.gear.any((tripGear) => tripGear.name == gearItem.name);
    }).toList();

    return GearPreference(
      priority: gearPref.priority,
      loadPreference: gearPref.loadPreference,
      gear: validGear,
    );
  }).toList();

  return tripPreferenceCopy;
}
