import 'dart:ui';

import 'package:fire_app/UI/06_edit_trip_external.dart';
import 'package:fire_app/UI/06_single_load_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
// For exporting to pdf
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Data/trip.dart';
import '../CodeShare/variables.dart';
import '../Data/gear.dart';
import '../Data/load.dart';
import '../Data/load_accoutrements.dart';
import '../UI/06_edit_trip.dart';

// Generates PDF
Future<Uint8List> generateTripPDF(Trip trip, String manifestForm, bool isExternal, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
  final pdf = pw.Document();
  late String imagePath;
  late pw.Widget Function(Load load, int pageIndex, int totalPages, List<dynamic> pageItems) fillFormFields;
  late PdfPageFormat pageFormat;

  // Determine the image path, form-filling logic, and page format based on the manifestForm
  if (manifestForm == 'pms245') {
    imagePath = 'assets/images/crew_manifest_form.png';
    fillFormFields = (load, pageIndex, totalPages, pageItems) => fillFormFieldsPMS245(load);
    pageFormat = PdfPageFormat.letter;
  } else if (manifestForm == 'of252') {
    imagePath = 'assets/images/helicopter_manifest_form.jpg';
    fillFormFields = (load, pageIndex, totalPages, pageItems) =>
        fillFormFieldsOF252(load, trip.isExternal ?? false, pageIndex, totalPages, pageItems, helicopterNum, departure, destination, manifestPreparer, null);
    pageFormat = PdfPageFormat.a4;
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Load the background image
  final imageBytes = await rootBundle.load(imagePath);
  final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Iterate through each load in the trip
  for (var load in trip.loads) {
    // Combine all items from the load
    List<dynamic> allItems;
    if (isExternal) {
      allItems = load.slings?.expand((sling) => [...sling.loadGear, ...sling.loadAccoutrements]).toList() ?? [];

      // Create a map to merge items with the same name (without modifying originals)
      Map<String, dynamic> mergedItems = {};

      for (var item in allItems) {
        String itemName = item.name;

        if (mergedItems.containsKey(itemName)) {
          // Merge quantities for duplicate items
          if (item is Gear) {
            mergedItems[itemName] = Gear(
              name: item.name,
              quantity: mergedItems[itemName].quantity + item.quantity, // Sum quantity
              weight: item.weight,
              isHazmat: item.isHazmat,
            );
          } else if (item is LoadAccoutrement) {
            mergedItems[itemName] = LoadAccoutrement(
              name: item.name,
              quantity: mergedItems[itemName].quantity + item.quantity, // Sum quantity
              weight: item.weight,
            );
          }
        } else {
          // Clone the object without modifying original
          if (item is Gear) {
            mergedItems[itemName] = Gear(
              name: item.name,
              quantity: item.quantity,
              weight: item.weight,
              isHazmat: item.isHazmat,
            );
          } else if (item is LoadAccoutrement) {
            mergedItems[itemName] = LoadAccoutrement(
              name: item.name,
              quantity: item.quantity,
              weight: item.weight,
            );
          }
        }
      }

      // Convert map back to list and update allItems
      allItems = mergedItems.values.toList();

      allItems.sort((a, b) {
        // Prioritize LoadAccoutrements over Gear
        if (a is LoadAccoutrement && b is! LoadAccoutrement) return -1;
        if (a is! LoadAccoutrement && b is LoadAccoutrement) return 1;

        // Prioritize specific LoadAccoutrement names
        int getPriority(dynamic item) {
          if (item is LoadAccoutrement) {
            if (item.name.contains("Cargo Net")) return 1;
            if (item.name.contains("Lead Line")) return 2;
            if (item.name.contains("Swivel")) return 3;
          }
          return 4; // Default priority for other items
        }

        return getPriority(a).compareTo(getPriority(b));
      });
    } else {
      allItems = [
        ...load.loadPersonnel,
        ...load.loadGear,
        ...load.customItems,
      ];
    }

    // Count hazmat items
    int numHaz = allItems.where((item) => item is Gear && item.isHazmat).length;

    // Calculate the required number of pages
    int totalPages = calculatePagesNeeded(allItems.length, numHaz);

    // Paginate items if `of252`
    final paginatedItems = manifestForm == 'of252' ? paginateItems(allItems, totalPages) : [allItems];

    // Generate pages based on pagination
    for (int i = 0; i < paginatedItems.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat, // Use the dynamically set page format
          margin: pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: pw.Image(
                    backgroundImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
                pw.Padding(
                  padding: manifestForm == 'pms245'
                      ? const pw.EdgeInsets.all(32) // Adjust padding for PMS245
                      : const pw.EdgeInsets.all(22), // Adjust padding for OF252
                  child: fillFormFields(
                    load,
                    i + 1, // Page index (1-based)
                    paginatedItems.length, // Total pages
                    paginatedItems[i], // Items on the current page
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  // Save the PDF and return it as a Uint8List
  return pdf.save();
}

// Display preview
void previewTripPDF(BuildContext context, Trip trip, String manifestForm, bool? isExternal, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
  Uint8List pdfBytes;
  late PdfPageFormat pageFormat;

  // Determine the correct format based on the manifest form
  if (manifestForm == 'pms245') {
    pdfBytes = await generateTripPDF(trip, 'pms245', isExternal ?? false, null, null, null, null);
    pageFormat = PdfPageFormat.letter; // PMS245 requires Letter format
  } else if (manifestForm == 'of252') {
    pdfBytes = await generateTripPDF(trip, 'of252', isExternal!, helicopterNum, departure, destination, manifestPreparer);
    pageFormat = PdfPageFormat.a4; // OF252 requires A4 format
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Display the PDF with the appropriate page format
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
    usePrinterSettings: false, // Enforce the specified format
    format: pageFormat, // Dynamically set the format based on the manifest type
  );
}

class SingleTripView extends StatefulWidget {
  // This page requires a trip to be passed to it
  final Trip trip;

  //final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const SingleTripView({
    super.key,
    required this.trip,
    //required this.onUpdate,
  });

  @override
  State<SingleTripView> createState() => _SingleTripViewState();
}

class _SingleTripViewState extends State<SingleTripView> {
  late final bool? isExternal;

  @override
  void initState() {
    isExternal = widget.trip.isExternal;
    super.initState();
    // print('Number of loads: ${widget.trip.loads.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
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
          widget.trip.tripName,
          style: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          overflow: TextOverflow.ellipsis, // Add this
          maxLines: 1,
        ),
        actions: [
          IconButton(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textColorPrimary,
              ),
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppData.bottomModalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Export
                          ListTile(
                            leading: Icon(Icons.ios_share, color: AppColors.textColorPrimary),
                            title: Text(
                              'Export',
                              style: TextStyle(color: AppColors.textColorPrimary),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  int selectedIndex = 0; // Initial selection index

                                  return AlertDialog(
                                    backgroundColor: AppColors.textFieldColor2,
                                    title: Text(
                                      'Select Manifest Type',
                                      style: TextStyle(
                                        fontSize: AppData.text22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textColorPrimary,
                                      ),
                                    ),
                                    content: SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.15, // Dynamic height
                                      child: CupertinoPicker(
                                        itemExtent: 50, // Height of each item in the picker
                                        onSelectedItemChanged: (int index) {
                                          selectedIndex = index;
                                        },
                                        children: [
                                          Center(child: Text('Helicopter Manifest', style: TextStyle(fontSize: AppData.text18, color: AppColors.textColorPrimary))),
                                          if (!isExternal!) Center(child: Text('Fixed-Wing Manifest', style: TextStyle(fontSize: AppData.text18, color: AppColors.textColorPrimary))),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: AppData.text16, color: AppColors.cancelButton),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          if (selectedIndex == 0) {
                                            // Show additional input dialog for `of252`
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AdditionalInfoDialog(
                                                  onConfirm: (String helicopterNum, String departure, String destination, String manifestPreparer) {
                                                    previewTripPDF(context, widget.trip, 'of252', widget.trip.isExternal, helicopterNum, departure, destination, manifestPreparer);
                                                  },
                                                );
                                              },
                                            );
                                          } else {
                                            // Fixed-Wing manifest
                                            previewTripPDF(context, widget.trip, 'pms245', null, null, null, null, null);
                                          }
                                        },
                                        child: Text(
                                          'Export',
                                          style: TextStyle(fontSize: AppData.text16, color: AppColors.saveButtonAllowableWeight),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          // Edit
                          ListTile(
                            leading: Icon(Icons.edit, color: AppColors.textColorPrimary),
                            title: Text(
                              'Edit Trip',
                              style: TextStyle(color: AppColors.textColorPrimary),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => widget.trip.isExternal!
                                        ? EditTripExternal(
                                            trip: widget.trip,
                                          )
                                        : EditTrip(
                                            trip: widget.trip,
                                          )),
                              );
                            },
                          ),

                          // Delete
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete trip',
                              style: TextStyle(color: AppColors.textColorPrimary),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              // if (savedTrips.savedTrips.isNotEmpty) {}
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.textFieldColor2,
                                    title: Text(
                                      'Confirm Deletion',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete this trip?',
                                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog without deleting
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            savedTrips.removeTrip(widget.trip);
                                          });
                                          Navigator.of(context).pop(); // Close the dialog after deletion
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
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
                    );
                  },
                );
              }),
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      //hive: itemCount: tripList.length,
                      itemCount: widget.trip.loads.length,
                      itemBuilder: (context, index) {
                        // hive: final trip = tripList[index];
                        final load = widget.trip.loads[index];

                        // Display trip data in a scrollable list
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            border: Border(top: BorderSide(color: Colors.black, width: 1)), // Add a border
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleLoadView(
                                    load: load,
                                    isExternal: widget.trip.isExternal!,
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: Icon(
                                Icons.numbers,
                                color: AppColors.primaryColor,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Load ${load.loadNumber.toString()}',
                                        style: TextStyle(
                                          fontSize: AppData.text22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Weight: ${load.weight} lb',
                                        style: TextStyle(
                                          fontSize: AppData.text18,
                                          color: AppColors.textColorPrimary,
                                        ),
                                      )
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      //Icons.edit,
                                      color: AppColors.textColorPrimary,
                                      size: AppData.text28),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalInfoDialog extends StatefulWidget {
  final Function(String helicopterNum, String departure, String destination, String manifestPreparer) onConfirm;

  const AdditionalInfoDialog({required this.onConfirm, super.key});

  @override
  State<AdditionalInfoDialog> createState() => _AdditionalInfoDialogState();
}

class _AdditionalInfoDialogState extends State<AdditionalInfoDialog> {
  final TextEditingController _helicopterNumController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _manifestPreparerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manifestPreparerController.text = AppData.userName ?? ''; // Default to empty if null
  }

  @override
  void dispose() {
    _helicopterNumController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    _manifestPreparerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.textFieldColor2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      // Adjust padding
      title: Text(
        'Additional Information',
        style: TextStyle(fontSize: AppData.text22, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
      ),
      content: SingleChildScrollView(
        // Wrap content in a scrollable view
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _helicopterNumController,
                decoration: InputDecoration(labelText: 'Enter helicopter tail #:', labelStyle: TextStyle(color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.characters,
                // Automatically capitalize all characters
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6), // Limit to 25 characters
                ],
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _departureController,
                decoration: InputDecoration(labelText: 'Enter departure:', labelStyle: TextStyle(color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                decoration: InputDecoration(labelText: 'Enter destination:', labelStyle: TextStyle(color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _manifestPreparerController,
                decoration: InputDecoration(labelText: 'Enter manifest preparer:', labelStyle: TextStyle(color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20), // Limit to 25 characters
                ],
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: AppData.text16, color: AppColors.cancelButton),
          ),
        ),
        TextButton(
          onPressed: () {
            final helicopterNum = _helicopterNumController.text.trim();
            final departure = _departureController.text.trim();
            final destination = _destinationController.text.trim();
            final manifestPreparer = _manifestPreparerController.text.trim();
            widget.onConfirm(helicopterNum, departure, destination, manifestPreparer); // Pass collected data to the callback
            Navigator.of(context).pop();
          },
          child: Text(
            'Confirm',
            style: TextStyle(fontSize: AppData.bottomDialogTextSize, color: AppColors.saveButtonAllowableWeight),
          ),
        ),
      ],
    );
  }
}
