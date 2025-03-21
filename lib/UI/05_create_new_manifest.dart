import 'dart:ui';

import 'package:fire_app/Algorithms/external_load_calculator.dart';
import 'package:fire_app/CodeShare/variables.dart';
import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../../Data/trip.dart';
import '../CodeShare/keyboardActions.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/trip_preferences.dart';
import '../UI/05_define_constraints_manifest.dart';
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
  late TextEditingController safetyBufferController = TextEditingController(text: '0');

  // Controllers for load hardware input fields
  final TextEditingController net12x12QuantityController = TextEditingController();
  final TextEditingController net12x12WeightController = TextEditingController();
  final TextEditingController net20x20QuantityController = TextEditingController();
  final TextEditingController net20x20WeightController = TextEditingController();
  final TextEditingController swivelQuantityController = TextEditingController();
  final TextEditingController swivelWeightController = TextEditingController();
  final TextEditingController leadLineQuantityController = TextEditingController();
  final TextEditingController leadLineWeightController = TextEditingController();

  final TextEditingController keyboardController = TextEditingController();
  double _sliderValue = 1000;

  // Can be null as a "None" option is available where user doesn't select a Load Preference
  TripPreference? selectedTripPreference;

  bool isCalculateButtonEnabled = false; // Controls whether saving button is showing
  bool isExternalManifest = false; // Default to internal manifest (personnel + cargo)

  final FocusNode _availableSeatsFocusNode = FocusNode();
  final FocusNode _allowableFocusNode = FocusNode();
  final FocusNode _safetyBufferFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    gearBox = Hive.box<Gear>('gearBox');
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

    // Listeners to the TextControllers
    tripNameController.addListener(_checkInput);
    allowableController.addListener(_checkInput);
    availableSeatsController.addListener(_checkInput);
    safetyBufferController = TextEditingController(text: AppData.safetyBuffer.toString());
    allowableController.text = _sliderValue.toStringAsFixed(0);

    // Initialize load hardware with default values
    net12x12QuantityController.text = '0';
    net12x12WeightController.text = '20';
    net20x20QuantityController.text = '0';
    net20x20WeightController.text = '45';
    swivelQuantityController.text = '0';
    swivelWeightController.text = '5';
    leadLineQuantityController.text = '0';
    leadLineWeightController.text = '10';

    // Add Listeners (if needed)
    // net12x12QuantityController.addListener();
    // net12x12WeightController.addListener();
    // net20x20QuantityController.addListener();
    // net20x20WeightController.addListener();
    // swivelQuantityController.addListener();
    // swivelWeightController.addListener();
    // leadLineQuantityController.addListener();
    // leadLineWeightController.addListener();

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
          isHazmat: gear.isHazmat,
        );
      }).toList();
      gearListExternal = gearBox.values.map((gear) {
        return Gear(
          name: gear.name,
          quantity: gear.quantity,
          weight: gear.weight,
          isPersonalTool: gear.isPersonalTool,
          isHazmat: gear.isHazmat,
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
    bool isSelectAllChecked = selectedItemsExternal.length == gearListExternal.length && selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Function to update "Select All" checkbox dynamically
            void updateSelectAllState() {
              dialogSetState(() {
                isSelectAllChecked = selectedItemsExternal.length == gearListExternal.length && selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Select Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
              ),
              contentPadding: EdgeInsets.all(AppData.padding10),
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
                                  selectedItemsExternal = [...gearListExternal]; // Only gear if external manifest

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
                                    color: AppColors.gearYellow,
                                    child: CheckboxListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        gear.name,
                                                        style: TextStyle(
                                                          fontSize: AppData.text16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (gear.isHazmat == true)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 4.0),
                                                        child: Icon(
                                                          FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                          color: Colors.red, // Red color for hazard
                                                          size: AppData.text14, // Icon size
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  '${gear.weight} lb x$remainingQuantity',
                                                  style: TextStyle(
                                                    fontSize: AppData.text14,
                                                    color: Colors.black,
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
                                                          fontSize: AppData.text14,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    if (gear.quantity > 1)
                                                      Icon(
                                                        Icons.arrow_drop_down,
                                                        color: Colors.black,
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
                    } else {
                      // Update thisTripGearListExternal with only selected gear items and quantities
                      thisTripGearListExternal = selectedItemsExternal.whereType<Gear>().map((gear) {
                        final selectedQuantity = selectedGearQuantitiesExternal[gear] ?? 1; // Get selected quantity
                        return Gear(
                          name: gear.name,
                          quantity: selectedQuantity,
                          weight: gear.weight,
                          isPersonalTool: gear.isPersonalTool,
                          isHazmat: gear.isHazmat,
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
    bool isSelectAllChecked = selectedItems.length == (crewList.length + gearList.length) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);

    bool isSelectAllCheckedCrew = selectedItems.length >= crewList.length && crewList.every((crew) => selectedItems.contains(crew));

    bool isSelectAllCheckedGear = gearList.every((gear) => selectedItems.contains(gear)) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // Function to update "Select All" checkbox dynamically
            void updateSelectAllState() {
              dialogSetState(() {
                // Update all Select All Checkboxes
                isSelectAllChecked = selectedItems.length == (crewList.length + gearList.length) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
                isSelectAllCheckedCrew = selectedItems.length >= crewList.length && crewList.every((crew) => selectedItems.contains(crew));
                isSelectAllCheckedGear = gearList.every((gear) => selectedItems.contains(gear)) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Select Crew Members and Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
              ),
              contentPadding: EdgeInsets.all(AppData.padding10),
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
                                updateSelectAllState();
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
                                children: [
                                  Container(
                                    color: AppColors.textFieldColor2,
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
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                      ),
                                      value: isSelectAllCheckedCrew,
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          isSelectAllCheckedCrew = isChecked ?? false;

                                          if (isSelectAllCheckedCrew) {
                                            selectedItems.addAll(crewList.where((crew) => !selectedItems.contains(crew)));
                                          } else {
                                            selectedItems.removeWhere((item) => item is CrewMember);
                                          }
                                          updateSelectAllState();
                                        });
                                      },
                                    ),
                                  ),
                                  Column(
                                    children: sortedCrewList.map((crew) {
                                      return Container(
                                        color: AppColors.textFieldColor2,
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
                                            '${crew.name}, ${crew.flightWeight} lb',
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
                                ],
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
                                children: [
                                  Container(
                                    color: AppColors.gearYellow,
                                    child: CheckboxListTile(
                                      // Checkmark color
                                      title: Text(
                                        'Select All',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text16, color: Colors.black),
                                      ),
                                      value: isSelectAllCheckedGear,
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          isSelectAllCheckedGear = isChecked ?? false;

                                          if (isSelectAllCheckedGear) {
                                            selectedItems.addAll(gearList.where((gear) => !selectedItems.contains(gear)));

                                            selectedGearQuantities = {
                                              for (var gear in gearList) gear: gear.quantity,
                                            };
                                          } else {
                                            // Remove only gear items, keeping crew members
                                            selectedItems.removeWhere((item) => item is Gear);

                                            // Reset selected quantities for gear (avoid stale selections)
                                            selectedGearQuantities.clear();
                                          }
                                          updateSelectAllState();
                                        });
                                      },
                                    ),
                                  ),
                                  Column(
                                    children: sortedGearList.map((gear) {
                                      int remainingQuantity = gear.quantity - (selectedGearQuantities[gear] ?? 0);

                                      return Container(
                                        //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                        color: AppColors.gearYellow,

                                        child: CheckboxListTile(
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            gear.name,
                                                            style: TextStyle(
                                                              fontSize: AppData.text16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (gear.isHazmat == true)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 4.0),
                                                            child: Icon(
                                                              FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                              color: Colors.red, // Red color for hazard
                                                              size: AppData.text14, // Icon size
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '${gear.weight} lb x$remainingQuantity',
                                                      style: TextStyle(
                                                        fontSize: AppData.text14,
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
                                                              fontSize: AppData.text14,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                        if (gear.quantity > 1)
                                                          Icon(
                                                            Icons.arrow_drop_down,
                                                            color: Colors.black,
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
                                ],
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
                    } else {
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
                          isHazmat: gear.isHazmat,
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

  // Calculates num loads based on allowable, safety buffer, and total weight including hardware
  int calculateInitialNumLoads() {
    // **Step 1: Initial Calculation Based on Gear Weight Only**
    int totalGearWeight = 0;
    for (var gearItem in thisTripGearListExternal) {
      totalGearWeight += gearItem.totalGearWeight;
    }

    // Adjust max allowable weight by subtracting safety buffer
    int maxLoadWeight = int.parse(allowableController.text) - int.parse(safetyBufferController.text);

    // First pass: Calculate numLoads without hardware weight
    int numLoads = (totalGearWeight / maxLoadWeight).ceil();

    // **Step 2: Determine Minimum Required Hardware Based on numLoads**
    int minimumNets = numLoads; // At least equal to number of loads
    int minimumSwivels = numLoads; // Must be at least 1 swivel
    int minimumLeadLines = numLoads; // At least 1 long line per net (same as numLoads for now)

    // **Step 3: Calculate Total Weight Again (Now Including Hardware)**
    int net12x12Weight = int.tryParse(net12x12WeightController.text) ?? 0;
    int net20x20Weight = int.tryParse(net20x20WeightController.text) ?? 0;
    int leadLineWeight = int.tryParse(leadLineWeightController.text) ?? 0;
    int swivelWeight = int.tryParse(swivelWeightController.text) ?? 0;

    int totalHardwareWeight = (minimumNets * net12x12Weight) + // Assume 12x12 nets at minimum
        (minimumLeadLines * leadLineWeight) +
        (minimumSwivels * swivelWeight);

    // **Step 4: Final Recalculation Including Hardware**
    int finalTotalWeight = totalGearWeight + totalHardwareWeight;
    int adjustedNumLoads = (finalTotalWeight / maxLoadWeight).ceil();

    return adjustedNumLoads;
  }

  int calculateUpdatedNumLoads() {
    // **Step 1: Get Gear Weight**
    int totalGearWeight = 0;
    for (var gearItem in thisTripGearListExternal) {
      totalGearWeight += gearItem.totalGearWeight;
    }

    // Adjust max allowable weight by subtracting safety buffer
    int maxLoadWeight = int.parse(allowableController.text) - int.parse(safetyBufferController.text);

    // **Step 2: Get User-Selected Quantities**
    int net12x12Qty = int.tryParse(net12x12QuantityController.text) ?? 0;
    int net20x20Qty = int.tryParse(net20x20QuantityController.text) ?? 0;
    int leadLineQty = int.tryParse(leadLineQuantityController.text) ?? 0;
    int swivelQty = int.tryParse(swivelQuantityController.text) ?? 0;

    // **Step 3: Get Weights of User-Selected Hardware**
    int net12x12Weight = int.tryParse(net12x12WeightController.text) ?? 0;
    int net20x20Weight = int.tryParse(net20x20WeightController.text) ?? 0;
    int leadLineWeight = int.tryParse(leadLineWeightController.text) ?? 0;
    int swivelWeight = int.tryParse(swivelWeightController.text) ?? 0;

    // **Step 4: Compute Total Weight with User Inputs**
    int totalHardwareWeight = (net12x12Qty * net12x12Weight) + (net20x20Qty * net20x20Weight) + (leadLineQty * leadLineWeight) + (swivelQty * swivelWeight);

    // **Step 5: Compute Final Loads**
    int finalTotalWeight = totalGearWeight + totalHardwareWeight;
    return (finalTotalWeight / maxLoadWeight).ceil();
  }

  int calculateTotalHardwareWeight() {
    int net12x12Qty = int.tryParse(net12x12QuantityController.text) ?? 0;
    int net20x20Qty = int.tryParse(net20x20QuantityController.text) ?? 0;
    int leadLineQty = int.tryParse(leadLineQuantityController.text) ?? 0;
    int swivelQty = int.tryParse(swivelQuantityController.text) ?? 0;

    int net12x12Weight = int.tryParse(net12x12WeightController.text) ?? 0;
    int net20x20Weight = int.tryParse(net20x20WeightController.text) ?? 0;
    int leadLineWeight = int.tryParse(leadLineWeightController.text) ?? 0;
    int swivelWeight = int.tryParse(swivelWeightController.text) ?? 0;

    return (net12x12Qty * net12x12Weight) + (net20x20Qty * net20x20Weight) + (leadLineQty * leadLineWeight) + (swivelQty * swivelWeight);
  }

  void _showLoadAccoutrementSelectionDialog() async {
    int totalGearWeight = 0;
    for (var gearItem in thisTripGearListExternal) {
      totalGearWeight += gearItem.totalGearWeight;
    }
    int maxLoadWeight = int.parse(allowableController.text) - int.parse(safetyBufferController.text);

    // Get initial number of loads (before hardware is included)
    int initialNumLoads = calculateInitialNumLoads();

    // **Stateful variables for tracking changes**
    int updatedNumLoads = initialNumLoads; // Will update dynamically
    int totalGearWeightWithHardware = totalGearWeight; // Will include added hardware

    // Now determine minimum hardware required
    int minimumNets = updatedNumLoads; // At least equal to number of loads
    int minimumSwivels = updatedNumLoads; // Must be at least 1 swivel per load
    int minimumLeadLines = updatedNumLoads; // At least 1 long line per net

    // **Stateful quantities tracking hardware**
    int net12x12Value = minimumNets; // Start at minimum
    int net20x20Value = 0;
    int leadLineValue = net12x12Value;
    int totalNets = net12x12Value + net20x20Value; // Calculate total nets
    int leadLineMin = totalNets.clamp(updatedNumLoads, 20);
    int maxSwivels = totalNets;
    int allowable = int.tryParse(allowableController.text) ?? 0;

    // **Ensure Quantity Controllers Start with Correct Values**
    net12x12QuantityController.text = net12x12Value.toString();
    net20x20QuantityController.text = net20x20Value.toString();
    leadLineQuantityController.text = minimumLeadLines.toString();
    swivelQuantityController.text = minimumSwivels.toString();

    // **Calculate initial total weight with hardware**
    int net12x12Weight = int.tryParse(net12x12WeightController.text) ?? 0;
    int net20x20Weight = int.tryParse(net20x20WeightController.text) ?? 0;
    int leadLineWeight = int.tryParse(leadLineWeightController.text) ?? 0;
    int swivelWeight = int.tryParse(swivelWeightController.text) ?? 0;
    int totalHardwareWeight = calculateTotalHardwareWeight(); // **Initial hardware weight**

    totalGearWeightWithHardware += (minimumNets * net12x12Weight) + (minimumLeadLines * leadLineWeight) + (minimumSwivels * swivelWeight);

    // **Recalculate numLoads based on included hardware**
    updatedNumLoads = (totalGearWeightWithHardware / maxLoadWeight).ceil();

    int noSafetyBufferMaxNumLoads = (totalGearWeightWithHardware / allowable).ceil();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Load Accoutrements',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
                  ),
                  SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppData.padding8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryColor, width: 1.5), // Outline border
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Minimum Requirements Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minimum Requirements:',
                                style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.w500, color: AppColors.textColorPrimary),
                              ),
                              Text(
                                '• $updatedNumLoads load${updatedNumLoads > 1 ? 's' : ''}',
                                style: TextStyle(fontSize: AppData.text12, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                              ),
                              Text(
                                '• $minimumNets net${minimumNets > 1 ? 's' : ''}, '
                                'lead line${minimumLeadLines > 1 ? 's' : ''}, '
                                'swivel${minimumSwivels > 1 ? 's' : ''}',
                                style: TextStyle(fontSize: AppData.text12, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppData.sizedBox16),

                        // Min Requirement Info Box
                        IconButton(
                          icon: Icon(Icons.info_outline, color: AppColors.textColorPrimary),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(color: AppColors.primaryColor, width: 1.5), // Outline border
                                  ),
                                  contentPadding: EdgeInsets.all(AppData.padding16),
                                  // Ensures uniform padding
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Minimum Requirements Factors:",
                                          style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                        ),
                                        Divider(
                                          color: AppColors.textColorPrimary,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "• $totalGearWeightWithHardware lb total weight, to include:",
                                          style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        SizedBox(height: 4),
                                        Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: Text(
                                            "- $totalGearWeight lb gear weight",
                                            style: TextStyle(fontSize: AppData.text14, color: AppColors.textColorPrimary),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: Text(
                                            "- $totalHardwareWeight lb for ${int.parse(net20x20QuantityController.text) + int.parse(net12x12QuantityController.text)} net, ${int.parse(leadLineQuantityController.text)} lead line, and ${int.parse(swivelQuantityController.text)} swivel\n",
                                            style: TextStyle(fontSize: AppData.text14, color: AppColors.textColorPrimary),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "• $maxLoadWeight lb max load weight",
                                          style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        Text(
                                          "  (allowable - safety buffer)\n",
                                          style: TextStyle(fontSize: AppData.text14, color: AppColors.textColorPrimary),
                                        ),
                                        Text(
                                          "$totalGearWeightWithHardware lb / $maxLoadWeight lb = ${(totalGearWeightWithHardware / maxLoadWeight).toStringAsFixed(3)} = $updatedNumLoads load${updatedNumLoads > 1 ? 's' : ''}",
                                          style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        // Conditional message when margin is ≤ 0.2 and safetyBuffer > 0
                                        if (int.parse(safetyBufferController.text) > 0 && (updatedNumLoads - (totalGearWeightWithHardware / maxLoadWeight)) >= 0.9)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              "* Reducing the safety buffer may result in fewer loads.",
                                              style: TextStyle(fontSize: AppData.text12, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  actionsPadding: EdgeInsets.symmetric(horizontal: AppData.padding8, vertical: AppData.padding8),
                                  // Adds spacing around button
                                  actions: [
                                    Align(
                                      alignment: Alignment.centerRight, // Ensures button alignment
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK", style: TextStyle(color: AppColors.primaryColor)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Display daisy chaining notification
                  if (leadLineValue > updatedNumLoads) SizedBox(height: AppData.sizedBox10),

                  if (leadLineValue > updatedNumLoads)
                    Text(
                      '* Nets will be daisy-chained',
                      style: TextStyle(fontSize: AppData.text12, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                    ),
                ],
              ),
              contentPadding: EdgeInsets.all(AppData.padding10),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Cargo Net (12'x12')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  "Cargo Net",
                                  style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                                ),
                                Text(
                                  " (12'x12')",
                                  style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary.withValues(alpha: 0.9)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              dropdownColor: AppColors.textFieldColor2,
                              value: net12x12Value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              items: List.generate(
                                11,
                                (index) => DropdownMenuItem<int>(
                                  value: index,
                                  child: Text(index.toString(), style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary)),
                                ),
                              ),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  dialogSetState(() {
                                    net12x12Value = newValue;
                                    int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                    // Ensure total nets never drop below minimumNets
                                    if (totalNets < minimumNets) {
                                      net20x20Value = minimumNets - net12x12Value;
                                      net20x20QuantityController.text = net20x20Value.toString();
                                    }

                                    net12x12QuantityController.text = net12x12Value.toString();
                                    totalNets = net12x12Value + net20x20Value; // Re-calc again to be safe

                                    // Recalculate the new lead line minimum
                                    int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                    leadLineQuantityController.text = newLeadLineMin.toString();
                                    leadLineValue = newLeadLineMin;
                                    leadLineMin = newLeadLineMin;

                                    int previousNumLoads = updatedNumLoads;

                                    // Update number of loads dynamically if need be, as well as minimum hardware required
                                    updatedNumLoads = calculateUpdatedNumLoads();

                                    minimumNets = updatedNumLoads;
                                    minimumSwivels = updatedNumLoads;
                                    minimumLeadLines = updatedNumLoads;

                                    if ((int.tryParse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                      swivelQuantityController.text = minimumSwivels.toString();
                                    }
                                    if ((int.tryParse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                      leadLineQuantityController.text = minimumLeadLines.toString();
                                    }

                                    maxSwivels = totalNets;
                                    totalHardwareWeight = calculateTotalHardwareWeight();
                                    totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                    // Show Alert Dialog if the number of loads changes
                                    if (previousNumLoads != updatedNumLoads) {
                                      showDialog(
                                        context: context,
                                        builder: (alertContext) {
                                          return AlertDialog(
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text(
                                              "Minimum Loads Update!",
                                              style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                            ),
                                            content: Text(
                                              "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(alertContext).pop(); // Close alert
                                                },
                                                child: Text(
                                                  "OK",
                                                  style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: net12x12WeightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'lb',
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                              onChanged: (value) {
                                int newWeight = int.tryParse(value) ?? 0; // Convert input to integer
                                dialogSetState(() {
                                  int previousNumLoads = updatedNumLoads;

                                  // Update number of loads dynamically if need be, as well as minimum hardware required
                                  updatedNumLoads = calculateUpdatedNumLoads();

                                  minimumNets = updatedNumLoads;
                                  minimumSwivels = updatedNumLoads;
                                  minimumLeadLines = updatedNumLoads;

                                  // Update nets number if need be
                                  int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                  // Ensure total nets never drop below minimumNets
                                  if (totalNets < minimumNets) {
                                    net12x12Value = (minimumNets - net20x20Value);
                                    net12x12QuantityController.text = net12x12Value.toString();
                                  }
                                  int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                  // Update the lead line only if it's below the new minimum
                                  leadLineQuantityController.text = newLeadLineMin.toString();
                                  leadLineValue = newLeadLineMin;
                                  leadLineMin = newLeadLineMin;

                                  if ((int.parse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                    swivelQuantityController.text = minimumSwivels.toString();
                                  }
                                  if ((int.parse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                    leadLineQuantityController.text = minimumLeadLines.toString();
                                  }

                                  maxSwivels = totalNets;
                                  totalHardwareWeight = calculateTotalHardwareWeight();
                                  totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                  // Show Alert Dialog if the number of loads changes
                                  if (previousNumLoads != updatedNumLoads) {
                                    showDialog(
                                      context: context,
                                      builder: (alertContext) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.textFieldColor2,
                                          title: Text(
                                            "Minimum Loads Update!",
                                            style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                          ),
                                          content: Text(
                                            "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                            style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(alertContext).pop(); // Close alert
                                              },
                                              child: Text(
                                                "OK",
                                                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppData.sizedBox10),

                      // Cargo Net (20'x20')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  "Cargo Net",
                                  style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                                ),
                                Text(
                                  " (20'x20')",
                                  style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary.withValues(alpha: 0.9)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              dropdownColor: AppColors.textFieldColor2,
                              value: net20x20Value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              items: List.generate(
                                11,
                                (index) => DropdownMenuItem<int>(
                                  value: index,
                                  child: Text(index.toString(), style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary)),
                                ),
                              ),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  dialogSetState(() {
                                    net20x20Value = newValue;
                                    int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                    // Ensure total nets never drop below minimumNets
                                    if (totalNets < minimumNets) {
                                      net12x12Value = minimumNets - net20x20Value;
                                      net12x12QuantityController.text = net12x12Value.toString();
                                    }

                                    net20x20QuantityController.text = net20x20Value.toString();
                                    totalNets = net12x12Value + net20x20Value; // Re-calc again to be safe

                                    // Recalculate the new lead line minimum
                                    int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                    leadLineQuantityController.text = newLeadLineMin.toString();
                                    leadLineValue = newLeadLineMin;
                                    leadLineMin = newLeadLineMin;

                                    int previousNumLoads = updatedNumLoads;

                                    // Update number of loads dynamically if need be, as well as minimum hardware required
                                    updatedNumLoads = calculateUpdatedNumLoads();

                                    minimumNets = updatedNumLoads;
                                    minimumSwivels = updatedNumLoads;
                                    minimumLeadLines = updatedNumLoads;

                                    if ((int.tryParse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                      swivelQuantityController.text = minimumSwivels.toString();
                                    }
                                    if ((int.tryParse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                      leadLineQuantityController.text = minimumLeadLines.toString();
                                    }
                                    maxSwivels = totalNets;
                                    totalHardwareWeight = calculateTotalHardwareWeight();
                                    totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                    // Show Alert Dialog if the number of loads changes
                                    if (previousNumLoads != updatedNumLoads) {
                                      showDialog(
                                        context: context,
                                        builder: (alertContext) {
                                          return AlertDialog(
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text(
                                              "Minimum Loads Update!",
                                              style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                            ),
                                            content: Text(
                                              "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(alertContext).pop(); // Close alert
                                                },
                                                child: Text(
                                                  "OK",
                                                  style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: net20x20WeightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'lb',
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                              onChanged: (value) {
                                int newWeight = int.tryParse(value) ?? 0; // Convert input to integer
                                dialogSetState(() {
                                  int previousNumLoads = updatedNumLoads;

                                  // Update number of loads dynamically if need be, as well as minimum hardware required
                                  updatedNumLoads = calculateUpdatedNumLoads();

                                  minimumNets = updatedNumLoads;
                                  minimumSwivels = updatedNumLoads;
                                  minimumLeadLines = updatedNumLoads;

                                  // Update nets number if need be
                                  int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                  // Ensure total nets never drop below minimumNets
                                  if (totalNets < minimumNets) {
                                    net12x12Value = (minimumNets - net20x20Value);
                                    net12x12QuantityController.text = net12x12Value.toString();
                                  }
                                  int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                  // Update the lead line only if it's below the new minimum
                                  leadLineQuantityController.text = newLeadLineMin.toString();
                                  leadLineValue = newLeadLineMin;
                                  leadLineMin = newLeadLineMin;

                                  if ((int.parse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                    swivelQuantityController.text = minimumSwivels.toString();
                                  }
                                  if ((int.parse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                    leadLineQuantityController.text = minimumLeadLines.toString();
                                  }
                                  maxSwivels = totalNets;
                                  totalHardwareWeight = calculateTotalHardwareWeight();
                                  totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                  // Show Alert Dialog if the number of loads changes
                                  if (previousNumLoads != updatedNumLoads) {
                                    showDialog(
                                      context: context,
                                      builder: (alertContext) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.textFieldColor2,
                                          title: Text(
                                            "Minimum Loads Update!",
                                            style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                          ),
                                          content: Text(
                                            "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                            style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(alertContext).pop(); // Close alert
                                              },
                                              child: Text(
                                                "OK",
                                                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppData.sizedBox10),

                      // Lead Line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Lead Line",
                              style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              dropdownColor: AppColors.textFieldColor2,
                              value: leadLineValue,
                              // Dynamically updates with nets

                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              icon: SizedBox.shrink(),
                              // Removes dropdown arrow

                              items: [
                                DropdownMenuItem<int>(
                                  value: leadLineValue,
                                  child: Text(
                                    leadLineValue.toString(),
                                    style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                  ),
                                ),
                              ],

                              onChanged: null, // Disables manual selection
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: leadLineWeightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'lb',
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                              onChanged: (value) {
                                int newWeight = int.tryParse(value) ?? 0; // Convert input to integer
                                dialogSetState(() {
                                  int previousNumLoads = updatedNumLoads;

                                  // Update number of loads dynamically if need be, as well as minimum hardware required
                                  updatedNumLoads = calculateUpdatedNumLoads();

                                  minimumNets = updatedNumLoads;
                                  minimumSwivels = updatedNumLoads;
                                  minimumLeadLines = updatedNumLoads;

                                  // Update nets number if need be
                                  int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                  // Ensure total nets never drop below minimumNets
                                  if (totalNets < minimumNets) {
                                    net12x12Value = (minimumNets - net20x20Value);
                                    net12x12QuantityController.text = net12x12Value.toString();
                                  }
                                  int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                  // Update the lead line only if it's below the new minimum
                                  leadLineQuantityController.text = newLeadLineMin.toString();
                                  leadLineValue = newLeadLineMin;
                                  leadLineMin = newLeadLineMin;

                                  if ((int.parse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                    swivelQuantityController.text = minimumSwivels.toString();
                                  }
                                  if ((int.parse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                    leadLineQuantityController.text = minimumLeadLines.toString();
                                  }
                                  maxSwivels = totalNets;
                                  totalHardwareWeight = calculateTotalHardwareWeight();
                                  totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                  // Show Alert Dialog if the number of loads changes
                                  if (previousNumLoads != updatedNumLoads) {
                                    showDialog(
                                      context: context,
                                      builder: (alertContext) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.textFieldColor2,
                                          title: Text(
                                            "Minimum Loads Update!",
                                            style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                          ),
                                          content: Text(
                                            "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                            style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(alertContext).pop(); // Close alert
                                              },
                                              child: Text(
                                                "OK",
                                                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppData.sizedBox10),

                      // Swivel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Swivel",
                              style: TextStyle(fontSize: AppData.text14, fontWeight: FontWeight.normal, color: AppColors.textColorPrimary),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              dropdownColor: AppColors.textFieldColor2,
                              value: (int.tryParse(swivelQuantityController.text) ?? minimumSwivels).clamp(minimumSwivels, maxSwivels),
                              // Max is now dynamic

                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),

                              items: List.generate(
                                (maxSwivels - minimumSwivels) + 1,
                                (index) => DropdownMenuItem<int>(
                                  value: index + minimumSwivels, // Start from minimumSwivels
                                  child: Text(
                                    (index + minimumSwivels).toString(),
                                    style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                  ),
                                ),
                              ),

                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  dialogSetState(() {
                                    swivelQuantityController.text = newValue.toString();

                                    int previousNumLoads = updatedNumLoads;

                                    // Update number of loads dynamically if need be, as well as minimum hardware required
                                    updatedNumLoads = calculateUpdatedNumLoads();

                                    minimumNets = updatedNumLoads;
                                    minimumSwivels = updatedNumLoads;
                                    minimumLeadLines = updatedNumLoads;

                                    // Update nets number if need be
                                    int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                    // Ensure total nets never drop below minimumNets
                                    if (totalNets < minimumNets) {
                                      net12x12Value = (minimumNets - net20x20Value);
                                      net12x12QuantityController.text = net12x12Value.toString();
                                    }
                                    int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                    // Update the lead line only if it's below the new minimum
                                    leadLineQuantityController.text = newLeadLineMin.toString();
                                    leadLineValue = newLeadLineMin;
                                    leadLineMin = newLeadLineMin;

                                    if ((int.parse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                      swivelQuantityController.text = minimumSwivels.toString();
                                    }
                                    if ((int.parse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                      leadLineQuantityController.text = minimumLeadLines.toString();
                                    }
                                    maxSwivels = totalNets;
                                    totalHardwareWeight = calculateTotalHardwareWeight();
                                    totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                    // Show Alert Dialog if the number of loads changes
                                    if (previousNumLoads != updatedNumLoads) {
                                      showDialog(
                                        context: context,
                                        builder: (alertContext) {
                                          return AlertDialog(
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text(
                                              "Minimum Loads Update!",
                                              style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                            ),
                                            content: Text(
                                              "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(alertContext).pop(); // Close alert
                                                },
                                                child: Text(
                                                  "OK",
                                                  style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: swivelWeightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'lb',
                                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0)),
                                contentPadding: EdgeInsets.all(4),
                              ),
                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                              onChanged: (value) {
                                int newWeight = int.tryParse(value) ?? 0; // Convert input to integer
                                dialogSetState(() {
                                  int previousNumLoads = updatedNumLoads;

                                  // Update number of loads dynamically if need be, as well as minimum hardware required
                                  updatedNumLoads = calculateUpdatedNumLoads();

                                  minimumNets = updatedNumLoads;
                                  minimumSwivels = updatedNumLoads;
                                  minimumLeadLines = updatedNumLoads;

                                  // Update nets number if need be
                                  int totalNets = net12x12Value + net20x20Value; // Recalculate total nets

                                  // Ensure total nets never drop below minimumNets
                                  if (totalNets < minimumNets) {
                                    net12x12Value = (minimumNets - net20x20Value);
                                    net12x12QuantityController.text = net12x12Value.toString();
                                  }
                                  int newLeadLineMin = totalNets.clamp(minimumLeadLines, 20);

                                  // Update the lead line only if it's below the new minimum
                                  leadLineQuantityController.text = newLeadLineMin.toString();
                                  leadLineValue = newLeadLineMin;
                                  leadLineMin = newLeadLineMin;

                                  if ((int.parse(swivelQuantityController.text) ?? 0) < minimumSwivels) {
                                    swivelQuantityController.text = minimumSwivels.toString();
                                  }
                                  if ((int.parse(leadLineQuantityController.text) ?? 0) < minimumLeadLines) {
                                    leadLineQuantityController.text = minimumLeadLines.toString();
                                  }
                                  maxSwivels = totalNets;
                                  totalHardwareWeight = calculateTotalHardwareWeight();
                                  totalGearWeightWithHardware = totalHardwareWeight + totalGearWeight;

                                  // Show Alert Dialog if the number of loads changes
                                  if (previousNumLoads != updatedNumLoads) {
                                    showDialog(
                                      context: context,
                                      builder: (alertContext) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.textFieldColor2,
                                          title: Text(
                                            "Minimum Loads Update!",
                                            style: TextStyle(fontSize: AppData.text22, color: AppColors.textColorPrimary),
                                          ),
                                          content: Text(
                                            "The number of loads required is now $updatedNumLoads due to quantity/weight changes for nets, lead lines, or swivels.",
                                            style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(alertContext).pop(); // Close alert
                                              },
                                              child: Text(
                                                "OK",
                                                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    swivelQuantityController.text = minimumSwivels.toString();
                    swivelWeightController.text = '5';
                    leadLineWeightController.text = '10';
                    net12x12WeightController.text = '20';
                    net20x20WeightController.text = '45';

                    totalHardwareWeight = calculateTotalHardwareWeight();
                  },
                  child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    saveTripData(() {
                      if (mounted) {
                        widget.onSwitchTab(1); // Switch to Saved Trips tab
                      }
                    });
                  },
                  child: Text('Calculate', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
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
    // Convert available seats text to integer. Available seats not necessary in External Manifesting
    final int availableSeats = isExternalManifest ? -1 : int.parse(availableSeatsController.text);
    final int safetyBuffer = int.parse(safetyBufferController.text);

    // Creating a new Trip object
    Trip newTrip;
    if (isExternalManifest) {
      newTrip = Trip(tripName: tripNameCapitalized, allowable: allowable, availableSeats: availableSeats, isExternal: true, safetyBuffer: safetyBuffer);
    } else {
      newTrip = Trip(tripName: tripNameCapitalized, allowable: allowable, availableSeats: availableSeats);
    }

    // Deep copy crewMembers and gear into the new Trip
    if (isExternalManifest) {
      newTrip.gear = thisTripGearListExternal.map((item) => item.copyWith()).toList();
    }
    // Internal Manifest
    else {
      newTrip.crewMembers = thisTripCrewMemberList.map((member) => member.copy()).toList();
      newTrip.gear = thisTripGearList.map((item) => item.copyWith()).toList();
    }

    newTrip.calculateTotalCrewWeight();
    // If internal manifesting, crewmembers must exist and cannot be empty
    if (!isExternalManifest) {
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
    }
    // External manifesting error checks -> need to include load accoutrement checks here
    // Logic: If external manifesting, gear must exist, and  safety buffer cannot be lower than allowable
    if (isExternalManifest) {
      Gear? heaviestGearItem;
      num maxGearWeight = 0;

      heaviestGearItem = gearListExternal.reduce((a, b) => a.weight > b.weight ? a : b);
      maxGearWeight = heaviestGearItem.weight;
      num remainingWeight = allowable - safetyBuffer;

      if (gearListExternal.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.textFieldColor2,
                  title: Text(
                    'No Gear Available',
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
                  content: Text('There is no existing gear. Create at least one to begin manifesting.', style: TextStyle(color: AppColors.textColorPrimary)),
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
      if (newTrip.gear.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.textFieldColor2,
                  title: Text(
                    'No Gear Selected',
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
                  content: Text('Select at least gear item and try again.', style: TextStyle(color: AppColors.textColorPrimary)),
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

      if (safetyBuffer >= allowable) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.textFieldColor2,
                  title: Text(
                    'Input Error',
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
                  content: Text('Safety Buffer must be lower than the allowable load weight.', style: TextStyle(color: AppColors.textColorPrimary)),
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

      if (remainingWeight < maxGearWeight) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.textFieldColor2,
                  title: Text(
                    'Weight Error',
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
                  content: Text(
                      'The remaining allowable weight with the safety buffer ($remainingWeight lb) is less than the heaviest gear item (${heaviestGearItem?.name}: ${heaviestGearItem?.weight} lb). Adjust values and try again.',
                      style: TextStyle(color: AppColors.textColorPrimary)),
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
    }

    // Add the new trip to the global crew object
    savedTrips.addTrip(newTrip);

    // Load Calculation with animation
    // Current testing: for internal only, to be used eventually by external
    if (!isExternalManifest) {
      startCalculation(context, isExternalManifest, newTrip, selectedTripPreference, safetyBuffer);
    } else {
      // Create Load Accoutrement objecets to pass

      LoadAccoutrement cargoNet12x12 = LoadAccoutrement(
        name: "Cargo Net (12'x12')",
        quantity: int.parse(net12x12QuantityController.text),
        weight: int.parse(net12x12WeightController.text),
      );

      LoadAccoutrement cargoNet20x20 = LoadAccoutrement(
        name: "Cargo Net (20'x20')",
        quantity: int.parse(net20x20QuantityController.text),
        weight: int.parse(net20x20WeightController.text),
      );

      LoadAccoutrement swivel = LoadAccoutrement(
        name: "Swivel",
        quantity: int.parse(swivelQuantityController.text),
        weight: int.parse(swivelWeightController.text),
      );

      LoadAccoutrement leadLine = LoadAccoutrement(
        name: "Lead Line (12')",
        quantity: int.parse(leadLineQuantityController.text),
        weight: int.parse(leadLineWeightController.text),
      );

      // Testing only -> fast version no animation for external manifesting
      externalLoadCalculator(context, newTrip, selectedTripPreference, safetyBuffer, cargoNet12x12, cargoNet20x20, swivel, leadLine);
    }

    // Load Calculation without animation
    // loadCalculator(context, newTrip, selectedTripPreference);

    // Reset all load hardware controllers
    net12x12QuantityController.text = '0';
    net12x12WeightController.text = '20';
    net20x20QuantityController.text = '0';
    net20x20WeightController.text = '45';
    swivelQuantityController.text = '0';
    swivelWeightController.text = '5';
    leadLineQuantityController.text = '0';
    leadLineWeightController.text = '10';

    // Clear the text fields (reset them to empty), so we can add more trips
    tripNameController.text = '';
    availableSeatsController.text = '';
    safetyBufferController.text = '0';

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
        return selectedItemsExternal.length == gearListExternal.length && selectedGearQuantitiesExternal.entries.every((entry) => entry.value == entry.key.quantity);
      } else {
        return selectedItems.length == (crewList.length + gearList.length) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
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
                                isExternalManifest
                                    ? Transform.scale(
                                        scale: 1.5,
                                        child: SvgPicture.asset(
                                          'assets/icons/sling_icon.svg', // Your SVG file path
                                          width: 24, // Adjust size as needed
                                          height: 24,
                                          colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn), // Apply color dynamically
                                        ),
                                      )
                                    : Icon(
                                        FontAwesomeIcons.helicopter,
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
                              child: KeyboardActions(
                                config: keyboardActionsConfig(
                                  focusNodes: [_availableSeatsFocusNode],
                                ),
                                disableScroll: true,
                                child: TextField(
                                  focusNode: _availableSeatsFocusNode,
                                  keyboardType: TextInputType.number,
                                  controller: availableSeatsController,
                                  textInputAction: TextInputAction.done,
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
                              ),
                            )),

                      // Safety Buffer
                      if (isExternalManifest)
                        Padding(
                            padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
                            child: Container(
                              width: AppData.inputFieldWidth,
                              child: KeyboardActions(
                                config: keyboardActionsConfig(
                                  focusNodes: [_safetyBufferFocusNode],
                                ),
                                disableScroll: true,
                                child: TextField(
                                  focusNode: _safetyBufferFocusNode,
                                  textInputAction: TextInputAction.done,
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
                                    labelText: 'Enter Safety Buffer (lb)',
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
                              ),
                            )),

                      SizedBox(height: AppData.spacingStandard),

                      // Select All/Some Crew
                      Padding(
                        padding: EdgeInsets.only(left: AppData.padding16, right: AppData.padding16),
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
                                      } else {
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
                                            content: KeyboardActions(
                                              config: keyboardActionsConfig(
                                                focusNodes: [_allowableFocusNode],
                                              ),
                                              disableScroll: true,
                                              child: TextField(
                                                focusNode: _allowableFocusNode,
                                                controller: keyboardController,
                                                textInputAction: TextInputAction.done,
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
                                                  hintText: 'Up to 9,999 lb',
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
                                                '${_sliderValue.toStringAsFixed(0)} lb',
                                                style: TextStyle(fontSize: AppData.text32, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                              ),
                                            ),
                                            // Keyboard input value
                                            Visibility(
                                              visible: !lastInputFromSlider,
                                              child: Text(
                                                '${keyboardController.text.isNotEmpty ? keyboardController.text : '----'} lb',
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
                                  if (!isExternalManifest) {
                                    saveTripData(() {
                                      if (mounted) {
                                        widget.onSwitchTab(1); // Switch to Saved Trips tab
                                      }
                                    });
                                  } else {
                                    _showLoadAccoutrementSelectionDialog();
                                  }
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
