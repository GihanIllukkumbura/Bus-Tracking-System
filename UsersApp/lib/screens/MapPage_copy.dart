// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// const String googleApiKey = 'AIzaSyArDKkHbbMghmnCkdPwFNh8mx_Q9w4c370';
//
// class MapPage extends StatefulWidget {
//   const MapPage({Key? key}) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() => _MapWidgetState();
// }
//
// class _MapWidgetState extends State<MapPage> {
//   GoogleMapController? mapController;
//   Map<MarkerId, Marker> markers = {};
//   Set<Circle> circles = {};
//   LatLngBounds? bounds;
//   Position? currentLocation;
//   bool isFullScreen = true;  // To track full-screen state
//   BitmapDescriptor? busIcon;
//
//
//   String? selectedRoute;
//   List<Map<String, String>> routes = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     _fetchDriversLocations();
//     _fetchRoutes();
//     loadBusIcon();
//   }
//
//   void _getCurrentLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
//       Position position = await Geolocator.getCurrentPosition();
//       setState(() {
//         currentLocation = position;
//         circles.add(Circle(
//           circleId: CircleId('currentLocation'),
//           center: LatLng(position.latitude, position.longitude),
//           radius: 5000,
//           fillColor: Colors.lightBlue.withOpacity(0.5),
//           strokeColor: Colors.lightBlue,
//           strokeWidth: 1,
//         ));
//       });
//     } else {
//       print('Location permission not granted');
//     }
//   }
//
//   void _fetchDriversLocations() {
//     FirebaseFirestore.instance
//         .collection('users')
//         .where('role', isEqualTo: 'driver')
//         .snapshots()
//         .listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         final DocumentSnapshot document = change.doc;
//         final String userId = document.id;
//         final Map<String, dynamic> userData = document.data() as Map<String, dynamic>;
//
//         if (userData.containsKey('username')) {
//           final String username = userData['username'] as String;
//
//           FirebaseFirestore.instance.collection('locations').doc(userId).snapshots().listen((locationSnapshot) {
//             if (locationSnapshot.exists) {
//               final Map<String, dynamic> locationData = locationSnapshot.data() as Map<String, dynamic>;
//
//               if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
//                 final double latitude = locationData['latitude'] as double;
//                 final double longitude = locationData['longitude'] as double;
//
//                 final MarkerId markerId = MarkerId(userId);
//                 final Marker marker = Marker(
//                   markerId: markerId,
//                   position: LatLng(latitude, longitude),
//                   infoWindow: InfoWindow(title: username),
//                   icon: busIcon ?? BitmapDescriptor.defaultMarker,
//                 );
//
//                 setState(() {
//                   markers[markerId] = marker;
//                 });
//               }
//             }
//           });
//         }
//       }
//     });
//   }
//
//   Future<void> loadBusIcon() async {
//     try {
//       busIcon = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(size: Size(100, 100)),
//         'assets/bus_icon.png',
//       );
//       print('Bus icon loaded successfully');
//     } catch (e) {
//       print('Error loading bus icon: $e');
//     }
//   }
//
//
//   void _fetchRoutes() async {
//     final QuerySnapshot routeSnapshot = await FirebaseFirestore.instance.collection('route').get();
//     setState(() {
//       routes = routeSnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'id': doc.id,
//           'start': data['start'] as String,
//           'destination': data['destination'] as String,
//         };
//       }).toList();
//     });
//   }
//
//   void _filterByRoute(String routeId) async {
//     final QuerySnapshot tripSnapshot = await FirebaseFirestore.instance
//         .collection('activetrips')
//         .where('routeid', isEqualTo: routeId)
//         .get();
//
//     final List<String> docIds = tripSnapshot.docs.map((doc) => doc.id).toList();
//     final List<String> vehicleIds = tripSnapshot.docs.map((doc) => doc['vehicleId'] as String).toList();
//
//     Map<MarkerId, Marker> newMarkers = {};
//
//     for (var docId in docIds) {
//       final DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance.collection('locations').doc(docId).get();
//       if (locationSnapshot.exists) {
//         final Map<String, dynamic> locationData = locationSnapshot.data() as Map<String, dynamic>;
//         if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
//           final double latitude = locationData['latitude'] as double;
//           final double longitude = locationData['longitude'] as double;
//
//           final MarkerId markerId = MarkerId(docId);
//           final Marker marker = Marker(
//             markerId: markerId,
//             position: LatLng(latitude, longitude),
//             infoWindow: InfoWindow(title: 'Vehicle: ${vehicleIds[docIds.indexOf(docId)]}'),
//             icon: busIcon ?? BitmapDescriptor.defaultMarker,
//           );
//
//           newMarkers[markerId] = marker;
//         }
//       }
//     }
//
//     setState(() {
//       markers = newMarkers;
//     });
//   }
//
//   void _toggleFullScreen() {
//     setState(() {
//       isFullScreen = !isFullScreen;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             bottom: isFullScreen ? 0 : MediaQuery.of(context).size.height / 2 ,
//             child: GoogleMap(
//               markers: Set<Marker>.of(markers.values),
//               circles: circles,
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(7.2, 80.7),
//                 zoom: 8.33,
//               ),
//               myLocationEnabled: true,
//               onMapCreated: (GoogleMapController controller) {
//                 mapController = controller;
//               },
//             ),
//           ),
//           Positioned(
//             top: 10,
//             right: 10,
//             child: ElevatedButton(
//               onPressed: _toggleFullScreen,
//               child: Icon(
//                 isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 10,
//             left: 10,
//             right: 10,
//             child: Column(
//               children: [
//                 DropdownButton<String>(
//                   value: selectedRoute,
//                   hint: Text('Select Route'),
//                   items: routes.map((route) {
//                     return DropdownMenuItem<String>(
//                       value: route['id'],
//                       child: Text('${route['start']} to ${route['destination']}'),
//                     );
//                   }).toList(),
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       selectedRoute = newValue;
//                     });
//                   },
//                 ),
//                 ElevatedButton(
//                   onPressed: selectedRoute != null
//                       ? () {
//                     _filterByRoute(selectedRoute!);
//                   }
//                       : null,
//                   child: Text('Filter by Route'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
