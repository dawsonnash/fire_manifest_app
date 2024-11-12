import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import '../Data/load.dart';
// For exporting to pdf
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

// Function to generate the PDF
Future<Uint8List> generatePDF(Load load) async {
  final pdf = pw.Document();

  // Load the image of the NWCG form
  final imageBytes = await rootBundle.load('assets/images/crew_manifest_form.png');
  final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Add content to the PDF with the image as the background
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Background image
            pw.Positioned.fill(
              child: pw.Image(backgroundImage, fit: pw.BoxFit.fitWidth),
            ),
            // Overlay form fields
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: fillFormFields(load),
            ),
          ],
        );
      },
    ),
  );

  // Save the PDF and return it as Uint8List
  return pdf.save();
}

// Function to display the PDF preview
void previewPDF(BuildContext context, Load load) async {
  final pdfBytes = await generatePDF(load);

  // Use the Printing package to show the PDF preview
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
  );
}

pw.Widget fillFormFields(Load load) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Example: Placing crew member data into the form
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Text(
          "${i + 1}. ${load.loadPersonnel[i].name} - ${load.loadPersonnel[i].totalCrewMemberWeight} lbs",
          style: pw.TextStyle(fontSize: 12),
        ),
      pw.SizedBox(height: 10), // Space between sections

      // Example: Placing gear data into the form
      pw.Text("Gear Items:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      for (var gear in load.loadGear)
        pw.Text(
          "${gear.name} - ${gear.weight} lbs",
          style: pw.TextStyle(fontSize: 12),
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
      resizeToAvoidBottomInset:
          false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
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
              icon: Icon(Icons.ios_share, size: 28,),    // Does this work for android, i dont know
              onPressed: () {
                previewPDF(context, widget.load);
              },
              tooltip: 'Export to NWCG Crew Manifest Form',
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
                      widget.load.loadGear.length,
                  itemBuilder: (context, index) {
                    // Calculate the boundary between crew members and gear
                    int numCrewMembers = widget.load.loadPersonnel.length;

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
                    } else {
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
                                    Text(
                                      gearItem.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                    }
                  },
                ),
              ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
