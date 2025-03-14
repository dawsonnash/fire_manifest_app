import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/Data/positional_preferences.dart';
import 'package:flutter/material.dart';

import '../CodeShare/colors.dart';
import '../Data/sling.dart';
import '../main.dart';
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
  /// Algo Variables
  int maxLoadWeight = trip.allowable - safetyBuffer; // Get max load weight
  int totalGearWeight = trip.totalCrewWeight ?? 0;
  int totalAccoutrementWeight =
      (cargoNet12x12.quantity * cargoNet12x12.weight) + (cargoNet20x20.quantity * cargoNet20x20.weight) + (swivel.quantity * swivel.weight) + (leadLine.quantity * leadLine.weight);
  int totalWeight = totalGearWeight + totalAccoutrementWeight; // Calculate Total Weight (Gear + Accoutrements)
  int numLoads = (totalWeight / maxLoadWeight).ceil(); // Get  number of loads based on allowable
  int totalNets = cargoNet12x12.quantity + cargoNet20x20.quantity;

  /// Gear array (Deep Copy) ~ Quantities treated as individual items
  var gearCopy = <Gear>[];
  for (var gear in trip.gear) {
    for (int i = 0; i < gear.quantity; i++) {
      // Create copy of gear item for each quantity
      gearCopy.add(Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
    }
  }

  var gearCopyHazmat = <Gear>[];
  var gearCopyNonHazmat = <Gear>[];
  for (var gear in trip.gear) {
    for (int i = 0; i < gear.quantity; i++) {
      // Create copy of gear item for each quantity
      if (gear.isHazmat) {
        gearCopyHazmat.add(Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
      } else {
        gearCopyNonHazmat.add(Gear(name: gear.name, weight: gear.weight, quantity: 1, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));
      }
    }
  }

  /// Load and Sling Initialization / Swivel, Leadline Distribution
  List<Load> loads = List.generate(
    numLoads,
        (index) => Load(
      loadNumber: index + 1,
      weight: 0,
      // Adjusted if missing swivels
      loadPersonnel: [],
      loadGear: [],
      slings: [],
      // Ensure slings list is initialized
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
    int swivelCount = load.loadAccoutrements?.where((acc) => acc.name == "Swivel").length ?? 0;

    if (slingCount > swivelCount) {
      // If there are more slings than swivels, subtract the missing swivel weight from the load
      int missingSwivels = slingCount - swivelCount;
      int missingSwivelWeight = missingSwivels * swivel.weight;
      load.weight -= missingSwivelWeight; // Reduce total load weight
    } else if (slingCount == swivelCount) {
      // If each sling should get exactly one swivel, move them from load to sling level
      List<LoadAccoutrement> swivelsToDistribute = load.loadAccoutrements!.where((acc) => acc.name == "Swivel").toList();

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

  /// Net Distribution
// Create a list of all nets (20x20 first, then 12x12)
  List<LoadAccoutrement> nets = [
    ...List.generate(
        cargoNet20x20.quantity,
            (index) => LoadAccoutrement(
          name: "Cargo Net (20'x20')",
          weight: cargoNet20x20.weight,
          quantity: 1,
        )),
    ...List.generate(
        cargoNet12x12.quantity,
            (index) => LoadAccoutrement(
          name: "Cargo Net (12'x12')",
          weight: cargoNet12x12.weight,
          quantity: 1,
        )),
  ];
  netIndex = 0; // Track how many nets have been placed
  int maxSlingCount = loads.map((load) => load.slings?.length ?? 0).reduce((a, b) => a > b ? a : b); // Find the load with the most slings
  // Cyclically distribute nets across loads and slings
  for (int slingRound = 0; slingRound < maxSlingCount; slingRound++) {
    for (int loadIndex = loads.length - 1; loadIndex >= 0; loadIndex--) {
      // Start from last load, move backward
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
  /// Distributing remaining GEAR
  List<Load> loadsWithSingle12x12 = [];
  List<Load> loadsWithAny12x12 = [];
  List<Load> remainingLoads = [];

// Categorize loads based on 12x12 net presence
  for (var load in loads) {
    int num12x12Nets = load.slings?.where((sling) =>
        sling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (12'x12')")).length ?? 0;

    if (num12x12Nets == 1) {
      loadsWithSingle12x12.add(load);
    } else if (num12x12Nets > 1) {
      loadsWithAny12x12.add(load);
    } else {
      remainingLoads.add(load);
    }
  }

// Prioritize loads in the correct order
  List<Load> prioritizedLoadOrder = [
    ...loadsWithSingle12x12,
    ...loadsWithAny12x12,
    ...remainingLoads
  ];

  // Distribute Hazmat Gear: Fill one load completely before moving to the next

  // Step 1: Find slings with highest-priority nets for Hazmat gear placement
  List<Sling> prioritizedSlings = [];

// First, add slings with a single 12x12 net
  for (var load in prioritizedLoadOrder) {
    for (var sling in load.slings ?? []) {
      int num12x12Nets = sling.loadAccoutrements.where((acc) => acc.name == "Cargo Net (12'x12')").length;
      if (num12x12Nets == 1) {
        prioritizedSlings.add(sling);
      }
    }
  }

// Next, add slings with any 12x12 net (not just single ones)
  for (var load in prioritizedLoadOrder) {
    for (var sling in load.slings ?? []) {
      int num12x12Nets = sling.loadAccoutrements.where((acc) => acc.name == "Cargo Net (12'x12')").length;
      if (num12x12Nets > 1 && !prioritizedSlings.contains(sling)) {
        prioritizedSlings.add(sling);
      }
    }
  }

// Finally, add any remaining slings
  for (var load in prioritizedLoadOrder) {
    for (var sling in load.slings ?? []) {
      if (!prioritizedSlings.contains(sling)) {
        prioritizedSlings.add(sling);
      }
    }
  }

  /// DISTRIBUTION STEP 1: HAZMAT GEAR
  int hazmatGearIndex = 0;
  for (var sling in prioritizedSlings) {
    while (hazmatGearIndex < gearCopyHazmat.length &&
        sling.weight + gearCopyHazmat[hazmatGearIndex].weight <= maxLoadWeight) {
      // Add hazmat gear to the sling
      sling.loadGear.add(gearCopyHazmat[hazmatGearIndex]);
      sling.weight += gearCopyHazmat[hazmatGearIndex].weight;

      // Find the parent load and update its weight
      Load parentLoad = prioritizedLoadOrder.firstWhere((load) => load.slings?.contains(sling) ?? false);
      parentLoad.weight += gearCopyHazmat[hazmatGearIndex].weight;

      // Move to the next piece of hazmat gear
      hazmatGearIndex++;
    }

    // If this sling is full, move to the next one in the prioritization order
    if (hazmatGearIndex >= gearCopyHazmat.length) break;
  }

  /// DISTRIBUTION STEP 2: PRIORITIZE 20x20s, Distribute Gear in Non-Hazmat Slings First.
  gearCopyNonHazmat.sort((a, b) => b.quantity.compareTo(a.quantity)); // Higher quantity items should go on the 20x20s
  int gearIndex = 0;
  loadIndex = loads.length - 1; // Start from the last load
  while (gearIndex < gearCopyNonHazmat.length) {
    Load currentLoad = loads[loadIndex];
    int slingIndex = 0;
    bool itemAdded = false;

    // **Check if there are any 20x20 slings that still have space**
    bool anyTwentyByTwentyHasSpace = loads.any((load) =>
        load.slings!.any((sling) =>
        sling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (20'x20')") &&
            sling.weight + gearCopyNonHazmat[gearIndex].weight <= maxLoadWeight
        )
    );

    while (slingIndex < (currentLoad.slings?.length ?? 0)) {
      Sling selectedSling = currentLoad.slings![slingIndex];

      // **Skip hazmat slings unless no other option is available**
      bool isHazmatSling = selectedSling.loadGear.any((gear) => gear.isHazmat);
      if (isHazmatSling) {
        slingIndex++;
        continue; // Skip hazmat slings
      }

      // **Prioritize 20x20 Nets First**
      bool isTwentyByTwenty = selectedSling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (20'x20')");
      bool isTwelveByTwelve = selectedSling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (12'x12')");

      // **If a 20x20 net still has space, skip 12x12 nets**
      if (!isTwentyByTwenty && anyTwentyByTwentyHasSpace) {
        slingIndex++;
        continue;
      }

      // **Try adding gear (prioritizing 20x20 first)**
      if (gearIndex < gearCopyNonHazmat.length &&
          selectedSling.weight + gearCopyNonHazmat[gearIndex].weight <= maxLoadWeight) {
        selectedSling.loadGear.add(gearCopyNonHazmat[gearIndex]);
        selectedSling.weight += gearCopyNonHazmat[gearIndex].weight;
        currentLoad.weight += gearCopyNonHazmat[gearIndex].weight;
        gearIndex++;
        itemAdded = true;
      }

      // Move to the next sling in the same load
      slingIndex++;

      // If all slings in the load have been checked, move to the next load
      if (slingIndex >= (currentLoad.slings?.length ?? 0)) {
        break;
      }
    }

    // **If all 20x20 slings are full, distribute into 12x12 slings *cyclically***
    if (!anyTwentyByTwentyHasSpace) {
      int cyclicSlingIndex = 0; // Start cyclic distribution
      int numSlings = currentLoad.slings?.length ?? 1;
      bool distributedTo12x12 = false; // Tracks if gear was placed

      do {
        Sling selectedSling = currentLoad.slings![cyclicSlingIndex];

        // **Ensure it's a 12x12 net and not a hazmat sling**
        if (selectedSling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (12'x12')") &&
            !selectedSling.loadGear.any((gear) => gear.isHazmat)) {

          if (gearIndex < gearCopyNonHazmat.length &&
              selectedSling.weight + gearCopyNonHazmat[gearIndex].weight <= maxLoadWeight) {
            // **Add gear to the sling**
            selectedSling.loadGear.add(gearCopyNonHazmat[gearIndex]);
            selectedSling.weight += gearCopyNonHazmat[gearIndex].weight;
            currentLoad.weight += gearCopyNonHazmat[gearIndex].weight;
            gearIndex++;
            itemAdded = true;
            distributedTo12x12 = true;
          }
        }

        // **Move cyclically to the next sling**
        cyclicSlingIndex = (cyclicSlingIndex + 1) % numSlings;

      } while (cyclicSlingIndex != 0 && gearIndex < gearCopyNonHazmat.length && distributedTo12x12);
    }

    // **Check if gear placement is still possible**
    bool canPlaceMoreGear = gearIndex < gearCopyNonHazmat.length &&
        loads.any((load) => load.slings!.any((sling) =>
        sling.weight + gearCopyNonHazmat[gearIndex].weight <= maxLoadWeight &&
            !sling.loadGear.any((gear) => gear.isHazmat)));

    // **Exit loop if no more gear can be placed**
    if (!itemAdded && !canPlaceMoreGear) {
      break;
    }

    // **Move cyclically **backwards** to the next load**
    loadIndex = (loadIndex - 1 + loads.length) % loads.length;
  }

  /// DISTRIBUTION STEP 3: Use Hazmat Slings as last resort for non-hazmat items.
  if (gearIndex < gearCopyNonHazmat.length) {
    loadIndex = loads.length - 1; // Restart at the last load

    while (gearIndex < gearCopyNonHazmat.length) {
      Load currentLoad = loads[loadIndex];
      int slingIndex = 0;
      bool placedGear = false;

      while (slingIndex < (currentLoad.slings?.length ?? 0)) {
        Sling selectedSling = currentLoad.slings![slingIndex];

        // Now, allow placement into hazmat slings if needed
        if (selectedSling.weight + gearCopyNonHazmat[gearIndex].weight <= maxLoadWeight) {
          // Add gear to the sling
          selectedSling.loadGear.add(gearCopyNonHazmat[gearIndex]);
          selectedSling.weight += gearCopyNonHazmat[gearIndex].weight;
          currentLoad.weight += gearCopyNonHazmat[gearIndex].weight;

          gearIndex++; // Move to next gear item
          placedGear = true;
        }

        // Move to the next sling in the same load
        slingIndex++;

        // If all slings in the load have been checked, move to the next load
        if (slingIndex >= (currentLoad.slings?.length ?? 0)) {
          break;
        }
      }

      // **Move cyclically **backwards** to the next load**
      loadIndex = (loadIndex - 1 + loads.length) % loads.length;

      // **Break if no gear was placed this round (prevents infinite looping)**
      if (!placedGear) break;
    }
  }

  /// REDISTRIBUTION Step 1: Transfer 20x20 items to 12x12s if over volume constraints WITHIN LOADS
  int gearRatio20x20 = 25; // 25 items in 20x20 per 9 in 12x12, i.e, 20x20s can fit a lot more items
  int gearRatio12x12 = 9;  // 9 items in 12x12 per 25 in 20x20
  for (var load in loads) {
    List<Sling> twentyByTwentySlings = [];
    List<Sling> twelveByTwelveSlings = [];

    num totalGearQuantity = 0;

    // **Sort slings by type and count total gear**
    for (var sling in load.slings ?? []) {
      if (sling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (20'x20')")) {
        twentyByTwentySlings.add(sling);
      } else if (sling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (12'x12')")) {
        twelveByTwelveSlings.add(sling);
      }
      totalGearQuantity += sling.loadGear.fold(0, (sum, gear) => sum + gear.quantity);
    }

    // **Skip redistribution if only one type of net exists**
    if (twentyByTwentySlings.isEmpty || twelveByTwelveSlings.isEmpty) {
      continue;
    }

    // **Calculate total expected ratio based on number of slings**
    int totalRatio20x20 = gearRatio20x20 * twentyByTwentySlings.length;
    int totalRatio12x12 = gearRatio12x12 * twelveByTwelveSlings.length;

    // **Compute expected gear distribution based on scaled ratio**
    int targetTwentyByTwentyQuantity = ((totalRatio20x20 / (totalRatio20x20 + totalRatio12x12)) * totalGearQuantity).round();
    num targetTwelveByTwelveQuantity = totalGearQuantity - targetTwentyByTwentyQuantity;


    // **Current state of slings**
    int currentTwentyByTwentyQuantity = twentyByTwentySlings.fold(
        0, (sum, sling) => sum + sling.loadGear.fold(0, (gearSum, gear) => gearSum + gear.quantity));

    int excessGear = currentTwentyByTwentyQuantity - targetTwentyByTwentyQuantity;

    if (excessGear > 0) {
      List<Gear> gearToMove = [];

      // **Extract excess gear from 20x20 slings**
      for (var sling in twentyByTwentySlings) {
        List<Gear> newGearList = [];

        for (var gear in sling.loadGear) {
          if (excessGear <= 0) {
            newGearList.add(gear);
            continue;
          }

          int amountToMove = (gear.quantity < excessGear) ? gear.quantity : excessGear;
          excessGear -= amountToMove;

          gearToMove.add(Gear(
            name: gear.name,
            weight: gear.weight,
            quantity: amountToMove,
            isPersonalTool: gear.isPersonalTool,
            isHazmat: gear.isHazmat,
          ));

          // Reduce quantity in 20x20 sling
          if (gear.quantity > amountToMove) {
            newGearList.add(Gear(
              name: gear.name,
              weight: gear.weight,
              quantity: gear.quantity - amountToMove,
              isPersonalTool: gear.isPersonalTool,
              isHazmat: gear.isHazmat,
            ));
          }

          sling.weight -= amountToMove * gear.weight;
          load.weight -= amountToMove * gear.weight;
        }
        sling.loadGear = newGearList;
      }

      // **Evenly distribute moved gear across 12x12 slings**
      int cycleIndex = 0;
      for (var gear in gearToMove) {
        while (gear.quantity > 0) {
          Sling targetSling = twelveByTwelveSlings[cycleIndex];

          int moveAmount = (gear.quantity > 0) ? 1 : 0;
          gear.quantity -= moveAmount;

          var existingGear = targetSling.loadGear.firstWhere(
                  (g) => g.name == gear.name && g.isPersonalTool == gear.isPersonalTool,
              orElse: () => Gear(name: gear.name, weight: gear.weight, quantity: 0, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat));

          if (existingGear.quantity == 0) {
            targetSling.loadGear.add(existingGear);
          }

          existingGear.quantity += moveAmount;
          targetSling.weight += moveAmount * gear.weight;
          load.weight += moveAmount * gear.weight;

          cycleIndex = (cycleIndex + 1) % twelveByTwelveSlings.length;
        }
      }
    }
  }

  /// REDISTRIBUTION Step 2: Balance out 12x12s if large volume difference WITHIN LOADS
  double balanceRatio = 3.0;  // Balances out 12x12 if one has 3x as many items; primarily for hazmat
  for (var load in loads) {
    List<Sling> twelveByTwelveSlings = [];
    num totalGearQuantity = 0;

    // **Sort slings by type and count total gear**
    for (var sling in load.slings ?? []) {
      if (sling.loadAccoutrements.any((acc) => acc.name == "Cargo Net (12'x12')")) {
        twelveByTwelveSlings.add(sling);
      }
      totalGearQuantity += sling.loadGear.fold(0, (sum, gear) => sum + gear.quantity);
    }

    // **Skip balancing if there is only one or zero 12x12 slings**
    if (twelveByTwelveSlings.isEmpty || twelveByTwelveSlings.length == 1) {
      continue;
    }

    // **Find the most and least loaded slings**
    twelveByTwelveSlings.sort((a, b) =>
    b.loadGear.fold(0, (sum, gear) => sum + gear.quantity) -
        a.loadGear.fold(0, (sum, gear) => sum + gear.quantity));

    int mostLoadedQuantity = twelveByTwelveSlings.first.loadGear.fold(0, (sum, gear) => sum + gear.quantity);
    int leastLoadedQuantity = twelveByTwelveSlings.last.loadGear.fold(0, (sum, gear) => sum + gear.quantity);

    int excessGear = mostLoadedQuantity - (leastLoadedQuantity * balanceRatio).round();

    if (excessGear > 0) {
      List<Gear> gearToMove = [];

      // **Extract excess gear from the most loaded slings**
      for (var sling in twelveByTwelveSlings) {
        List<Gear> newGearList = [];

        for (var gear in sling.loadGear) {
          if (excessGear <= 0) {
            newGearList.add(gear);
            continue;
          }

          int amountToMove = (gear.quantity < excessGear) ? gear.quantity : excessGear;
          excessGear -= amountToMove;

          gearToMove.add(Gear(
            name: gear.name,
            weight: gear.weight,
            quantity: amountToMove,
            isPersonalTool: gear.isPersonalTool,
            isHazmat: gear.isHazmat,
          ));

          // Reduce quantity in the most loaded sling
          if (gear.quantity > amountToMove) {
            newGearList.add(Gear(
              name: gear.name,
              weight: gear.weight,
              quantity: gear.quantity - amountToMove,
              isPersonalTool: gear.isPersonalTool,
              isHazmat: gear.isHazmat,
            ));
          }

          sling.weight -= amountToMove * gear.weight;
          load.weight -= amountToMove * gear.weight;
        }
        sling.loadGear = newGearList;
      }

      // **Evenly distribute moved gear across underloaded 12x12 slings**
      int cycleIndex = 0;
      for (var gear in gearToMove) {
        while (gear.quantity > 0) {
          Sling targetSling = twelveByTwelveSlings.reversed.toList()[cycleIndex]; // Target least-loaded slings first

          int moveAmount = (gear.quantity > 0) ? 1 : 0;
          gear.quantity -= moveAmount;

          var existingGear = targetSling.loadGear.firstWhere(
                  (g) => g.name == gear.name && g.isPersonalTool == gear.isPersonalTool,
              orElse: () => Gear(name: gear.name, weight: gear.weight, quantity: 0, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat)
          );

          if (existingGear.quantity == 0) {
            targetSling.loadGear.add(existingGear);
          }

          existingGear.quantity += moveAmount;
          targetSling.weight += moveAmount * gear.weight;
          load.weight += moveAmount * gear.weight;

          cycleIndex = (cycleIndex + 1) % twelveByTwelveSlings.length;
        }
      }
    }
  }

  /// SWIVELS: Step Swivels in Daisy-Chained Loads
  for (var load in loads) {
    if ((load.slings?.length ?? 0) > 1) { // Only process loads with more than one sling (daisy-chained)
      // Get available swivels in the load accoutrements
      int availableSwivels = load.loadAccoutrements
          ?.where((acc) => acc.name == "Swivel")
          .fold(0, (sum, acc) => sum! + acc.quantity) ?? 0;

      if (availableSwivels > 0) {
        // Sort slings by current weight (lightest first)
        List<Sling> sortedSlings = [...?load.slings]
          ..sort((a, b) => a.weight.compareTo(b.weight));

        int swivelIndex = 0;
        while (swivelIndex < availableSwivels) {
          // Cycle through slings from lightest to heaviest
          for (var sling in sortedSlings) {
            if (swivelIndex >= availableSwivels) break; // Stop if all swivels are placed

            // Create a new Swivel LoadAccoutrement object and add it to the sling
            LoadAccoutrement swivelAcc = LoadAccoutrement(
              name: "Swivel",
              weight: swivel.weight,
              quantity: 1,
            );
            sling.loadAccoutrements.add(swivelAcc);
            sling.weight += swivel.weight; // Update sling weight

            // Move to the next swivel
            swivelIndex++;
          }
        }

        // Remove all swivels from the load-level storage
        load.loadAccoutrements?.removeWhere((acc) => acc.name == "Swivel");
      }
    }
  }

  /// Consolidate identical gear items within each sling of every load
  for (var load in loads) {
    for (var sling in load.slings ?? []) {
      List<Gear> consolidatedGear = [];

      for (var gear in sling.loadGear) {
        var existingGear = consolidatedGear.firstWhere(
              (item) => item.name == gear.name && item.isPersonalTool == gear.isPersonalTool,
          orElse: () {
            var newGear = Gear(
              name: gear.name,
              weight: gear.weight,
              quantity: 0, // Ensure initialized as an integer
              isPersonalTool: gear.isPersonalTool,
              isHazmat: gear.isHazmat,
            );
            consolidatedGear.add(newGear);
            return newGear;
          },
        );

        // Ensure quantity is treated as an integer
        existingGear.quantity = (existingGear.quantity + gear.quantity).toInt();
      }

      // Replace the sling's gear list with the consolidated list
      sling.loadGear = consolidatedGear;
    }
  }

  /// Sort slings
  for (var load in loads) {
    if (load.slings == null) continue; // Ensure slings list exists

    for (var sling in load.slings!) {
      // Ensure loadAccoutrements is initialized before sorting
      if (sling.loadAccoutrements.isNotEmpty) {
        sling.loadAccoutrements.sort((a, b) {
          bool isNetA = a.name.toLowerCase().contains("net");
          bool isNetB = b.name.toLowerCase().contains("net");
          if (isNetA && !isNetB) return -1; // Nets first
          if (!isNetA && isNetB) return 1;

          bool isLeadLineA = a.name.toLowerCase().contains("lead line");
          bool isLeadLineB = b.name.toLowerCase().contains("lead line");
          if (isLeadLineA && !isLeadLineB) return -1; // Lead Line second
          if (!isLeadLineA && isLeadLineB) return 1;

          bool isSwivelA = a.name.toLowerCase().contains("swivel");
          bool isSwivelB = b.name.toLowerCase().contains("swivel");
          if (isSwivelA && !isSwivelB) return -1; // Swivel third
          if (!isSwivelA && isSwivelB) return 1;

          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Default alphabetical
        });
      }

      // Ensure loadGear is initialized before sorting
      if (sling.loadGear.isNotEmpty) {
        sling.loadGear.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    }
  }

  loads.removeWhere((load) => load.weight == 0); // Remove loads with zero weight
  // Re-consolidate load numbers
  for (int i = 0; i < loads.length; i++) {
    loads[i].loadNumber = i + 1; // Reassign sequential load numbers starting from 1
  }

  /// Get final weights for slings and loads
  for (var load in loads) {
    int newLoadWeight = 0; // Reset load weight

    if (load.slings != null) { // Check if slings exist before looping
      for (var sling in load.slings!) {
        int newSlingWeight = 0; // Initialize as non-nullable int

        // Sum all Load Accoutrements
        for (var acc in sling.loadAccoutrements) {
          newSlingWeight += (acc.weight * acc.quantity);
        }

        // Sum all Gear
        for (var gear in sling.loadGear) {
          newSlingWeight += (gear.weight * gear.quantity);
        }

        // Sum all Custom Items
        for (var item in sling.customItems) {
          newSlingWeight += item.weight;
        }

        // Ensure the weight is properly updated
        sling.weight = newSlingWeight;

        // Add the sling weight to the total load weight
        newLoadWeight += newSlingWeight;
      }
    }

    // Ensure the total load weight is updated
    load.weight = newLoadWeight;
  }


  /// ADD TO TRIP OBJECT
  for (var load in loads) {
    trip.addLoad(trip, load);
  }


  /// Error Checking: Ensure all gear from trip.gear is allocated
  Set<String> placedGearNames = {}; // Track gear names
  Map<String, num> placedGearCounts = {}; // Track gear quantities
  Map<String, int> expectedGearCounts = {}; // Expected gear from trip.gear
  List<String> unallocatedGear = []; // Stores names of missing gear

// **Step 1: Count all placed gear in slings across loads**
  for (var load in loads) {
    for (var sling in load.slings ?? []) {
      for (var gear in sling.loadGear) {
        placedGearNames.add(gear.name);

        // Track how many of this gear item were actually placed
        placedGearCounts[gear.name] = (placedGearCounts[gear.name] ?? 0) + gear.quantity;
      }
    }
  }

// **Step 2: Count expected gear from trip.gear**
  for (var gear in trip.gear) {
    expectedGearCounts[gear.name] = (expectedGearCounts[gear.name] ?? 0) + gear.quantity;
  }

// **Step 3: Compare expected gear vs. placed gear**
  for (var gear in trip.gear) {
    int expectedQuantity = expectedGearCounts[gear.name] ?? 0;
    num placedQuantity = placedGearCounts[gear.name] ?? 0;

    if (placedQuantity < expectedQuantity) {
      num missingQuantity = expectedQuantity - placedQuantity;
      unallocatedGear.add("${gear.name} (Missing: $missingQuantity)");
    }
  }

// **Step 4: Show Error Message if Gear is Missing**
  if (unallocatedGear.isNotEmpty) {
    String errorMessage = "Some gear items were not allocated due to weight constraints. Consider increasing the allowable weight.";

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

              if (unallocatedGear.isNotEmpty) const SizedBox(height: 8), // Add spacing

              if (unallocatedGear.isNotEmpty)
                RichText(
                  text: TextSpan(
                    text: "Unallocated Gear Items:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange, // Highlight missing gear
                      fontSize: AppData.text16,
                    ),
                    children: [
                      TextSpan(
                        text: unallocatedGear.join(', '),
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


