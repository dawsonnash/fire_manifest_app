import 'dart:ui';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../Data/trip.dart';
import 'Data/crewmember.dart';
import 'Data/gear.dart';
import 'Data/load_calculator.dart';
import 'Data/trip_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateNewManifest extends StatefulWidget {
  const CreateNewManifest({super.key});

  @override
  State<CreateNewManifest> createState() => _CreateNewManifestState();
}

class _CreateNewManifestState extends State<CreateNewManifest> {
  late final Box<Gear> gearBox;
  late final Box<CrewMember> crewmemberBox;

  // Lists for Select All/Some dialog
  List<Gear> gearList = [];
  List<CrewMember> crewList = [];

  // Lists for actual crew going into trip object
  List<CrewMember> thisTripCrewMemberList = [];
  List<Gear> thisTripGearList = [];

  late Map<Gear, int> selectedGearQuantities;
  late List<dynamic> selectedItems;

  // Variables to store user input
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController allowableController = TextEditingController();
  final TextEditingController availableSeatsController = TextEditingController();
  final TextEditingController keyboardController = TextEditingController();
  double _sliderValue = 1000;

  // Can be null as a "None" option is available where user doesn't select a Load Preference
  TripPreference? selectedTripPreference;

  bool isCalculateButtonEnabled = false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();

    gearBox = Hive.box<Gear>('gearBox');
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

    // Listeners to the TextControllers
    tripNameController.addListener(_checkInput);
    allowableController.addListener(_checkInput);
    availableSeatsController.addListener(_checkInput);

    // Initialize allowableController with the default slider value
    allowableController.text = _sliderValue.toStringAsFixed(0);



    loadItems();

    // Initialize selectedItems with all crew and gear items
    selectedItems = [
      ...crewList,
      ...gearList,
    ];

    // Optionally initialize selectedGearQuantities
    selectedGearQuantities = {
      for (var gear in gearList) gear: gear.quantity,
    };
  }

  void _showSelectionDialog() async {

    List<CrewMember> sortedCrewList = sortCrewListByPosition(crewList);
    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);
    bool isCrewExpanded = false;
    bool isGearExpanded = false;

    // "Select All" starts as true because everything is selected by default
    bool isSelectAllChecked = selectedItems.length == (crewList.length + gearList.length);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Function to update "Select All" checkbox dynamically
            void updateSelectAllState() {
              dialogSetState(() {
                isSelectAllChecked = selectedItems.length == (crewList.length + gearList.length);
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Select Crew Members and Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Select All Checkbox
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black, // Outline color
                              width: 1.0,         // Outline thickness
                            ),
                        //    borderRadius: BorderRadius.circular(8.0), // Rounded corners (optional)
                          ),
                          child: CheckboxListTile(
                            //  activeColor: Colors.black, // Checkbox outline color when active
                           // checkColor: Colors.white,  // Checkmark color
                            title: const Text(
                              'Select All',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            value: isSelectAllChecked,
                            onChanged: (bool? isChecked) {
                              dialogSetState(() {
                                isSelectAllChecked = isChecked ?? false;

                                if (isSelectAllChecked) {
                                  selectedItems = [
                                    ...crewList,
                                    ...gearList,
                                  ];
                                  selectedGearQuantities = {
                                    for (var gear in gearList) gear: gear.quantity,
                                  };
                                } else {
                                  selectedItems.clear();
                                  selectedGearQuantities.clear();
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Crew Member Dropdown
                        ExpansionPanelList(
                          elevation: 8,
                          expandedHeaderPadding: const EdgeInsets.all(0),
                          expansionCallback: (int index, bool isExpanded) {
                            dialogSetState(() {
                              isCrewExpanded = !isCrewExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isCrewExpanded,
                              backgroundColor: Colors.deepOrangeAccent,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  child: ListTile(
                                    title: const Text(
                                      'Crew Members',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedCrewList.map((crew) {
                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0.0),
                                      // Rounded corners
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Text(
                                        '${crew.name}, ${crew.flightWeight} lbs',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.start,
                                      ),
                                      subtitle: Text(
                                        crew.getPositionTitle(crew.position),
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      value: selectedItems.contains(crew),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            selectedItems.add(crew);
                                          } else {
                                            selectedItems.remove(crew);
                                          }
                                          updateSelectAllState(); // Dynamically update "Select All" state
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Gear Dropdown
                        ExpansionPanelList(
                          elevation: 8,
                          expandedHeaderPadding: const EdgeInsets.all(0),
                          expansionCallback: (int index, bool isExpanded) {
                            dialogSetState(() {
                              isGearExpanded = !isGearExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isGearExpanded,
                              backgroundColor: Colors.deepOrangeAccent,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  //color: Colors.deepOrangeAccent, // Set the background color for the header
                                  child: ListTile(
                                    title: const Text(
                                      'Gear',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedGearList.map((gear) {
                                  int remainingQuantity = gear.quantity - (selectedGearQuantities[gear] ?? 0);

                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: gear.isPersonalTool
                                          ? Colors.blue[100] // Color for personal tools
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(0.0),
                                      // Rounded corners
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    gear.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  ' (x$remainingQuantity)  ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selectedItems.contains(gear))
                                            if (selectedItems.contains(gear))
                                              GestureDetector(
                                                onTap: () {
                                                  final int gearQuantity = gear.quantity;
                                                  if (gearQuantity > 1) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text('Select Quantity for ${gear.name}'),
                                                          content: SizedBox(
                                                            height: 150,
                                                            child: CupertinoPicker(
                                                              scrollController: FixedExtentScrollController(
                                                                initialItem: (selectedGearQuantities[gear] ?? 1) - 1,
                                                              ),
                                                              itemExtent: 32.0,
                                                              onSelectedItemChanged: (int value) {
                                                                dialogSetState(() {
                                                                  selectedGearQuantities[gear] = value + 1;
                                                                });
                                                              },
                                                              children: List<Widget>.generate(
                                                                gear.quantity,
                                                                // Use the full quantity for selection
                                                                    (int index) {
                                                                  return Center(
                                                                    child: Text('${index + 1}'),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                // Finalize the selection
                                                                dialogSetState(() {
                                                                  int selectedQuantity = selectedGearQuantities[gear] ?? 1;
                                                                  remainingQuantity = gear.quantity - selectedQuantity;
                                                                });
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: const Text('Confirm'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: const Text('Cancel'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                child: Row(
                                                  children: [
                                                    if (gear.quantity > 1)
                                                      Text(
                                                        'Qty: ${selectedGearQuantities[gear] ?? 1}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    if (gear.quantity > 1) const Icon(Icons.arrow_drop_down, color: Colors.black),
                                                  ],
                                                ),
                                              ),
                                        ],
                                      ),
                                      value: selectedItems.contains(gear),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            selectedItems.add(gear);
                                            selectedGearQuantities[gear] = 1; // Default quantity
                                          } else {
                                            selectedItems.remove(gear);
                                            selectedGearQuantities.remove(gear);
                                          }
                                        });
                                        updateSelectAllState(); // Dynamically update "Select All" state
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (selectedItems.isEmpty){

                        // Select all items again
                        selectedItems = [
                          ...crewList,
                          ...gearList,
                        ];
                        selectedGearQuantities = {
                          for (var gear in gearList) gear: gear.quantity,
                        };

                        // Update trip lists to reflect the selection
                        thisTripCrewMemberList = crewList.map((crew) => crew.copy()).toList();
                        thisTripGearList = gearList.map((gear) => gear.copyWith()).toList();

                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Update thisTripCrewMemberList with only selected crew members
                    thisTripCrewMemberList = selectedItems.whereType<CrewMember>().toList();

                    // Update thisTripGearList with only selected gear items and quantities
                    thisTripGearList = selectedItems
                        .whereType<Gear>()
                        .map((gear) {
                      final selectedQuantity = selectedGearQuantities[gear] ?? 1; // Get selected quantity
                      return Gear(
                        name: gear.name,
                        quantity: selectedQuantity,
                        weight: gear.weight,
                        isPersonalTool: gear.isPersonalTool,
                      );
                    })
                        .toList();

                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: const Text('Select'),
                ),

              ],
            );
          },
        );
      },
    );
  }

  void loadItems() {
    setState(() {
      // Create deep copies of the gear and crew member data
      gearList = gearBox.values.map((gear) {
        return Gear(
          name: gear.name,
          quantity: gear.quantity,
          weight: gear.weight,
          isPersonalTool: gear.isPersonalTool,
        );
      }).toList();

      crewList = crewmemberBox.values.map((crew) {
        return CrewMember(
          name: crew.name,
          flightWeight: crew.flightWeight,
          position: crew.position,
          personalTools: crew.personalTools,
        );
      }).toList();
    });
    // Load CrewMembers from Hive (or another data source)
    thisTripCrewMemberList.addAll(crewmemberBox.values.toList());

    // Load Gear from Hive (or another data source)
    thisTripGearList.addAll(gearBox.values.toList());
  }

  // Track the last input source
  bool lastInputFromSlider = true;

  @override
  void dispose() {
    tripNameController.dispose();
    allowableController.dispose();
    availableSeatsController.dispose();
    keyboardController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isTripNameValid = tripNameController.text.isNotEmpty;
    final isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && int.tryParse(availableSeatsController.text) != null && int.parse(availableSeatsController.text) > 0;

    setState(() {
      // Need to adjust for position as well
      isCalculateButtonEnabled = isTripNameValid && isAvailableSeatsValid;
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveTripData() {
    // Take what the trip name contrller has saved
    final String tripName = tripNameController.text;

    // Check if crew member name already exists
    bool tripNameExists = savedTrips.savedTrips.any((member) => member.tripName == tripName);

    if (tripNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Trip name already used!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return; // Exit function if the trip name is already used
    }
    final int allowable = int.parse(allowableController.text);
    // Convert available seats text to integer
    final int availableSeats = int.parse(availableSeatsController.text);

    // Creating a new Trip object
    Trip newTrip = Trip(tripName: tripName, allowable: allowable, availableSeats: availableSeats);

    // Deep copy crewMembers and gear into the new Trip
    newTrip.crewMembers = thisTripCrewMemberList.map((member) => member.copy()).toList();
    newTrip.gear =  thisTripGearList.map((item) => item.copyWith()).toList();

    newTrip.calculateTotalCrewWeight();

    if (newTrip.crewMembers.isEmpty){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {

              return AlertDialog(
                title: const Text('No Crew Members Selected'),
                content: Text('Select at least one crew member and try again.'
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),

                ],
              );
            },
          );
        },
      );
      return;
    }
    // Add the new trip to the global crew object
    savedTrips.addTrip(newTrip);

    // Manifest that load, baby
    loadCalculator(context, newTrip, selectedTripPreference);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Trip Saved!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Clear the text fields (reset them to empty), so we can add more trips
    tripNameController.text = '';
    availableSeatsController.text = '';

    // Reset the slider value back to 0
    setState(() {
      _sliderValue = 1000;
      allowableController.text = _sliderValue.toStringAsFixed(0); // Sync the allowableController with the slider
    });

    // // Debug for LogCat
    // print("--------------------------");
    // print("Trip Name: $tripName");
    // print("Allowable: $allowable");
    // print("--------------------------");
    // savedTrips.printTripDetails();
  }

  void _incrementSlider() {
    setState(() {
      _sliderValue = (_sliderValue + 5).clamp(1000, 5000); // Prevents from going past boundaries
      allowableController.text = _sliderValue.toStringAsFixed(0);
    });
  }

  void _decrementSlider() {
    setState(() {
      _sliderValue = (_sliderValue - 5).clamp(1000, 5000);
      allowableController.text = _sliderValue.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10));

    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Create New Manifest',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        onVerticalDragStart: (_) {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard on vertical swipe
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              // Takes up all available space
              child: Stack(
                children: [
                  // Background image
                  Container(
                    child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        // Blur effect
                        child: Image.asset(
                          'assets/images/logo1.png',
                          fit: BoxFit.cover, // Cover  entire background
                          width: double.infinity,
                          height: double.infinity,
                        )),
                  ),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                        SizedBox(height: 16),
                          // Trip Name input field
                          Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                              child: TextField(
                                controller: tripNameController,
                                maxLength: 20,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Enter Trip Name',
                                  labelStyle: const TextStyle(
                                    color: Colors.black, // Label color when not focused
                                    fontSize: 18, // Label font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      // Border color when the TextField is not focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      // Border color when the TextField is focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                      
                          // Available Seats input field
                          Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                              child: TextField(
                                controller: availableSeatsController,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                // Only show numeric keyboard
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  // Allow only digits
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Enter # of Available Seats',
                                  labelStyle: const TextStyle(
                                    color: Colors.black, // Label color when not focused
                                    fontSize: 18, // Label font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      // Border color when the TextField is not focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      // Border color when the TextField is focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                      
                          // Select All/Some Crew
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.black, width: 2.0),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  // Checkbox
                                  IconButton(
                                    icon: Icon(
                                      selectedItems.length == (crewList.length + gearList.length)
                                          ? Icons.check_box // Fully selected
                                          : Icons.check_box_outline_blank, // Partially or none selected
                                      color: Colors.black,
                                      size: 28, // Adjust size as needed
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (selectedItems.length != (crewList.length + gearList.length)) {
                                          // Select all items again
                                          selectedItems = [
                                            ...crewList,
                                            ...gearList,
                                          ];
                                          selectedGearQuantities = {
                                            for (var gear in gearList) gear: gear.quantity,
                                          };
                      
                                          // Update trip lists to reflect the selection
                                          thisTripCrewMemberList = crewList.map((crew) => crew.copy()).toList();
                                          thisTripGearList = gearList.map((gear) => gear.copyWith()).toList();
                                        } else {
                                          // Clear selections
                                          thisTripCrewMemberList.clear();
                                          thisTripGearList.clear();
                                          selectedItems.clear();
                                          selectedGearQuantities.clear();
                                          _showSelectionDialog();
                                        }
                                      });
                      
                                    },
                                  ),
                      
                                  const Text(
                                  'Select All Crew',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                      
                                  const Spacer(),
                      
                                  // List icon
                                  IconButton(
                                    icon: Icon(
                                      Icons.list,
                                      color: Colors.black,
                                      size: 32,
                                    ), onPressed: () {
                                      _showSelectionDialog();
                                      setState(() {
                      
                                      });
                                      },
                                  ),
                              ],
                              ),
                            ),
                          ),
                      
                          // Choose Trip Preference text box
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0, bottom: 0.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.deepOrangeAccent,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              //alignment: Alignment.center,
                              child: Text(
                                'Choose Trip Preference',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                      
                          // Choose Trip Preference
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0, left: 16.0, right: 16.0, bottom: 5.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.black, width: 2.0),
                              ),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TripPreference?>(
                                value: selectedTripPreference,
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                iconEnabledColor: Colors.black,
                                items: [
                                  DropdownMenuItem<TripPreference?>(
                                    value: null, // Represents the "None" option
                                    child: const Text("None"),
                                  ),
                                  ...savedPreferences.tripPreferences.map((entry) {
                                    return DropdownMenuItem<TripPreference>(
                                      value: entry,
                                      child: Text(entry.tripPreferenceName),
                                    );
                                  }),
                                ],
                                onChanged: (TripPreference? newValue) {
                                  setState(() {
                                    selectedTripPreference = newValue;
                                    _checkInput();
                                  });
                                },
                              )),
                            ),
                          ),
                      
                      
                          // Choose allowable text box
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.deepOrangeAccent,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), // Reduced padding
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      'Choose Allowable',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Clear the keyboardController before opening the dialog
                                      keyboardController.text = '';
                      
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          // Save the original value in case of cancel
                                          String originalValue = allowableController.text;
                      
                                          // Track if the Save button should be enabled
                                          bool isSaveEnabled = false;
                      
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              // Function to validate input and enable/disable Save button
                                              void validateInput(String value) {
                                                final int? parsedValue = int.tryParse(value);
                                                setState(() {
                                                  isSaveEnabled = parsedValue != null && parsedValue >= 500 && parsedValue <= 10000;
                                                });
                                              }
                      
                                              return AlertDialog(
                                                title: const Text('Enter Allowable Weight'),
                                                content: TextField(
                                                  controller: keyboardController,
                                                  keyboardType: TextInputType.number,
                                                  maxLength: 4,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                  ],
                                                  onChanged: (value) {
                                                    validateInput(value); // Validate the input
                                                    setState(() {
                                                      lastInputFromSlider = false;
                                                    });
                                                  },
                                                  decoration: const InputDecoration(
                                                    hintText: 'Up to 9,999 lbs',
                                                    counterText: '',
                                                    border: OutlineInputBorder(),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      // Revert to the original value on cancel
                                                      keyboardController.text = originalValue;
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: isSaveEnabled
                                                        ? () {
                                                            setState(() {
                                                              if (keyboardController.text.isNotEmpty) {
                                                                _sliderValue = double.parse(keyboardController.text).clamp(1000, 5000);
                                                                allowableController.text = keyboardController.text;
                                                              }
                                                            });
                                                            Navigator.of(context).pop();
                                                          }
                                                        : null, // Disable Save if input is invalid
                                                    child: Text(
                                                      'Save',
                                                      style: TextStyle(
                                                        color: isSaveEnabled ? Colors.blue : Colors.grey, // Show enabled/disabled state
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(FontAwesomeIcons.keyboard, size: 32, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      
                          // Allowable Slider
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0, right: 16.0, left: 16.0),
                            child: Stack(
                              children: [
                                // Background container with white background, black outline, and rounded corners
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white, // Background color
                                      border: Border.all(color: Colors.black, width: 2), // Black outline
                                      borderRadius: BorderRadius.circular(8), // Rounded corners
                                    ),
                                  ),
                                ),
                                // Column with existing widgets
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: _decrementSlider,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors.deepOrangeAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              elevation: 15,
                                              shadowColor: Colors.black,
                                              side: const BorderSide(color: Colors.black, width: 2),
                                              shape: CircleBorder(),
                                            ),
                                            child: const Icon(Icons.remove, color: Colors.black, size: 32),
                                          ),
                                          const Spacer(),
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Slider value
                                              Visibility(
                                                visible: lastInputFromSlider,
                                                child: Text(
                                                  '${_sliderValue.toStringAsFixed(0)} lbs',
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              // Keyboard input value
                                              Visibility(
                                                visible: !lastInputFromSlider,
                                                child: Text(
                                                  '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lbs',
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: _incrementSlider,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors.deepOrangeAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              elevation: 15,
                                              shadowColor: Colors.black,
                                              side: const BorderSide(color: Colors.black, width: 2),
                                              shape: CircleBorder(),
                                            ),
                                            child: const Icon(Icons.add, color: Colors.black, size: 32),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Slider(
                                      value: _sliderValue,
                                      min: 1000,
                                      max: 5000,
                                      divisions: 40,
                                      label: null,
                                      onChanged: (double value) {
                                        setState(() {
                                          _sliderValue = value;
                                          lastInputFromSlider = true;
                                          allowableController.text = _sliderValue.toStringAsFixed(0);
                                        });
                                      },
                                      activeColor: Colors.deepOrange,
                                      // Color when the slider is active
                                      inactiveColor: Colors.grey, // Color for the inactive part
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),
                          // Calculate Button
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                            child: ElevatedButton(
                              onPressed: isCalculateButtonEnabled
                                  ? () {
                                      saveTripData(); // Call saveTripData first
                                    }
                                  : null, // Button is only enabled if there is input
                              style: style, // Main button theme
                              child: const Text('Calculate'),
                            ),
                          ),

                        ],
                      ),
                    ),
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
