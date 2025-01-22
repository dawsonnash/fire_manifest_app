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
import '06_edit_trip.dart';
import 'Data/load.dart';

// Generates PDF
Future<Uint8List> generateTripPDF(Trip trip, String manifestForm, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
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
        fillFormFieldsOF252(load, pageIndex, totalPages, pageItems, helicopterNum, departure, destination, manifestPreparer);
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
    final allItems = [
      ...load.loadPersonnel,
      ...load.loadGear,
      ...load.customItems,
    ];

    // Paginate items for `of252`, use a single page for `pms245`
    final paginatedItems = manifestForm == 'of252'
        ? paginateItems(allItems, maxItemsPerPage)
        : [allItems];

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
                      ? const pw.EdgeInsets.all(32)
                      : const pw.EdgeInsets.all(22),
                  child: fillFormFields(
                    load,
                    i + 1, // Current page index (1-based)
                    paginatedItems.length, // Total pages for the current load
                    paginatedItems[i], // Items for the current page
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
void previewTripPDF(BuildContext context, Trip trip, String manifestForm, String? helicopterNum, String? departure, String? destination, String? manifestPreparer) async {
  Uint8List pdfBytes;
  late PdfPageFormat pageFormat;

  // Determine the correct format based on the manifest form
  if (manifestForm == 'pms245') {
    pdfBytes = await generateTripPDF(trip, 'pms245', null, null, null, null);
    pageFormat = PdfPageFormat.letter; // PMS245 requires Letter format
  } else if (manifestForm == 'of252') {
    pdfBytes = await generateTripPDF(trip, 'of252', helicopterNum, departure,destination, manifestPreparer);
    pageFormat = PdfPageFormat.a4; // OF252 requires A4 format
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Display the PDF with the appropriate page format
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
    usePrinterSettings: false, // Enforce the specified format
    format: pageFormat,        // Dynamically set the format based on the manifest type
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
            Expanded(
              child: Text(
              widget.trip.tripName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Add this
                  maxLines: 1, 
                        ),
            ),
            Spacer(),
            IconButton(
                icon: Icon(Icons.more_vert, color: Colors.black,),
                onPressed: (){
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Export
                          ListTile(
                            leading: Icon(Icons.ios_share, color: Colors.black),
                            title: Text('Export', style: TextStyle(color: Colors.black),),
                            onTap: () {
                              Navigator.of(context)
                                  .pop();
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
                                            // Show additional input dialog for `of252`
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AdditionalInfoDialog(
                                                  onConfirm: (
                                                      String helicopterNum,
                                                      String departure,
                                                      String destination,
                                                      String manifestPreparer) {
                                                    previewTripPDF(context, widget.trip, 'of252', helicopterNum, departure, destination, manifestPreparer);
                                                  },
                                                );
                                              },
                                            );
                                          }  else {
                                            // Fixed-Wing manifest
                                            previewTripPDF(context, widget.trip, 'pms245', null, null, null, null);
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
                          ),

                          // Edit
                          ListTile(
                            leading: Icon(Icons.edit, color: Colors.black),
                            title: Text('Edit Trip', style: TextStyle(color: Colors.black),),
                            onTap: () {
                              Navigator.of(context)
                                  .pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditTrip(trip: widget.trip,)),
                              );
                            },
                          ),

                          // Delete
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete trip', style: TextStyle(color: Colors.black),),
                            onTap: () {
                              Navigator.of(context)
                                  .pop();
                              // if (savedTrips.savedTrips.isNotEmpty) {}
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Confirm Deletion',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this trip?',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog without deleting
                                        },
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                              color: Colors.grey),
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
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                              color: Colors.red),
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
                }
            ),
        ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            // child: ImageFiltered(
            //     imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            //     // Blur effect
            //     child: Image.asset('assets/images/logo1.png',
            //       fit: BoxFit.cover, // Cover  entire background
            //       width: double.infinity,
            //       height: double.infinity,
            //     )
            // ),
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
                            color: Colors.grey[800]?.withValues(alpha: 0.9),
                            border: Border(bottom: BorderSide(color: Colors.grey, width: 1)), // Add a border
                          ),
                          child: ListTile(
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
                                          fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Weight: ${load.weight} lbs',
                                      style: const TextStyle(
                                        fontSize:18,
                                        color: Colors.white,

                                      ),
                                    )
                                  ],
                                ),
                                IconButton(
                                    icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        //Icons.edit,
                                        color: Colors.deepOrangeAccent,
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
                            leading: Icon(Icons.numbers,color: Colors.deepOrangeAccent,),
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
  final Function(
      String helicopterNum,
      String departure,
      String destination,
      String manifestPreparer) onConfirm;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Adjust padding
      title: const Text(
        'Additional Information',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView( // Wrap content in a scrollable view
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _helicopterNumController,
                decoration: const InputDecoration(
                  labelText: 'Enter helicopter tail #:',
                ),
                maxLines: 1, // Single-line input
                textCapitalization: TextCapitalization.characters, // Automatically capitalize all characters
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6), // Limit to 25 characters
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _departureController,
                decoration: const InputDecoration(
                  labelText: 'Enter departure:',
                ),
                maxLines: 1, // Single-line input
                textCapitalization: TextCapitalization.words, // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words, // Capitalize only the first character
                decoration: const InputDecoration(
                  labelText: 'Enter destination:',
                ),
                maxLines: 1, // Single-line input
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
              ),
            ),Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _manifestPreparerController,
                decoration: const InputDecoration(
                  labelText: 'Enter manifest preparer:',
                ),
                maxLines: 1, // Single-line input
                textCapitalization: TextCapitalization.words, // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20), // Limit to 25 characters
                ],
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
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 18),
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
          child: const Text(
            'Confirm',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

}
