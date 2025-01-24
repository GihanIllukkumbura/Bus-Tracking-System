// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import '../Methods/checkAuth.dart';
// import '../widgets/text_field.dart';
//
// const String googleApiKey = 'AIzaSyDrTc6KslPKkmjyes74AKZNWSBEYFrQ-uM';
//
// class NewSettingTrip extends StatefulWidget {
//   final String selectedVehicleId;
//   final String selectedVehicleName;
//
//   const NewSettingTrip({
//     Key? key,
//     required this.selectedVehicleId,
//     required this.selectedVehicleName,
//   }) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() => _MapWidgetState();
// }
//
// class _MapWidgetState extends State<NewSettingTrip> {
//   CameraPosition initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
//   late List<Location> startPlacemark;
//   late List<Location> destinationPlacemark;
//   Set<Marker> markers = {};
//   var _currentAddress = "";
//   var _startAddress = "";
//   var _destinationAddress = "";
//   late PolylinePoints polylinePoints;
//
//   // List of coordinates to join
//   List<LatLng> polylineCoordinates = [];
//
//   // Map storing polylines created by connecting two points
//   Map<PolylineId, Polyline> polylines = {};
//   final startAddressFocusNode = FocusNode();
//   final destinationAddressFocusNode = FocusNode();
//   late Position _currentPosition;
//   final startAddressController = TextEditingController();
//   final destinationAddressController = TextEditingController();
//   late GoogleMapController mapController;
//   bool _confirmingTrip = false;
//
//   @override
//   void initState() {
//     super.initState();
//     getCurrentLocation();
//
//   }
//
//   // Create the polylines for showing the route between two places
//   _createPolylines(
//       double startLatitude,
//       double startLongitude,
//       double destinationLatitude,
//       double destinationLongitude,
//       ) async {
//     // Initializing PolylinePoints
//     polylinePoints = PolylinePoints();
//
//     // Generating the list of coordinates to be used for drawing the polylines
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       googleApiKey, // Google Maps API Key
//       PointLatLng(startLatitude, startLongitude),
//       PointLatLng(destinationLatitude, destinationLongitude),
//       travelMode: TravelMode.transit,
//     );
//
//     // Adding the coordinates to the list
//     if (result.points.isNotEmpty) {
//       result.points.forEach((PointLatLng point) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       });
//     }
//
//     // Defining an ID
//     PolylineId id = PolylineId('poly');
//
//     // Initializing Polyline
//     Polyline polyline = Polyline(
//       polylineId: id,
//       color: Colors.red,
//       points: polylineCoordinates,
//       width: 3,
//     );
//
//     // Adding the polyline to the map
//     polylines[id] = polyline;
//   }
//
//   _calculateDistance() async {
//     // Retrieving placemarks from addresses
//     List<Location>? startPlacemark = await locationFromAddress(_startAddress);
//
//     List<Location>? destinationPlacemark = await locationFromAddress(_destinationAddress);
//
//     double startLatitude = _startAddress == _currentAddress
//         ? _currentPosition.latitude
//         : startPlacemark![0].latitude;
//
//     double startLongitude = _startAddress == _currentAddress
//         ? _currentPosition.longitude
//         : startPlacemark![0].longitude;
//
//     double destinationLatitude = destinationPlacemark![0].latitude;
//     double destinationLongitude = destinationPlacemark![0].longitude;
//
//     // Calculate the distance between the two points
//     double distanceInMeters = await Geolocator.distanceBetween(
//       startLatitude,
//       startLongitude,
//       destinationLatitude,
//       destinationLongitude,
//     );
//
//     double distanceInKm = distanceInMeters / 1000; // Convert meters to kilometers
//     print('Distance: $distanceInKm km');
//     // Rest of your code...
//
//     String startCoordinatesString = '($startLatitude, $startLongitude)';
//     String destinationCoordinatesString = '($destinationLatitude, $destinationLongitude)';
//
//     // Start Location Marker
//     Marker startMarker = Marker(
//       markerId: MarkerId(startCoordinatesString),
//       position: LatLng(startLatitude, startLongitude),
//       infoWindow: InfoWindow(
//         title: 'Start $startCoordinatesString',
//         snippet: _startAddress,
//       ),
//       icon: BitmapDescriptor.defaultMarker,
//     );
//
//     // Destination Location Marker
//     Marker destinationMarker = Marker(
//       markerId: MarkerId(destinationCoordinatesString),
//       position: LatLng(destinationLatitude, destinationLongitude),
//       infoWindow: InfoWindow(
//         title: 'Destination $destinationCoordinatesString',
//         snippet: _destinationAddress,
//       ),
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//     );
//
//     setState(() {
//       markers.add(startMarker);
//       markers.add(destinationMarker);
//     });
//
//     double miny = (startLatitude <= destinationLatitude) ? startLatitude : destinationLatitude;
//     double minx = (startLongitude <= destinationLongitude) ? startLongitude : destinationLongitude;
//     double maxy = (startLatitude <= destinationLatitude) ? destinationLatitude : startLatitude;
//     double maxx = (startLongitude <= destinationLongitude) ? destinationLongitude : startLongitude;
//
//     double southWestLatitude = miny;
//     double southWestLongitude = minx;
//
//     double northEastLatitude = maxy;
//     double northEastLongitude = maxx;
//
//     mapController.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         LatLngBounds(
//           northeast: LatLng(northEastLatitude, northEastLongitude),
//           southwest: LatLng(southWestLatitude, southWestLongitude),
//         ),
//         100.0,
//       ),
//     );
//
//     _createPolylines(startLatitude, startLongitude, destinationLatitude, destinationLongitude);
//
//     setState(() {
//       _confirmingTrip = true;
//     });
//   }
//
//   _confirmTrip() async {
//     setState(() {
//       _confirmingTrip = false;
//     });
//
//     // Upload trip details to Firestore
//     try {
//       // Get current user ID
//       User? user = FirebaseAuth.instance.currentUser;
//       String? userId = user?.uid;
//
//       // Prepare trip data
//       Map<String, dynamic> tripData = {
//         'startAddress': _startAddress,
//         'destinationAddress': _destinationAddress,
//         'startLatitude': markers.elementAt(0).position.latitude,
//         'startLongitude': markers.elementAt(0).position.longitude,
//         'destinationLatitude': markers.elementAt(1).position.latitude,
//         'destinationLongitude': markers.elementAt(1).position.longitude,
//         'distance': calculateDistanceInKm(markers.elementAt(0).position.latitude,
//             markers.elementAt(0).position.longitude, markers.elementAt(1).position.latitude,
//             markers.elementAt(1).position.longitude),
//         'startTime': DateTime.now(),
//         'liveTrackingCoordinates': [], // Add live tracking coordinates later
//         'vehicleId': widget.selectedVehicleId, // Add selectedVehicleId from widget
//         'vehicleName': widget.selectedVehicleName, // Add selectedVehicleName from widget
//         'tripstatus': 0,
//       };
//
//       // Upload trip data to Firestore for the user
//       await FirebaseFirestore.instance
//           .collection('trips')
//           .doc(userId)
//           .collection('userTrips')
//           .add(tripData);
//
//
//
//
//       print('Trip details uploaded successfully');
//       // Navigate back to HomeScreen
//       Navigator.of(context).pop();
//     } catch (e) {
//       print('Error uploading trip details: $e');
//     }
//   }
//
//
//   double calculateDistanceInKm(double startLatitude, double startLongitude, double destinationLatitude, double destinationLongitude) {
//     double distanceInMeters = Geolocator.distanceBetween(
//       startLatitude,
//       startLongitude,
//       destinationLatitude,
//       destinationLongitude,
//     );
//
//     return distanceInMeters / 1000; // Convert meters to kilometers
//   }
//
//
//   // Method for retrieving the address
//   _getAddress() async {
//     try {
//       List<Placemark> p = await placemarkFromCoordinates(
//           _currentPosition.latitude, _currentPosition.longitude);
//
//       Placemark place = p[0];
//       setState(() {
//         _currentAddress =
//         "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
//         startAddressController.text = _currentAddress;
//         _startAddress = _currentAddress;
//       });
//     } catch (e) {
//       print("ERROR ADDRESS $e");
//     }
//   }
//
//   getCurrentLocation() async {
//     var status = await Permission.location.status;
//     var permissionGranted = false;
//
//     permissionGranted = status.isGranted;
//     if (!permissionGranted) {
//       permissionGranted = await Permission.location.request().isGranted;
//     }
//     if (permissionGranted) {
//       if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
//         await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high)
//             .then((Position position) async {
//           setState(() {
//             _currentPosition = position;
//             mapController.animateCamera(
//               CameraUpdate.newCameraPosition(
//                 CameraPosition(
//                   target: LatLng(position.latitude, position.longitude),
//                   zoom: 18.0,
//                 ),
//               ),
//             );
//           });
//           await _getAddress();
//         }).catchError((e) {
//           print(e);
//         });
//       }
//     } else {
//       print("Enable Location services to continue using it");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var height = MediaQuery.of(context).size.height;
//     var width = MediaQuery.of(context).size.width;
//     return Container(
//       height: height,
//       width: width,
//       child: Scaffold(
//         body: Stack(
//           children: [
//             GoogleMap(
//               polylines: Set<Polyline>.of(polylines.values),
//               markers: Set<Marker>.from(markers),
//               initialCameraPosition: initialLocation,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: false,
//               mapType: MapType.normal,
//               zoomGesturesEnabled: true,
//               zoomControlsEnabled: false,
//               onMapCreated: (GoogleMapController controller) {
//                 mapController = controller;
//               },
//             ),
//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10.0),
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       TextField(
//                         decoration: InputDecoration(
//                           labelText: 'Start',
//                           hintText: 'Choose starting point',
//                           prefixIcon: const Icon(Icons.looks_one),
//                           suffixIcon: IconButton(
//                             icon: const Icon(Icons.my_location),
//                             onPressed: () {
//                               startAddressController.text = _currentAddress;
//                               _startAddress = _currentAddress;
//                             },
//                           ),
//                         ),
//                         controller: startAddressController,
//                         focusNode: startAddressFocusNode,
//                         onChanged: (value) {
//                           setState(() {
//                             _startAddress = value;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         decoration: InputDecoration(
//                           labelText: 'Destination',
//                           hintText: 'Choose destination',
//                           prefixIcon: const Icon(Icons.looks_two),
//                         ),
//                         controller: destinationAddressController,
//                         focusNode: destinationAddressFocusNode,
//                         onChanged: (value) {
//                           setState(() {
//                             _destinationAddress = value;
//                           });
//                         },
//                       ),
//                       SizedBox(height: 10),
//                       ElevatedButton(
//                         onPressed: (_startAddress != '' && _destinationAddress != '')
//                             ? () async {
//                           startAddressFocusNode.unfocus();
//                           destinationAddressFocusNode.unfocus();
//                           setState(() {
//                             if (markers.isNotEmpty) markers.clear();
//                             _calculateDistance();
//                           });
//                         }
//                             : () {
//                           if (kDebugMode) {
//                             print("Invalid Address");
//                           }
//                         },
//                         child: const Text("Find route"),
//                       ),
//                       if (_confirmingTrip)
//                         ElevatedButton(
//                           onPressed: _confirmTrip,
//                           child: const Text("Confirm Trip"),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 10.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     ClipOval(
//                       child: Material(
//                         color: Colors.blue.shade100,
//                         child: InkWell(
//                           splashColor: Colors.blue,
//                           child: const SizedBox(
//                             width: 50,
//                             height: 50,
//                             child: Icon(Icons.add),
//                           ),
//                           onTap: () {
//                             mapController.animateCamera(
//                               CameraUpdate.zoomIn(),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ClipOval(
//                       child: Material(
//                         color: Colors.blue.shade100,
//                         child: InkWell(
//                           splashColor: Colors.blue,
//                           child: const SizedBox(
//                             width: 50,
//                             height: 50,
//                             child: Icon(Icons.remove),
//                           ),
//                           onTap: () {
//                             mapController.animateCamera(
//                               CameraUpdate.zoomOut(),
//                             );
//                           },
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//             SafeArea(
//               child: Align(
//                 alignment: Alignment.bottomLeft,
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
//                   child: ClipOval(
//                     child: Material(
//                       color: Colors.orange.shade100,
//                       child: InkWell(
//                         splashColor: Colors.orange,
//                         child: const SizedBox(
//                           width: 56,
//                           height: 56,
//                           child: Icon(Icons.my_location),
//                         ),
//                         onTap: () {
//                           mapController.animateCamera(
//                             CameraUpdate.newCameraPosition(
//                               CameraPosition(
//                                 target: LatLng(
//                                   _currentPosition.latitude,
//                                   _currentPosition.longitude,
//                                 ),
//                                 zoom: 18.0,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
