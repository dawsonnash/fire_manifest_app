import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/Data/positional_preferences.dart';
import 'package:flutter/material.dart';

import '../CodeShare/colors.dart';
import '../Data/sling.dart';
import '../UI/main.dart';
import '../Data/crew.dart';
import '../Data/gear_preferences.dart';
import '../Data/trip.dart';
import 'dart:math';
import '../Data/load.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/trip_preferences.dart';

Future<void> externalLoadCalculator(BuildContext context, Trip trip, TripPreference? tripPreference, int safetyBuffer, LoadAccoutrement cargoNet12x12, LoadAccoutrement cargoNet20x20,
    LoadAccoutrement swivel, LoadAccoutrement leadLine) async {

  int maxLoadWeight = trip.allowable - safetyBuffer;  // Get max load weight

  int totalGearWeight = trip.totalCrewWeight ?? 0;

  int totalAccoutrementWeight =
      (cargoNet12x12.quantity * cargoNet12x12.weight) + (cargoNet20x20.quantity * cargoNet20x20.weight) + (swivel.quantity * swivel.weight) + (leadLine.quantity * leadLine.weight);

  int totalWeight = totalGearWeight + totalAccoutrementWeight;  // Calculate Total Weight (Gear + Accoutrements)

  int numLoads = (totalWeight / maxLoadWeight).ceil();    // Get  number of loads based on allowable
  int totalNets = cargoNet12x12.quantity + cargoNet20x20.quantity;

  // This treats quantities as individual items
  var gearCopy = <Gear>[];
  for (var gear in trip.gear) {
    for (int i = 0; i < gear.quantity; i++) {
      // Create copy of gear item for each quantity
      gearCopy.add(Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
    }
  }

// Initialize all Loads
  List<Load> loads = List.generate(
    numLoads,
        (index) => Load(
      loadNumber: index + 1,
      weight: 0, // Adjusted if missing swivels
      loadPersonnel: [],
      loadGear: [],
      slings: [], // Ensure slings list is initialized
      loadAccoutrements: [], // Ensure list is initialized
    ),
  );

// Initialize Slings and distribute cyclically
  int netIndex = 0; // Tracks assigned nets
  int loadIndex = 0; // Cycles through loads

  while (netIndex < totalNets) {
    // Assign a new sling to the current load in a cyclic manner
    Sling newSling = Sling(
      slingNumber: (loads[loadIndex].slings!.length + 1), // Sling numbers reset per load
      weight: 0,
      loadAccoutrements: [],
      loadGear: [],
    );

    // Add sling to corresponding load
    loads[loadIndex].slings?.add(newSling);
    netIndex++;

    // Move to the next load cyclically
    loadIndex = (loadIndex + 1) % numLoads; // Cycles back to 0 after reaching last load
  }

  // Now, distribute swivels CYCLICALLY across loads
  int swivelIndex = 0;
  int loadSwivelIndex = 0; // Track which load gets the next swivel

  while (swivelIndex < swivel.quantity) {
    // Assign one swivel per load in cyclic order
    LoadAccoutrement swivelAcc = LoadAccoutrement(
      name: "Swivel",
      weight: swivel.weight,
      quantity: 1,
    );

    loads[loadSwivelIndex].loadAccoutrements?.add(swivelAcc);
    swivelIndex++;

    // Move to the next load cyclically
    loadSwivelIndex = (loadSwivelIndex + 1) % numLoads;
  }

// After all swivels are placed, check each load if there's not enough swivels for each net
  for (var load in loads) {
    int slingCount = load.slings?.length ?? 0;
    int swivelCount = load.loadAccoutrements
        ?.where((acc) => acc.name == "Swivel")
        .length ??
        0;

    if (slingCount > swivelCount) {
      // If there are more slings than swivels, subtract the missing swivel weight from the load
      int missingSwivels = slingCount - swivelCount;
      int missingSwivelWeight = missingSwivels * swivel.weight;
      load.weight -= missingSwivelWeight; // Reduce total load weight
    } else if (slingCount == swivelCount) {
      // If each sling should get exactly one swivel, move them from load to sling level
      List<LoadAccoutrement> swivelsToDistribute = load.loadAccoutrements!
          .where((acc) => acc.name == "Swivel")
          .toList();

      for (int i = 0; i < slingCount; i++) {
        // Add the swivel to the sling
        load.slings?[i].loadAccoutrements.add(swivelsToDistribute[i]);

        // **Update the sling weight** after adding the swivel
        load.slings?[i].weight += swivelsToDistribute[i].weight;
      }

      // Remove all swivels from the load-level storage
      load.loadAccoutrements!.removeWhere((acc) => acc.name == "Swivel");

      // **Update the load weight** since swivels were moved to slings
      load.weight += swivelCount * swivel.weight;
    }

    // **Now, add a lead line to each sling**
    for (var sling in load.slings ?? []) {
      LoadAccoutrement leadLineAcc = LoadAccoutrement(
        name: "Lead Line",
        weight: leadLine.weight, // Use the weight of the leadLine object
        quantity: 1,
      );

      // Add lead line to sling
      sling.loadAccoutrements.add(leadLineAcc);

      // **Update the sling's weight** after adding the lead line
      sling.weight += leadLine.weight;

      // **Update the load's weight** to reflect the added lead line
      load.weight += leadLine.weight;
    }
  }

// Create a list of all nets (20x20 first, then 12x12)
  List<LoadAccoutrement> nets = [
    ...List.generate(cargoNet20x20.quantity, (index) => LoadAccoutrement(
      name: "Cargo Net (20'x20')",
      weight: cargoNet20x20.weight,
      quantity: 1,
    )),
    ...List.generate(cargoNet12x12.quantity, (index) => LoadAccoutrement(
      name: "Cargo Net (12'x12')",
      weight: cargoNet12x12.weight,
      quantity: 1,
    )),
  ];

  netIndex = 0; // Track how many nets have been placed
  int maxSlingCount = loads.map((load) => load.slings?.length ?? 0).reduce((a, b) => a > b ? a : b); // Find the load with the most slings

// Cyclically distribute nets across loads and slings
  for (int slingRound = 0; slingRound < maxSlingCount; slingRound++) {
    for (int loadIndex = loads.length - 1; loadIndex >= 0; loadIndex--) { // Start from last load, move backward
      Load currentLoad = loads[loadIndex];

      if (currentLoad.slings != null && slingRound < currentLoad.slings!.length) {
        Sling selectedSling = currentLoad.slings![slingRound]; // Get the next sling in the cycle

        if (netIndex < nets.length) {
          // Get the next net to place
          LoadAccoutrement netToPlace = nets[netIndex];

          // Add the net to the selected sling
          selectedSling.loadAccoutrements.add(netToPlace);
          selectedSling.weight += netToPlace.weight; // Update sling weight

          // Update the corresponding load weight
          currentLoad.weight += netToPlace.weight;

          // Move to the next net
          netIndex++;
        }
      }
    }
  }


// Print each load's weight after adjustments
  print("________________________________________________________");

  for (var load in loads) {
    print("Load# ${load.loadNumber}: Weight = ${load.weight} lbs");
  }
  // Filling in the remainder of gear
  loadIndex = 0; // To track current load index

  bool noMoreGearCanBeAdded = false;

  // Distribute Gear across loads
  while ((gearCopy.isNotEmpty && !noMoreGearCanBeAdded)) {
    Load currentLoad = loads[loadIndex];
    num currentLoadWeight = currentLoad.weight;

    bool itemAdded = false;

    // Add gear if space allows
    if (!itemAdded && gearCopy.isNotEmpty && currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {
      currentLoadWeight += gearCopy.first.weight;
      currentLoad.loadGear.add(gearCopy.first);
      gearCopy.removeAt(0);
      itemAdded = true;
    } else if (gearCopy.isNotEmpty && loads.every((load) => load.weight + gearCopy.first.weight > maxLoadWeight)) {
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
          isPersonalTool: gear.isPersonalTool,
          // Keep the personal tool flag
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
      if (!a.isPersonalTool && b.isPersonalTool) return 1; // General gear comes after personal tools
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
  if (gearCopy.isNotEmpty || duplicateGear.isNotEmpty) {
    String errorMessage = "Not all gear items were allocated to a load due to tight weight constraints. Try again or pick a higher allowable.";

    if (duplicateGear.isNotEmpty) {
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
// Function to calculate the total weight of a Load
int calculateLoadWeight(Load load) {
  int totalWeight = 0;

  // Sum all Load Accoutrements (if not null)
  load.loadAccoutrements?.forEach((acc) {
    totalWeight += (acc.weight ?? 0) * (acc.quantity ?? 1);
  });

  // Sum all Gear (if not null)
  for (var gear in load.loadGear) {
    totalWeight += (gear.weight ?? 0) * (gear.quantity ?? 1);
  }

  // Sum all Custom Items (if not null)
  for (var item in load.customItems) {
    totalWeight += item.weight ?? 0;
  }

  // Sum all Sling Weights (if any slings exist)
  load.slings?.forEach((sling) {
    totalWeight += calculateSlingWeight(sling);
  });

  return totalWeight;
}

// Function to calculate the total weight of a Sling
int calculateSlingWeight(Sling sling) {
  int totalWeight = 0;

  // Add the base weight of the sling
  totalWeight += sling.weight;

  // Sum all Load Accoutrements
  for (var acc in sling.loadAccoutrements) {
    totalWeight += acc.weight * acc.quantity;
  }

  // Sum all Gear
  for (var gear in sling.loadGear) {
    totalWeight += gear.weight * gear.quantity;
  }

  // Sum all Custom Items
  for (var item in sling.customItems) {
    totalWeight += item.weight;
  }

  return totalWeight;
}

TripPreference cleanTripPreference(TripPreference originalPreference, Trip trip) {
  // Create a deep copy of the original TripPreference
  TripPreference tripPreferenceCopy = TripPreference(
    tripPreferenceName: originalPreference.tripPreferenceName,
  );

  // Filter and copy positional preferences
  tripPreferenceCopy.positionalPreferences = originalPreference.positionalPreferences.map((posPref) {
    // Filter crew members based on trip.crewMembers
    var validCrewMembersDynamic = posPref.crewMembersDynamic
        .map((crewDynamic) {
          if (crewDynamic is CrewMember) {
            // Check if the crew member exists in the trip
            return trip.crewMembers.any((member) => member.name == crewDynamic.name) ? crewDynamic : null;
          } else if (crewDynamic is List<CrewMember>) {
            // Filter the group to include only members that exist in the trip
            var validGroup = crewDynamic.where((member) => trip.crewMembers.any((tripMember) => tripMember.name == member.name)).toList();

            return validGroup.isNotEmpty ? validGroup : null;
          }
          return null;
        })
        .where((item) => item != null)
        .toList(); // Remove null entries

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

// // TripPreference can be "None", i.e., null
// if (tripPreference != null) {
// // Clean the tripPreference before evaluation
// var tripPreferenceCopy = cleanTripPreference(tripPreference, trip);
//
//
// // Loop through all Gear Preferences, not based on Priority yet
// for (var gearPref in tripPreferenceCopy.gearPreferences) {
// switch (gearPref.loadPreference) {
// case 0: // First load preference
// for (var gear in gearPref.gear) {
// int quantityToAdd = gear.quantity;
// int addedQuantity = 0;
//
// // Loop through loads to distribute gear based on the quantity
// for (var load in loads) {
// while (addedQuantity < quantityToAdd) {
// if (gearCopy.isNotEmpty &&
// load.weight + gear.weight <= maxLoadWeight) {
// // Add the gear item to the load
// load.loadGear.add(
// Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
// load.weight += gear.weight;
// addedQuantity++;
// // Remove one instance of the gear from gearCopy
// gearCopy.removeAt(
// gearCopy.indexWhere((item) => item.name == gear.name));
// } else {
// break;
// }
// }
// if (addedQuantity >= quantityToAdd) break;
// }
// }
// break;
//
// case 1: // Last load preference
// for (var gear in gearPref.gear) {
// int quantityToAdd = gear.quantity;
// int addedQuantity = 0;
//
// // Loop through loads in reverse order to distribute gear
// for (var load in loads.reversed) {
// while (addedQuantity < quantityToAdd) {
// if (gearCopy.isNotEmpty &&
// load.weight + gear.weight <= maxLoadWeight) {
// load.loadGear.add(
// Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
// load.weight += gear.weight;
// addedQuantity++;
// gearCopy.removeAt(
// gearCopy.indexWhere((item) => item.name == gear.name));
// } else {
// break;
// }
// }
// if (addedQuantity >= quantityToAdd) break;
// }
// }
// break;
//
// case 2: // Balanced load preference
// int loadIndex = 0;
//
// // Loop through each gear item in the gear preference
// for (var gear in gearPref.gear) {
// // Continue until there are no more items of this specific gear type in gearCopy
// while (gearCopy.any((item) => item.name == gear.name)) {
// int quantityToAdd = gear.quantity;
// int addedQuantity = 0;
//
// // Continue placing gear items on loads until the preferred quantity is added
// while (addedQuantity < quantityToAdd) {
// var load = loads[loadIndex];
//
// // Try to add as many items of this specific gear type as possible
// while (addedQuantity < quantityToAdd &&
// load.weight + gear.weight <= maxLoadWeight &&
// gearCopy.any((item) => item.name == gear.name)) {
// // Add one item of this specific gear type to the current load
// load.loadGear.add(
// Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
// load.weight += gear.weight;
// addedQuantity++;
//
// // Remove one instance of this specific gear type from gearCopy
// int indexToRemove =
// gearCopy.indexWhere((item) => item.name == gear.name);
// if (indexToRemove != -1) {
// gearCopy.removeAt(indexToRemove);
// }
// }
//
// // Move to the next load after placing the preferred quantity (or as much as possible)
// loadIndex = (loadIndex + 1) % loads.length;
// }
// }
// }
// break;
// }
// }
// }
