import 'dart:math';
import 'dart:ui';
import 'package:fire_app/CodeShare/colors.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../Data/trip.dart';
import '../UI/05_define_constraints_manifest.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Algorithms/load_calculator.dart';
import '../Data/trip_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'calculating_screen.dart';

class CreateNewManifest extends StatelessWidget {
  final void Function(int) onSwitchTab; // Callback to switch tabs

  const CreateNewManifest({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context); // Updates width and orientation
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.appBarColor, // Transparent to show the background
              elevation: 0,
              toolbarHeight: 0,
              bottom: TabBar(
                unselectedLabelColor: AppColors.tabIconColor,
                labelColor: AppColors.primaryColor,
                dividerColor: AppColors.appBarColor,
                indicatorColor: AppColors.primaryColor,
                tabs: const [
                  Tab(
                    text: 'Quick Manifest',
                    icon: Icon(Icons.bolt),
                  ),
                  Tab(
                    text: 'Build Your Own',
                    icon: Icon(Icons.build),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent, // Transparent to ensure the background is visible
            body: Stack(
              children: [
                Container(
                  color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
                  child: AppColors.isDarkMode
                      ? (AppColors.enableBackgroundImage
                          ? Stack(
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                                  child: Image.asset(
                                    'assets/images/logo1.png',
                                    fit: BoxFit.cover, // Cover the entire background
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Container(
                                  color: AppColors.logoImageOverlay, // Semi-transparent overlay
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ],
                            )
                          : null) // No image if background is disabled
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Always display in light mode
                          child: Image.asset(
                            'assets/images/logo1.png',
                            fit: BoxFit.cover, // Cover the entire background
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Dismiss the keyboard
                  },
                  onVerticalDragStart: (_) {
                    FocusScope.of(context).unfocus(); // Dismiss the keyboard on vertical swipe
                  },
                  child: TabBarView(
                    children: [
                      QuickManifest(onSwitchTab: onSwitchTab), // Your first screen
                      const DesignNewManifest(), // Replace with your second screen widget
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickManifest extends StatefulWidget {
  final void Function(int) onSwitchTab;

  const QuickManifest({super.key, required this.onSwitchTab});

  @override
  State<QuickManifest> createState() => _QuickManifestState();
}

class _QuickManifestState extends State<QuickManifest> {
  late final Box<Gear> gearBox;
  late final Box<CrewMember> crewmemberBox;

  // Lists for Select All/Some dialog
  List<Gear> gearList = [];
  List<Gear> gearListExternal = [];
  List<CrewMember> crewList = [];

  String? tripNameErrorMessage;
  String? availableSeatsErrorMessage;
  String? safetyBufferErrorMessage;

  // Lists for actual crew going into trip object
  List<CrewMember> thisTripCrewMemberList = [];
  List<Gear> thisTripGearList = [];
  List<Gear> thisTripGearListExternal = [];


  late Map<Gear, int> selectedGearQuantities;
  late List<dynamic> selectedItems;

  late Map<Gear, int> selectedGearQuantitiesExternal;
  late List<dynamic> selectedItemsExternal;

  // Variables to store user input
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController allowableController = TextEditingController();
  final TextEditingController availableSeatsController = TextEditingController();
  final TextEditingController safetyBufferController = TextEditingController(text: '0');

  final TextEditingController keyboardController = TextEditingController();
  double _sliderValue = 1000;

  // Can be null as a "None" option is available where user doesn't select a Load Preference
  TripPreference? selectedTripPreference;

  bool isCalculateButtonEnabled = false; // Controls whether saving button is showing
  bool isExternalManifest = false; // Default to internal manifest (personnel + cargo)

  @override
  void initState() {
    super.initState();

    gearBox = Hive.box<Gear>('gearBox');
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

    // Listeners to the TextControllers
    tripNameController.addListener(_checkInput);
    allowableController.addListener(_checkInput);
    availableSeatsController.addListener(_checkInput);
    safetyBufferController.addListener(_checkInput);

    // Initialize allowableController with the default slider value
    allowableController.text = _sliderValue.toStringAsFixed(0);

    loadItems();

    // Initialize selectedItems with all crew and gear items
    selectedItems = [
      ...crewList,
      ...gearList,
    ];

    // Initialize selectedGearQuantities
    selectedGearQuantities = {
      for (var gear in gearList) gear: gear.quantity,
    };

    // Do the same for External Manifesting
    selectedItemsExternal = [
      ...gearListExternal,
    ];
    selectedGearQuantitiesExternal = {
      for (var gear in gearListExternal) gear: gear.quantity,
    };
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
      gearListExternal = gearBox.values.map((gear) {
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
    // Load CrewMembers from Hive
    thisTripCrewMemberList.addAll(crewmemberBox.values.toList());

    // Load Gear from Hive
    thisTripGearList.addAll(gearBox.values.toList());
    thisTripGearListExternal.addAll(gearBox.values.toList());

  }

  void _showExternalManifestSelectionDialog() async {
    List<Gear> sortedGearList = sortGearListAlphabetically(gearListExternal);
    bool isGearExpanded = false;

    // "Select All" starts as true because everything is selected by default
    bool isSelectAllChecked = selectedItemsExternal.length == gearListExternal.length &&
        selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Function to update "Select All" checkbox dynamically
            void updateSelectAllState() {
              dialogSetState(() {
                isSelectAllChecked =  selectedItemsExternal.length == gearListExternal.length &&
                    selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Select Gear' ,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
              ),
              contentPadding: EdgeInsets.all(AppData.padding16),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Container(
                  width: AppData.selectionDialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Select All Checkbox
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor, // Outline color
                              width: 1.0, // Outline thickness
                            ),
                            //    borderRadius: BorderRadius.circular(8.0), // Rounded corners (optional)
                          ),
                          child: CheckboxListTile(
                            activeColor: AppColors.textColorPrimary,
                            // Checkbox outline color when active
                            checkColor: AppColors.textColorSecondary,
                            side: BorderSide(
                              color: AppColors.textColorPrimary, // Outline color
                              width: 2.0, // Outline width
                            ),
                            // Checkmark color
                            title: Text(
                              'Select All',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18, color: AppColors.textColorPrimary),
                            ),
                            value: isSelectAllChecked,
                            onChanged: (bool? isChecked) {
                              dialogSetState(() {
                                isSelectAllChecked = isChecked ?? false;

                                if (isSelectAllChecked) {
                                  selectedItemsExternal =  [...gearListExternal]; // Only gear if external manifest

                                  selectedGearQuantitiesExternal = {
                                    for (var gear in gearListExternal) gear: gear.quantity,
                                  };
                                } else {
                                  selectedItemsExternal.clear();
                                  selectedGearQuantitiesExternal.clear();
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(height: AppData.sizedBox16),


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
                              backgroundColor: AppColors.fireColor,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  //color: Colors.deepOrangeAccent, // Set the background color for the header
                                  child: ListTile(
                                    title: Text(
                                      'Gear',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedGearList.map((gear) {
                                  int remainingQuantity = gear.quantity - (selectedGearQuantitiesExternal[gear] ?? 0);

                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: AppColors.textFieldColor,
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
                                      activeColor: AppColors.textColorPrimary,
                                      // Checkbox outline color when active
                                      checkColor: AppColors.textColorSecondary,
                                      side: BorderSide(
                                        color: AppColors.textColorPrimary, // Outline color
                                        width: 2.0, // Outline width
                                      ),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    gear.name,
                                                    style: TextStyle(
                                                      fontSize: AppData.text16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textColorPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  ' (x$remainingQuantity)  ',
                                                  style: TextStyle(
                                                    fontSize: AppData.text12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textColorPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selectedItemsExternal.contains(gear))
                                            if (selectedItemsExternal.contains(gear))
                                              GestureDetector(
                                                onTap: () {
                                                  final int gearQuantity = gear.quantity;
                                                  if (gearQuantity > 1) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          backgroundColor: AppColors.textFieldColor2,
                                                          title: Text(
                                                            'Select Quantity for ${gear.name}',
                                                            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text18),
                                                          ),
                                                          content: SizedBox(
                                                            height: AppData.miniSelectionDialogHeight,
                                                            child: CupertinoPicker(
                                                              scrollController: FixedExtentScrollController(
                                                                initialItem: (selectedGearQuantitiesExternal[gear] ?? 1) - 1,
                                                              ),
                                                              itemExtent: 32.0,
                                                              onSelectedItemChanged: (int value) {
                                                                dialogSetState(() {
                                                                  selectedGearQuantitiesExternal[gear] = value + 1;
                                                                });
                                                              },
                                                              children: List<Widget>.generate(
                                                                gear.quantity,
                                                                // Use the full quantity for selection
                                                                    (int index) {
                                                                  return Center(
                                                                    child: Text('${index + 1}', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.cupertinoPickerItemSize)),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Finalize the selection
                                                                dialogSetState(() {
                                                                  int selectedQuantity = selectedGearQuantitiesExternal[gear] ?? 1;
                                                                  remainingQuantity = gear.quantity - selectedQuantity;
                                                                  updateSelectAllState();
                                                                });
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Confirm', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
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
                                                        'Qty: ${selectedGearQuantitiesExternal[gear] ?? 1}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: AppData.text14,
                                                          color: AppColors.textColorPrimary,
                                                        ),
                                                      ),
                                                    if (gear.quantity > 1)
                                                      Icon(
                                                        Icons.arrow_drop_down,
                                                        color: AppColors.textColorPrimary,
                                                        size: AppData.dropDownArrowSize,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                        ],
                                      ),
                                      value: selectedItemsExternal.contains(gear),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            selectedItemsExternal.add(gear);
                                            selectedGearQuantitiesExternal[gear] = 1; // Default quantity
                                          } else {
                                            selectedItemsExternal.remove(gear);
                                            selectedGearQuantitiesExternal.remove(gear);
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
                      if (selectedItemsExternal.isEmpty) {
                        // Select all items again
                        selectedItemsExternal = [
                          ...gearListExternal,
                        ];
                        selectedGearQuantitiesExternal = {
                          for (var gear in gearListExternal) gear: gear.quantity,
                        };

                        // Update trip lists to reflect the selection
                        thisTripGearListExternal = gearListExternal.map((gear) => gear.copyWith()).toList();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedItemsExternal.isEmpty) {
                      // Select all items again
                      selectedItemsExternal = [
                        ...gearListExternal,
                      ];
                      selectedGearQuantitiesExternal = {
                        for (var gear in gearListExternal) gear: gear.quantity,
                      };

                      // Update trip lists to reflect the selection
                      thisTripGearListExternal = gearListExternal.map((gear) => gear.copyWith()).toList();
                    }
                    else {
                      // Update thisTripGearListExternal with only selected gear items and quantities
                      thisTripGearListExternal = selectedItemsExternal.whereType<Gear>().map((gear) {
                        final selectedQuantity = selectedGearQuantitiesExternal[gear] ?? 1; // Get selected quantity
                        return Gear(
                          name: gear.name,
                          quantity: selectedQuantity,
                          weight: gear.weight,
                          isPersonalTool: gear.isPersonalTool,
                        );
                      }).toList();
                    }
                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: Text('Select', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showInternalManifestSelectionDialog() async {
    List<CrewMember> sortedCrewList = sortCrewListByPosition(crewList);
    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);
    bool isCrewExpanded = false;
    bool isGearExpanded = false;

    // "Select All" starts as true because everything is selected by default
    bool isSelectAllChecked =  selectedItems.length == (crewList.length + gearList.length) &&
        selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Function to update "Select All" checkbox dynamically
            void updateSelectAllState() {
              dialogSetState(() {
                 isSelectAllChecked = selectedItems.length == (crewList.length + gearList.length) &&
                     selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Select Crew Members and Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
              ),
              contentPadding: EdgeInsets.all(AppData.padding16),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Container(
                  width: AppData.selectionDialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Select All Checkbox
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor, // Outline color
                              width: 1.0, // Outline thickness
                            ),
                            //    borderRadius: BorderRadius.circular(8.0), // Rounded corners (optional)
                          ),
                          child: CheckboxListTile(
                            activeColor: AppColors.textColorPrimary,
                            // Checkbox outline color when active
                            checkColor: AppColors.textColorSecondary,
                            side: BorderSide(
                              color: AppColors.textColorPrimary, // Outline color
                              width: 2.0, // Outline width
                            ),
                            // Checkmark color
                            title: Text(
                              'Select All',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18, color: AppColors.textColorPrimary),
                            ),
                            value: isSelectAllChecked,
                            onChanged: (bool? isChecked) {
                              dialogSetState(() {
                                isSelectAllChecked = isChecked ?? false;

                                if (isSelectAllChecked) {
                                  selectedItems = [...crewList, ...gearList]; // Both crew and gear if internal manifest

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
                        SizedBox(height: AppData.sizedBox16),

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
                                backgroundColor: AppColors.fireColor,
                                // Set background color
                                headerBuilder: (context, isExpanded) {
                                  return Container(
                                    child: ListTile(
                                      title: Text(
                                        'Crew Members',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18, color: Colors.black),
                                      ),
                                    ),
                                  );
                                },
                                body: Column(
                                  children: sortedCrewList.map((crew) {
                                    return Container(
                                      //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                      decoration: BoxDecoration(
                                        color: AppColors.textFieldColor,
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
                                        activeColor: AppColors.textColorPrimary,
                                        // Checkbox outline color when active
                                        checkColor: AppColors.textColorSecondary,
                                        // Checkmark color
                                        side: BorderSide(
                                          color: AppColors.textColorPrimary, // Outline color
                                          width: 2.0, // Outline width
                                        ),
                                        title: Text(
                                          '${crew.name}, ${crew.flightWeight} lbs',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                          textAlign: TextAlign.start,
                                        ),
                                        subtitle: Text(
                                          crew.getPositionTitle(crew.position),
                                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: AppData.text14, color: AppColors.textColorPrimary),
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
                           SizedBox(height: AppData.sizedBox16),

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
                              backgroundColor: AppColors.fireColor,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  //color: Colors.deepOrangeAccent, // Set the background color for the header
                                  child: ListTile(
                                    title: Text(
                                      'Gear',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18),
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
                                      color: AppColors.textFieldColor,
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
                                      activeColor: AppColors.textColorPrimary,
                                      // Checkbox outline color when active
                                      checkColor: AppColors.textColorSecondary,
                                      side: BorderSide(
                                        color: AppColors.textColorPrimary, // Outline color
                                        width: 2.0, // Outline width
                                      ),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    gear.name,
                                                    style: TextStyle(
                                                      fontSize: AppData.text16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textColorPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  ' (x$remainingQuantity)  ',
                                                  style: TextStyle(
                                                    fontSize: AppData.text12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textColorPrimary,
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
                                                          backgroundColor: AppColors.textFieldColor2,
                                                          title: Text(
                                                            'Select Quantity for ${gear.name}',
                                                            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text18),
                                                          ),
                                                          content: SizedBox(
                                                            height: AppData.miniSelectionDialogHeight,
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
                                                                    child: Text('${index + 1}', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.cupertinoPickerItemSize)),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Finalize the selection
                                                                dialogSetState(() {
                                                                  int selectedQuantity = selectedGearQuantities[gear] ?? 1;
                                                                  remainingQuantity = gear.quantity - selectedQuantity;
                                                                  updateSelectAllState();
                                                                });
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Confirm', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
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
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: AppData.text14,
                                                          color: AppColors.textColorPrimary,
                                                        ),
                                                      ),
                                                    if (gear.quantity > 1)
                                                      Icon(
                                                        Icons.arrow_drop_down,
                                                        color: AppColors.textColorPrimary,
                                                        size: AppData.dropDownArrowSize,
                                                      ),
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
                      if (selectedItems.isEmpty) {
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedItems.isEmpty) {
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
                    else {
                      // Update thisTripCrewMemberList with only selected crew members
                      thisTripCrewMemberList = selectedItems.whereType<CrewMember>().toList();

                      // Update thisTripGearList with only selected gear items and quantities
                      thisTripGearList = selectedItems.whereType<Gear>().map((gear) {
                        final selectedQuantity = selectedGearQuantities[gear] ?? 1; // Get selected quantity
                        return Gear(
                          name: gear.name,
                          quantity: selectedQuantity,
                          weight: gear.weight,
                          isPersonalTool: gear.isPersonalTool,
                        );
                      }).toList();
                    }
                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: Text('Select', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // Track the last input source
  bool lastInputFromSlider = true;

  @override
  void dispose() {
    tripNameController.dispose();
    allowableController.dispose();
    availableSeatsController.dispose();
    safetyBufferController.dispose();
    keyboardController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final String tripName = tripNameController.text;
// Validate trip name existence (case-insensitive)
    final bool isTripNameUnique = !savedTrips.savedTrips.any(
      (member) => member.tripName.toLowerCase() == tripName.toLowerCase(),
    );

    final bool isTripNameValid = tripName.isNotEmpty && isTripNameUnique;
    var isAvailableSeatsValid = availableSeatsController.text.isNotEmpty && int.tryParse(availableSeatsController.text) != null && int.parse(availableSeatsController.text) > 0;

    if (isExternalManifest) {
      isAvailableSeatsValid = true;
    }
    setState(() {
      // Need to adjust for position as well
      isCalculateButtonEnabled = isTripNameValid && isAvailableSeatsValid;
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveTripData(VoidCallback onSuccess) {
    // Take what the trip name contrller has saved
    final String tripName = tripNameController.text;

    // Check if crew member name already exists
    bool tripNameExists = savedTrips.savedTrips.any(
      (member) => member.tripName.toLowerCase() == tripName.toLowerCase(),
    );

    final String tripNameCapitalized = tripNameController.text
        .toLowerCase() // Ensure the rest of the string is lowercase
        .split(' ') // Split by spaces into words
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' '); // Join the words back with a space

    if (tripNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Trip name already used!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: AppData.text28,
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
    Trip newTrip = Trip(tripName: tripNameCapitalized, allowable: allowable, availableSeats: availableSeats);

    // Deep copy crewMembers and gear into the new Trip
    newTrip.crewMembers = thisTripCrewMemberList.map((member) => member.copy()).toList();
    newTrip.gear = thisTripGearList.map((item) => item.copyWith()).toList();

    newTrip.calculateTotalCrewWeight();
    if (crewList.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: AppColors.textFieldColor2,
                title: Text(
                  'No Crew Members Available',
                  style: TextStyle(color: AppColors.textColorPrimary),
                ),
                content: Text('There are no existing crew members. Create at least one to begin manifesting.', style: TextStyle(color: AppColors.textColorPrimary)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: TextStyle(color: AppColors.textColorPrimary)),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }
    if (newTrip.crewMembers.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: AppColors.textFieldColor2,
                title: Text(
                  'No Crew Members Selected',
                  style: TextStyle(color: AppColors.textColorPrimary),
                ),
                content: Text('Select at least one crew member and try again.', style: TextStyle(color: AppColors.textColorPrimary)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: TextStyle(color: AppColors.textColorPrimary)),
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

    // Load Calculation with animation
    startCalculation(context, newTrip, selectedTripPreference);

    // Load Calculation without animation
    // loadCalculator(context, newTrip, selectedTripPreference);

    // Clear the text fields (reset them to empty), so we can add more trips
    tripNameController.text = '';
    availableSeatsController.text = '';

    // Reset the slider value back to 0
    setState(() {
      _sliderValue = 1000;
      allowableController.text = _sliderValue.toStringAsFixed(0); // Sync the allowableController with the slider
    });

    // Notify parent widget
    // onSuccess();
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
    // Select All is only checked if full item selection + full quantity selection
     bool isSelectAllChecked() {
      if (isExternalManifest) {
        return selectedItemsExternal.length == gearListExternal.length &&
            selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
      } else {
        return selectedItems.length == (crewList.length + gearList.length) &&
            selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
      }
    }

    AppData.updateScreenData(context); // Updates width and orientation
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
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
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withValues(alpha: 0.05),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),

                      // Internal/External Manifest toggle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(
                              isExternalManifest ? "External" : "Internal",
                              style: TextStyle(
                                fontSize: AppData.text18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min, // Keeps row from expanding
                              children: [
                                Icon(
                                  isExternalManifest ? FontAwesomeIcons.battleNet : FontAwesomeIcons.helicopter,
                                  color: AppColors.primaryColor,
                                  size: AppData.text24,
                                ),
                                SizedBox(width: 8), // Add spacing between icon and switch
                                Switch(
                                  value: isExternalManifest,
                                  activeColor: AppColors.primaryColor,
                                  inactiveThumbColor: AppColors.primaryColor,
                                  inactiveTrackColor: AppColors.textFieldColor,
                                  onChanged: (bool value) {
                                    setState(() {
                                      isExternalManifest = value;
                                      // Reset selected items and gear quantities
                                      selectedItems.clear();
                                      selectedGearQuantities.clear();

                                      thisTripCrewMemberList.clear();
                                      thisTripGearList.clear();

                                      // Re-populate selection based on the mode
                                      if (isExternalManifest) {
                                        // External: Only gear is selectable
                                        selectedItems = [...gearList];
                                        selectedGearQuantities = {for (var gear in gearList) gear: gear.quantity};
                                      } else {
                                        // Internal: Both crew and gear are selectable
                                        selectedItems = [...crewList, ...gearList];
                                        selectedGearQuantities = {for (var gear in gearList) gear: gear.quantity};
                                      }
                                    });
                                    _checkInput();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: AppData.spacingStandard),

                      // Trip Name input field
                      Padding(
                          padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                          child: Container(
                            width: AppData.inputFieldWidth,
                            child: TextField(
                              controller: tripNameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                              ],
                              textCapitalization: TextCapitalization.words,
                              onChanged: (value) {
                                setState(() {
                                  // Check if the trip name exists in the savedTrips list (case-insensitive)
                                  final String tripName = tripNameController.text;

                                  // Check if crew member name already exists
                                  bool tripNameExists = savedTrips.savedTrips.any(
                                    (member) => member.tripName.toLowerCase() == tripName.toLowerCase(),
                                  );

                                  // Validate the input and set error message
                                  if (tripNameExists) {
                                    tripNameErrorMessage = 'Trip name already used';
                                  } else {
                                    tripNameErrorMessage = null;
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Enter Trip Name',
                                labelStyle: TextStyle(
                                  color: AppColors.textColorPrimary, // Label color when not focused
                                  fontSize: AppData.text18, // Label font size
                                ),
                                errorText: tripNameErrorMessage,
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: AppData.text24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),

                      SizedBox(height: AppData.spacingStandard),

                      // Available Seats input field
                      if (!isExternalManifest)
                        Padding(
                            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                            child: Container(
                              width: AppData.inputFieldWidth,
                              child: TextField(
                                controller: availableSeatsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    // Validate the input and set error message
                                    if (value == '0') {
                                      availableSeatsErrorMessage = 'Available seats cannot be 0.';
                                    } else {
                                      availableSeatsErrorMessage = null;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Enter # of Available Seats',
                                  labelStyle: TextStyle(
                                    color: AppColors.textColorPrimary, // Label color when not focused
                                    fontSize: AppData.text18, // Label font size
                                  ),
                                  errorText: availableSeatsErrorMessage,
                                  filled: true,
                                  fillColor: AppColors.textFieldColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.borderPrimary,
                                      // Border color when the TextField is not focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      // Border color when the TextField is focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),

                      // Safety Buffer
                      if (isExternalManifest)
                        Padding(
                            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                            child: Container(
                              width: AppData.inputFieldWidth,
                              child: TextField(
                                controller: safetyBufferController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(3),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  labelText: 'Enter Safety Buffer (lbs)',
                                  labelStyle: TextStyle(
                                    color: AppColors.textColorPrimary, // Label color when not focused
                                    fontSize: AppData.text18, // Label font size
                                  ),
                                  errorText: safetyBufferErrorMessage,
                                  filled: true,
                                  fillColor: AppColors.textFieldColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.borderPrimary,
                                      // Border color when the TextField is not focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0), // Rounded corners
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      // Border color when the TextField is focused
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                style: TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: AppData.text24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                      SizedBox(height: AppData.spacingStandard),

                      // Select All/Some Crew
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16, top: 0.0, bottom: AppData.padding5),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          padding: EdgeInsets.symmetric(vertical: AppData.padding8),
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              // Checkbox
                              Padding(
                                padding: EdgeInsets.only(left: AppData.padding5, right: AppData.padding5),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    isSelectAllChecked()
                                        ? Icons.check_box // Fully selected
                                        : Icons.check_box_outline_blank, // Partially or none selected
                                    color: AppColors.textColorPrimary,
                                    size: AppData.text28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (!isExternalManifest) {
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
                                          _showInternalManifestSelectionDialog();
                                        }
                                      }
                                      else{
                                        if (selectedItemsExternal.length != (gearListExternal.length)) {
                                          // Select all items again
                                          selectedItemsExternal = [
                                            ...gearListExternal,
                                          ];
                                          selectedGearQuantitiesExternal = {
                                            for (var gear in gearListExternal) gear: gear.quantity,
                                          };

                                          // Update trip lists to reflect the selection
                                          thisTripGearListExternal = gearListExternal.map((gear) => gear.copyWith()).toList();
                                        } else {
                                          // Clear selections
                                          thisTripGearListExternal.clear();
                                          selectedItemsExternal.clear();
                                          selectedGearQuantitiesExternal.clear();
                                          _showExternalManifestSelectionDialog();
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),

                              Text(
                                isExternalManifest ? 'Select All Gear' : 'Select All Crew',
                                style: TextStyle(
                                  fontSize: AppData.text18,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),

                              const Spacer(),

                              // List icon
                              IconButton(
                                icon: Icon(
                                  Icons.list,
                                  color: AppColors.textColorPrimary,
                                  size: AppData.text32,
                                ),
                                onPressed: () {
                                  isExternalManifest ? _showExternalManifestSelectionDialog() : _showInternalManifestSelectionDialog();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppData.spacingStandard),

                      // Choose Trip Preference text box
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          decoration: BoxDecoration(
                            color: AppColors.fireColor,
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
                          padding: EdgeInsets.symmetric(horizontal: AppData.padding10, vertical: AppData.padding10),
                          //alignment: Alignment.center,
                          child: Text(
                            'Choose Trip Preference',
                            style: TextStyle(
                              fontSize: AppData.text18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Choose Trip Preference
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          padding: EdgeInsets.symmetric(horizontal: AppData.padding12, vertical: AppData.padding8),
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<TripPreference?>(
                            value: selectedTripPreference,
                            dropdownColor: AppColors.textFieldColor2,
                            style: TextStyle(
                              color: AppColors.textColorPrimary,
                              fontSize: AppData.text24,
                              fontWeight: FontWeight.bold,
                            ),
                            iconEnabledColor: AppColors.textColorPrimary,
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

                      SizedBox(height: AppData.spacingStandard),

                      // Choose allowable text box
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          decoration: BoxDecoration(
                            color: AppColors.fireColor,
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
                          padding: EdgeInsets.symmetric(horizontal: AppData.padding5, vertical: AppData.padding5), // Reduced padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: AppData.padding8),
                                child: Text(
                                  'Choose Allowable',
                                  style: TextStyle(
                                    fontSize: AppData.text18,
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
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text('Enter Allowable Weight', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize)),
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
                                              decoration: InputDecoration(
                                                hintText: 'Up to 9,999 lbs',
                                                hintStyle: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                                                filled: true,
                                                fillColor: AppColors.textFieldColor,
                                                // Background color of the text field
                                                counterText: '',
                                                border: const OutlineInputBorder(),
                                              ),
                                              style: TextStyle(
                                                color: AppColors.textColorPrimary, // Color of the typed text
                                                fontSize: AppData.miniDialogBodyTextSize, // Font size for the typed text
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Revert to the original value on cancel
                                                  keyboardController.text = originalValue;
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
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
                                                      color: isSaveEnabled ? AppColors.saveButtonAllowableWeight : Colors.grey, fontSize: AppData.bottomDialogTextSize // Show enabled/disabled state
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
                                icon: Icon(FontAwesomeIcons.keyboard, size: AppData.text32, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Allowable Slider
                      Padding(
                        padding: EdgeInsets.only(right: AppData.padding16, left: AppData.padding16),
                        child: Container(
                          width: AppData.inputFieldWidth,
                          child: Stack(
                            children: [
                              // Background container with white background, black outline, and rounded corners
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor, // Background color
                                    border: Border.all(color: AppColors.borderPrimary, width: 2), // Black outline
                                    borderRadius: BorderRadius.circular(8), // Rounded corners
                                  ),
                                ),
                              ),
                              // Column with existing widgets
                              Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: AppData.padding20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: _decrementSlider,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            backgroundColor: AppColors.fireColor,
                                            padding: EdgeInsets.symmetric(horizontal: AppData.padding20, vertical: AppData.padding10),
                                            elevation: 15,
                                            shadowColor: Colors.black,
                                            side: BorderSide(color: Colors.black, width: 2),
                                            shape: CircleBorder(),
                                          ),
                                          child: Icon(Icons.remove, color: Colors.black, size: AppData.text32),
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
                                                style: TextStyle(fontSize: AppData.text32, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                              ),
                                            ),
                                            // Keyboard input value
                                            Visibility(
                                              visible: !lastInputFromSlider,
                                              child: Text(
                                                '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lbs',
                                                style: TextStyle(fontSize: AppData.text32, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: _incrementSlider,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            backgroundColor: AppColors.fireColor,
                                            padding: EdgeInsets.symmetric(horizontal: AppData.padding20, vertical: AppData.padding10),
                                            elevation: 15,
                                            shadowColor: Colors.black,
                                            side: const BorderSide(color: Colors.black, width: 2),
                                            shape: CircleBorder(),
                                          ),
                                          child: Icon(Icons.add, color: Colors.black, size: AppData.text32),
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
                                    activeColor: AppColors.fireColor,
                                    // Color when the slider is active
                                    inactiveColor: Colors.grey, // Color for the inactive part
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppData.spacingStandard * 2),
                      // Calculate Button
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16, bottom: AppData.padding16),
                        child: ElevatedButton(
                          onPressed: isCalculateButtonEnabled
                              ? () {
                                  saveTripData(() {
                                    if (mounted) {
                                      widget.onSwitchTab(1); // Switch to Saved Trips tab
                                    }
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            textStyle: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold),
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: AppData.padding20, vertical: AppData.padding10),
                            elevation: 15,
                            shadowColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            fixedSize: Size(AppData.buttonWidth, AppData.buttonHeight),
                          ),
                          child: const Text('Calculate'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
