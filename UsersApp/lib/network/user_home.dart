// import 'dart:async';
// import 'dart:math';
//
// import 'package:clients/screens/auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import 'EditProfilePage.dart';
// import 'MapPage.dart';
//
// class UserHome extends StatefulWidget {
//   const UserHome({Key? key}) : super(key: key);
//
//   @override
//   _HomeState createState() => _HomeState();
// }
//
// class _HomeState extends State<UserHome> {
//   final user = FirebaseAuth.instance.currentUser!;
//   Position? currentPositionOfUser;
//   GoogleMapController? controllerGoogleMap;
//
//   final Completer<GoogleMapController> _controller = Completer();
//
//   StreamSubscription<Position>? positionStream;
//   int _selectedIndex = 0;
//   double _distance = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     getCurrentLiveLocationOfUser();
//     Timer.periodic(Duration(seconds: 3), (Timer t) => _updateDistance());
//   }
//
//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }
//
//   void getCurrentLiveLocationOfUser() {
//     positionStream = Geolocator.getPositionStream().listen((Position position) {
//       setState(() {
//         currentPositionOfUser = position;
//         LatLng positionOfUserInLatLng = LatLng(
//             currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//
//         CameraPosition cameraPosition =
//             CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//         controllerGoogleMap
//             ?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
//
//         // Upload user's live location to Firestore
//         FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
//           'userid': user.uid,
//           'latitude': currentPositionOfUser!.latitude,
//           'longitude': currentPositionOfUser!.longitude,
//         });
//       });
//     });
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
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
//
//   Future<Map<String, dynamic>?> _getVehicleDetails(String driverId) async {
//     try {
//       // Fetch active trips document using driverId
//       DocumentSnapshot activeTripSnapshot = await FirebaseFirestore.instance
//           .collection('activetrips')
//           .doc(driverId)
//           .get();
//       if (!activeTripSnapshot.exists) return null;
//
//       String vehicleId = activeTripSnapshot['vehicleId'];
//
//       // Fetch vehicle details using vehicleId
//       DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//       if (!vehicleSnapshot.exists) return null;
//
//       return {
//         'sltbnumber': vehicleSnapshot['sltbnumber'],
//         'model': vehicleSnapshot['model'],
//       };
//     } catch (e) {
//       print('Error fetching vehicle details: $e');
//       return null;
//     }
//   }
//
//   void _updateDistance() {
//     if (currentPositionOfUser != null) {
//       FirebaseFirestore.instance
//           .collection('tracking')
//           .doc(user.uid)
//           .get()
//           .then((trackingDoc) {
//         if (trackingDoc.exists) {
//           String driverId = trackingDoc['driverId'] ?? 'N/A';
//
//           FirebaseFirestore.instance
//               .collection('locations')
//               .doc(driverId)
//               .get()
//               .then((locationDoc) {
//             if (locationDoc.exists) {
//               Map<String, dynamic> locationData =
//                   locationDoc.data() as Map<String, dynamic>;
//               double driverLat = locationData['latitude'] ?? 0.0;
//               double driverLong = locationData['longitude'] ?? 0.0;
//
//               setState(() {
//                 _distance = _calculateDistance(currentPositionOfUser!.latitude,
//                     currentPositionOfUser!.longitude, driverLat, driverLong);
//               });
//             }
//           });
//         }
//       });
//     }
//   }
//
//   double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     var p = 0.017453292519943295; // Pi/180
//     var c = cos;
//     var a = 0.5 -
//         c((lat2 - lat1) * p) / 2 +
//         c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
//   }
//
//   Widget _buildContent() {
//     bool hasDisplayedTrackStatusZero = false; // Local state variable
//
//     switch (_selectedIndex) {
//       case 0:
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('tracking')
//                     .doc(user.uid)
//                     .snapshots(),
//                 builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return CircularProgressIndicator();
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || !snapshot.data!.exists) {
//                     return Center(child: Text('Document does not exist'));
//                   } else {
//                     // Access data from DocumentSnapshot
//                     Map<String, dynamic> data =
//                         snapshot.data!.data() as Map<String, dynamic>;
//                     int trackStatus = data['trackstatus'] ?? 0;
//
//                     if (trackStatus == 0 && !hasDisplayedTrackStatusZero) {
//                       // Display content only if trackstatus is 0 and not displayed before
//                       hasDisplayedTrackStatusZero = true; // Update local state
//                       String driverId = data['driverId'] ?? 'N/A';
//                       Timestamp timestamp =
//                           data['timestamp'] ?? Timestamp.now();
//                       String userId = data['userId'] ?? 'N/A';
//
//                       return FutureBuilder<Map<String, dynamic>?>(
//                         future: _getVehicleDetails(driverId),
//                         builder: (context,
//                             AsyncSnapshot<Map<String, dynamic>?>
//                                 vehicleSnapshot) {
//                           if (vehicleSnapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return CircularProgressIndicator();
//                           } else if (vehicleSnapshot.hasError) {
//                             return Center(
//                                 child: Text('Error: ${vehicleSnapshot.error}'));
//                           } else if (!vehicleSnapshot.hasData) {
//                             return Center(
//                                 child: Text('Vehicle details not found'));
//                           } else {
//                             Map<String, dynamic> vehicleData =
//                                 vehicleSnapshot.data!;
//                             return Card(
//                               color: Colors
//                                   .blue, // Example color for trackstatus == 1
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       'Driver ID: $driverId',
//                                       style: TextStyle(
//                                         fontSize: 20,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white, // Text color
//                                       ),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       'Timestamp: ${timestamp.toDate()}',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       'User ID: $userId',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       'SLTB Number: ${vehicleData['sltbnumber']}',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       'Model: ${vehicleData['model']}',
//                                       style: TextStyle(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                     StreamBuilder<DocumentSnapshot>(
//                                       stream: FirebaseFirestore.instance
//                                           .collection('locations')
//                                           .doc(driverId)
//                                           .snapshots(),
//                                       builder: (context, locationSnapshot) {
//                                         if (locationSnapshot.connectionState ==
//                                             ConnectionState.waiting) {
//                                           return CircularProgressIndicator();
//                                         } else if (locationSnapshot.hasError) {
//                                           return Center(
//                                               child: Text(
//                                                   'Error: ${locationSnapshot.error}'));
//                                         } else if (!locationSnapshot.hasData ||
//                                             !locationSnapshot.data!.exists) {
//                                           return Center(
//                                               child:
//                                                   Text('Location not found'));
//                                         } else {
//                                           Map<String, dynamic> locationData =
//                                               locationSnapshot.data!.data()
//                                                   as Map<String, dynamic>;
//                                           double latitude =
//                                               locationData['latitude'] ?? 0.0;
//                                           double longitude =
//                                               locationData['longitude'] ?? 0.0;
//                                           return Column(
//                                             children: [
//                                               Text(
//                                                 'Latitude: $latitude',
//                                                 style: TextStyle(
//                                                     fontSize: 16,
//                                                     color: Colors.white),
//                                               ),
//                                               Text(
//                                                 'Longitude: $longitude',
//                                                 style: TextStyle(
//                                                     fontSize: 16,
//                                                     color: Colors.white),
//                                               ),
//                                               Text(
//                                                 'Distance: ${_distance.toStringAsFixed(2)} km',
//                                                 style: TextStyle(
//                                                     fontSize: 16,
//                                                     color: Colors.white),
//                                               ),
//                                             ],
//                                           );
//                                         }
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }
//                         },
//                       );
//                     } else {
//                       // Display placeholder or other content if trackstatus is not 0 or already displayed
//                       return Center(child: Text('Welcome to SLTB Part'));
//                     }
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       case 1:
//         return MapPage();
//       case 2:
//         return Center(child: Text('Profile Content'));
//       default:
//         return Center(child: Text('Home Page Content'));
//     }
//   }
//
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
//
//               Map<String, dynamic>? userData =
//                   snapshot.data!.data() as Map<String, dynamic>?;
//               String? username = userData?['username'];
//               String? userImageUrl = userData?['image_url'];
//
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
