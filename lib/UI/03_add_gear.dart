import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../CodeShare/functions.dart';
import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/gear.dart';

// Tester data
class AddGear extends StatefulWidget {
  const AddGear({super.key});

  @override
  State<AddGear> createState() => _AddGearState();
}

class _AddGearState extends State<AddGear> {
  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];
  String? weightErrorMessage;
  String? quantityErrorMessage;
  String? irpgWeightErrorMessage;
  String? irpgQuantityErrorMessage;

  // Variables to store user input
  final TextEditingController gearNameController = TextEditingController();
  final TextEditingController gearWeightController = TextEditingController();
  final TextEditingController gearQuantityController = TextEditingController(text: '1');
  final TextEditingController irpgGearNameController = TextEditingController();
  final TextEditingController irpgGearWeightController = TextEditingController();
  final TextEditingController irpgGearQuantityController = TextEditingController(text: '1');

  bool isSaveButtonEnabled = false; // Controls whether saving button is showing
  bool isSaveButtonEnabledForIRPG = false;

  String? selectedGearName;
  bool isHazmat = false;
  bool isHazmatIRPG = false;

  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _weightFocusNode2 = FocusNode();
  final FocusNode _quantityFocusNode2 = FocusNode();

  @override
  void initState() {
    super.initState();

    // Open the Hive box and load the list of tool items
    personalToolsBox = Hive.box<Gear>('personalToolsBox');
    loadPersonalToolsList();

    // Listeners to the TextControllers
    gearNameController.addListener(_checkInput);
    gearWeightController.addListener(_checkInput);
    gearQuantityController.addListener(_checkInput);
    irpgGearNameController.addListener(_checkInputforIRPG);
    irpgGearWeightController.addListener(_checkInputforIRPG);
    irpgGearQuantityController.addListener(_checkInputforIRPG);
  }

  // Function to load the list of tool items from the Hive box
  void loadPersonalToolsList() {
    setState(() {
      personalToolsList = personalToolsBox.values.toList();
    });
  }

  @override
  void dispose() {
    gearNameController.dispose();
    gearWeightController.dispose();
    gearQuantityController.dispose();
    irpgGearNameController.dispose();
    irpgGearWeightController.dispose();
    irpgGearQuantityController.dispose();
    super.dispose();
  }

  // Function to check if input is valid and update button state
  void _checkInput() {
    final isGearNameValid = gearNameController.text.isNotEmpty;
    final isGearWeightValid =
        gearWeightController.text.isNotEmpty && int.tryParse(gearWeightController.text) != null && int.parse(gearWeightController.text) > 0 && int.parse(gearWeightController.text) <= 500;
    final isGearQuantityValid =
        gearQuantityController.text.isNotEmpty && int.tryParse(gearQuantityController.text) != null && int.parse(gearQuantityController.text) >= 1 && int.parse(gearQuantityController.text) < 100;

    setState(() {
      // Need to adjust for position as well
      isSaveButtonEnabled = isGearNameValid && isGearWeightValid && isGearQuantityValid;
    });
  }

  void _checkInputforIRPG() {
    final isIrpgGearNameValid = irpgGearNameController.text.isNotEmpty;
    final isIrpgGearWeightValid = irpgGearWeightController.text.isNotEmpty &&
        int.tryParse(irpgGearWeightController.text) != null &&
        int.parse(irpgGearWeightController.text) > 0 &&
        int.parse(irpgGearWeightController.text) <= 500;
    final isIrpgGearQuantityValid = irpgGearQuantityController.text.isNotEmpty &&
        int.tryParse(irpgGearQuantityController.text) != null &&
        int.parse(irpgGearQuantityController.text) >= 1 &&
        int.parse(irpgGearQuantityController.text) < 100;

    setState(() {
      // Need to adjust for position as well
      isSaveButtonEnabledForIRPG = isIrpgGearNameValid && isIrpgGearWeightValid && isIrpgGearQuantityValid;
    });
  }

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveGearData(bool isCustom) {
    String gearName;
    int gearWeight;
    int gearQuantity;
    bool isHazmatFinal;

    if (isCustom) {
      gearName = gearNameController.text;
      gearWeight = int.parse(gearWeightController.text);
      gearQuantity = int.parse(gearQuantityController.text);
      isHazmatFinal = isHazmat;
    } else {
      gearName = irpgGearNameController.text;
      gearWeight = int.parse(irpgGearWeightController.text);
      gearQuantity = int.parse(irpgGearQuantityController.text);
      isHazmatFinal = isHazmatIRPG;
    }
    String capitalizedGearName = capitalizeEveryWord(gearName);

    // Check if gear name already exists
    bool gearNameExists = crew.gear.any((gear) => gear.name.toLowerCase() == gearName.toLowerCase());
    bool personalToolExists = personalToolsList.any((gear) => gear.name.toLowerCase() == gearName.toLowerCase());

    if (personalToolExists && gearNameExists) {
      // Show a single AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Text(
              'Gear Conflict',
              style: TextStyle(color: AppColors.textColorPrimary),
            ),
            content: Text(
              '$capitalizedGearName already exists as both a tool and an item in your inventory. Any gear that is also a personal tool must be edited in the Tool panel under the Crew tab. If you would like to add more to your gear inventory, do so within the Edit Gear panel.',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                ),
              ),
            ],
          );
        },
      );

      // Reset values for both conditions if applicable
      setState(() {
        if (isCustom) {
          gearNameController.text = '';
          gearWeightController.text = '';
          isHazmat = false;
        } else {
          irpgGearNameController.text = '';
          irpgGearWeightController.text = '';
          selectedGearName = null;
          isHazmatIRPG = false;
        }
        _checkInput(); // Re-validate inputs
      });

      return;
    }

    if (personalToolExists) {
      int personalToolWeight = personalToolsList.firstWhere((gear) => gear.name.toLowerCase() == gearName.toLowerCase()).weight;
      bool personalToolisHazmat = personalToolsList.firstWhere((gear) => gear.name.toLowerCase() == gearName.toLowerCase()).isHazmat;

      if (personalToolWeight != gearWeight || personalToolisHazmat != isHazmatFinal) {
        // Determine the appropriate error messages based on which condition(s) failed
        String weightError = '';
        String hazmatError = '';
        const String universalMessage = 'Any gear that is also a personal tool can be added to your gear inventory, but it must be of the same weight and HAZMAT value.';

        if (personalToolWeight != gearWeight) {
          weightError = '$capitalizedGearName must be of the weight, $personalToolWeight lb.';
        }

        if (personalToolisHazmat != isHazmatFinal) {
          hazmatError = '$capitalizedGearName must have a HAZMAT value of ${personalToolisHazmat ? 'TRUE' : 'FALSE'}.';
        }

        // Combine error messages
        String combinedError = [weightError, hazmatError].where((msg) => msg.isNotEmpty).join('\n\n');

        // Append the universal message once
        if (combinedError.isNotEmpty) {
          combinedError = '$combinedError\n\n$universalMessage';
        } else {
          combinedError = universalMessage;
        }

        // Show a single AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Gear Conflict',
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
              content: Text(
                combinedError,
                style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                  ),
                ),
              ],
            );
          },
        );

        // Reset values for both conditions if applicable
        setState(() {
          if (isCustom) {
            if (personalToolWeight != gearWeight) {
              gearWeightController.text = personalToolWeight.toString();
            }
            if (personalToolisHazmat != isHazmatFinal) {
              isHazmat = personalToolisHazmat;
            }
          } else {
            if (personalToolWeight != gearWeight) {
              irpgGearWeightController.text = personalToolWeight.toString();
            }
            if (personalToolisHazmat != isHazmatFinal) {
              isHazmatIRPG = personalToolisHazmat;
            }
          }
          _checkInput(); // Re-validate inputs
        });

        return;
      }
    }

    if (gearNameExists) {
      String matchingGearName = crew.gear.firstWhere((gear) => gear.name.toLowerCase() == gearName.toLowerCase()).name;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Text('Gear Conflict', style: TextStyle(color: AppColors.textColorPrimary)),
            content: Text(
              '$matchingGearName already exists in your gear inventory. If you would like to add more, edit the item quantity in the Edit Gear panel.',
              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                ),
              ),
            ],
          );
        },
      );
      setState(() {
        if (isCustom) {
          gearNameController.text = '';
          gearWeightController.text = '';
          gearQuantityController.text = '1';
          isHazmat = false;
        } else {
          irpgGearNameController.text = '';
          irpgGearWeightController.text = '';
          irpgGearQuantityController.text = '1';
          selectedGearName = null;
          isHazmatIRPG = false;
        }
        _checkInput(); // Re-validate inputs
      });
      return; // Exit function if the gear name is already used
    }

    // Creating a new gear object
    Gear newGearItem = Gear(name: capitalizedGearName, weight: gearWeight, quantity: gearQuantity, isHazmat: isHazmatFinal);

    // Add the new member to the global crew object
    crew.addGear(newGearItem);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Gear Saved!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
    FirebaseAnalytics.instance.logEvent(
      name: 'gear_added',
      parameters: {
        'gear_name': newGearItem.name.trim(),
        'gear_weight': newGearItem.weight.toString(),
        'gear_quantity': newGearItem.quantity.toString(),
        'gear_isHazmat': newGearItem.isHazmat ? 'true' : 'false',
      },
    );
    // Clear the text fields (reset them to empty), so you can add more ppl
    gearNameController.text = '';
    gearWeightController.text = '';
    gearQuantityController.text = '1';

    irpgGearNameController.text = '';
    irpgGearWeightController.text = '';
    irpgGearQuantityController.text = '1';

    selectedGearName = null;
    isHazmatIRPG = false;
    isHazmat = false;

    // Debug for LogCat
    // print("Gear Name: $gearName");
    //print("Gear Weight: $gearWeight");
    //crew.printCrewDetails();


  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back, // The back arrow icon
              color: AppColors.textColorPrimary, // Set the desired color
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Navigate back when pressed
            },
          ),
          backgroundColor: AppColors.appBarColor,
          title: Text(
            'Add Gear',
            style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.tabIconColor,
            indicatorColor: AppColors.primaryColor,
            tabs: [
              Tab(
                  text: 'Custom',
                  icon: Icon(
                    Icons.create,
                    color: AppColors.textColorPrimary,
                  )),
              Tab(
                  text: 'IRPG',
                  icon: Icon(
                    Icons.forest_outlined,
                    color: AppColors.textColorPrimary,
                  )),
            ],
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

                    TabBarView(
                      children: [
                        // Custom
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Enter Name
                              Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                                  child: TextField(
                                    controller: gearNameController,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(25),
                                    ],
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Gear Name',
                                      labelStyle: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text22,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.textFieldColor,
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.borderPrimary,
                                          // Border color when the TextField is not focused
                                          width: 2.0, // Border width
                                        ),
                                        borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.primaryColor,
                                          // Border color when the TextField is focused
                                          width: 2.0, // Border width
                                        ),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textColorPrimary,
                                      fontSize: AppData.text28,
                                    ),
                                  )),

                              SizedBox(height: AppData.spacingStandard),
                              // Enter Gear Weight
                              Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 16.0,
                                  ),
                                  child: KeyboardActions(
                                    config: keyboardActionsConfig(
                                      focusNodes: [_weightFocusNode],
                                    ),
                                    disableScroll: true,
                                    child: TextField(
                                      focusNode: _weightFocusNode,
                                      textInputAction: TextInputAction.done,
                                      controller: gearWeightController,
                                      keyboardType: TextInputType.number,
                                      // Only show numeric keyboard
                                      inputFormatters: <TextInputFormatter>[
                                        LengthLimitingTextInputFormatter(3),
                                        FilteringTextInputFormatter.digitsOnly,
                                        // Allow only digits
                                      ],
                                      onChanged: (value) {
                                        int? weight = int.tryParse(value);
                                        setState(() {
                                          // Validate the input and set error message
                                          if (weight! > 500) {
                                            weightErrorMessage = 'Weight must be less than 500';
                                          } else if (weight == 0) {
                                            weightErrorMessage = 'Weight must be greater than 0';
                                          } else {
                                            weightErrorMessage = null;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Weight',
                                        hintText: 'Up to 500 lb',
                                        hintStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text20,
                                        ),
                                        errorText: weightErrorMessage,
                                        errorStyle: TextStyle(
                                          fontSize: AppData.errorText,
                                          color: Colors.red,
                                        ),
                                        labelStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text22,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.textFieldColor,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.borderPrimary,
                                            // Border color when the TextField is not focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryColor,
                                            // Border color when the TextField is focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text28,
                                      ),
                                    ),
                                  )),

                              SizedBox(height: AppData.spacingStandard),

                              // Enter quantity
                              Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                  child: KeyboardActions(
                                    config: keyboardActionsConfig(
                                      focusNodes: [_quantityFocusNode],
                                    ),
                                    disableScroll: true,
                                    child: TextField(
                                      focusNode: _quantityFocusNode,
                                      controller: gearQuantityController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        int? weight = int.tryParse(value);
                                        setState(() {
                                          if (weight == 0) {
                                            quantityErrorMessage = 'Quantity must be greater than 0';
                                          } else {
                                            quantityErrorMessage = null;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Quantity',
                                        hintText: 'Up to 99',
                                        hintStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text20,
                                        ),
                                        errorText: quantityErrorMessage,
                                        errorStyle: TextStyle(
                                          fontSize: AppData.errorText,
                                          color: Colors.red,
                                        ),
                                        labelStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text22,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.textFieldColor,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.borderPrimary,
                                            // Border color when the TextField is not focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryColor,
                                            // Border color when the TextField is focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text28,
                                      ),
                                    ),
                                  )),
                              SizedBox(height: AppData.spacingStandard),

                              // HAZMAT
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        'HAZMAT',
                                        style: TextStyle(
                                          fontSize: AppData.text22,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        isHazmat ? 'Yes' : 'No', // Dynamic label
                                        style: TextStyle(
                                          fontSize: AppData.text18,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      ),
                                      SizedBox(width: AppData.sizedBox8),
                                      // Toggle Switch
                                      Switch(
                                        value: isHazmat,
                                        onChanged: (bool value) {
                                          setState(() {
                                            isHazmat = value; // Update the state
                                          });
                                        },
                                        activeColor: Colors.red,
                                        inactiveThumbColor: AppColors.textColorPrimary,
                                        inactiveTrackColor: AppColors.textFieldColor,
                                      ),
                                      // HAZMAT Label
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(flex: 6),

                              // Save Button
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton(
                                    onPressed: isSaveButtonEnabled ? () => saveGearData(true) : null, // Button is only enabled if there is input
                                    style: style, // Main button theme
                                    child: const Text('Save')),
                              ),
                            ],
                          ),
                        ),

                        // IRPG
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      decoration: BoxDecoration(
                                        color: AppColors.textFieldColor2,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: AppColors.borderPrimary,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: DropdownButton<String>(
                                          itemHeight: null,
                                          dropdownColor: AppColors.textFieldColor2,
                                          iconEnabledColor: AppColors.textColorPrimary,
                                          value: selectedGearName,
                                          hint: Text(
                                            'Select Gear',
                                            style: TextStyle(
                                              color: AppColors.textColorPrimary,
                                              fontWeight: FontWeight.normal,
                                              fontSize: AppData.text20,
                                            ),
                                          ),
                                          isExpanded: true,
                                          underline: SizedBox(),
                                          items: irpgItems.map((item) {
                                            return DropdownMenuItem<String>(
                                              value: item['name'],
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${item['name']}',
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: AppColors.textColorPrimary,
                                                        fontWeight: FontWeight.normal,
                                                        fontSize: AppData.text18,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item['weight']} lb',
                                                    style: TextStyle(
                                                      color: AppColors.textColorPrimary,
                                                      fontWeight: FontWeight.normal,
                                                      fontSize: AppData.text18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedGearName = value!;
                                              // Find the selected gear item in the dropdown list
                                              final selectedGear = irpgItems.firstWhere(
                                                (item) => item['name'] == selectedGearName,
                                              );
                                              // Update the controllers with the selected gear's name and weight
                                              irpgGearNameController.text = selectedGear['name'];
                                              irpgGearWeightController.text = selectedGear['weight'].toString();
                                              isHazmatIRPG = selectedGear['hazmat'];
                                            });
                                          },
                                          selectedItemBuilder: (BuildContext context) {
                                            return irpgItems.map((item) {
                                              return Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  item['name'], // Display only the gear name when selected
                                                  style: TextStyle(
                                                    color: AppColors.textColorPrimary,
                                                    fontWeight: FontWeight.normal,
                                                    fontSize: AppData.text22,
                                                  ),
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: AppData.spacingStandard),
                              // Enter Gear Weight
                              Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                  child: KeyboardActions(
                                    config: keyboardActionsConfig(
                                      focusNodes: [_weightFocusNode2],
                                    ),
                                    disableScroll: true,
                                    child: TextField(
                                      focusNode: _weightFocusNode2,
                                      controller: irpgGearWeightController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(3),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        int? weight = int.tryParse(value);
                                        setState(() {
                                          // Validate the input and set error message
                                          if (weight! > 500) {
                                            irpgWeightErrorMessage = 'Weight must be less than 500';
                                          } else if (weight == 0) {
                                            irpgWeightErrorMessage = 'Weight must be greater than 0';
                                          } else {
                                            irpgWeightErrorMessage = null;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Weight',
                                        hintText: 'Up to 500 lb',
                                        hintStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text20,
                                        ),
                                        errorText: irpgWeightErrorMessage,
                                        errorStyle: TextStyle(
                                          fontSize: AppData.errorText,
                                          color: Colors.red,
                                        ),
                                        labelStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text22,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.textFieldColor,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.borderPrimary,
                                            // Border color when the TextField is not focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryColor,
                                            // Border color when the TextField is focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text28,
                                      ),
                                    ),
                                  )),

                              SizedBox(height: AppData.spacingStandard),

                              // Enter quantity
                              Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                  child: KeyboardActions(
                                    config: keyboardActionsConfig(
                                      focusNodes: [_quantityFocusNode2],
                                    ),
                                    disableScroll: true,
                                    child: TextField(
                                      focusNode: _quantityFocusNode2,
                                      controller: irpgGearQuantityController,
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        int? weight = int.tryParse(value);
                                        setState(() {
                                          if (weight == 0) {
                                            irpgQuantityErrorMessage = 'Quantity must be greater than 0';
                                          } else {
                                            irpgQuantityErrorMessage = null;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Quantity',
                                        hintText: 'Up to 99',
                                        hintStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text20,
                                        ),
                                        errorText: irpgQuantityErrorMessage,
                                        errorStyle: TextStyle(
                                          fontSize: AppData.errorText,
                                          color: Colors.red,
                                        ),
                                        labelStyle: TextStyle(
                                          color: AppColors.textColorPrimary,
                                          fontSize: AppData.text22,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.textFieldColor,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.borderPrimary,
                                            // Border color when the TextField is not focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryColor,
                                            // Border color when the TextField is focused
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text28,
                                      ),
                                    ),
                                  )),
                              SizedBox(height: AppData.spacingStandard),

                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 5.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        'HAZMAT',
                                        style: TextStyle(
                                          fontSize: AppData.text22,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        selectedGearName == null
                                            ? ''
                                            : isHazmatIRPG
                                                ? 'Yes'
                                                : 'No', // Dynamic label
                                        style: TextStyle(
                                          fontSize: AppData.text18,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      ),
                                      SizedBox(width: AppData.sizedBox8),
                                      // Toggle Switch
                                      Switch(
                                        value: isHazmatIRPG,
                                        onChanged: selectedGearName == null
                                            ? (_) {} // Prevent interaction but keep the track visible
                                            : (bool value) {
                                                setState(() {
                                                  isHazmatIRPG = value; // Update the toggle state
                                                });
                                              },
                                        activeColor: Colors.red,
                                        inactiveThumbColor: selectedGearName == null
                                            ? Colors.grey[400] // Gray out thumb when disabled
                                            : AppColors.textColorPrimary,
                                        inactiveTrackColor: selectedGearName == null
                                            ? Colors.grey[600] // Keep track visible when disabled
                                            : AppColors.textFieldColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(flex: 6),

                              // Save Button
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton(
                                    onPressed: isSaveButtonEnabledForIRPG ? () => saveGearData(false) : null, // Button is only enabled if there is input
                                    style: style, // Main button theme
                                    child: const Text('Save')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
