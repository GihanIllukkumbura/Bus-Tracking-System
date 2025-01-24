import 'dart:async';
import 'package:clients/screens/auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clients/screens/phone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'EditProfilePage.dart';
import 'MapPage.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<UserHome> {
  final user = FirebaseAuth.instance.currentUser!;
  Position? currentPositionOfUser;
  LatLng? driverPosition;
  GoogleMapController? controllerGoogleMap;

  final Completer<GoogleMapController> _controller = Completer();

  StreamSubscription<Position>? positionStream;
  double _distance = 0.0;
  bool trackingStopped = false; // Flag to track if tracking is stopped
  bool notifiedLessThan1km = false;
  bool notifiedLessThan500m = false;
  bool notifiedBeyond1_5km = false;

  @override
  void initState() {
    super.initState();
    getCurrentLiveLocationOfUser();
    Timer.periodic(Duration(seconds: 3), (Timer t) => _updateDistance());
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  void getCurrentLiveLocationOfUser() {
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        currentPositionOfUser = position;
        _updateMap();
        _updateDistance(); // Update distance whenever user location changes
      });

      FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
        'userid': user.uid,
        'latitude': currentPositionOfUser!.latitude,
        'longitude': currentPositionOfUser!.longitude,
      });
    });
  }

  void _updateMap() {
    if (currentPositionOfUser != null && driverPosition != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          currentPositionOfUser!.latitude < driverPosition!.latitude
              ? currentPositionOfUser!.latitude
              : driverPosition!.latitude,
          currentPositionOfUser!.longitude < driverPosition!.longitude
              ? currentPositionOfUser!.longitude
              : driverPosition!.longitude,
        ),
        northeast: LatLng(
          currentPositionOfUser!.latitude > driverPosition!.latitude
              ? currentPositionOfUser!.latitude
              : driverPosition!.latitude,
          currentPositionOfUser!.longitude > driverPosition!.longitude
              ? currentPositionOfUser!.longitude
              : driverPosition!.longitude,
        ),
      );

      controllerGoogleMap
          ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  void _updateDistance() {
    if (currentPositionOfUser != null && driverPosition != null) {
      double newDistance = Geolocator.distanceBetween(
            currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude,
            driverPosition!.latitude,
            driverPosition!.longitude,
          ) /
          1000.0;

      if (newDistance < 0.5 && !notifiedLessThan500m) {
        _sendNotification('Bus is less than 500m away',
            'The bus is now less than 500m away from your location.');
        notifiedLessThan500m = true;
        notifiedLessThan1km =
            true; // Ensure the less than 1km notification is also flagged
      } else if (newDistance < 1.0 && !notifiedLessThan1km) {
        _sendNotification('Bus is less than 1 km away',
            'The bus is now less than 1 km away from your location.');
        notifiedLessThan1km = true;
      } else if (newDistance > 1.5) {
        if (notifiedLessThan500m || notifiedLessThan1km) {
          _sendNotification('Bus is beyond the reach',
              'The bus is now beyond the reach, more than 1.5 km away from your location.');
        }
        notifiedLessThan1km = false; // Reset less than 1 km notification flag
        notifiedLessThan500m = false; // Reset less than 500m notification flag
      }

      _distance = newDistance;
      setState(() {});
    }
  }

  void _sendNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: title,
        body: body,
      ),
    );
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

  Future<Map<String, dynamic>?> _getVehicleDetails(String vehicleId) async {
    try {
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (!vehicleSnapshot.exists) return null; // Check if document exists

      var data = vehicleSnapshot.data() as Map<String, dynamic>;
      if (data == null) return null; // Handle null data
      return {
        'imageUrl': data['imageUrl'],
        'model': data['model'],
        'registeredNumber': data['registeredNumber'],
        'sltbnumber': data['sltbnumber'],
      };
    } catch (e) {
      print('Error fetching vehicle details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getTripDetails(String driverId) async {
    try {
      DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
          .collection('activetrips')
          .doc(driverId)
          .get();

      if (!tripSnapshot.exists) return null; // Check if document exists

      var data = tripSnapshot.data() as Map<String, dynamic>;
      if (data == null) return null; // Handle null data

      // Fetch driver's location from 'locations' collection using driverId
      DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(driverId)
          .get();

      if (!locationSnapshot.exists)
        return null; // Check if location document exists

      var locationData = locationSnapshot.data() as Map<String, dynamic>;
      if (locationData == null) return null; // Handle null location data

      setState(() {
        driverPosition =
            LatLng(locationData['latitude'], locationData['longitude']);
      });
      _updateMap();
      return {
        'destinationAddress': data['destinationAddress'],
        'routeid': data['routeid'],
        'startAddress': data['startAddress'],
        'startTime': data['startTime'],
        'tripstatus': data['tripstatus'],
        'vehicleId': data['vehicleId'],
      };
    } catch (e) {
      print('Error fetching trip details: $e');
      return null;
    }
  }

  Future<String> _getDriverUsername(String driverId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .get();
      if (!userSnapshot.exists) return 'Unknown';

      var userData = userSnapshot.data() as Map<String, dynamic>;
      return userData['username'] ?? 'Unknown';
    } catch (e) {
      print('Error fetching driver username: $e');
      return 'Unknown';
    }
  }

  Stream<String> _currentTime() async* {
    while (true) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy MMM  d').format(now);
      String formattedTime = DateFormat('hh:mm:ss a').format(now);

      yield '$formattedDate\n$formattedTime';
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Widget buildWelcomeCard(BuildContext context, User user) {
    return Center(
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/bus.png', // Ensure this path matches the location of your logo asset
                height: 100,
              ),
              SizedBox(height: 10),
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

                  return Column(
                    children: [
                      Text(
                        'Welcome to SLTB Kuliyapitiya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 229, 164, 130),                        ),
                      ),
                      SizedBox(height: 10),
                      StreamBuilder<String>(
                        stream: _currentTime(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Hello, ${username ?? 'User'}!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade900, Colors.deepOrange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
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
                          : const AssetImage('assets/profile.png')
                      as ImageProvider,
                      radius: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      username ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: trackingStopped
          ? buildWelcomeCard(context, user)
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tracking')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var data = snapshot.data!.data() as Map<String, dynamic>?;

                if (data == null || data.isEmpty) {
                  // No tracking data found or data is empty, load default content
                  return buildWelcomeCard(context, user);
                }

                var trackingData = {
                  'driverId': data['driverId'],
                  'timestamp': data['timestamp'],
                  'trackstatus': data['trackstatus'],
                };

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _getTripDetails(trackingData['driverId']),
                  builder: (context, tripSnapshot) {
                    if (!tripSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    var tripData = tripSnapshot.data!;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getVehicleDetails(tripData['vehicleId']),
                      builder: (context, vehicleSnapshot) {
                        if (!vehicleSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var vehicleData = vehicleSnapshot.data!;
                        return FutureBuilder<String>(
                          future: _getDriverUsername(trackingData['driverId']),
                          builder: (context, usernameSnapshot) {
                            if (!usernameSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            var driverUsername = usernameSnapshot.data!;

                            return Column(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ListView(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: -20, horizontal: 10),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Driver: $driverUsername',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 0),
                                            Text(
                                              'Start time: ${trackingData['timestamp'].toDate()}',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            SizedBox(height: 0),
                                            Text(
                                              'Route: ${tripData['startAddress']} to ${tripData['destinationAddress']}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 50),
                                        leading: SizedBox(
                                          width: 100,
                                          height: 150,
                                          child: Container(
                                            width: 150,
                                            height: 150,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              // Change this to BoxShape.rectangle
                                              image: DecorationImage(
                                                image: vehicleData['imageUrl'] != null
                                                    ? NetworkImage(vehicleData['imageUrl'])
                                                    : AssetImage('assets/vehicle_placeholder.png')
                                                as ImageProvider,
                                                fit: BoxFit.cover, // Ensures the image covers the container
                                              ),
                                            ),

                                          ),
                                        ),
                                        title: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Model:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text('${vehicleData['model']}'),
                                            SizedBox(height: 0),
                                            Text('Registered Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text('${vehicleData['registeredNumber']}'),
                                            SizedBox(height: 0),
                                            Text('SLTB Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text('${vehicleData['sltbnumber']}'),
                                          ],
                                        ),
                                      ),

                                      ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 0, horizontal: 80),
                                        title: Text(
                                          'Distance to Bus: ${_distance.toStringAsFixed(2)} Km',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: Text(
                                                      "Do you want to stop tracking '${vehicleData['sltbnumber']}'?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text('No'),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: Text('Confirm'),
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'tracking')
                                                            .doc(user.uid)
                                                            .delete()
                                                            .then((_) {
                                                          print(
                                                              'Tracking deleted successfully');
                                                          setState(() {
                                                            trackingStopped =
                                                                true;
                                                          });
                                                        }).catchError((error) {
                                                          print(
                                                              'Failed to delete tracking: $error');
                                                        });

                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 1, horizontal: 24),
                                          ),
                                          child: Text('Stop Tracking'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        currentPositionOfUser?.latitude ?? 0.0,
                                        currentPositionOfUser?.longitude ?? 0.0,
                                      ),
                                      zoom: 15,
                                    ),
                                    markers: {
                                      if (currentPositionOfUser != null)
                                        Marker(
                                          markerId: MarkerId('user'),
                                          position: LatLng(
                                            currentPositionOfUser!.latitude,
                                            currentPositionOfUser!.longitude,
                                          ),
                                          infoWindow: InfoWindow(
                                              title: 'Your Location'),
                                        ),
                                      if (driverPosition != null)
                                        Marker(
                                          markerId: MarkerId('driver'),
                                          position: driverPosition!,
                                          icon: BitmapDescriptor
                                              .defaultMarkerWithHue(
                                                  BitmapDescriptor.hueBlue),
                                          infoWindow:
                                              InfoWindow(title: 'Bus Location'),
                                        ),
                                    },
                                    onMapCreated:
                                        (GoogleMapController controller) {
                                      _controller.complete(controller);
                                      controllerGoogleMap = controller;
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color:
              Color.fromRGBO(255, 255, 255, 1), // RGB color (red in this case)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
                icon: Icon(Icons.phone),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DialPadScreen(),
                    ),
                  ); // Navigate to DialPadScreen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
