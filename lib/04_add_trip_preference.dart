import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/04_add_load_preference.dart';

class AddTripPreference extends StatefulWidget {

  final VoidCallback onUpdate;  // Callback to update previous page

  const AddTripPreference({
    required this.onUpdate,
    super.key});

  @override
  State<AddTripPreference> createState() => _AddTripPreferenceState();
}

class _AddTripPreferenceState extends State<AddTripPreference> {

  // New TripPreference object
  late TripPreference tripPreference;
  List<PositionalPreference> positionalPreferenceList = [];
  //List Gear

  @override
  void initState() {
    super.initState();

    // Initialize the TripPreference object with a default name
    // Should add an option that if they click the back arrow and its still 'Untitled' They will lose all data
    tripPreference = TripPreference(tripPreferenceName: 'Untitled');
    // Add the new tripPreference to savedPreferences.tripPreferences
    savedPreferences.tripPreferences.add(tripPreference);

  }
  // Function to edit title
  void _editTitle() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController titleController = TextEditingController(text: tripPreference.tripPreferenceName);

        return AlertDialog(
          title: const Text("Edit Trip Preference Name"),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Trip Preference Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss  dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tripPreference.tripPreferenceName = titleController.text;
                });
                Navigator.of(context).pop(); // Dismiss dialog
                //widget.onUpdate();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Loads all preferences upon screen opening or after creating new one
  void loadPositionalPreferenceList() {
    setState(() {
      positionalPreferenceList = tripPreference.positionalPreferences.toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      backgroundColor: Colors.deepOrangeAccent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 15,
      shadowColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: Size(MediaQuery.of(context).size.width / 1.6, MediaQuery.of(context).size.height / 10),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                tripPreference.tripPreferenceName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editTitle,
            ),
          ],
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                tripPreference.positionalPreferences.isEmpty

                // Container for if user has no preferences
                    ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: const Text(
                    'No preferences added...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
                    : Expanded(
                  child: ListView.builder(
                    itemCount: tripPreference.positionalPreferences.length +
                        tripPreference.gearPreferences.length,
                    itemBuilder: (context, index) {
                      // If index is within the positionalPreferences range
                      // This approach may not work if we are doing drag n drop
                      if (index <
                          tripPreference.positionalPreferences
                              .length) {
                        final posPref = tripPreference.positionalPreferences[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Priority"),
                                Text(posPref.priority.toString()),
                              ],
                            ),
                            title: Text(
                              posPref.crewMembers
                                  .map((member) => member.name)
                                  .join(', '),
                              style:
                              TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                "Load Preference: ${loadPreferenceMap[posPref.loadPreference]}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {tripPreference
                                      .positionalPreferences
                                      .removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      }
                      // Handle gearPreferences
                      else {
                        final gearIndex = index -
                            tripPreference.positionalPreferences
                                .length;
                        final gearPref = tripPreference.gearPreferences[gearIndex];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Priority"),
                                Text(gearPref.priority.toString()),
                              ],
                            ),
                            title: Text(
                              gearPref.gear
                                  .map((member) => member.name)
                                  .join(', '),
                              style:
                              TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                            Text(
                                "Load Preference: ${loadPreferenceMap[gearPref.loadPreference]}"),                                  trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                tripPreference.gearPreferences
                                    .removeAt(gearIndex);
                              });
                            },
                          ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Add Load Preference Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddLoadPreference(
                            tripPreference: tripPreference,
                            onUpdate:
                            loadPositionalPreferenceList, // refresh list on return
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          tripPreference.positionalPreferences
                              .add(result);
                        });
                      }
                    },
                    style: style,
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.black, size: 32),
                        Flexible(
                          child: Text(
                            'Load Preference',
                            textAlign: TextAlign.center,
                            softWrap: true,
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
