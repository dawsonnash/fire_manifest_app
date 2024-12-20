import 'dart:ui';
import 'package:fire_app/06_single_load_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import '../Data/trip.dart';
// For exporting to pdf
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'Data/load.dart';

// Generates PDF
Future<Uint8List> generateTripPDF(Trip trip, String manifestForm) async {
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
    for (var load in trip.loads) {
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
                    fit: pw.BoxFit
                        .cover, // Ensures image covers the entire page
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
    }
  } else if (manifestForm == 'of252') {
    for (var load in trip.loads) {
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
  }

  // Save the PDF and return it as a Uint8List
  return pdf.save();
}

// Display preview
void previewTripPDF(BuildContext context, Trip trip, String manifestForm) async {
  Uint8List pdfBytes;

  if (manifestForm == 'pms245') {
    pdfBytes = await generateTripPDF(trip, 'pms245');
  } else if (manifestForm == 'of252') {
    pdfBytes = await generateTripPDF(trip, 'of252');
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Display the PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
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
class _SingleTripViewState extends State<SingleTripView>{

  @override
  void initState() {
    super.initState();
    // print('Number of loads: ${widget.trip.loads.length}');

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,  // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
            widget.trip.tripName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
            IconButton(
              icon: Icon(Icons.ios_share, size: 28,),    // Does this work for android, i dont know
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
                              previewTripPDF(context, widget.trip, 'of252');
                            } else {
                              // Fixed-Wing manifest
                              previewTripPDF(context, widget.trip, 'pms245');
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
                child: Image.asset('assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover  entire background
                  width: double.infinity,
                  height: double.infinity,
                )
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              //hive: itemCount: tripList.length,
              itemCount: widget.trip.loads.length,
              itemBuilder: (context, index) {

                // hive: final trip = tripList[index];
                final load = widget.trip.loads[index];

                // Display trip data in a scrollable list
                return Card(
                  child: Container(
                    decoration: BoxDecoration(
                      // Could change color here
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
                                'Load ${load.loadNumber.toString()}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                'Weight: ${load.weight} lbs',
                                style: const TextStyle(
                                  fontSize:18,
                                ),
                              )
                            ],
                          ),
                          IconButton(
                              icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  //Icons.edit,
                                  color: Colors.black,
                                  size: 32
                              ),
                              onPressed: (){

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SingleLoadView(
                                      load: load,
                                    ),
                                  ),
                                );
                              }
                          )
                        ],
                      ),
                      leading: Icon(Icons.flight),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
