import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:flutter/material.dart';

import '../CodeShare/variables.dart';
import '../Data/gear.dart';
import '../Data/load.dart';
import '../Data/sling.dart';
import '../Data/trip.dart';
import '../Data/trip_preferences.dart';
import '../main.dart';

Future<void> externalLoadCalculator(BuildContext context, Trip trip, int safetyBuffer, LoadAccoutrement cargoNet12x12, LoadAccoutrement cargoNet20x20,
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

  // Populate gearCopyHazmat (treat each quantity as individual)
  var gearCopyHazmat = <Gear>[];
  for (var gear in trip.gear) {
    if (gear.isHazmat) {
      for (int i = 0; i < gear.quantity; i++) {
        gearCopyHazmat.add(Gear(
          name: gear.name,
          weight: gear.weight,
          quantity: 1,
          isPersonalTool: gear.isPersonalTool,
          isHazmat: true,
        ));
      }
    }
  }

  var gearCopyNonHazmat = <Gear>[];
  // Consolidate non-hazmat gear before breaking them into individual units
  Map<String, Gear> consolidatedNonHazmatMap = {};

  for (var gear in trip.gear) {
    if (!gear.isHazmat) {
      String key = "${gear.name}-${gear.weight}-${gear.isPersonalTool}";
      if (consolidatedNonHazmatMap.containsKey(key)) {
        consolidatedNonHazmatMap[key]!.quantity += gear.quantity;
      } else {
        consolidatedNonHazmatMap[key] = Gear(
          name: gear.name,
          weight: gear.weight,
          quantity: gear.quantity,
          isPersonalTool: gear.isPersonalTool,
          isHazmat: false,
        );
      }
    }
  }

  // Sort consolidated list by total weight (quantity × weight), descending
  List<Gear> sortedNonHazmatConsolidated = consolidatedNonHazmatMap.values.toList()
    ..sort((a, b) => (b.quantity * b.weight).compareTo(a.quantity * a.weight));

  // Expand them back into individual items
  gearCopyNonHazmat = [];
  for (var gear in sortedNonHazmatConsolidated) {
    for (int i = 0; i < gear.quantity; i++) {
      gearCopyNonHazmat.add(Gear(
        name: gear.name,
        weight: gear.weight,
        quantity: 1,
        isPersonalTool: gear.isPersonalTool,
        isHazmat: false,
      ));
    }
  }

  /// Gear (non-hazmat) Prioritization Debug
  // debugPrint("debug: ===== NON-HAZMAT GEAR PRIORITY ORDER =====");
  //
  // for (var gear in sortedNonHazmatConsolidated) {
  //   int totalWeight = gear.quantity * gear.weight;
  //   debugPrint(
  //       "debug: ${gear.name} → Total Weight: $totalWeight");
  // }
  // debugPrint("debug: ===========================================");


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

  /// Swivel Distribution
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

  ///--------------------- Distribution Logic Here -------------------------------------------------

  /// STEP 1: Determine Load Item Ratios Based on Net Surface Area
  const int area12x12 = 144;
  const int area20x20 = 400;

  Map<Load, double> rawItemShares = {};
  Map<Load, int> loadItemTargets = {};
  Map<Load, int> loadSurfaceArea = {};

  int totalSurfaceArea = 0;
  int totalItemCount = gearCopy.length;

  // Step 1: Surface area per load
  for (var load in loads) {
    int area = 0;
    for (var sling in load.slings ?? []) {
      for (var acc in sling.loadAccoutrements) {
        if (acc.name.contains("12'x12'")) {
          area += area12x12;
        } else if (acc.name.contains("20'x20'")) {
          area += area20x20;
        }
      }
    }
    loadSurfaceArea[load] = area;
    totalSurfaceArea += area;
  }

  // Step 2: Raw item share (floating point)
  for (var load in loads) {
    int area = loadSurfaceArea[load] ?? 0;
    double share = (area / totalSurfaceArea) * totalItemCount;
    rawItemShares[load] = share;
    loadItemTargets[load] = share.floor(); // Start with floor to ensure under total
  }

  // Step 3: Distribute leftover items to lowest-count loads
  int distributed = loadItemTargets.values.fold(0, (a, b) => a + b);
  int remaining = totalItemCount - distributed;

  if (remaining > 0) {
    // Create a list of loads sorted by current item allocation (asc)
    List<Load> prioritized = [...loads];
    prioritized.sort((a, b) => loadItemTargets[a]!.compareTo(loadItemTargets[b]!));

    int i = 0;
    while (remaining > 0) {
      Load targetLoad = prioritized[i % prioritized.length];
      loadItemTargets[targetLoad] = loadItemTargets[targetLoad]! + 1;
      remaining--;
      i++;
    }
  }

  /// DEBUG LOG: Item Ratio
  // debugPrint("debug: Total Items $totalItemCount");
  // int confirmedTotal = 0;
  //
  // for (var entry in loadItemTargets.entries) {
  //   Load load = entry.key;
  //   int targetCount = entry.value;
  //
  //   // Count net types
  //   int net12x12 = 0;
  //   int net20x20 = 0;
  //   for (var sling in load.slings ?? []) {
  //     for (var acc in sling.loadAccoutrements) {
  //       if (acc.name.contains("12'x12'")) net12x12++;
  //       if (acc.name.contains("20'x20'")) net20x20++;
  //     }
  //   }
  //
  //   int surfaceArea = loadSurfaceArea[load] ?? 0;
  //
  //   debugPrint(
  //       "debug: Load #${load.loadNumber} → Target: $targetCount items, "
  //           "Surface Area: $surfaceArea sq ft, "
  //           "Nets: $net20x20×20x20, $net12x12×12x12"
  //   );
  //
  //   confirmedTotal += targetCount;
  // }
  //
  // debugPrint("debug: Confirmed total assigned: $confirmedTotal");

  // Track how many items have been placed in each load so far

  /// STEP 2: LOAD HAZMAT DISTRIBUTION
  Map<Load, int> currentItemCount = {
    for (var load in loads) load: 0,
  };

// Step 1: Prioritize loads with multiple nets
  List<Load> prioritizedHazmatLoads = [...loads];
  prioritizedHazmatLoads.sort((a, b) {
    int aNets = a.slings
        ?.expand((s) => s.loadAccoutrements)
        .where((acc) => acc.name.contains("Cargo Net"))
        .length ?? 0;

    int bNets = b.slings
        ?.expand((s) => s.loadAccoutrements)
        .where((acc) => acc.name.contains("Cargo Net"))
        .length ?? 0;

    return bNets.compareTo(aNets); // Descending: more nets first
  });

  int hazmatIndex = 0;
  while (hazmatIndex < gearCopyHazmat.length) {
    Gear item = gearCopyHazmat[hazmatIndex];
    bool itemPlaced = false;

    for (var load in prioritizedHazmatLoads) {
      // Skip if load has already reached its target
      if (currentItemCount[load]! >= loadItemTargets[load]!) continue;

      if ((load.weight + item.weight) <= maxLoadWeight) {
        load.loadGear.add(item);
        load.weight += item.weight;
        currentItemCount[load] = currentItemCount[load]! + 1;

        gearCopyHazmat.removeAt(hazmatIndex); // Remove from list
        itemPlaced = true;
        break;
      }
    }

    if (!itemPlaced) {
      // Couldn’t place this item — move to next
      hazmatIndex++;
    }
  }


  /// DEBUG LOG: LOAD HAZMAT DISTRIBUTION
  // int totalHazmatItemsPlaced = currentItemCount.values.fold(0, (a, b) => a + b);
  //
  // debugPrint("debug: ===== HAZMAT DISTRIBUTION SUMMARY =====");
  // debugPrint("debug: Total Hazmat Items Available: ${gearCopyHazmat.length}");
  // debugPrint("debug: Total Hazmat Items Placed: $totalHazmatItemsPlaced");
  //
  // for (var load in prioritizedHazmatLoads) {
  //   int hazmatCount = load.loadGear.where((g) => g.isHazmat).length;
  //
  //   debugPrint("debug: Load #${load.loadNumber} received $hazmatCount hazmat items:");
  //
  //   for (var gear in load.loadGear.where((g) => g.isHazmat)) {
  //     debugPrint("  → ${gear.name} (x${gear.quantity})");
  //   }
  //
  //   if (hazmatCount == 0) {
  //     debugPrint("  → [None]");
  //   }
  // }
  //
  // debugPrint("debug: =======================================");

  /// STEP 3: LOAD NON HAZMAT DISTRIBUTION
  int gearIndex = 0;
  while (gearIndex < gearCopyNonHazmat.length) {
    Gear gear = gearCopyNonHazmat[gearIndex];

    // Sort loads by current item count vs. target, descending by remaining capacity
    List<Load> prioritizedLoads = [...loads];
    prioritizedLoads.sort((a, b) {
      int remainingA = loadItemTargets[a]! - currentItemCount[a]!;
      int remainingB = loadItemTargets[b]! - currentItemCount[b]!;

      // If same number of remaining items, prefer higher surface area
      if (remainingA == remainingB) {
        return (loadSurfaceArea[b] ?? 0).compareTo(loadSurfaceArea[a] ?? 0);
      }

      return remainingB.compareTo(remainingA); // Descending
    });

    bool itemPlaced = false;

    for (var load in prioritizedLoads) {
      if (currentItemCount[load]! >= loadItemTargets[load]!) continue;

      if ((load.weight + gear.weight) <= maxLoadWeight) {
        load.loadGear.add(gear);
        load.weight += gear.weight;
        currentItemCount[load] = currentItemCount[load]! + 1;

        gearCopyNonHazmat.removeAt(gearIndex); // Remove placed item
        itemPlaced = true;
        break;
      }
    }

    if (!itemPlaced) {
      // Couldn’t place item — move to next
      gearIndex++;
    }
  }

  /// DEBUG LOG: LOAD NON-HAZMAT DISTRIBUTION
  // debugPrint("debug: ===== NON-HAZMAT DISTRIBUTION SUMMARY =====");
  // int totalNonHazmatPlaced = 0;
  //
  // for (var load in loads) {
  //   List<Gear> nonHazmatGear = load.loadGear.where((g) => !g.isHazmat).toList();
  //   int groupedCount = nonHazmatGear.fold(0, (sum, g) => sum + g.quantity);
  //   totalNonHazmatPlaced += groupedCount;
  //
  //   debugPrint("debug: Load #${load.loadNumber}: $groupedCount non-hazmat items:");
  //
  //   Map<String, int> groupedItems = {};
  //
  //   for (var gear in nonHazmatGear) {
  //     String key = "${gear.name}${gear.isPersonalTool ? " (Tool)" : ""}";
  //     groupedItems.update(key, (existing) => existing + gear.quantity, ifAbsent: () => gear.quantity);
  //   }
  //
  //   if (groupedItems.isEmpty) {
  //     debugPrint("  → [None]");
  //   } else {
  //     groupedItems.forEach((name, qty) {
  //       debugPrint("  → $name (x$qty)");
  //     });
  //   }
  // }
  //
  // debugPrint("debug: TOTAL NON-HAZMAT ITEMS PLACED: $totalNonHazmatPlaced");
  // debugPrint("debug: ===========================================");
  //

  /// STEP 4: PLACE REMAINING ITEMS INTO LIGHTEST LOADS (if any)
  List<Gear> leftoverItems = [...gearCopyHazmat, ...gearCopyNonHazmat];
  for (var item in leftoverItems) {
    // Sort loads by current total weight (ascending)
    List<Load> sortedByWeight = [...loads];
    sortedByWeight.sort((a, b) => a.weight.compareTo(b.weight));

    bool itemPlaced = false;

    for (var load in sortedByWeight) {
      if ((load.weight + item.weight) <= maxLoadWeight) {
        load.loadGear.add(item);
        load.weight += item.weight;
        itemPlaced = true;
        debugPrint("debug: Leftover! Placed '${item.name}' (weight: ${item.weight})");
        break;
      }
    }

    if (!itemPlaced) {
      // Couldn't place the item anywhere
      debugPrint("debug: ERROR: Could not place item '${item.name}' (weight: ${item.weight}) due to load weight constraints.");
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Text("Load Calculation Error", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),),
            content: Text("Could not place gear item '${item.name}' (${item.weight} lbs) due to tight weight constraints. Please try again.", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:  Text("OK", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize)),
              ),
            ],
          );
        },
      );
    }
  }

  /// STEP 5: DISTRIBUTE LOAD GEAR INTO SLINGS (PER LOAD) BASED ON NET SURFACE AREA
  for (var load in loads) {
    List<Sling> slings = load.slings ?? [];
    if (slings.isEmpty) continue;

    // Step 1: Surface area per sling
    Map<Sling, int> slingSurfaceArea = {};
    int totalSlingArea = 0;

    for (var sling in slings) {
      int area = 0;
      for (var acc in sling.loadAccoutrements) {
        if (acc.name.contains("20'x20'")) area += area20x20;
        if (acc.name.contains("12'x12'")) area += area12x12;
      }
      slingSurfaceArea[sling] = area;
      totalSlingArea += area;
    }

    // Step 2: Flatten load.loadGear into individual items
    List<Gear> flattenedGear = [];
    for (var gear in load.loadGear) {
      for (int i = 0; i < gear.quantity; i++) {
        flattenedGear.add(Gear(
          name: gear.name,
          weight: gear.weight,
          quantity: 1,
          isHazmat: gear.isHazmat,
          isPersonalTool: gear.isPersonalTool,
        ));
      }
    }

    // Step 3: Determine item distribution targets
    Map<Sling, int> slingItemTargets = {};
    int totalItems = flattenedGear.length;

    for (var sling in slings) {
      int area = slingSurfaceArea[sling] ?? 0;
      double ratio = totalSlingArea == 0 ? 0 : area / totalSlingArea;
      slingItemTargets[sling] = (ratio * totalItems).floor();
    }

    // Step 4: Distribute remaining items
    int totalAssigned = slingItemTargets.values.fold(0, (a, b) => a + b);
    int remaining = totalItems - totalAssigned;

    if (remaining > 0) {
      List<Sling> prioritized = [...slings];
      prioritized.sort((a, b) => (slingItemTargets[a] ?? 0).compareTo(slingItemTargets[b] ?? 0));
      int i = 0;
      while (remaining > 0) {
        Sling s = prioritized[i % prioritized.length];
        slingItemTargets[s] = (slingItemTargets[s] ?? 0) + 1;
        remaining--;
        i++;
      }
    }

    // Step 5: Assign gear to slings
    for (var sling in slings) {
      int target = slingItemTargets[sling] ?? 0;
      for (int i = 0; i < target && flattenedGear.isNotEmpty; i++) {
        Gear gearItem = flattenedGear.removeAt(0);
        sling.loadGear.add(gearItem);
        sling.weight += gearItem.weight;
      }
    }
    //
    // debugPrint("debug: --- SLING DISTRIBUTION FOR LOAD #${load.loadNumber} ---");
    // for (var sling in slings) {
    //   int count = sling.loadGear.length;
    //   int area = slingSurfaceArea[sling] ?? 0;
    //   debugPrint("debug: Sling #${sling.slingNumber} → $count items, Area: ${area} sq ft");
    // }
  }


  /// DEBUG LOG: DETAILED FINAL GEAR PLACEMENT PER LOAD
  // int totalPlacedItems = 0;
  // int totalHazmat = 0;
  // int totalNonHazmat = 0;
  //
  // debugPrint("debug: ===== FINAL GEAR DISTRIBUTION PER LOAD =====");
  //
  // for (var load in loads) {
  //   Map<String, int> hazmatItems = {};
  //   Map<String, int> nonHazmatItems = {};
  //   int hazmatCount = 0;
  //   int nonHazmatCount = 0;
  //
  //   for (var gear in load.loadGear) {
  //     String key = gear.name;
  //     if (gear.isHazmat) {
  //       hazmatItems[key] = (hazmatItems[key] ?? 0) + gear.quantity;
  //       hazmatCount += gear.quantity;
  //     } else {
  //       nonHazmatItems[key] = (nonHazmatItems[key] ?? 0) + gear.quantity;
  //       nonHazmatCount += gear.quantity;
  //     }
  //   }
  //
  //   int loadTotal = hazmatCount + nonHazmatCount;
  //   totalHazmat += hazmatCount;
  //   totalNonHazmat += nonHazmatCount;
  //   totalPlacedItems += loadTotal;
  //
  //   debugPrint("debug: Load #${load.loadNumber}");
  //   debugPrint("debug:  → Hazmat Items: $hazmatCount");
  //   debugPrint("debug:  → Non-Hazmat Items: $nonHazmatCount");
  //
  //   debugPrint("  → Total Items in Load: $loadTotal\n");
  // }
  //
  // debugPrint("debug: ---------------------------------------------");
  // debugPrint("debug: TOTAL ITEMS PLACED: $totalPlacedItems");

  /// DEBUG: LOAD WEIGHT VERIFICATION
  // debugPrint("debug: ========== LOAD WEIGHT SUMMARY ==========");
  // for (var load in loads) {
  //   String status = (load.weight > maxLoadWeight)
  //       ? " OVERWEIGHT"
  //       : (load.weight == maxLoadWeight)
  //       ? " MAXED OUT"
  //       : "OK";
  //
  //   debugPrint("debug: Load #${load.loadNumber} → "
  //       "Weight: ${load.weight} lbs / Max: $maxLoadWeight lbs [$status]");
  //
  //   if (load.loadAccoutrements!.isNotEmpty) {
  //     debugPrint("debug:  Accoutrements:");
  //     for (var acc in load.loadAccoutrements!) {
  //       debugPrint("debug:   → ${acc.name} (x${acc.quantity}) - ${acc.weight * acc.quantity} lbs");
  //     }
  //   } else {
  //     debugPrint("debug:  Accoutrements: [None]");
  //   }
  // }
  // debugPrint("debug: ========================================");


  /// -------------- No more main Gear Distribution Logic. Only Consolidation and QoL sorting below ----------------

  /// SWIVELS: Distribute Swivels into Daisy-Chained Loads
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

  /// Sort Load Accoutrements in Slings
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

      // // Ensure loadGear is initialized before sorting
      // if (sling.loadGear.isNotEmpty) {
      //   sling.loadGear.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      // }
    }
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

