import 'trip.dart';
import 'load.dart';
import 'crew.dart';
import 'crewmember.dart';
import 'gear.dart';

// Currently, this algorithm follows a heaviest loads first approach
// In the future, if we want to do a more balanced load approach,
// It will be slightly more complex - like a 'greedy balancing/backtracking' algo,
// where it finds the lightest load, and places the object there
//
// For Saw Team smart loading - just make sure both individuals on SawTeam1, 2, 3, etc., all go on same load
void loadCalculator(Trip trip) {
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

  trip.printLoadDetails();
}
