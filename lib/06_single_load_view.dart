import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import '../Data/load.dart';

// For exporting to pdf
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import 'CodeShare/colors.dart';
import 'Data/crewmember.dart';
import 'Data/customItem.dart';
import 'Data/gear.dart';

const int maxItemsPerPage = 14; // Maximum items (crew + gear + custom) per page

// Helper function to split load if greater than alloted pdf cells
List<List<dynamic>> paginateItems(List<dynamic> items, int maxItems) {
  List<List<dynamic>> pages = [];
  for (int i = 0; i < items.length; i += maxItems) {
    pages.add(items.sublist(i, i + maxItems > items.length ? items.length : i + maxItems));
  }
  return pages;
}

// Generates PDF
Future<Uint8List> generatePDF(Load load, String manifestForm, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
  final pdf = pw.Document();
  late String imagePath;
  late pw.Widget Function(Load load, int pageIndex, int totalPages, List<dynamic> pageItems) fillFormFields;
  late PdfPageFormat pageFormat;

  // Determine the image path, form-filling logic, and page format based on the manifestForm
  if (manifestForm == 'pms245') {
    imagePath = 'assets/images/crew_manifest_form.png';
    fillFormFields = (load, pageIndex, totalPages, pageItems) => fillFormFieldsPMS245(load); // No pagination needed for PMS245
    pageFormat = PdfPageFormat.letter;
  } else if (manifestForm == 'of252') {
    imagePath = 'assets/images/helicopter_manifest_form.jpg';
    fillFormFields = (load, pageIndex, totalPages, pageItems) => fillFormFieldsOF252(load, pageIndex, totalPages, pageItems, helicopterNum, departure, destination, manifestPreparer);
    pageFormat = PdfPageFormat.a4;
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Load the background image
  final imageBytes = await rootBundle.load(imagePath);
  final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Combine all items from the load
  final allItems = [
    ...load.loadPersonnel,
    ...load.loadGear,
    ...load.customItems,
  ];

  // Paginate items if `of252`
  final paginatedItems = manifestForm == 'of252' ? paginateItems(allItems, maxItemsPerPage) : [allItems];

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

  return pdf.save();
}

// Display preview
void previewPDF(BuildContext context, Load load, String manifestForm, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
  Uint8List pdfBytes;
  late PdfPageFormat pageFormat;

  // Determine the correct format based on the manifest form
  if (manifestForm == 'pms245') {
    pdfBytes = await generatePDF(load, 'pms245', null, null, null, null);
    pageFormat = PdfPageFormat.letter; // PMS245 requires Letter format
  } else if (manifestForm == 'of252') {
    pdfBytes = await generatePDF(load, 'of252', helicopterNum, departure, destination, manifestPreparer);
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

// Fills PDFs
pw.Widget fillFormFieldsPMS245(Load load) {
  const double yOffset = 65; // Adjust this value to move everything down
  const double itemSpacing = 15; // Adjust this value to control spacing between items

  int subtotalCrewMemberWeight = load.loadPersonnel.fold(0, (sum, crewMember) => sum + crewMember.flightWeight);
  int subtotalGearWeight = load.loadGear.fold(0, (sum, gear) => sum + gear.totalGearWeight);
  DateTime today = DateTime.now();
  String formattedDate = DateFormat('MM/dd/yyyy').format(today);

  return pw.Stack(
    children: [
      // Crew Members
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            load.loadPersonnel[i].name,
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      // Gear
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].name} (x${load.loadGear[j].quantity})",
            style: pw.TextStyle(fontSize: 12),
          ),
        ),

      // Custom Items
      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            load.customItems[k].name,
            style: pw.TextStyle(fontSize: 12),
          ),
        ),

      // CrewMember Weights
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: 267,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            "${load.loadPersonnel[i].flightWeight} lbs",
            style: pw.TextStyle(fontSize: 12),
          ),
        ),

      // Gear Weights
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: 323,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].totalGearWeight} lbs",
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: 323,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            "${load.customItems[k].weight} lbs",
            style: pw.TextStyle(fontSize: 12),
          ),
        ),

      // Total Load Weight
      pw.Positioned(
        left: 494,
        top: yOffset + 545,
        child: pw.Text(
          '${load.weight.toString()} lbs',
          style: pw.TextStyle(fontSize: 12),
        ),
      ),

      // # of passengers on page
      pw.Positioned(
        left: 110,
        top: yOffset + 545,
        child: pw.Text(
          load.loadPersonnel.length.toString(),
          style: pw.TextStyle(fontSize: 12),
        ),
      ),

      // Weight subtotals: CrewMembers
      pw.Positioned(
        left: 260,
        top: yOffset + 545,
        child: pw.Text(
          '${subtotalCrewMemberWeight.toString()} lbs',
          style: pw.TextStyle(fontSize: 12),
        ),
      ),

      // Weight subtotals: Gear
      pw.Positioned(
        left: 320,
        top: yOffset + 545,
        child: pw.Text(
          '${subtotalGearWeight.toString()} lbs',
          style: pw.TextStyle(fontSize: 12),
        ),
      ),

      // Current date
      pw.Positioned(
        left: 390,
        top: yOffset + 580,
        child: pw.Text(
          formattedDate.toString(),
          style: pw.TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
}

pw.Widget fillFormFieldsOF252(Load load, int pageIndex, int totalPages, List<dynamic> pageItems, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) {
  const double yOffset = 112; // Adjust this value to move everything vertically
  const double xOffset = 6; // Adjust this value to move everything horizontally
  const double itemSpacing = 27.4; // Adjust spacing between items
  const double fontSizeOF252 = 18.0;

  DateTime today = DateTime.now();
  String formattedDate = DateFormat('MM/dd/yyyy').format(today);
  String formattedTime = DateFormat('hh:mm a').format(today);
  return pw.Stack(
    children: [
      // Display names and quantities for Crew Members, Gear, and Custom Items
      for (var i = 0; i < pageItems.length; i++)
        pw.Positioned(
          left: xOffset + 32,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            pageItems[i] is CrewMember
                ? pageItems[i].name
                : pageItems[i] is Gear
                    ? pageItems[i].name
                    : pageItems[i].name,
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // Display weights for each item
      for (var i = 0; i < pageItems.length; i++)
        if (pageItems[i] is CrewMember || pageItems[i] is Gear || pageItems[i] is CustomItem)
          pw.Positioned(
            left: xOffset + 442,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              "${pageItems[i] is CrewMember ? pageItems[i].flightWeight : pageItems[i] is Gear ? pageItems[i].totalGearWeight : pageItems[i].totalGearWeight} lbs",
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

      // Display gear quantities for items on the current page
      for (var i = 0; i < pageItems.length; i++)
        if (pageItems[i] is Gear)
          pw.Positioned(
            left: xOffset - 2,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              "${pageItems[i].quantity}",
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

      // Total Load Weight
      if (pageIndex == totalPages)
        pw.Positioned(
          left: xOffset + 442,
          top: yOffset + 610,
          child: pw.Text(
            '${load.weight.toString()} lbs',
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // Current date
      pw.Positioned(
        left: xOffset + 459,
        top: 15,
        child: pw.Text(
          formattedDate,
          style: pw.TextStyle(fontSize: 14),
        ),
      ),

      // Current time
      pw.Positioned(
        left: xOffset + 350,
        top: 15,
        child: pw.Text(
          formattedTime,
          style: pw.TextStyle(fontSize: 14),
        ),
      ),

      // Page number in the bottom-left corner
      pw.Positioned(
        left: xOffset - 6,
        top: yOffset + 605,
        child: pw.Text(
          'Load #${load.loadNumber}, Page $pageIndex of $totalPages',
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.black, // Optional: use a lighter color for page numbers
          ),
        ),
      ),

      // Helicopter Tail Number
      pw.Positioned(
        left: xOffset + 70,
        top: 13,
        child: pw.Text(
          helicopterNum!,
          style: pw.TextStyle(fontSize: 16),
        ),
      ),

      // Departure
      pw.Positioned(
        left: xOffset + 56,
        top: 55,
        child: pw.Text(
          departure!,
          style: pw.TextStyle(fontSize: 16),
        ),
      ),

      // Destintation
      pw.Positioned(
        left: xOffset + 336,
        top: 55,
        child: pw.Text(
          destination!,
          style: pw.TextStyle(fontSize: 16),
        ),
      ),

      // Destintation
      pw.Positioned(
        left: xOffset + 135,
        top: yOffset + 656,
        child: pw.Text(
          manifestPreparer!,
          style: pw.TextStyle(fontSize: 16),
        ),
      ),
    ],
  );
}

class SingleLoadView extends StatefulWidget {
  // This page requires a trip to be passed to it
  final Load load;

  //final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const SingleLoadView({
    super.key,
    required this.load,
    //required this.onUpdate,
  });

  @override
  State<SingleLoadView> createState() => _SingleLoadViewState();
}

class _SingleLoadViewState extends State<SingleLoadView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Load ${widget.load.loadNumber}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                ),
                Text(
                  ' • ${widget.load.weight} lbs',
                  style: TextStyle(fontSize: 20, color: AppColors.textColorPrimary),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.ios_share, size: 28, color: AppColors.textColorPrimary),
              // Does this work for android, i dont know
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    int selectedIndex = 0; // Initial selection index

                    return AlertDialog(
                      backgroundColor: AppColors.textFieldColor,
                      title: Text(
                        'Select Manifest Type',
                        style: TextStyle(
                          fontSize: 22,
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
                            Center(child: Text('Helicopter Manifest', style: TextStyle(fontSize: 18, color: AppColors.textColorPrimary))),
                            Center(child: Text('Fixed-Wing Manifest', style: TextStyle(fontSize: 18, color: AppColors.textColorPrimary))),
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
                            style: TextStyle(fontSize: 16, color: AppColors.cancelButton),
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
                                      previewPDF(context, widget.load, 'of252', helicopterNum, departure, destination, manifestPreparer);
                                    },
                                  );
                                },
                              );
                            } else {
                              // Fixed-Wing manifest
                              previewPDF(context, widget.load, 'pms245', null, null, null, null);
                            }
                          },
                          child: Text(
                            'Export',
                            style: TextStyle(fontSize: 16, color: AppColors.saveButtonAllowableWeight),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },

              tooltip: 'Export all loads to a manifest form',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Black background in dark mode
            child: AppColors.isDarkMode
                ? null // No child if dark mode is enabled
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.cover, // Cover the entire background
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.load.loadPersonnel.length + widget.load.loadGear.length + widget.load.customItems.length,
                  itemBuilder: (context, index) {
                    int numCrewMembers = widget.load.loadPersonnel.length;
                    int numGearItems = widget.load.loadGear.length;

                    if (index < numCrewMembers) {
                      // Display a crew member
                      final crewmember = widget.load.loadPersonnel[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.textFieldColor2, // Background color
                          border: Border(bottom: BorderSide(color: Colors.grey, width: 1)), // Add a border
                        ),
                        child: ListTile(
                          iconColor: AppColors.primaryColor,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crewmember.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColorPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Flight Weight: ${crewmember.flightWeight} lbs',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: Icon(Icons.person),
                        ),
                      );
                    } else if (index < numCrewMembers + numGearItems) {
                      // Display a gear item
                      final gearIndex = index - numCrewMembers;
                      final gearItem = widget.load.loadGear[gearIndex];
                      return Container(
                        decoration: BoxDecoration(
                          color: gearItem.isPersonalTool
                              ? AppColors.toolBlue // Color for personal tools
                              : AppColors.gearYellow, // Background color
                          border: Border(bottom: BorderSide(color: Colors.grey, width: 1)), // Add a border
                        ),
                        child: ListTile(
                          iconColor: Colors.black,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        gearItem.name,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,                                         color: Colors.black
                                        ),
                                      ),
                                      Text(
                                        ' (x${gearItem.quantity})',
                                        style: TextStyle(fontSize: 18,                                         color: Colors.black
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Weight: ${gearItem.totalGearWeight} lbs',
                                    style: TextStyle(
                                      fontSize: 18,
                                        color: Colors.black

                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: Icon(Icons.work_outline_outlined),
                        ),
                      );
                    } else {
                      // Display a custom item
                      final customItemIndex = index - numCrewMembers - numGearItems;
                      final customItem = widget.load.customItems[customItemIndex];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          border: Border(bottom: BorderSide(color: Colors.grey, width: 1)), // Add a border
                        ),
                        child: ListTile(
                          iconColor: Colors.black,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        customItem.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Weight: ${customItem.weight} lbs',
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: Icon(Icons.inventory_2_outlined),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
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
      backgroundColor: AppColors.textFieldColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      // Adjust padding
      title: Text(
        'Additional Information',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
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
            style: TextStyle(fontSize: 16, color: AppColors.cancelButton),
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
            style: TextStyle(fontSize: 16, color: AppColors.saveButtonAllowableWeight),
          ),
        ),
      ],
    );
  }
}
