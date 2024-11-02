import 'package:fire_app/create_new_manifest.dart';
import 'package:fire_app/saved_trips.dart';
import 'package:flutter/material.dart';
import '../edit_crew.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Data/gear.dart';
import '../Data/crewmember.dart';
import 'Data/crew.dart';
import 'Data/load.dart';
import 'Data/trip.dart';

void main() async {

  // Set up for Hive that needs to run before starting app
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the Gear adapters
  Hive.registerAdapter(GearAdapter());
  Hive.registerAdapter(CrewMemberAdapter());
  Hive.registerAdapter(LoadAdapter());
  Hive.registerAdapter(TripAdapter());

  // Open a Hive boxes to store objects
  await Hive.openBox<Gear>('gearBox');
  await Hive.openBox<CrewMember>('crewmemberBox');
  await Hive.openBox<Load>('loadBox');
  await Hive.openBox<Trip>('tripBox');

  // Load data from Hive
  crew.loadCrewDataFromHive();
  // do we need to load trip data as well?how does that work

  // start app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Manifest App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        // for theme based text-> style: Theme.of(context).textTheme.headlineMedium,
      ),
      home: const MyHomePage(title: 'Fire Manifesting'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;



  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // APP FUNCTIONS

  // Home Page UI
  @override
  Widget build(BuildContext context) {

    // Style for elevated buttons. Should probably figure out a way
    // to make this universal so we don't have to declare it in every page
    final ButtonStyle style =
    ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 12)
    );

    return Scaffold(

      // appBar: AppBar(
      //
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //
      //   title: Text(widget.title),
      // ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3, // Scales based on 30% of screen height
            color: Colors.deepOrangeAccent,
            child: const Center(
              // Fitted box automatically scales text based on available space
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Fire Manifesting App',
                  textAlign: TextAlign.center,
                  // style: Theme.of(context).textTheme.headlineLarge,
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),


                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [

                Positioned.fill(
                  child: Image.asset('assets/images/logo1.png',
                    fit: BoxFit.cover,  // Cover  entire background
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      // Manifest
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateNewManifest()),
                              );
                              },
                            style: style,
                            child: const Text(
                                'Manifest'
                            )
                        ),
                      ),

                      // View Trips
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SavedTripsView()),
                              );
                            },
                            style: style,
                            child: const Text(
                                'View Trips'
                            )
                        ),
                      ),

                      // Edit Crew
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditCrew()),
                              );
                              },
                            style: style,
                            child: const Text(
                                'Edit Crew'
                            )
                        ),
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
