import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
// For exporting to pdf
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../CodeShare/variables.dart';
import '../Data/crewmember.dart';
import '../Data/customItem.dart';
import '../Data/gear.dart';
import '../Data/load.dart';
import '../Data/load_accoutrements.dart';
import '../Data/sling.dart';

const int maxItemsPerPage = 14; // Maximum items (crew + gear + custom) per page

const int maxTotalItemsPerPage = 16;
const int maxNormItemsPerPage = 14;

// Helper function to split items into pages based on the required number of pages
List<List<dynamic>> paginateItems(List<dynamic> items, int totalPages) {
  List<List<dynamic>> pages = [];
  for (int i = 0; i < totalPages; i++) {
    pages.add([]);
  }

  int index = 0;
  for (var item in items) {
    pages[index ~/ maxTotalItemsPerPage].add(item);
    index++;
  }

  return pages;
}

// Function to calculate the required number of pages
int calculatePagesNeeded(int totalItems, int numHaz) {
  int numNorm = totalItems - numHaz;

  int totalLengthPagesNeeded = (totalItems / maxTotalItemsPerPage).ceil();
  int nonItemPagesNeeded = (numNorm / maxNormItemsPerPage).ceil();

  return totalLengthPagesNeeded > nonItemPagesNeeded ? totalLengthPagesNeeded : nonItemPagesNeeded;
}

// Generates PDF
Future<Uint8List> generatePDF(Load load, String manifestForm, bool isExternal, String? helicopterNum, String? departure, String? destination, String? manifestPreparer, bool? exportAsLoad) async {
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
    fillFormFields = (load, pageIndex, totalPages, pageItems) => fillFormFieldsOF252(load, isExternal, pageIndex, totalPages, pageItems, helicopterNum, departure, destination, manifestPreparer, null);
    pageFormat = PdfPageFormat.a4;
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Load the background image
  final imageBytes = await rootBundle.load(imagePath);
  final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Handle normal loads OR process each sling individually
  if (isExternal) {
    if (load.slings != null && load.slings!.isNotEmpty) {
      if (!exportAsLoad!) {
        for (var sling in load.slings!) {
          // Aggregate items in the current sling
          List<dynamic> slingItems = [
            ...sling.loadGear,
            ...sling.loadAccoutrements,
            ...sling.customItems,
          ];

          slingItems.sort((a, b) {
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

          // Count hazmat items in the sling
          int numHaz = slingItems.where((item) => item is Gear && item.isHazmat).length;

          // Calculate the required number of pages for this sling
          int totalPages = calculatePagesNeeded(slingItems.length, numHaz);

          // Paginate items for the sling if `of252`
          final paginatedItems = manifestForm == 'of252' ? paginateItems(slingItems, totalPages) : [slingItems];

          // Generate pages for this sling
          for (int i = 0; i < paginatedItems.length; i++) {
            pdf.addPage(
              pw.Page(
                pageFormat: pageFormat,
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
                        child: fillFormFieldsOF252(
                          load,
                          isExternal,
                          i + 1,
                          // Page index (1-based)
                          paginatedItems.length,
                          // Total pages
                          paginatedItems[i],
                          // Items on the current page
                          helicopterNum,
                          departure,
                          destination,
                          manifestPreparer,
                          sling,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }
        }
      }
      // Export as Slings
      else {
        // Combine loadAccoutrements and loadGear from all slings
        List<dynamic> slingItems = load.slings?.expand((sling) => [...sling.loadGear, ...sling.loadAccoutrements]).toList() ?? [];

        // Create a map to merge items with the same name (without modifying originals)
        Map<String, dynamic> mergedItems = {};

        for (var item in slingItems) {
          String itemName = item.name;

          if (mergedItems.containsKey(itemName)) {
            // If item already exists in map, create a new merged object
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

        // Convert map back to a new list (without modifying the original objects)
        List<dynamic> combinedSlingItems = mergedItems.values.toList();

        combinedSlingItems.sort((a, b) {
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

        // Count hazmat items in the sling
        int numHaz = combinedSlingItems.where((item) => item is Gear && item.isHazmat).length;

        // Calculate the required number of pages for this sling
        int totalPages = calculatePagesNeeded(combinedSlingItems.length, numHaz);

        // Paginate items for the sling if `of252`
        final paginatedItems = manifestForm == 'of252' ? paginateItems(combinedSlingItems, totalPages) : [combinedSlingItems];

        // Generate pages for this sling
        for (int i = 0; i < paginatedItems.length; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
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
                      child: fillFormFieldsOF252(
                        load,
                        isExternal,
                        i + 1, // Page index (1-based)
                        paginatedItems.length, // Total pages
                        paginatedItems[i], // Items on the current page
                        helicopterNum,
                        departure,
                        destination,
                        manifestPreparer,
                        null,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
    }
  } else {
    // Handle normal loads (not external or no slings)
    List<dynamic> allItems = [
      ...load.loadPersonnel,
      ...load.loadGear,
      ...load.customItems,
    ];

    int numHaz = allItems.where((item) => item is Gear && item.isHazmat).length;
    int totalPages = calculatePagesNeeded(allItems.length, numHaz);
    final paginatedItems = manifestForm == 'of252' ? paginateItems(allItems, totalPages) : [allItems];

    for (int i = 0; i < paginatedItems.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
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

  return pdf.save();
}

// Display preview
void previewPDF(
    BuildContext context, Load load, String manifestForm, bool isExternal, String? helicopterNum, String? departure, String? destination, String? manifestPreparer, bool? exportAsLoad) async {
  Uint8List pdfBytes;
  late PdfPageFormat pageFormat;

  // Determine the correct format based on the manifest form
  if (manifestForm == 'pms245') {
    pdfBytes = await generatePDF(load, 'pms245', isExternal, null, null, null, null, null);
    pageFormat = PdfPageFormat.letter; // PMS245 requires Letter format
  } else if (manifestForm == 'of252') {
    pdfBytes = await generatePDF(load, 'of252', isExternal, helicopterNum, departure, destination, manifestPreparer, exportAsLoad);
    pageFormat = PdfPageFormat.a4; // OF252 requires A4 format
  } else {
    throw Exception('Invalid manifest form type: $manifestForm');
  }

  // Display the PDF with the appropriate page format
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async {
      return await generatePDF(load, manifestForm, isExternal, helicopterNum, departure, destination, manifestPreparer, exportAsLoad);
    },
    format: pageFormat, // Explicitly setting format
    usePrinterSettings: false, // Ensure iOS does not override the format
  );
}

// Helicopter/External Manifest
pw.Widget fillFormFieldsOF252(
    Load load, bool isExternal, int pageIndex, int totalPages, List<dynamic> pageItems, String? helicopterNum, String? departure, String? destination, String? manifestPreparer, Sling? sling) {
  const double yOffset = 112; // Adjust this value to move everything vertically
  const double xOffset = 6; // Adjust this value to move everything horizontally
  const double itemSpacing = 27.4; // Adjust spacing between items
  const double fontSizeOF252 = 18.0;
  const double bottomOffset = 610; // Position for the total load weight
  const int maxHazmatSlots = 2; // Number of hazmat slots per page
  bool exportAsLoad = sling == null ? true : false;

  DateTime today = DateTime.now();
  String formattedDate = DateFormat('MM/dd/yyyy').format(today);
  String formattedTime = DateFormat('hh:mm a').format(today);

  // Separate normal and hazmat items (assuming items are already sorted)
  List<dynamic> hazmatItems = pageItems.where((item) => item is Gear && item.isHazmat).toList();
  List<dynamic> normalItems = pageItems.where((item) => !(item is Gear && item.isHazmat)).toList();
// Sort normalItems to place LoadAccoutrement items first
  normalItems.sort((a, b) {
    if (a is LoadAccoutrement && b is! LoadAccoutrement) {
      return -1; // `a` comes first
    } else if (a is! LoadAccoutrement && b is LoadAccoutrement) {
      return 1; // `b` comes first
    }
    return 0; // Keep original order otherwise
  });

  // Start placing hazmat items from the bottom of the page, moving upward
  double hazmatPosition = yOffset + bottomOffset - (hazmatItems.length * itemSpacing);

  List<pw.Widget> hazmatWidgets = [];

  double adjustedPosition = yOffset + 606; // Start from the bottom of the page

// **Hazmat Items and Weights (Bottom-Up)**
  for (var i = 0; i < hazmatItems.length; i++) {
    // Move upwards instead of downwards
    adjustedPosition -= itemSpacing;

    // Add a slight extra offset after two items for better spacing
    if (i == 2) {
      adjustedPosition -= 18; // Increase spacing upward
    }

    // **Hazmat Item Quantity**
    hazmatWidgets.add(
      pw.Positioned(
        left: i < 2 ? xOffset - 8 : xOffset - 2, // (x1) should be farther left than just 1
        top: adjustedPosition,
        child: pw.Text(
          i < 2 ? '(x${hazmatItems[i].quantity})' : '${hazmatItems[i].quantity}',
          style: pw.TextStyle(fontSize: fontSizeOF252),
        ),
      ),
    );

    // **Hazmat Item Name**
    hazmatWidgets.add(
      pw.Positioned(
        left: xOffset + 32, // Left-side placement for item names
        top: adjustedPosition,
        child: pw.Text(
          i >= 2 ? '${hazmatItems[i].name} (HAZMAT)' : hazmatItems[i].name, // Fix condition
          style: pw.TextStyle(fontSize: fontSizeOF252),
        ),
      ),
    );

    // **Hazmat Item Weight**
    hazmatWidgets.add(
      pw.Positioned(
        left: xOffset + 442, // Right-side placement for weights
        top: adjustedPosition,
        child: pw.Text(
          "${hazmatItems[i].totalGearWeight} lb",
          style: pw.TextStyle(fontSize: fontSizeOF252),
        ),
      ),
    );
  }

  if (isExternal) {
    return pw.Stack(
      children: [
        // **Normal Items (Top-Down)**
        for (var i = 0; i < normalItems.length; i++)
          pw.Positioned(
            left: xOffset + 32,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              normalItems[i] is LoadAccoutrement
                  ? normalItems[i].name
                  : normalItems[i] is Gear
                      ? normalItems[i].name
                      : normalItems[i].name,
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

        ...hazmatWidgets,

        // **Weights for All Items**
        for (var i = 0; i < normalItems.length; i++)
          pw.Positioned(
            left: xOffset + 442,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              "${normalItems[i] is LoadAccoutrement ? normalItems[i].weight : normalItems[i] is Gear ? normalItems[i].totalGearWeight : normalItems[i].weight} lb",
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

        // **Gear Quantities**
        for (var i = 0; i < normalItems.length; i++)
          if (normalItems[i] is! CustomItem)
            pw.Positioned(
              left: xOffset - 2,
              top: yOffset + 150 + (i * itemSpacing),
              child: pw.Text(
                "${normalItems[i].quantity}",
                style: pw.TextStyle(fontSize: fontSizeOF252),
              ),
            ),

        // **Total Load Weight (Last Page Only)**
        if (pageIndex == totalPages)
          !exportAsLoad
              ? pw.Positioned(
                  left: xOffset + 442,
                  top: yOffset + 610,
                  child: pw.Text(
                    '${sling?.weight.toString()} lb',
                    style: pw.TextStyle(fontSize: fontSizeOF252),
                  ),
                )
              : pw.Positioned(
                  left: xOffset + 442,
                  top: yOffset + 610,
                  child: pw.Text(
                    '${load.weight.toString()} lb',
                    style: pw.TextStyle(fontSize: fontSizeOF252),
                  ),
                ),

        // **Current Date**
        pw.Positioned(
          left: xOffset + 459,
          top: 15,
          child: pw.Text(
            formattedDate,
            style: pw.TextStyle(fontSize: AppData.text14),
          ),
        ),

        // **Current Time**
        pw.Positioned(
          left: xOffset + 350,
          top: 15,
          child: pw.Text(
            formattedTime,
            style: pw.TextStyle(fontSize: AppData.text14),
          ),
        ),

        // **Page Number**
        pw.Positioned(
            left: xOffset - 6,
            top: yOffset + 610,
            child: !exportAsLoad
                ? pw.Text(
                    'Load #${load.loadNumber}, Sling #${sling?.slingNumber}, Page $pageIndex of $totalPages',
                    style: pw.TextStyle(
                      fontSize: AppData.text16,
                      color: PdfColors.black,
                    ),
                  )
                : pw.Text(
                    'Load #${load.loadNumber}, Page $pageIndex of $totalPages',
                    style: pw.TextStyle(
                      fontSize: AppData.text16,
                      color: PdfColors.black,
                    ),
                  )),

        // **Helicopter Tail Number**
        pw.Positioned(
          left: xOffset + 70,
          top: 13,
          child: pw.Text(
            helicopterNum!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Departure Location**
        pw.Positioned(
          left: xOffset + 56,
          top: 55,
          child: pw.Text(
            departure!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Destination**
        pw.Positioned(
          left: xOffset + 336,
          top: 55,
          child: pw.Text(
            destination!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Manifest Preparer**
        pw.Positioned(
          left: xOffset + 135,
          top: yOffset + 656,
          child: pw.Text(
            manifestPreparer!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),
      ],
    );
  } else {
    return pw.Stack(
      children: [
        // **Normal Items (Top-Down)**
        for (var i = 0; i < normalItems.length; i++)
          pw.Positioned(
            left: xOffset + 32,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              normalItems[i] is CrewMember
                  ? normalItems[i].name
                  : normalItems[i] is Gear
                      ? normalItems[i].name
                      : normalItems[i].name,
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

        ...hazmatWidgets,

        // **Weights for All Items**
        for (var i = 0; i < normalItems.length; i++)
          pw.Positioned(
            left: xOffset + 442,
            top: yOffset + 150 + (i * itemSpacing),
            child: pw.Text(
              "${normalItems[i] is CrewMember ? normalItems[i].flightWeight : normalItems[i] is Gear ? normalItems[i].totalGearWeight : normalItems[i].totalGearWeight} lb",
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

        // **Gear Quantities**
        for (var i = 0; i < normalItems.length; i++)
          if (normalItems[i] is Gear)
            pw.Positioned(
              left: xOffset - 2,
              top: yOffset + 150 + (i * itemSpacing),
              child: pw.Text(
                "${normalItems[i].quantity}",
                style: pw.TextStyle(fontSize: fontSizeOF252),
              ),
            ),

        // **Total Load Weight (Last Page Only)**
        if (pageIndex == totalPages)
          pw.Positioned(
            left: xOffset + 442,
            top: yOffset + 610,
            child: pw.Text(
              '${load.weight.toString()} lb',
              style: pw.TextStyle(fontSize: fontSizeOF252),
            ),
          ),

        // **Current Date**
        pw.Positioned(
          left: xOffset + 459,
          top: 15,
          child: pw.Text(
            formattedDate,
            style: pw.TextStyle(fontSize: AppData.text14),
          ),
        ),

        // **Current Time**
        pw.Positioned(
          left: xOffset + 350,
          top: 15,
          child: pw.Text(
            formattedTime,
            style: pw.TextStyle(fontSize: AppData.text14),
          ),
        ),

        // **Page Number**
        pw.Positioned(
          left: xOffset - 6,
          top: yOffset + 610,
          child: pw.Text(
            'Load #${load.loadNumber}, Page $pageIndex of $totalPages',
            style: pw.TextStyle(
              fontSize: AppData.text16,
              color: PdfColors.black,
            ),
          ),
        ),

        // **Helicopter Tail Number**
        pw.Positioned(
          left: xOffset + 70,
          top: 13,
          child: pw.Text(
            helicopterNum!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Departure Location**
        pw.Positioned(
          left: xOffset + 56,
          top: 55,
          child: pw.Text(
            departure!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Destination**
        pw.Positioned(
          left: xOffset + 336,
          top: 55,
          child: pw.Text(
            destination!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),

        // **Manifest Preparer**
        pw.Positioned(
          left: xOffset + 135,
          top: yOffset + 656,
          child: pw.Text(
            manifestPreparer!,
            style: pw.TextStyle(fontSize: AppData.text16),
          ),
        ),
      ],
    );
  }
}

// Fixed-Wing
pw.Widget fillFormFieldsPMS245(Load load) {
  const double yOffset = 65; // Adjust this value to move everything down
  const double itemSpacing = 15; // Adjust this value to control spacing between items

  int subtotalCrewMemberWeight = load.loadPersonnel.fold(0, (sum, crewMember) => sum + crewMember.flightWeight);
  int subtotalGearWeight = load.loadGear.fold(0, (sum, gear) => sum + gear.totalGearWeight);
  DateTime today = DateTime.now();
  String formattedDate = DateFormat('MM/dd/yyyy').format(today);

  return pw.Stack(
    children: [
      // Crew Name
      pw.Positioned(
        left: 96,
        top: yOffset - 58,
        child: pw.Text(
          AppData.crewName,
          style: pw.TextStyle(fontSize: AppData.text10),
        ),
      ),
      // Crew Members
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            load.loadPersonnel[i].name,
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),
      // Gear
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].name} (x${load.loadGear[j].quantity})",
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),

      // Custom Items
      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: 18,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            load.customItems[k].name,
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),

      // CrewMember Weights
      for (var i = 0; i < load.loadPersonnel.length; i++)
        pw.Positioned(
          left: 267,
          top: yOffset + 150 + (i * itemSpacing),
          child: pw.Text(
            "${load.loadPersonnel[i].flightWeight} lb",
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),

      // Gear Weights
      for (var j = 0; j < load.loadGear.length; j++)
        pw.Positioned(
          left: 323,
          top: yOffset + 150 + ((load.loadPersonnel.length + j) * itemSpacing),
          child: pw.Text(
            "${load.loadGear[j].totalGearWeight} lb",
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),
      for (var k = 0; k < load.customItems.length; k++)
        pw.Positioned(
          left: 323,
          top: yOffset + 150 + ((load.loadPersonnel.length + load.loadGear.length + k) * itemSpacing),
          child: pw.Text(
            "${load.customItems[k].weight} lb",
            style: pw.TextStyle(fontSize: AppData.text12),
          ),
        ),

      // Total Load Weight
      pw.Positioned(
        left: 494,
        top: yOffset + 545,
        child: pw.Text(
          '${load.weight.toString()} lb',
          style: pw.TextStyle(fontSize: AppData.text12),
        ),
      ),

      // # of passengers on page
      pw.Positioned(
        left: 110,
        top: yOffset + 545,
        child: pw.Text(
          load.loadPersonnel.length.toString(),
          style: pw.TextStyle(fontSize: AppData.text12),
        ),
      ),

      // Weight subtotals: CrewMembers
      pw.Positioned(
        left: 260,
        top: yOffset + 545,
        child: pw.Text(
          '${subtotalCrewMemberWeight.toString()} lb',
          style: pw.TextStyle(fontSize: AppData.text12),
        ),
      ),

      // Weight subtotals: Gear
      pw.Positioned(
        left: 320,
        top: yOffset + 545,
        child: pw.Text(
          '${subtotalGearWeight.toString()} lb',
          style: pw.TextStyle(fontSize: AppData.text12),
        ),
      ),

      // Current date
      pw.Positioned(
        left: 390,
        top: yOffset + 580,
        child: pw.Text(
          formattedDate.toString(),
          style: pw.TextStyle(fontSize: AppData.text12),
        ),
      ),
    ],
  );
}

class SingleLoadView extends StatefulWidget {
  // This page requires a trip to be passed to it
  final Load load;
  final bool isExternal;

  //final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const SingleLoadView({super.key, required this.load, required this.isExternal
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Load ${widget.load.loadNumber}',
              style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
            ),
            Text(
              ' • ${widget.load.weight} lb',
              style: TextStyle(fontSize: 18, color: AppColors.textColorPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, size: AppData.text28, color: AppColors.textColorPrimary),
            // Does this work for android, i dont know
            onPressed: () {
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
                          if (!widget.isExternal) Center(child: Text('Fixed-Wing Manifest', style: TextStyle(fontSize: AppData.text18, color: AppColors.textColorPrimary))),
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
                                  onConfirm: (String helicopterNum, String departure, String destination, String manifestPreparer, bool? exportAsLoad) {
                                    if (widget.isExternal) {
                                      previewPDF(context, widget.load, 'of252', widget.isExternal, helicopterNum, departure, destination, manifestPreparer, exportAsLoad);
                                    } else {
                                      previewPDF(context, widget.load, 'of252', widget.isExternal, helicopterNum, departure, destination, manifestPreparer, null);
                                    }
                                  },
                                  isExternal: widget.isExternal,
                                );
                              },
                            );
                          } else {
                            // Fixed-Wing manifest
                            previewPDF(context, widget.load, 'pms245', widget.isExternal, null, null, null, null, null);
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

            tooltip: 'Export all loads to a manifest form',
          ),
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
                    child: widget.isExternal
                        ? ListView.builder(
                            itemCount: widget.load.slings?.length ?? 0, // Number of slings in this load
                            itemBuilder: (context, slingIndex) {
                              final sling = widget.load.slings![slingIndex];

                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.textFieldColor,
                                  border: Border(top: BorderSide(color: Colors.black, width: 1)), // Add a border
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                                  child: ExpansionTile(
                                    iconColor: Colors.white,
                                    // Color of the expand/collapse arrow
                                    collapsedIconColor: Colors.white,
                                    leading: Transform.scale(
                                      scale: 1.5,
                                      child: SvgPicture.asset(
                                        'assets/icons/sling_icon.svg', // Your SVG file path
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn), // Apply color dynamically
                                      ),
                                    ),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sling #${sling.slingNumber}',
                                                style: TextStyle(
                                                  fontSize: AppData.text22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textColorPrimary,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Weight: ${sling.weight} lb',
                                                      style: TextStyle(
                                                        fontSize: AppData.text18,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' • ${sling.loadGear.fold(0, (sum, gear) => sum + gear.quantity)} items',
                                                      style: TextStyle(
                                                        fontSize: AppData.text18,
                                                        fontWeight: FontWeight.normal,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      // Load Accoutrements Section (Displayed First)
                                      if (sling.loadAccoutrements.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: sling.loadAccoutrements.map((accoutrement) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.loadAccoutrementBlueGrey,
                                                border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                                              ),
                                              child: ListTile(
                                                leading: Icon(Icons.link),
                                                title: Text(
                                                  accoutrement.name,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  style: TextStyle(fontSize: AppData.text20, color: Colors.black, fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Text(
                                                  'Weight: ${accoutrement.weight} lb',
                                                  style: TextStyle(color: Colors.black),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),

                                      // Gear Section
                                      if (sling.loadGear.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: sling.loadGear.map((gearItem) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: gearItem.isPersonalTool ? AppColors.toolBlue.withValues(alpha: 0.9) : AppColors.gearYellow.withValues(alpha: 0.9),
                                                border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                                              ),
                                              child: ListTile(
                                                leading: Icon(Icons.work_outline_outlined),
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  '${gearItem.name} ',
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(fontSize: AppData.text20, color: Colors.black, fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                              if (gearItem.isHazmat)
                                                                Icon(
                                                                  FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                                  color: Colors.red,
                                                                  size: AppData.text18,
                                                                ),
                                                              Text(
                                                                ' (x${gearItem.quantity})',
                                                                style: TextStyle(fontSize: AppData.text18),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            'Weight: ${gearItem.totalGearWeight} lb',
                                                            style: TextStyle(fontSize: AppData.text18),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),

                                      // Custom Items Section
                                      if (sling.customItems.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: sling.customItems.map((customItem) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.gearYellow,
                                                border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                                              ),
                                              child: ListTile(
                                                iconColor: Colors.black,
                                                leading: Icon(Icons.inventory_2_outlined),
                                                title: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      customItem.name,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontSize: AppData.text22,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Weight: ${customItem.weight} lb',
                                                      style: TextStyle(
                                                        fontSize: AppData.text18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: widget.load.loadPersonnel.length + widget.load.loadGear.length + widget.load.customItems.length,
                            itemBuilder: (context, index) {
                              int numCrewMembers = widget.load.loadPersonnel.length;
                              int numGearItems = widget.load.loadGear.length;

                              if (index < numCrewMembers) {
                                // Display a crew member
                                final crewmember = widget.load.loadPersonnel[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor, // Background color
                                    border: Border(top: BorderSide(color: Colors.black, width: 1)), // Add a border
                                  ),
                                  child: GestureDetector(
                                    onLongPress: () {
                                      // Show a crew member's position when the tile is held
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${crewmember.name} • ${crewmember.getPositionTitle(crewmember.position)}',
                                            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text18),
                                          ),
                                          backgroundColor: AppColors.textFieldColor2,
                                          duration: Duration(seconds: 2), // How long the message appears
                                        ),
                                      );
                                    },
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
                                                  fontSize: AppData.text22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textColorPrimary,
                                                ),
                                              ),
                                              Text(
                                                'Flight Weight: ${crewmember.flightWeight} lb',
                                                style: TextStyle(
                                                  fontSize: AppData.text18,
                                                  color: AppColors.textColorPrimary,
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
                                return Container(
                                  decoration: BoxDecoration(
                                    color: gearItem.isPersonalTool
                                        ? AppColors.toolBlue.withValues(alpha: 0.9) // Color for personal tools
                                        : AppColors.gearYellow.withValues(alpha: 0.9), // Background color
                                    border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Add a border
                                  ),
                                  child: GestureDetector(
                                    onLongPress: () {
                                      // Show a crew member's position when the tile is held
                                      if (gearItem.quantity > 1) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${gearItem.name} • ${gearItem.weight} lb each',
                                              style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text18),
                                            ),
                                            backgroundColor: AppColors.textFieldColor2,
                                            duration: Duration(seconds: 2), // How long the message appears
                                          ),
                                        );
                                      }
                                    },
                                    child: ListTile(
                                      iconColor: Colors.black,
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '${gearItem.name} ',
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(fontSize: AppData.text22, fontWeight: FontWeight.bold, color: Colors.black),
                                                      ),
                                                    ),
                                                    if (gearItem.isHazmat)
                                                      Icon(
                                                        FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                        color: Colors.red, // Red color for hazard
                                                        size: AppData.text18, // Icon size
                                                      ),
                                                    Text(
                                                      ' (x${gearItem.quantity})',
                                                      style: TextStyle(fontSize: AppData.text18, color: Colors.black),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Weight: ${gearItem.totalGearWeight} lb',
                                                  style: TextStyle(fontSize: AppData.text18, color: Colors.black),
                                                ),
                                              ],
                                            ),
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
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.gearYellow, // Background color
                                    border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Add a border
                                  ),
                                  child: ListTile(
                                    iconColor: Colors.black,
                                    leading: Icon(Icons.inventory_2_outlined),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          customItem.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: AppData.text22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Weight: ${customItem.weight} lb',
                                          style: TextStyle(
                                            fontSize: AppData.text18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalInfoDialog extends StatefulWidget {
  final Function(String helicopterNum, String departure, String destination, String manifestPreparer, bool? exportAsLoad) onConfirm;

  const AdditionalInfoDialog({required this.onConfirm, super.key, required this.isExternal});

  final bool isExternal;

  @override
  State<AdditionalInfoDialog> createState() => _AdditionalInfoDialogState();
}

class _AdditionalInfoDialogState extends State<AdditionalInfoDialog> {
  final TextEditingController _helicopterNumController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _manifestPreparerController = TextEditingController();
  bool exportAsLoad = true;

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
                decoration: InputDecoration(labelText: 'Enter helicopter tail #:', labelStyle: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.characters,
                // Automatically capitalize all characters
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6), // Limit to 25 characters
                ],
                style: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _departureController,
                decoration: InputDecoration(labelText: 'Enter departure:', labelStyle: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
                style: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                decoration: InputDecoration(labelText: 'Enter destination:', labelStyle: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16), // Limit to 25 characters
                ],
                style: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _manifestPreparerController,
                decoration: InputDecoration(labelText: 'Enter manifest preparer:', labelStyle: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary)),
                maxLines: 1,
                // Single-line input
                textCapitalization: TextCapitalization.words,
                // Capitalize only the first character
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20), // Limit to 25 characters
                ],
                style: TextStyle(fontSize: AppData.text16,color: AppColors.textColorPrimary),
              ),
            ),
            // **Show toggle only if it's an external load**
            if (widget.isExternal)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Export as:  ",
                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                    ),
                    Expanded(
                      // Ensures consistent sizing without fixed width
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: true,
                            label: Text("Load", style: TextStyle(color: Colors.black, fontSize: AppData.text16),),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text("Slings", style: TextStyle(color: Colors.black, fontSize: AppData.text16),),
                          ),
                        ],
                        selected: {exportAsLoad ?? false},
                        // Default to "Load"
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            exportAsLoad = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.fireColor; // Selected color
                              }
                              return AppColors.textFieldColor2; // Default unselected color
                            },
                          ),
                          foregroundColor: WidgetStateProperty.all(Colors.black), // Text color
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
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
            widget.onConfirm(helicopterNum, departure, destination, manifestPreparer, exportAsLoad); // Pass collected data to the callback
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
