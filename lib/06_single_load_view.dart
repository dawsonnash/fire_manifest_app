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

// Generates PDF
Future<Uint8List> generatePDF(Load load, String manifestForm) async {
  final pdf = pw.Document();
  late String imagePath;
  late pw.Widget Function(Load load) fillFormFields;

  // Determine form and form-filling function based on manifestForm
  if (manifestForm == 'pms245') {
    imagePath = 'assets/images/crew_manifest_form.png';
    fillFormFields = fillFormFieldsPMS245;
  } else if (manifestForm == 'of252') {
    imagePath = 'assets/images/helicopter_manifest_form.jpg';
    fillFormFields = fillFormFieldsOF252;
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Load the background image
  final imageBytes = await rootBundle.load(imagePath);
  final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Dynamically add pages based on manifestForm
  if (manifestForm == 'pms245') {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                child: pw.Image(
                  backgroundImage,
                  fit: pw.BoxFit.cover, // Ensures image covers the entire page
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: fillFormFields(load), // PMS 245-specific logic
              ),
            ],
          );
        },
      ),
    );
  } else if (manifestForm == 'of252') {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
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
                padding: const pw.EdgeInsets.all(22),
                child: fillFormFields(load),
              ),
            ],
          );
        },
      ),
    );
  }

  // Save the PDF and return it as a Uint8List
  return pdf.save();
}

// Display preview
void previewPDF(BuildContext context, Load load, String manifestForm) async {
  Uint8List pdfBytes;

  if (manifestForm == 'pms245') {
    pdfBytes = await generatePDF(load, 'pms245');
  } else if (manifestForm == 'of252') {
    pdfBytes = await generatePDF(load, 'of252');
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Display the PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
  );
}

// Fills PDFs
pw.Widget fillFormFieldsPMS245(Load load) {
  const double yOffset = 65; // Adjust this value to move everything down
  const double itemSpacing =
      15; // Adjust this value to control spacing between items

  int subtotalCrewMemberWeight = load.loadPersonnel
      .fold(0, (sum, crewMember) => sum + crewMember.flightWeight);
  int subtotalGearWeight =
      load.loadGear.fold(0, (sum, gear) => sum + gear.weight);
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
            "${load.loadPersonnel[i].name}",
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

pw.Widget fillFormFieldsOF252(Load load) {
  const double yOffset = 112; // Adjust this value to move everything vertically
  const double xOffset = 6; // Adjust this value to move everything horizontally
  const double itemSpacing =
      27.4; // Adjust this value to control spacing between items
  const double fontSizeOF252 = 18.0;

  DateTime today = DateTime.now();
  String formattedDate = DateFormat('MM/dd/yyyy').format(today);

  return pw.Stack(
    children: [
      // Crew Members
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: xOffset + 32,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            "${load.loadPersonnel[i].name}",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),
      // Gear
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: xOffset + 32,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].name}",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // Custom Items
      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: xOffset + 32,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            load.customItems[k].name,
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // Gear Quantity
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: xOffset - 2,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].quantity}",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // CrewMember Weights
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: xOffset + 442,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            "${load.loadPersonnel[i].flightWeight} lbs",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),
      // Gear Weights
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: xOffset + 442,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].totalGearWeight} lbs",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: xOffset + 442,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            "${load.customItems[k].weight} lbs",
            style: pw.TextStyle(fontSize: fontSizeOF252),
          ),
        ),

      // Total Load Weight
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
        left: xOffset + 452,
        top: 13,
        child: pw.Text(
          formattedDate.toString(),
          style: pw.TextStyle(fontSize: fontSizeOF252),
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
        backgroundColor: Colors.deepOrangeAccent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Load ${widget.load.loadNumber}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                Icons.ios_share,
                size: 28,
              ),
              // Does this work for android, i dont know
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    int selectedIndex = 0; // Initial selection index

                    return AlertDialog(
                      title: const Text(
                        'Select Manifest Type',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.15, // Dynamic height
                        child: CupertinoPicker(
                          itemExtent: 50, // Height of each item in the picker
                          onSelectedItemChanged: (int index) {
                            selectedIndex = index;
                          },
                          children: const [
                            Center(
                                child: Text('Helicopter Manifest',
                                    style: TextStyle(fontSize: 18))),
                            Center(
                                child: Text('Fixed-Wing Manifest',
                                    style: TextStyle(fontSize: 18))),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();

                            if (selectedIndex == 0) {
                              // Helicopter Manifest
                              previewPDF(context, widget.load, 'of252');
                            } else {
                              // Fixed-Wing manifest
                              previewPDF(context, widget.load, 'pms245');
                            }
                          },
                          child: const Text(
                            'Export',
                            style: TextStyle(fontSize: 18),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.load.loadPersonnel.length +
                        widget.load.loadGear.length +
                        widget.load.customItems.length,
                    itemBuilder: (context, index) {
                      int numCrewMembers = widget.load.loadPersonnel.length;
                      int numGearItems = widget.load.loadGear.length;

                      if (index < numCrewMembers) {
                        // Display a crew member
                        final crewmember = widget.load.loadPersonnel[index];
                        return Card(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: ListTile(
                              iconColor: Colors.black,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        crewmember.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Flight Weight: ${crewmember.flightWeight} lbs',
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: Icon(Icons.person),
                            ),
                          ),
                        );
                      } else if (index < numCrewMembers + numGearItems) {
                        // Display a gear item
                        final gearIndex = index - numCrewMembers;
                        final gearItem = widget.load.loadGear[gearIndex];
                        return Card(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
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
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            ' (x${gearItem.quantity})',
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Weight: ${gearItem.weight} lbs',
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: Icon(Icons.work_outline_outlined),
                            ),
                          ),
                        );
                      } else {
                        // Display a custom item
                        final customItemIndex = index - numCrewMembers - numGearItems;
                        final customItem = widget.load.customItems[customItemIndex];
                        return Card(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
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
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    //alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          'Load Weight:',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${widget.load.weight} lbs',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
    );
  }
}
