// import 'dart:async';
// import 'dart:math';

// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:clients/screens/auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// import 'EditProfilePage.dart';
// import 'MapPage.dart';

// class UserHome extends StatefulWidget {
//   const UserHome({Key? key}) : super(key: key);

//   @override
//   _HomeState createState() => _HomeState();
// }

// class _HomeState extends State<UserHome> {
//   final user = FirebaseAuth.instance.currentUser!;
//   Position? currentPositionOfUser;
//   LatLng? driverPosition;
//   GoogleMapController? controllerGoogleMap;

//   final Completer<GoogleMapController> _controller = Completer();

//   StreamSubscription<Position>? positionStream;
//   int _selectedIndex = 0;
//   double _distance = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     getCurrentLiveLocationOfUser();
//     Timer.periodic(Duration(seconds: 3), (Timer t) => _updateDistance());
//   }

//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }

//   void getCurrentLiveLocationOfUser() {
//     positionStream = Geolocator.getPositionStream().listen((Position position) {
//       setState(() {
//         currentPositionOfUser = position;
//         _updateMap();
//         _updateDistance(); // Update distance whenever user location changes
//       });

//       FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
//         'userid': user.uid,
//         'latitude': currentPositionOfUser!.latitude,
//         'longitude': currentPositionOfUser!.longitude,
//       });
//     });
//   }

//   void _updateMap() {
//     if (currentPositionOfUser != null && driverPosition != null) {
//       LatLngBounds bounds = LatLngBounds(
//         southwest: LatLng(
//           currentPositionOfUser!.latitude < driverPosition!.latitude
//               ? currentPositionOfUser!.latitude
//               : driverPosition!.latitude,
//           currentPositionOfUser!.longitude < driverPosition!.longitude
//               ? currentPositionOfUser!.longitude
//               : driverPosition!.longitude,
//         ),
//         northeast: LatLng(
//           currentPositionOfUser!.latitude > driverPosition!.latitude
//               ? currentPositionOfUser!.latitude
//               : driverPosition!.latitude,
//           currentPositionOfUser!.longitude > driverPosition!.longitude
//               ? currentPositionOfUser!.longitude
//               : driverPosition!.longitude,
//         ),
//       );

//       controllerGoogleMap
//           ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//     }
//   }

//   void _updateDistance() {
//     if (currentPositionOfUser != null && driverPosition != null) {
//       _distance = Geolocator.distanceBetween(
//             currentPositionOfUser!.latitude,
//             currentPositionOfUser!.longitude,
//             driverPosition!.latitude,
//             driverPosition!.longitude,
//           ) /
//           1000.0;
//       setState(() {});
//     }
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   void _handleMenuOption(String option) {
//     switch (option) {
//       case 'Edit Profile':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => ProfileEditPage()),
//         );
//         break;
//       case 'Logout':
//         FirebaseAuth.instance.signOut();
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AuthScreen()),
//         );
//         break;
//     }
//   }

//   Future<Map<String, dynamic>?> _getVehicleDetails(String vehicleId) async {
//     try {
//       DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//       if (!vehicleSnapshot.exists) return null;

//       var data = vehicleSnapshot.data() as Map<String, dynamic>;
//       return {
//         'imageUrl': data['imageUrl'],
//         'model': data['model'],
//         'registeredNumber': data['registeredNumber'],
//         'sltbnumber': data['sltbnumber'],
//       };
//     } catch (e) {
//       print('Error fetching vehicle details: $e');
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _getTripDetails(String driverId) async {
//     try {
//       DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
//           .collection('activetrips')
//           .doc(driverId)
//           .get();
//       if (!tripSnapshot.exists) return null;

//       var data = tripSnapshot.data() as Map<String, dynamic>;
//       // Fetch driver's location from 'locations' collection using driverId
//       DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
//           .collection('locations')
//           .doc(driverId)
//           .get();
//       if (!locationSnapshot.exists) return null;

//       var locationData = locationSnapshot.data() as Map<String, dynamic>;
//       setState(() {
//         driverPosition =
//             LatLng(locationData['latitude'], locationData['longitude']);
//       });
//       _updateMap();
//       return {
//         'destinationAddress': data['destinationAddress'],
//         'routeid': data['routeid'],
//         'startAddress': data['startAddress'],
//         'startTime': data['startTime'],
//         'tripstatus': data['tripstatus'],
//         'vehicleId': data['vehicleId'],
//       };
//     } catch (e) {
//       print('Error fetching trip details: $e');
//       return null;
//     }
//   }

//   Future<String> _getDriverUsername(String driverId) async {
//     try {
//       DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(driverId)
//           .get();
//       if (!userSnapshot.exists) return 'Unknown';

//       var userData = userSnapshot.data() as Map<String, dynamic>;
//       return userData['username'] ?? 'Unknown';
//     } catch (e) {
//       print('Error fetching driver username: $e');
//       return 'Unknown';
//     }
//   }

//   Widget _buildContent() {
//     switch (_selectedIndex) {
//       case 0:
//         return StreamBuilder<DocumentSnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('tracking')
//               .doc(user.uid)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return Center(child: CircularProgressIndicator());
//             }

//             var data = snapshot.data!.data() as Map<String, dynamic>;
//             if (data.isEmpty) {
//               // No tracking data found, load default content
//               return Center(child: Text('Home Page Content'));
//             }

//             var trackingData = {
//               'driverId': data['driverId'],
//               'timestamp': data['timestamp'],
//               'trackstatus': data['trackstatus'],
//             };

//             return FutureBuilder<Map<String, dynamic>?>(
//               future: _getTripDetails(trackingData['driverId']),
//               builder: (context, tripSnapshot) {
//                 if (!tripSnapshot.hasData) {
//                   return Center(child: CircularProgressIndicator());
//                 }

//                 var tripData = tripSnapshot.data!;
//                 return FutureBuilder<Map<String, dynamic>?>(
//                   future: _getVehicleDetails(tripData['vehicleId']),
//                   builder: (context, vehicleSnapshot) {
//                     if (!vehicleSnapshot.hasData) {
//                       return Center(child: CircularProgressIndicator());
//                     }

//                     var vehicleData = vehicleSnapshot.data!;
//                     return FutureBuilder<String>(
//                       future: _getDriverUsername(trackingData['driverId']),
//                       builder: (context, usernameSnapshot) {
//                         if (!usernameSnapshot.hasData) {
//                           return Center(child: CircularProgressIndicator());
//                         }

//                         var driverUsername = usernameSnapshot.data!;

//                         return Column(
//                           children: [
//                             Expanded(
//                               flex: 2,
//                               child: ListView(
//                                 children: [
//                                   ListTile(
//                                     contentPadding: EdgeInsets.symmetric(
//                                         vertical: -20, horizontal: 10),
//                                     title: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Driver: $driverUsername',
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                         SizedBox(height: 1),
//                                         Text(
//                                           'Start time: ${trackingData['timestamp'].toDate()}',
//                                           style: TextStyle(color: Colors.grey),
//                                         ),
//                                         SizedBox(height: 1),
//                                         Text(
//                                           'Route: ${tripData['startAddress']} to ${tripData['destinationAddress']}',
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   ListTile(
//                                     contentPadding: EdgeInsets.symmetric(
//                                         vertical: 1, horizontal: 80),
//                                     leading: SizedBox(
//                                       width: 80,
//                                       height: 50,
//                                       child: CircleAvatar(
//                                         backgroundImage: vehicleData[
//                                                     'imageUrl'] !=
//                                                 null
//                                             ? NetworkImage(
//                                                 vehicleData['imageUrl'])
//                                             : AssetImage(
//                                                     'assets/vehicle_placeholder.png')
//                                                 as ImageProvider,
//                                       ),
//                                     ),
//                                     title: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text('Model:',
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.bold)),
//                                         Text('${vehicleData['model']}'),
//                                         SizedBox(height: 1),
//                                         Text('Registered Number:',
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.bold)),
//                                         Text(
//                                             '${vehicleData['registeredNumber']}'),
//                                         SizedBox(height: 1),
//                                         Text('SLTB Number:',
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.bold)),
//                                         Text('${vehicleData['sltbnumber']}'),
//                                       ],
//                                     ),
//                                   ),
//                                   ListTile(
//                                     contentPadding: EdgeInsets.symmetric(
//                                         vertical: 0, horizontal: 80),
//                                     title: Text(
//                                       'Distance to Driver: ${_distance.toStringAsFixed(2)} Km',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                   ),
//                                   Center(
//                                     child: ElevatedButton(
//                                       onPressed: () {
//                                         showDialog(
//                                           context: context,
//                                           builder: (BuildContext context) {
//                                             return AlertDialog(
//                                               content: Text(
//                                                   "Do you want to stop tracking '${vehicleData['sltbnumber']}'?"),
//                                               actions: <Widget>[
//                                                 TextButton(
//                                                   child: Text('No'),
//                                                   onPressed: () {
//                                                     Navigator.of(context).pop();
//                                                   },
//                                                 ),
//                                                 TextButton(
//                                                   child: Text('Confirm'),
//                                                   onPressed: () {
//                                                     FirebaseFirestore.instance
//                                                         .collection('tracking')
//                                                         .doc(user.uid)
//                                                         .delete()
//                                                         .then((_) {
//                                                       print(
//                                                           'Tracking deleted successfully');
//                                                     }).catchError((error) {
//                                                       print(
//                                                           'Failed to delete tracking: $error');
//                                                     });

//                                                     Navigator.of(context).pop();
//                                                   },
//                                                 ),
//                                               ],
//                                             );
//                                           },
//                                         );
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         foregroundColor: Colors.white,
//                                         backgroundColor: Colors.red,
//                                         padding: EdgeInsets.symmetric(
//                                             vertical: 12, horizontal: 24),
//                                       ),
//                                       child: Text('Stop Tracking'),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Expanded(
//                               flex: 1,
//                               child: GoogleMap(
//                                 initialCameraPosition: CameraPosition(
//                                   target: LatLng(
//                                     currentPositionOfUser?.latitude ?? 0.0,
//                                     currentPositionOfUser?.longitude ?? 0.0,
//                                   ),
//                                   zoom: 15,
//                                 ),
//                                 markers: {
//                                   if (currentPositionOfUser != null)
//                                     Marker(
//                                       markerId: MarkerId('user'),
//                                       position: LatLng(
//                                         currentPositionOfUser!.latitude,
//                                         currentPositionOfUser!.longitude,
//                                       ),
//                                       infoWindow:
//                                           InfoWindow(title: 'Your Location'),
//                                     ),
//                                   if (driverPosition != null)
//                                     Marker(
//                                       markerId: MarkerId('driver'),
//                                       position: driverPosition!,
//                                       icon:
//                                           BitmapDescriptor.defaultMarkerWithHue(
//                                               BitmapDescriptor.hueBlue),
//                                       infoWindow:
//                                           InfoWindow(title: 'Driver Location'),
//                                     ),
//                                 },
//                                 onMapCreated: (GoogleMapController controller) {
//                                   _controller.complete(controller);
//                                   controllerGoogleMap = controller;
//                                 },
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       case 1:
//         return MapPage();
//       case 2:
//         return Center(child: Text('Profile Content'));
//       case 3:
//         return Center(child: Text('Home Content'));
//       default:
//         return Center(child: Text('Home Page Content'));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home'),
//         backgroundColor: Colors.orange.shade900,
//         actions: [
//           StreamBuilder<DocumentSnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(user.uid)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return const CircularProgressIndicator();
//               }

//               Map<String, dynamic>? userData =
//                   snapshot.data!.data() as Map<String, dynamic>?;
//               String? username = userData?['username'];
//               String? userImageUrl = userData?['image_url'];

//               return PopupMenuButton<String>(
//                 onSelected: _handleMenuOption,
//                 itemBuilder: (BuildContext context) {
//                   return {'Edit Profile', 'Logout'}.map((String choice) {
//                     return PopupMenuItem<String>(
//                       value: choice,
//                       child: Text(choice),
//                     );
//                   }).toList();
//                 },
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundImage: userImageUrl != null
//                           ? NetworkImage(userImageUrl)
//                           : const AssetImage('assets/profile.png')
//                               as ImageProvider,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(username ?? 'User'),
//                     const Icon(Icons.arrow_drop_down),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _buildContent(),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.directions_bus),
//             label: 'Map',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.orange.shade900,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
