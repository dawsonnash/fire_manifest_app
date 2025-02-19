import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../Algorithms/load_calculator.dart';
import '../Data/trip.dart';
import '../Data/trip_preferences.dart';
import 'main.dart';

class CalculatingScreen extends StatefulWidget {
  const CalculatingScreen({super.key});

  @override
  _CalculatingScreenState createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<String> codeLines = [];
  final Random _random = Random();
  Timer? _calculationTimer;
  bool isCalculating = true;
  int dotCount = 0;


  final List<String> algorithmLines = [
    "int availableSeats = trip.availableSeats;",
    "int maxLoadWeight = trip.allowable;",

    "int numLoadsByAllowable = (trip.totalCrewWeight! / trip.allowable).ceil();",
    "int numLoadsBySeat = (trip.crewMembers.length / trip.availableSeats).ceil();",
    "int numLoads = numLoadsByAllowable > numLoadsBySeat ? numLoadsByAllowable : numLoadsBySeat;",

    "var crewMembersCopy = trip.crewMembers.map((member) {",
    "  return CrewMember(",
    "    name: member.name,",
    "    flightWeight: member.flightWeight,",
    "    position: member.position,",
    "    personalTools: member.personalTools?.map((tool) {",
    "      return Gear(",
    "        name: tool.name,",
    "        weight: tool.weight,",
    "        quantity: tool.quantity,",
    "        isPersonalTool: tool.isPersonalTool,",
    "        isHazmat: tool.isHazmat",
    "      );",
    "    }).toList(),",
    "  );",
    "}).toList();",

    "shuffleCrewMembers(crewMembersCopy);",

    "var gearCopy = <Gear>[];",
    "for (var gear in trip.gear) {",
    "  for (int i = 0; i < gear.quantity; i++) {",
    "    gearCopy.add(Gear(",
    "      name: gear.name,",
    "      weight: gear.weight,",
    "      quantity: 1,",
    "      isPersonalTool: gear.isPersonalTool,",
    "      isHazmat: gear.isHazmat",
    "    ));",
    "  }",
    "}",

    "List<Load> loads = List.generate(",
    "  numLoads,",
    "  (index) => Load(",
    "    loadNumber: index + 1,",
    "    weight: 0,",
    "    loadPersonnel: [],",
    "    loadGear: [],",
    "  )",
    ");",

    "if (tripPreference != null) {",
    "  var tripPreferenceCopy = cleanTripPreference(tripPreference, trip);",
    "  for (var posPref in tripPreferenceCopy.positionalPreferences) {",
    "    switch (posPref.loadPreference) {",
    "      case 0:",
    "        for (var crewMembersDynamic in posPref.crewMembersDynamic) {",
    "          if (crewMembersDynamic is CrewMember) {",
    "            for (var load in loads) {",
    "              if (load.weight + crewMembersDynamic.totalCrewMemberWeight <= maxLoadWeight && load.loadPersonnel.length < availableSeats) {",
    "                load.loadPersonnel.add(crewMembersDynamic);",
    "                load.weight += crewMembersDynamic.totalCrewMemberWeight;",
    "                crewMembersCopy.removeWhere((member) => member.name == crewMembersDynamic.name);",
    "                break;",
    "              }",
    "            }",
    "          }",
    "        }",
    "        break;",
    "      case 1:",
    "        for (var crewMembersDynamic in posPref.crewMembersDynamic) {",
    "          if (crewMembersDynamic is CrewMember) {",
    "            for (var load in loads.reversed) {",
    "              if (load.weight + crewMembersDynamic.totalCrewMemberWeight <= maxLoadWeight && load.loadPersonnel.length < availableSeats) {",
    "                load.loadPersonnel.add(crewMembersDynamic);",
    "                load.weight += crewMembersDynamic.totalCrewMemberWeight;",
    "                crewMembersCopy.removeWhere((member) => member.name == crewMembersDynamic.name);",
    "                break;",
    "              }",
    "            }",
    "          }",
    "        }",
    "        break;",
    "      case 2:",
    "        int loadIndex = 0;",
    "        for (var crewMembersDynamic in posPref.crewMembersDynamic) {",
    "          if (crewMembersDynamic is CrewMember) {",
    "            while (loadIndex < loads.length) {",
    "              var load = loads[loadIndex];",
    "              if (load.weight + crewMembersDynamic.totalCrewMemberWeight <= maxLoadWeight && load.loadPersonnel.length < availableSeats) {",
    "                load.loadPersonnel.add(crewMembersDynamic);",
    "                load.weight += crewMembersDynamic.totalCrewMemberWeight;",
    "                crewMembersCopy.removeWhere((member) => member.name == crewMembersDynamic.name);",
    "                loadIndex = (loadIndex + 1) % loads.length;",
    "                break;",
    "              }",
    "              loadIndex = (loadIndex + 1) % loads.length;",
    "            }",
    "          }",
    "        }",
    "        break;",
    "    }",
    "  }",
    "}",

    "int loadIndex = 0;",
    "bool noMoreCrewCanBeAdded = false;",
    "bool noMoreGearCanBeAdded = false;",

    "while ((crewMembersCopy.isNotEmpty && !noMoreCrewCanBeAdded) || (gearCopy.isNotEmpty && !noMoreGearCanBeAdded)) {",
    "  Load currentLoad = loads[loadIndex];",
    "  num currentLoadWeight = currentLoad.weight;",
    "  bool itemAdded = false;",

    "  if (crewMembersCopy.isNotEmpty && currentLoadWeight + crewMembersCopy.first.totalCrewMemberWeight <= maxLoadWeight && currentLoad.loadPersonnel.length < availableSeats) {",
    "    var firstCrewMember = crewMembersCopy.first;",
    "    currentLoadWeight += firstCrewMember.totalCrewMemberWeight;",
    "    currentLoad.loadPersonnel.add(firstCrewMember);",
    "    currentLoad.loadGear.addAll(firstCrewMember.personalTools as Iterable<Gear>);",
    "    crewMembersCopy.removeAt(0);",
    "    itemAdded = true;",
    "  } else if (crewMembersCopy.isNotEmpty && loads.every((load) => load.weight + crewMembersCopy.first.totalCrewMemberWeight > maxLoadWeight || load.loadPersonnel.length >= availableSeats)) {",
    "    noMoreCrewCanBeAdded = true;",
    "  }",

    "  if (!itemAdded && gearCopy.isNotEmpty && currentLoadWeight + gearCopy.first.weight <= maxLoadWeight) {",
    "    currentLoadWeight += gearCopy.first.weight;",
    "    currentLoad.loadGear.add(gearCopy.first);",
    "    gearCopy.removeAt(0);",
    "    itemAdded = true;",
    "  } else if (gearCopy.isNotEmpty && loads.every((load) => load.weight + gearCopy.first.weight > maxLoadWeight)) {",
    "    noMoreGearCanBeAdded = true;",
    "  }",

    "  currentLoad.weight = currentLoadWeight.toInt();",
    "  loadIndex = (loadIndex + 1) % loads.length;",
    "}",

    "loads.removeWhere((load) => load.weight == 0);",
    "for (int i = 0; i < loads.length; i++) {",
    "  loads[i].loadNumber = i + 1;",
    "}",
    "for (var load in loads) {",
    "  trip.addLoad(trip, load);",
    "}"
  ];

  void _startDotAnimation() {
    _calculationTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        dotCount = (dotCount + 1) % 3;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500))..repeat();

    _startCodeDisplayInOrder();
    _startDotAnimation();

    // Stop animation after 2 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          isCalculating = false;
          _controller.stop();
        });

        _calculationTimer?.cancel(); // Stops the timer
      }

      // Small delay before closing to ensure UI updates correctly
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  late ScrollController _scrollController;
  void _startCodeDisplayRandom() {
    _calculationTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (!mounted || !isCalculating) {
        timer.cancel();
        return;
      }

      setState(() {
        if (codeLines.length > 15) {
          codeLines.removeAt(0);
        }
        codeLines.add(algorithmLines[_random.nextInt(algorithmLines.length)]);
      });
    });
  }
  void _startCodeDisplayInOrder() {
    _scrollController = ScrollController();
    int currentIndex = Random().nextInt(algorithmLines.length); // Start at a random index

    _calculationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted || !isCalculating) {
        timer.cancel();
        return;
      }

      setState(() {
        // Add the current line
        codeLines.add(algorithmLines[currentIndex]);

        // Move to the next line, looping back if at the end
        currentIndex = (currentIndex + 1) % algorithmLines.length;

        // Remove old lines to keep the display clean
        if (codeLines.length > 15) {
          codeLines.removeAt(0);
        }

        // Force scroll immediately when adding the first few lines
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }

        // Smooth auto-scroll after that
        Future.delayed(Duration(milliseconds: 10), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _calculationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        body: Stack(
          children: [
            // **Full-Screen Background Code Snippets**
            Positioned.fill(
              child: Opacity(
                opacity: 0.4, // Keeps it subtle in the background
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: codeLines.map((code) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                      child: Text(
                        code,
                        style: TextStyle(
                          color: Colors.greenAccent.withOpacity(_random.nextDouble()), // Glitch effect
                          fontSize: 14,
                          fontFamily: "monospace",
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),

            // **Centered Foreground: "Calculating..." Text & Animation**
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Calculating${"." * (dotCount + 1)}", // Dynamically appends ".", "..", or "..."
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

Future<void> startCalculation(
    BuildContext context,
    Trip newTrip,
    TripPreference? selectedTripPreference,
    ) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CalculatingScreen(),
  );

  try {
    await loadCalculator(context, newTrip, selectedTripPreference);
  } finally {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(
      content: Center(
        child: Text(
          'Trip Saved!',
          style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
    ),
  );

  // Switch tab globally after delay
  Future.delayed(Duration(milliseconds: 300), () {
    print("Switching tabs globally...");
    selectedIndexNotifier.value = 1; // Switch to "Saved Trips"
  });
}
