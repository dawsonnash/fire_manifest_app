import 'dart:math';

import 'package:fire_app/Data/positional_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/gear_preferences.dart';
import '../Data/load.dart';
import '../Data/trip.dart';
import '../Data/trip_preferences.dart';
import '../main.dart';

// TripPreference based sorting algorithm
Future<void> loadCalculator(BuildContext context, Trip trip, TripPreference? tripPreference) async {
  int availableSeats = trip.availableSeats;
  int maxLoadWeight =  trip.allowable;

  bool tripPreferenceUsed = tripPreference == null ? false : true;

  // Get  number of loads based on allowable
  int numLoadsByAllowable = (trip.totalCrewWeight! / maxLoadWeight).ceil();
  // Get number of loads based on seats available in the helicopter
  int numLoadsBySeat = (trip.crewMembers.length / trip.availableSeats).ceil();

  // Whichever number is greater is the actual number of loads required
  int numLoads = numLoadsByAllowable > numLoadsBySeat
      ? numLoadsByAllowable
      : numLoadsBySeat;

  // Create copies of crew and gear
  var crewMembersCopy = trip.crewMembers.map((member) {
    return CrewMember(
      name: member.name,
      flightWeight: member.flightWeight,
      position: member.position,
      personalTools: member.personalTools?.map((tool) {
        return Gear(
          name: tool.name,
          weight: tool.weight,
          quantity: tool.quantity,
          isPersonalTool: tool.isPersonalTool,
          isHazmat: tool.isHazmat
        );
      }).toList(),
    );
  }).toList();

  // Shuffle and balance crew members
  shuffleCrewMembers(crewMembersCopy);

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

    // Loop through all Positional Preferences, not based on Priority yet
    for (var posPref in tripPreferenceCopy.positionalPreferences) {
      // Different cases based on Load Preference: First (0), Last (1), Balanced (2)
      switch (posPref.loadPreference) {
        case 0: // First load preference
          for (var crewMembersDynamic in posPref.crewMembersDynamic) {
            // If it's just an individual crew member
            if (crewMembersDynamic is CrewMember) {
              for (var load in loads) {
                // If the new Crew Member's flight weight is less than the allowable load weight and there are enough seats available
                if (load.weight + crewMembersDynamic.totalCrewMemberWeight <=
                    maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(CrewMember(
                    name: crewMembersDynamic.name,
                    flightWeight: crewMembersDynamic.flightWeight,
                    position: crewMembersDynamic.position,
                    personalTools: crewMembersDynamic.personalTools?.map((tool) {
                      return Gear(
                        name: tool.name,
                        weight: tool.weight,
                        quantity: tool.quantity,
                        isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                      );
                    }).toList(),
                  ));
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.removeWhere((member) =>
                  member.name == crewMembersDynamic.name);
                  break;
                }
              }
            }
            // If it's a group of crew members, i.e., a Saw Team
            else if (crewMembersDynamic is List<CrewMember>) {
              // Take the total weight of all crew member's in the group (saw team). Cannot be a double
              int totalGroupWeight = crewMembersDynamic.fold(
                  0, (sum, member) => sum + member.totalCrewMemberWeight);
              for (var load in loads) {
                if (load.weight + totalGroupWeight <= maxLoadWeight &&
                    load.loadPersonnel.length + crewMembersDynamic.length <=
                        availableSeats) {
                  load.loadPersonnel.addAll(crewMembersDynamic.map((member) {
                    return CrewMember(
                      name: member.name,
                      flightWeight: member.flightWeight,
                      position: member.position,
                      personalTools: member.personalTools?.map((tool) {
                        return Gear(
                          name: tool.name,
                          weight: tool.weight,
                          quantity: tool.quantity,
                          isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                        );
                      }).toList(),
                    );
                  }));
                  // Add all personal tools
                  for (var member in crewMembersDynamic) {
                    load.loadGear
                        .addAll(member.personalTools as Iterable<Gear>);
                  }
                  load.weight += totalGroupWeight;
                  // Remove members from crewMembersCopy based on their name
                  for (var dynamicMember in crewMembersDynamic) {
                    crewMembersCopy.removeWhere((member) => member.name == dynamicMember.name);
                  }
                  break;
                }
              }
            }
          }

          break;

        case 1: // Last load preference - if weight exceeds last load place in second to last and so on
          for (var crewMembersDynamic in posPref.crewMembersDynamic) {
            // If individual crew members are being sorted
            if (crewMembersDynamic is CrewMember) {
              for (var load in loads.reversed) {
                if (load.weight + crewMembersDynamic.totalCrewMemberWeight <=
                    maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(CrewMember(
                    name: crewMembersDynamic.name,
                    flightWeight: crewMembersDynamic.flightWeight,
                    position: crewMembersDynamic.position,
                    personalTools: crewMembersDynamic.personalTools?.map((tool) {
                      return Gear(
                        name: tool.name,
                        weight: tool.weight,
                        quantity: tool.quantity,
                        isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                      );
                    }).toList(),
                  ));
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.removeWhere((member) =>
                  member.name == crewMembersDynamic.name);
                  break;
                }
              }
            } // If groups of crew members are being sorted (i.e., saw teams)
            else if (crewMembersDynamic is List<CrewMember>) {
              int totalGroupWeight = crewMembersDynamic.fold(
                  0, (sum, member) => sum + member.totalCrewMemberWeight);
              for (var load in loads.reversed) {
                if (load.weight + totalGroupWeight <= maxLoadWeight &&
                    load.loadPersonnel.length + crewMembersDynamic.length <=
                        availableSeats) {
                  load.loadPersonnel.addAll(crewMembersDynamic.map((member) {
                    return CrewMember(
                      name: member.name,
                      flightWeight: member.flightWeight,
                      position: member.position,
                      personalTools: member.personalTools?.map((tool) {
                        return Gear(
                          name: tool.name,
                          weight: tool.weight,
                          quantity: tool.quantity,
                          isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                        );
                      }).toList(),
                    );
                  }));
                  for (var member in crewMembersDynamic) {
                    load.loadGear
                        .addAll(member.personalTools as Iterable<Gear>);
                  }
                  load.weight += totalGroupWeight;
                  // Remove members from crewMembersCopy based on their name
                  for (var dynamicMember in crewMembersDynamic) {
                    crewMembersCopy.removeWhere((member) => member.name == dynamicMember.name);
                  }
                  break;
                }
              }
            }
          }
          break;

        case 2: // Balanced load preference - places cyclically first through last
          int loadIndex = 0;

          // Calculate the maximum available seats on any load
          // Edge case for user inputted 1 available seat
          int maxAvailableSeats = loads
              .map((load) => availableSeats - load.loadPersonnel.length)
              .reduce((a, b) => a > b ? a : b);

          for (var crewMembersDynamic in posPref.crewMembersDynamic) {
            if (crewMembersDynamic is CrewMember) {
              while (loadIndex < loads.length) {
                var load = loads[loadIndex];
                if (load.weight + crewMembersDynamic.totalCrewMemberWeight <=
                    maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(CrewMember(
                    name: crewMembersDynamic.name,
                    flightWeight: crewMembersDynamic.flightWeight,
                    position: crewMembersDynamic.position,
                    personalTools: crewMembersDynamic.personalTools?.map((tool) {
                      return Gear(
                        name: tool.name,
                        weight: tool.weight,
                        quantity: tool.quantity,
                        isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                      );
                    }).toList(),
                  ));
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.removeWhere((member) =>
                  member.name == crewMembersDynamic.name);
                  loadIndex = (loadIndex + 1) % loads.length;
                  break;
                }
                loadIndex = (loadIndex + 1) % loads.length;
              }
            } else if (crewMembersDynamic is List<CrewMember>) {

              int totalGroupWeight = crewMembersDynamic.fold(
                  0, (sum, member) => sum + member.totalCrewMemberWeight);

              // FMximum remaining weight among all loads
              int maxRemainingWeight = loads.fold(0, (maxWeight, load) =>
              (maxLoadWeight - load.weight) > maxWeight ? (maxLoadWeight - load.weight) : maxWeight);

              // If the group size exceeds max available seats, treat members individually
              if ((crewMembersDynamic.length > maxAvailableSeats) || (totalGroupWeight > maxLoadWeight) || (totalGroupWeight > maxRemainingWeight)) {
                for (var member in crewMembersDynamic) {
                  while (loadIndex < loads.length) {
                    var load = loads[loadIndex];
                    if (load.weight + member.totalCrewMemberWeight <= maxLoadWeight &&
                        load.loadPersonnel.length < availableSeats) {
                      load.loadPersonnel.add(member);
                      load.loadGear.addAll(member.personalTools as Iterable<Gear>);
                      load.weight += member.totalCrewMemberWeight;
                      // Remove the member based on matching properties
                      crewMembersCopy.removeWhere((copyMember) =>
                      copyMember.name == member.name);
                      loadIndex = (loadIndex + 1) % loads.length;
                      break;
                    }
                    loadIndex = (loadIndex + 1) % loads.length;
                  }
                }
              } else {
                // Treat as a group if it fits within the constraints
                int totalGroupWeight = crewMembersDynamic.fold(
                    0, (sum, member) => sum + member.totalCrewMemberWeight);
                while (loadIndex < loads.length) {
                  var load = loads[loadIndex];
                  if (load.weight + totalGroupWeight <= maxLoadWeight &&
                      load.loadPersonnel.length + crewMembersDynamic.length <=
                          availableSeats) {
                    load.loadPersonnel.addAll(crewMembersDynamic.map((member) {
                      return CrewMember(
                        name: member.name,
                        flightWeight: member.flightWeight,
                        position: member.position,
                        personalTools: member.personalTools?.map((tool) {
                          return Gear(
                            name: tool.name,
                            weight: tool.weight,
                            quantity: tool.quantity,
                            isPersonalTool: tool.isPersonalTool, isHazmat: tool.isHazmat
                          );
                        }).toList(),
                      );
                    }));
                    for (var member in crewMembersDynamic) {
                      load.loadGear
                          .addAll(member.personalTools as Iterable<Gear>);
                    }
                    load.weight += totalGroupWeight;
                    // Remove members from crewMembersCopy based on their name
                    for (var dynamicMember in crewMembersDynamic) {
                      crewMembersCopy.removeWhere((member) => member.name == dynamicMember.name);
                    }
                    loadIndex = (loadIndex + 1) %
                        loads.length; // Loop through loads cyclically
                    break;
                  }
                  loadIndex = (loadIndex + 1) % loads.length;
                }
              }
            }
          }
          break;
      }
    }

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

  bool noMoreCrewCanBeAdded = false;
  bool noMoreGearCanBeAdded = false;

  while ((crewMembersCopy.isNotEmpty && !noMoreCrewCanBeAdded) ||
      (gearCopy.isNotEmpty && !noMoreGearCanBeAdded)) {
    Load currentLoad = loads[loadIndex];
    num currentLoadWeight = currentLoad.weight;

    bool itemAdded = false;

    // Add remaining crew members not covered by positional preferences
    if (crewMembersCopy.isNotEmpty &&
        currentLoadWeight + crewMembersCopy.first.totalCrewMemberWeight <=
            maxLoadWeight &&
        currentLoad.loadPersonnel.length < availableSeats) {
      var firstCrewMember = crewMembersCopy.first;
      currentLoadWeight += firstCrewMember.totalCrewMemberWeight;
      currentLoad.loadPersonnel.add(CrewMember(
        name: firstCrewMember.name,
        flightWeight: firstCrewMember.flightWeight,
        position: firstCrewMember.position,
        personalTools: firstCrewMember.personalTools?.map((tool) {
          return Gear(
            name: tool.name,
            weight: tool.weight,
            quantity: tool.quantity,
            isPersonalTool: tool.isPersonalTool,
              isHazmat: tool.isHazmat

          );
        }).toList(),
      ));
      currentLoad.loadGear
          .addAll(firstCrewMember.personalTools as Iterable<Gear>);
      crewMembersCopy.removeAt(0);
      itemAdded = true;
    } else if (crewMembersCopy.isNotEmpty &&
        loads.every((load) =>
        load.weight + crewMembersCopy.first.totalCrewMemberWeight > maxLoadWeight ||
            load.loadPersonnel.length >= availableSeats)) {
      noMoreCrewCanBeAdded = true; // No more crew can be added to any load
    }

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

  // Ensure all identical gear items are combined within each load, but only if they are BOTH personal tools or BOTH regular gear
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

// Find duplicate crew members
  Set<String> crewNames = {}; // Store unique crew member names
  List<String> duplicateCrew = [];

  for (var member in crew.crewMembers) {
    if (!crewNames.add(member.name)) {
      duplicateCrew.add(member.name); // Add to duplicate list if already exists
    }
  }

// Find duplicate gear
  Set<String> gearNames = {}; // Store unique gear names
  List<String> duplicateGear = [];

  for (var item in crew.gear) {
    if (!gearNames.add(item.name)) {
      duplicateGear.add(item.name); // Add to duplicate list if already exists
    }
  }
// Error message setup
  if (crewMembersCopy.isNotEmpty || gearCopy.isNotEmpty || duplicateCrew.isNotEmpty || duplicateGear.isNotEmpty) {
    String errorMessage =  "Not all crew members or gear items were allocated to a load due to tight weight constraints. Try again or pick a higher allowable.";

    if (duplicateCrew.isNotEmpty || duplicateGear.isNotEmpty) {
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

              if (crewMembersCopy.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Remaining crew members:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.text16,
                    ),
                    children: [
                      TextSpan(
                        text: crewMembersCopy.map((member) => member.name).join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (gearCopy.isNotEmpty) const SizedBox(height: 8), // Add spacing

              if (gearCopy.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Remaining gear items:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColorPrimary,
                      fontSize: AppData.text16,
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

              if (duplicateCrew.isNotEmpty) const SizedBox(height: 8), // Add spacing

              if (duplicateCrew.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Duplicate crew members detected:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Highlight duplicates
                      fontSize: AppData.text16,
                    ),
                    children: [
                      TextSpan(
                        text: duplicateCrew.join(', '),
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
                      fontSize: AppData.text16,
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
    FirebaseAnalytics.instance.logEvent(
      name: 'internal_load_calculation_error',
      parameters: {
        'trip_name': trip.tripName,
        'total_weight': trip.totalCrewWeight!,
        'trip_allowable': trip.allowable,
        'trip_available_seats': trip.availableSeats,
        'tripPreferenceUsed' : tripPreferenceUsed ? 'true' : 'false',
        'num_loads': numLoads,
        'num_unallocated_crewmembers': crewMembersCopy.length,
        'num_unallocated_gear': gearCopy.length,
        'num_duplicate_crewmembers': duplicateCrew.length,
        'num_duplicate_gear': duplicateGear.length,
      },
    );
  }


  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => MyHomePage(),
      settings: RouteSettings(name: 'HomePage'),

    ),
        (Route<dynamic> route) => false, // This clears all the previous routes
  );
  FirebaseAnalytics.instance.logEvent(
    name: 'trip_generated_internal',
    parameters: {
      'trip_name': trip.tripName,
      'trip_allowable': trip.allowable,
      'trip_available_seats': trip.availableSeats,
      'tripPreferenceUsed' : tripPreferenceUsed ? 'true' : 'false',
    },
  );
}

void shuffleCrewMembers(List<dynamic> crewMembersCopy) {

  // Step 1: Group crew members by their positions
  Map<int, List<CrewMember>> positionGroups = {};
  for (var member in crewMembersCopy) {
    positionGroups.putIfAbsent(member.position, () => []).add(member);
  }

  // Step 2: Shuffle crew members within each position group
  var random = Random();
  positionGroups.forEach((key, group) {
    group.shuffle(random);
  });

  // Step 3: Interweave members from different position groups
  List<CrewMember> balancedCrewList = [];
  bool membersRemaining = true;
  while (membersRemaining) {
    membersRemaining = false;
    for (var group in positionGroups.values) {
      if (group.isNotEmpty) {
        balancedCrewList.add(group.removeAt(0));
        membersRemaining = true;
      }
    }
  }

  // Step 4: Light shuffle of the final list for additional randomness
  balancedCrewList.shuffle(random);

  // Replace original crewMembersCopy with the balanced list
  crewMembersCopy
    ..clear()
    ..addAll(balancedCrewList);
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
