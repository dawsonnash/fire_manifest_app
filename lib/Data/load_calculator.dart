import 'package:flutter/material.dart';

import 'trip.dart';
import 'dart:math';
import 'load.dart';
import 'crew.dart';
import 'crewmember.dart';
import 'gear.dart';
import 'trip_preferences.dart';

// TripPreference based sorting algorithm
void loadCalculator(BuildContext context, Trip trip, TripPreference? tripPreference) {
  int availableSeats = trip.availableSeats;
  int maxLoadWeight = trip.allowable;

  // Get  number of loads based on allowable
  int numLoadsByAllowable = (crew.totalCrewWeight / trip.allowable).ceil();
  // Get number of loads based on seats available in the helicopter
  int numLoadsBySeat = (crew.crewMembers.length / trip.availableSeats).ceil();

  // Whichever number is greater is the actual number of loads required
  int numLoads = numLoadsByAllowable > numLoadsBySeat
      ? numLoadsByAllowable
      : numLoadsBySeat;

  // Create copies of crew and gear
  var crewMembersCopy = List.from(crew.crewMembers);
  // Shuffle and balance crew members
  shuffleCrewMembers(crewMembersCopy);

  // This treats quantities as individual items
  var gearCopy = <Gear>[];
  for (var gear in crew.gear) {
    for (int i = 0; i < gear.quantity; i++) {
      // Create copy of gear item for each quantity
      gearCopy.add(Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool));
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
    // Loop through all Positional Preferences, not based on Priority yet
    for (var posPref in tripPreference.positionalPreferences) {
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
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
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
                  load.loadPersonnel.addAll(crewMembersDynamic);
                  // Add all personal tools
                  crewMembersDynamic.forEach((member) {
                    load.loadGear
                        .addAll(member.personalTools as Iterable<Gear>);
                  });
                  load.weight += totalGroupWeight;
                  crewMembersCopy.removeWhere(
                      (member) => crewMembersDynamic.contains(member));
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
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
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
                  load.loadPersonnel.addAll(crewMembersDynamic);
                  crewMembersDynamic.forEach((member) {
                    load.loadGear
                        .addAll(member.personalTools as Iterable<Gear>);
                  });
                  load.weight += totalGroupWeight;
                  crewMembersCopy.removeWhere(
                      (member) => crewMembersDynamic.contains(member));
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
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.loadGear.addAll(
                      crewMembersDynamic.personalTools as Iterable<Gear>);
                  load.weight += crewMembersDynamic.totalCrewMemberWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
                  loadIndex = (loadIndex + 1) % loads.length;
                  break;
                }
                loadIndex = (loadIndex + 1) % loads.length;
              }
            } else if (crewMembersDynamic is List<CrewMember>) {
              // If the group size exceeds max available seats, treat members individually
              if (crewMembersDynamic.length > maxAvailableSeats) {
                for (var member in crewMembersDynamic) {
                  while (loadIndex < loads.length) {
                    var load = loads[loadIndex];
                    if (load.weight + member.totalCrewMemberWeight <= maxLoadWeight &&
                        load.loadPersonnel.length < availableSeats) {
                      load.loadPersonnel.add(member);
                      load.loadGear.addAll(member.personalTools as Iterable<Gear>);
                      load.weight += member.totalCrewMemberWeight;
                      crewMembersCopy.remove(member);
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
                    load.loadPersonnel.addAll(crewMembersDynamic);
                    crewMembersDynamic.forEach((member) {
                      load.loadGear
                          .addAll(member.personalTools as Iterable<Gear>);
                    });
                    load.weight += totalGroupWeight;
                    crewMembersCopy.removeWhere(
                            (member) => crewMembersDynamic.contains(member));
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
    for (var gearPref in tripPreference.gearPreferences) {
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
                      Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool));
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
                      Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool));
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
                      Gear(name: gear.name, weight: gear.weight, quantity: 1,  isPersonalTool: gear.isPersonalTool));
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

  while (crewMembersCopy.isNotEmpty || gearCopy.isNotEmpty) {
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
      currentLoad.loadPersonnel.add(firstCrewMember);
      currentLoad.loadGear
          .addAll(firstCrewMember.personalTools as Iterable<Gear>);
      crewMembersCopy.removeAt(0);
      itemAdded = true;
    }

    // Add gear if space allows
    if (!itemAdded &&
        gearCopy.isNotEmpty &&
        currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {
      currentLoadWeight += gearCopy.first.weight;
      currentLoad.loadGear.add(gearCopy.first);
      gearCopy.removeAt(0);
      itemAdded = true;
    }

    // Update load weight
    currentLoad.weight = currentLoadWeight.toInt();

    // Move to the next load in a cyclic manner
    loadIndex = (loadIndex + 1) % loads.length;

    // Break the loop if no items are left to add
    if (!itemAdded && crewMembersCopy.isEmpty && gearCopy.isEmpty) {
      break;
    }
  }

  // Ensure all identical gear items are combined within each load, i,e, removes identical items and increases quantity
  for (var load in loads) {
    List<Gear> consolidatedGear = [];

    for (var gear in load.loadGear) {
      var existingGear = consolidatedGear.firstWhere(
            (item) => item.name == gear.name,
        orElse: () => Gear(name: gear.name, weight: gear.weight, quantity: 0,   isPersonalTool: gear.isPersonalTool),
      );

      if (existingGear.quantity == 0) {
        consolidatedGear.add(existingGear);
      }
      existingGear.quantity += gear.quantity;
    }

    load.loadGear = consolidatedGear;
  }

  // Ensure the trip object reflects the updated loads
  for (var load in loads) {
    trip.addLoad(trip, load);
  }


  if (crewMembersCopy.isNotEmpty || gearCopy.isNotEmpty) {
    String errorMessage =
        "Error: Not all crew members or gear items were allocated to a load.";
    String remainingCrew = crewMembersCopy.isNotEmpty
        ? "Remaining crew members: ${crewMembersCopy.map((member) => member.name).join(', ')}"
        : "";
    String remainingGear = gearCopy.isNotEmpty
        ? "Remaining gear items: ${gearCopy.map((item) => item.name).join(', ')}"
        : "";

    // Show error dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text("Algorithm Error: Not all crew members or gear allocated"),
          content: Text("$errorMessage\n\n$remainingCrew\n$remainingGear"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  } else {
    print("Success! All crew members and gear allocated to loads.");
  }
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
