import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'CodeShare/colors.dart';
import 'Data/crew.dart';
import 'Data/gear.dart';
import 'CodeShare/functions.dart';

// Tester data
class AddGear extends StatefulWidget {
  const AddGear({super.key});

  @override
  State<AddGear> createState() => _AddGearState();
}

class _AddGearState extends State<AddGear> {
  late final Box<Gear> personalToolsBox;
  List<Gear> personalToolsList = [];

  // Variables to store user input
  final TextEditingController gearNameController = TextEditingController();
  final TextEditingController gearWeightController = TextEditingController();
  final TextEditingController gearQuantityController = TextEditingController(text: '1');
  bool isSaveButtonEnabled = false; // Controls whether saving button is showing

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

  // Local function to save user input. The contoller automatically tracks/saves the variable from the textfield
  void saveGearData() {
    final String gearName = gearNameController.text;
    final int gearWeight = int.parse(gearWeightController.text);
    final int gearQuantity = int.parse(gearQuantityController.text);
    String capitalizedGearName = capitalizeEveryWord(gearName);

    // Check if gear name already exists
    bool gearNameExists = crew.gear.any((gear) => gear.name.toLowerCase() == gearName.toLowerCase());
    bool personalToolExists = personalToolsList.any((gear) => gear.name.toLowerCase() == gearName.toLowerCase());

    if (personalToolExists) {
      int personalToolWeight = personalToolsList.firstWhere((gear) => gear.name.toLowerCase() == gearName.toLowerCase()).weight;
      if (personalToolWeight != gearWeight) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title:  Text('Gear Conflict', style: TextStyle(color: AppColors.textColorPrimary),),
              content: Text(
                '$capitalizedGearName already exists as a tool. To add this item, it must be of the same weight, ${personalToolsList.firstWhere((gear) => gear.name.toLowerCase() == gearName.toLowerCase()).weight} lbs.',
                style:  TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:  Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.cancelButton),
                  ),
                ),
              ],
            );
          },
        );
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
            title:  Text('Gear Conflict', style: TextStyle(color: AppColors.textColorPrimary)),
            content: Text(
              '$matchingGearName already exists. If you would like to add more, edit the item quantity in "Edit Gear" page.',
              style:  TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:  Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cancelButton),
                ),
              ),
            ],
          );
        },
      );
      return; // Exit function if the gear name is already used
    }

    // Creating a new gear object. Don't have hazmat yet
    Gear newGearItem = Gear(name: capitalizedGearName, weight: gearWeight, quantity: gearQuantity);

    // Add the new member to the global crew object
    crew.addGear(newGearItem);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Gear Saved!',
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

    // Clear the text fields (reset them to empty), so you can add more ppl
    gearNameController.text = '';
    gearWeightController.text = '';
    gearQuantityController.text = '1';

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
        title:  Text(
          'Add Gear',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
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

                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Enter Name
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
                            child: TextField(
                              controller: gearNameController,
                              maxLength: 20,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Gear Name',
                                labelStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 28,
                              ),
                            )),

                        // Enter Gear Weight
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
                            child: TextField(
                              controller: gearWeightController,
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              // Only show numeric keyboard
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                // Allow only digits
                              ],
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                hintText: 'Up to 500 lbs',
                                hintStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 20,
                                ),
                                labelStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 28,
                              ),
                            )),

                        // Enter quantity
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
                            child: TextField(
                              controller: gearQuantityController,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              // Only show numeric keyboard
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                // Allow only digits
                              ],
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                hintText: 'Up to 99',
                                hintStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 20,
                                ),
                                labelStyle:  TextStyle(
                                  color: AppColors.textColorPrimary,
                                  fontSize: 22,
                                  //fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.borderPrimary,
                                    // Border color when the TextField is not focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(
                                    color: AppColors.primaryColor,
                                    // Border color when the TextField is focused
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              style:  TextStyle(
                                color: AppColors.textColorPrimary,
                                fontSize: 28,
                              ),
                            )),

                        const Spacer(flex: 6),

                        // Save Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                              onPressed: isSaveButtonEnabled ? () => saveGearData() : null, // Button is only enabled if there is input
                              style: style, // Main button theme
                              child: const Text('Save')),
                        ),
                      ],
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
