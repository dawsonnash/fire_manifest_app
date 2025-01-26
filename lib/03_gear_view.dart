import 'dart:ui';
import 'package:fire_app/03_edit_gear.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '03_add_gear.dart';
import 'CodeShare/colors.dart';
import 'Data/crew.dart';
import 'Data/gear.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GearView extends StatefulWidget {
  const GearView({super.key});

  @override
  State<GearView> createState() => _GearViewState();
}

class _GearViewState extends State<GearView> {
  late final Box<Gear> gearBox;
  List<Gear> gearList = [];

  @override
  void initState() {
    super.initState();

    // Open the Hive box and load the list of Gear items
    gearBox = Hive.box<Gear>('gearBox');
    loadGearList();
  }

  // Function to load the list of Gear items from the Hive box
  void loadGearList() {
    setState(() {
      gearList = gearBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);

    TextStyle panelTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        title: Text(
          'Gear',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete All Gear', style: TextStyle(color: AppColors.textColorPrimary)),
                          onTap: () {
                            Navigator.of(context).pop(); // Close the dialog without deleting
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2 ,
                                  title:  Text(
                                    'Confirm Deletion',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                  ),
                                  content:  Text(
                                    'Are you sure you want to delete all gear?',
                                    style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog without deleting
                                      },
                                      child:  Text(
                                        'Cancel',
                                        style: TextStyle(color: AppColors.cancelButton),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        crew.deleteAllGear();
                                        setState(() {});
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.more_vert,  color: AppColors.textColorPrimary,))
        ],
      ),
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
          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      gearList.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Card(
                                                        color: AppColors.textFieldColor,
                                                        child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: ListTile(
                                  iconColor: AppColors.primaryColor,
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'No gear created...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textColorPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                                        ),
                                                      ),
                                SizedBox(height: 8), // Adds spacing between the list and the panel

                                GestureDetector(
                                  onTap: ()  {
                                    Navigator.of(context).pop(); // Navigate back when pressed
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddGear()),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(FontAwesomeIcons.circlePlus, color: AppColors.primaryColor,),
                                      SizedBox(width: 8), // Space between the icon and the text
                                      Text(
                                        'Gear',
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          :
                      // ListView
                      ListView.builder(
                        itemCount: sortedGearList.length,
                        padding: EdgeInsets.only(
                          bottom: 80, // Ensure space for the button at the bottom
                        ),
                        itemBuilder: (context, index) {
                          final gear = sortedGearList[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.textFieldColor, // Background color
                              border: Border(top: BorderSide(color: Colors.black, width: 1)), // Add a border
                            ),
                            child: ListTile(
                              iconColor: AppColors.primaryColor,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gear.name,
                                          style:  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                        ),
                                        Text(
                                          '${gear.weight} lbs x ${gear.quantity}',
                                          style:  TextStyle(
                                            fontSize: 16,
                                              color: AppColors.textColorPrimary
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon:  Icon(Icons.edit, color: AppColors.textColorPrimary, size: 32),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditGear(
                                            gear: gear,
                                            onUpdate: loadGearList, // Refresh the list on return
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              leading:  Icon(Icons.work_outline_outlined),
                            ),
                          );
                        },
                      ),
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
