import 'trip.dart';
import 'load.dart';
import 'crew.dart';
import 'crewmember.dart';
import 'gear.dart';
import 'saved_preferences.dart';

// Currently, this algorithm follows a heaviest loads first approach
// In the future, if we want to do a more balanced load approach,
// It will be slightly more complex - like a 'greedy balancing/backtracking' algo,
// where it finds the lightest load, and places the object there
// For Saw Team smart loading - just make sure both individuals on SawTeam1, 2, 3, etc., all go on same load

// TripPreference based sorting algorithm
void loadCalculator(Trip trip, TripPreference? tripPreference) {

  int availableSeats = trip.availableSeats;
  int maxLoadWeight = trip.allowable;

  // Get  number of loads based on allowable
  int numLoadsByAllowable = (crew.totalCrewWeight / trip.allowable).ceil();
  // Get number of loads based on seats available in the helicopter
  int numLoadsBySeat = (crew.crewMembers.length / trip.availableSeats).ceil();

  // Whichever number is greater is the actual number of loads required
  int numLoads = numLoadsByAllowable > numLoadsBySeat ? numLoadsByAllowable : numLoadsBySeat;

  // Create copies of crew and gear
  // List.from() creates a new list with exact same elements as OG.
  var crewMembersCopy = List.from(crew.crewMembers);
  var gearCopy = List.from(crew.gear);

  // Initialize all Loads
  List<Load> loads = List.generate(numLoads, (index) => Load(
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
                if (load.weight + crewMembersDynamic.flightWeight <= maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.weight += crewMembersDynamic.flightWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
                  break;
                }
              }
            }
            // If it's a group of crew members, i.e., a Saw Team
            else if (crewMembersDynamic is List<CrewMember>) {
              // Take the total weight of all crew member's in the group (saw team). Cannot be a double
              int totalGroupWeight = crewMembersDynamic.fold(0, (sum, member) => sum + member.flightWeight);
              for (var load in loads) {
                if (load.weight + totalGroupWeight <= maxLoadWeight &&
                    load.loadPersonnel.length + crewMembersDynamic.length <= availableSeats) {
                  load.loadPersonnel.addAll(crewMembersDynamic);
                  load.weight += totalGroupWeight;
                  crewMembersCopy.removeWhere((member) => crewMembersDynamic.contains(member));
                  break;
                }
              }
            }
          }

          break;

        case 1: // Last load preference - if weight exceeds last load place in second to last and so on
          for (var crewMembersDynamic in posPref.crewMembersDynamic) {
            if (crewMembersDynamic is CrewMember) {
              for (var load in loads.reversed) {
                if (load.weight + crewMembersDynamic.flightWeight <= maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.weight += crewMembersDynamic.flightWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
                  break;
                }
              }
            } else if (crewMembersDynamic is List<CrewMember>) {
              int totalGroupWeight = crewMembersDynamic.fold(0, (sum, member) => sum + member.flightWeight);
              for (var load in loads.reversed) {
                if (load.weight + totalGroupWeight <= maxLoadWeight &&
                    load.loadPersonnel.length + crewMembersDynamic.length <= availableSeats) {
                  load.loadPersonnel.addAll(crewMembersDynamic);
                  load.weight += totalGroupWeight;
                  crewMembersCopy.removeWhere((member) => crewMembersDynamic.contains(member));
                  break;
                }
              }
            }
          }
          break;

        case 2: // Balanced load preference - places cyclically first through last
          int loadIndex = 0;
          for (var crewMembersDynamic in posPref.crewMembersDynamic) {
            if (crewMembersDynamic is CrewMember) {
              while (loadIndex < loads.length) {
                var load = loads[loadIndex];
                if (load.weight + crewMembersDynamic.flightWeight <= maxLoadWeight &&
                    load.loadPersonnel.length < availableSeats) {
                  load.loadPersonnel.add(crewMembersDynamic);
                  load.weight += crewMembersDynamic.flightWeight;
                  crewMembersCopy.remove(crewMembersDynamic);
                  loadIndex = (loadIndex + 1) % loads.length;
                  break;
                }
                loadIndex = (loadIndex + 1) % loads.length;
              }
            } else if (crewMembersDynamic is List<CrewMember>) {
              int totalGroupWeight = crewMembersDynamic.fold(0, (sum, member) => sum + member.flightWeight);
              while (loadIndex < loads.length) {
                var load = loads[loadIndex];
                if (load.weight + totalGroupWeight <= maxLoadWeight &&
                    load.loadPersonnel.length + crewMembersDynamic.length <= availableSeats) {
                  load.loadPersonnel.addAll(crewMembersDynamic);
                  load.weight += totalGroupWeight;
                  crewMembersCopy.removeWhere((member) => crewMembersDynamic.contains(member));
                  loadIndex = (loadIndex + 1) % loads.length;     // Loop through loads cyclically
                  break;
                }
                loadIndex = (loadIndex + 1) % loads.length;
              }
            }
          }
          break;
      }
    }

    // Loop through all Gear Preferences, not based on Priority yet
    for (var gearPref in tripPreference.gearPreferences) {
      // Different cases based on Load Preference: First, Last, Balanced
      switch (gearPref.loadPreference) {
        case 0: // First load preference
          for (var gear in gearPref.gear) {
            for (var load in loads) {
              if (load.weight + gear.weight <= maxLoadWeight) {
                load.loadGear.add(gear);
                load.weight += gear.weight;
                gearCopy.remove(gear); // Remove from list
                break; // Move to next gear item
              }
            }
          }
          break;

        case 1: // Last load preference -  if weight exceeds last load weight, place in second to last and so on
          for (var gear in gearPref.gear) {
            for (var load in loads.reversed) {
              if (load.weight + gear.weight <= maxLoadWeight) {
                load.loadGear.add(gear);
                load.weight += gear.weight;
                gearCopy.remove(gear);
                break;
              }
            }
          }
          break;

        case 2: // Balanced load preference
          int loadIndex = 0;
          for (var gear in gearPref.gear) {
            while (loadIndex < loads.length) {
              var load = loads[loadIndex];
              if (load.weight + gear.weight <= maxLoadWeight) {
                load.loadGear.add(gear);
                load.weight += gear.weight;
                gearCopy.remove(gear);
                loadIndex = (loadIndex + 1) % loads.length; // Loop through loads
                break;
              }
              loadIndex = (loadIndex + 1) % loads.length;
            }
          }
          break;
      }
    }
  }

  // Fill the remaining space in loads with crew members and gear
  for (int i = 0; i < loads.length; i++) {
    Load currentLoad = loads[i];
    num currentLoadWeight = currentLoad.weight;

    while (currentLoadWeight < maxLoadWeight) {
      bool itemAdded = false;

      // Add remaining crew members not covered by positional preferences
      // Eventually to be replaced by "Smart Loading"
      if (crewMembersCopy.isNotEmpty &&
          currentLoadWeight + crewMembersCopy.first.flightWeight <= maxLoadWeight &&
          currentLoad.loadPersonnel.length < availableSeats) {
        var firstCrewMember = crewMembersCopy.first;
        currentLoadWeight += firstCrewMember.flightWeight;
        currentLoad.loadPersonnel.add(firstCrewMember);
        crewMembersCopy.removeAt(0);
        itemAdded = true;
      }

      // Add gear if space allows
      if (gearCopy.isNotEmpty &&
          currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {
        currentLoadWeight += gearCopy.first.weight;
        currentLoad.loadGear.add(gearCopy.first);
        gearCopy.removeAt(0);
        itemAdded = true;
      }

      if (!itemAdded || (crewMembersCopy.isEmpty && gearCopy.isEmpty)) {
        break;
      }
    }

    // Update load weight
    currentLoad.weight = currentLoadWeight.toInt();
    trip.addLoad(trip, currentLoad);
  }
  // Error checks to see if all Crew Members / Gear were allocated to loads
  if (crewMembersCopy.isNotEmpty || gearCopy.isNotEmpty) {
    print("Error: Not all crew members or gear items were allocated to a load.");
    if (crewMembersCopy.isNotEmpty) {
      print("Remaining crew members: ${crewMembersCopy.map((member) => member.name).join(', ')}");
    }
    if (gearCopy.isNotEmpty) {
      print("Remaining gear items: ${gearCopy.map((item) => item.name).join(', ')}");
    }
  }
  if (crewMembersCopy.isEmpty || gearCopy.isEmpty) {
    print("Success! All crew members and gear allocated to loads");
  }



}

// OG sorting algorithm
void loadCalculatorOG(Trip trip, TripPreference? tripPreference) {
  // Get the number of loads based on allowable, rounding up
  int numLoads = (crew.totalCrewWeight / trip.allowable).ceil();
  int maxLoadWeight = trip.allowable;

  // Create copies of crew and gear
  // List.from() creates a new list with exact same elements as OG.
  var crewMembersCopy = List.from(crew.crewMembers);
  var gearCopy = List.from(crew.gear);

  for (int i = 1; i <= numLoads; i++) {
    num currentLoadWeight = 0;
    List<CrewMember> thisLoadPersonnel = [];
    List<Gear> thisLoadGear = [];

    // Less than or equal to??
    while (currentLoadWeight < maxLoadWeight) {
      bool itemAdded = false;

      // Check if the first crew member can be added
      // If so add them, then remove them from the copied list
      if (crewMembersCopy.isNotEmpty &&
          currentLoadWeight + crewMembersCopy.first.flightWeight <=
              maxLoadWeight) {
        var firstCrewMember = crewMembersCopy.first;
        currentLoadWeight += firstCrewMember.flightWeight;
        thisLoadPersonnel.add(crewMembersCopy.first);
        crewMembersCopy
            .removeAt(0); // Remove the first crew member from the list
        itemAdded = true;
      }

      // Check if the first gear item can be added
      if (gearCopy.isNotEmpty &&
          currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {
        currentLoadWeight += gearCopy.first.weight;
        thisLoadGear.add(gearCopy.first);
        gearCopy.removeAt(0); // Remove the first gear item from the list
        itemAdded = true;
      }

      // If no more items can be added or both lists are empty, break the loop
      if (crewMembersCopy.isEmpty && gearCopy.isEmpty) {
        break;
      }

      if (!itemAdded) {
        break;
      }
    }

    int loadNumber = i;

    Load newLoad = Load(
      loadNumber: loadNumber,
      weight: currentLoadWeight.toInt(),
      loadPersonnel: thisLoadPersonnel,
      loadGear: thisLoadGear,
    );

    trip.addLoad(trip, newLoad);
  }

  //trip.printLoadDetails();
}

