import 'dart:async';
import 'package:bustracking/screens/selectVehical.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../Methods/checkAuth.dart';
import 'AssignedTrips.dart';
import 'EditProfilePage.dart';
import 'MapPage.dart';
import 'Trip History.dart';
import 'Vehicals.dart';
import 'auth.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<DriverHome> {
  final user = FirebaseAuth.instance.currentUser!;
  final DateTime now = DateTime.now();
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  StreamSubscription<Position>? positionStream;
  late Stream<QuerySnapshot> _ongoingTripsStream;
  final AuthChecker _authChecker = AuthChecker();

  @override
  void initState() {
    super.initState();
    _authChecker.startAuthCheck(context);
    getCurrentLiveLocationOfUser();
    _ongoingTripsStream = FirebaseFirestore.instance
        .collection('trips')
        .doc(user.uid)
        .collection('userTrips')
        .where('tripstatus', isEqualTo: 0)
        .snapshots();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _authChecker.stopAuthCheck();
    super.dispose();
  }

  void getCurrentLiveLocationOfUser() {
    positionStream =
        Geolocator.getPositionStream().listen((Position position) {
          setState(() {
            currentPositionOfUser = position;
            LatLng positionOfUserInLatLng =
            LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

            CameraPosition cameraPosition =
            CameraPosition(target: positionOfUserInLatLng, zoom: 15);
            controllerGoogleMap?.animateCamera(
                CameraUpdate.newCameraPosition(cameraPosition));

            // Upload user's live location to Firestore
            FirebaseFirestore.instance
                .collection('locations')
                .doc(user.uid)
                .set({
              'userid': user.uid,
              'latitude': currentPositionOfUser!.latitude,
              'longitude': currentPositionOfUser!.longitude,
            });
          });
        });
  }

  String _calculateTripTime(Timestamp startTime) {
    DateTime tripStartTime = startTime.toDate();
    Duration tripDuration = DateTime.now().difference(tripStartTime);

    int hours = tripDuration.inHours;
    int minutes = tripDuration.inMinutes.remainder(60);
    int seconds = tripDuration.inSeconds.remainder(60);

    return '$hours h, $minutes min, $seconds sec';
  }



  void _handleMenuOption(String option) {
    switch (option) {
      case 'Edit Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileEditPage()),
        );
        break;
      case 'Logout':
        FirebaseAuth.instance.signOut();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Color.fromRGBO(206, 70, 70, 1.0), // Use RGB color if needed
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              Map<String, dynamic>? userData =
              snapshot.data!.data() as Map<String, dynamic>?;
              String? username = userData?['username'];
              String? userImageUrl = userData?['image_url'];

              return PopupMenuButton<String>(
                onSelected: _handleMenuOption,
                itemBuilder: (BuildContext context) {
                  return {'Edit Profile', 'Logout'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: userImageUrl != null
                          ? NetworkImage(userImageUrl)
                          : AssetImage('assets/profile.png') as ImageProvider,
                    ),
                    SizedBox(width: 8),
                    Text(username ?? 'User'),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ongoingTripsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    SizedBox(
                      height: 120, // Adjust the height as needed
                      child: Image.asset(
                        'assets/sltb.png', // Assuming 'unilogo.png' is your university logo
                        fit: BoxFit.contain, // Adjust the fit as needed
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Sri Lanka Transport Board",
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kuliyapitiya Deport',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        Map<String, dynamic>? userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                        String? username = userData?['username'];



                        return Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(200, 125, 125, 1.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome, ${username ?? 'User'}!',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '${now.year} ${DateFormat.MMMM().format(now)} ${now.day}',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '${DateFormat('h:mm:ss a').format(now)}',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            );
          } else {
            return Container(

              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var trip = snapshot.data!.docs[index];
                  return Card(
                    color: Color.fromRGBO(212, 243, 212, 1.0), // RGB with full opacity
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ListTile(
                            title: Text(
                              'On Going Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.red, // Set the text color here
                              ),
                              textAlign: TextAlign.center, // Set the text alignment here
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Start: ${trip['startAddress']}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End: ${trip['destinationAddress']}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Bus: ${trip['selectedVehicleName']}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Trip Time: ${_calculateTripTime(trip['startTime'])}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  DateTime start = trip['startTime'].toDate();
                                  DateTime end = DateTime.now();
                                  Duration tripDuration = end.difference(start);
                                  String formattedDuration =
                                      '${tripDuration.inHours} hours ${tripDuration.inMinutes.remainder(60)} minutes';

                                  trip.reference.update({
                                    'tripstatus': 1,
                                    'endTime': end,
                                    'tripDuration': formattedDuration,
                                  });

                                  // Reference the activetrips document using the userId
                                  var docRef = FirebaseFirestore.instance.collection('activetrips').doc(user.uid);

                                  // Get the document snapshot to check if it exists
                                  var docSnapshot = await docRef.get();

                                  if (docSnapshot.exists) {
                                    // Delete the document if it exists
                                    await docRef.delete();
                                  }






                                },
                                child: Text('Finish'),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text('Are you sure you want to cancel this trip?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              trip.reference.delete();

                                              // Reference the activetrips document using the userId
                                              var docRef = FirebaseFirestore.instance.collection('activetrips').doc(user.uid);

                                              // Get the document snapshot to check if it exists
                                              var docSnapshot = await docRef.get();

                                              if (docSnapshot.exists) {
                                                // Delete the document if it exists
                                                await docRef.delete();
                                              }



                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('Cancel'),
                              ),


                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),

      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       GestureDetector(
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => ProfileEditPage()),
      //           );
      //         },
      //         child: StreamBuilder<DocumentSnapshot>(
      //           stream: FirebaseFirestore.instance
      //               .collection('users')
      //               .doc(FirebaseAuth.instance.currentUser!.uid)
      //               .snapshots(),
      //           builder: (context, snapshot) {
      //             if (!snapshot.hasData) {
      //               return Center(child: CircularProgressIndicator());
      //             }
      //
      //             Map<String, dynamic>? userData =
      //             snapshot.data!.data() as Map<String, dynamic>?;
      //             String? username = userData?['username'];
      //
      //             return UserAccountsDrawerHeader(
      //               accountName: Text(username ?? 'John'), // Replace with actual name
      //               accountEmail: Text('${user.email}'), // Replace with actual email
      //               currentAccountPicture: CircleAvatar(
      //                 backgroundImage: NetworkImage(userData?['image_url'] ?? ''), // Use image_url from Firestore
      //               ),
      //               decoration: BoxDecoration(
      //                 color: Color.fromRGBO(0, 103, 131, 1.0),
      //               ),
      //             );
      //           },
      //         ),
      //       ),
      //       ListTile(
      //         title: Text('Your Location'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => MapPage()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         title: Text('Trips '),
      //         onTap: () {
      //           // Navigator.push(
      //           //   context,
      //           //   MaterialPageRoute(builder: (context) => TripHistoryPage()),
      //           // );
      //         },
      //       ),
      //       ListTile(
      //         title: Text('Vehicles'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => VehicleList()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         title: Text('All the Drivers Map'),
      //         onTap: () {
      //           // Navigator.push(
      //           //   context,
      //           //   MaterialPageRoute(builder: (context) => AllMap()),
      //           // );
      //         },
      //       ),
      //       ListTile(
      //         title: Text('Log out'),
      //         onTap: () {
      //           FirebaseAuth.instance.signOut();
      //
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => AuthScreen()),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: Color.fromRGBO(209, 239, 178, 1.0), // RGB color (red in this case)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.directions),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectVehicle(),
                    ),
                  ); // Navigate to SelectVehicle
                },
              ),


              IconButton(
                icon: Icon(Icons.trip_origin_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignedTrips(),
                    ),
                  ); // Navigate to SelectVehicle
                },
              ),


              IconButton(
                icon: Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(),
                    ),
                  ); // Navigate to SelectVehicle
                },
              ),
              IconButton(
                icon: Icon(Icons.analytics),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripHistoryPage(),
                    ),
                  ); // Navigate to SelectVehicle
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
