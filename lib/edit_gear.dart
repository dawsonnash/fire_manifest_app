import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Data/crew.dart';
import 'Data/gear.dart';
import 'main.dart';

class EditGear extends StatefulWidget {
  const EditGear({super.key});

  @override
  State<EditGear> createState() => _EditGearState();
}
class _EditGearState extends State<EditGear>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gear',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrangeAccent,

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
              itemCount: crew.gear.length,
              itemBuilder: (context, index) {

                final gearItem = crew.gear[index];

                // Display gear data in a scrollable list
                return Card(
                  child: Container(
                    decoration: BoxDecoration(
                      // Could change color here
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: ListTile(
                      iconColor: Colors.black,

                      title: Text(
                        gearItem.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${gearItem.weight} lbs'),
                      leading: const Icon(Icons.work_outline_outlined),
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
