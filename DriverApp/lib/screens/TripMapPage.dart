import 'package:bustracking/screens/driver_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Methods/checkAuth.dart';
import '../widgets/text_field.dart';

const String googleApiKey = 'AIzaSyArDKkHbbMghmnCkdPwFNh8mx_Q9w4c370';

class TripMapPage extends StatefulWidget {
  final String selectedVehicleId;
  final String selectedVehicleName;
  final String selectedRouteId;
  final String startLocation;
  final String destinationLocation;

  const TripMapPage({
    Key? key,
    required this.selectedVehicleId,
    required this.selectedVehicleName,
    required this.selectedRouteId,
    required this.startLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<TripMapPage> {
  CameraPosition initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
  late List<Location> startPlacemark;
  late List<Location> destinationPlacemark;
  Set<Marker> markers = {};
  var _currentAddress = "";
  late String _startAddress;
  late String _destinationAddress;
  late PolylinePoints polylinePoints;

  // List of coordinates to join
  List<LatLng> polylineCoordinates = [];

  // Map storing polylines created by connecting two points
  Map<PolylineId, Polyline> polylines = {};
  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();
  late Position _currentPosition;
  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();
  late GoogleMapController mapController;
  bool _confirmingTrip = false;


  @override
  void initState() {
    super.initState();
    _startAddress = widget.startLocation;
    _destinationAddress = widget.destinationLocation;
    startAddressController.text = _startAddress;
    destinationAddressController.text = _destinationAddress;
    _calculateDistance();
    getCurrentLocation();
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    // Defining an ID
    PolylineId id = PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    setState(() {
      polylines[id] = polyline;
    });
  }
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Trip'),
          content: Text('Are you sure you want to confirm this trip?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss the dialog and return false
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Dismiss the dialog and return true
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value) {
        _confirmTrip(); // If user confirms, call _confirmTrip method
      }
    });
  }





  _calculateDistance() async {
    // Retrieving placemarks from addresses
    List<Location>? startPlacemark = await locationFromAddress(_startAddress);
    List<Location>? destinationPlacemark = await locationFromAddress(_destinationAddress);

    double startLatitude = startPlacemark![0].latitude;
    double startLongitude = startPlacemark[0].longitude;
    double destinationLatitude = destinationPlacemark![0].latitude;
    double destinationLongitude = destinationPlacemark[0].longitude;

    // Calculate the distance between the two points
    double distanceInMeters = await Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      destinationLatitude,
      destinationLongitude,
    );

    double distanceInKm = distanceInMeters / 1000; // Convert meters to kilometers
    print('Distance: $distanceInKm km');

    String startCoordinatesString = '($startLatitude, $startLongitude)';
    String destinationCoordinatesString = '($destinationLatitude, $destinationLongitude)';

    // Start Location Marker
    Marker startMarker = Marker(
      markerId: MarkerId(startCoordinatesString),
      position: LatLng(startLatitude, startLongitude),
      infoWindow: InfoWindow(
        title: 'Start $startCoordinatesString',
        snippet: _startAddress,
      ),
      icon: BitmapDescriptor.defaultMarker,
    );

    // Destination Location Marker
    Marker destinationMarker = Marker(
      markerId: MarkerId(destinationCoordinatesString),
      position: LatLng(destinationLatitude, destinationLongitude),
      infoWindow: InfoWindow(
        title: 'Destination $destinationCoordinatesString',
        snippet: _destinationAddress,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      markers.add(startMarker);
      markers.add(destinationMarker);
    });

    double miny = (startLatitude <= destinationLatitude) ? startLatitude : destinationLatitude;
    double minx = (startLongitude <= destinationLongitude) ? startLongitude : destinationLongitude;
    double maxy = (startLatitude <= destinationLatitude) ? destinationLatitude : startLatitude;
    double maxx = (startLongitude <= destinationLongitude) ? destinationLongitude : startLongitude;

    double southWestLatitude = miny;
    double southWestLongitude = minx;
    double northEastLatitude = maxy;
    double northEastLongitude = maxx;

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          northeast: LatLng(northEastLatitude, northEastLongitude),
          southwest: LatLng(southWestLatitude, southWestLongitude),
        ),
        100.0,
      ),
    );

    _createPolylines(startLatitude, startLongitude, destinationLatitude, destinationLongitude);

    setState(() {
      _confirmingTrip = true;
    });
  }

  _confirmTrip() async {
    setState(() {
      _confirmingTrip = false;
    });

    // Upload trip details to Firestore
    try {
      // Get current user ID
      User? user = FirebaseAuth.instance.currentUser;
      String? userId = user?.uid;

      // Prepare trip data
      Map<String, dynamic> tripData = {
        'startAddress': _startAddress,
        'destinationAddress': _destinationAddress,
        'startLatitude': markers.elementAt(0).position.latitude,
        'startLongitude': markers.elementAt(0).position.longitude,
        'destinationLatitude': markers.elementAt(1).position.latitude,
        'destinationLongitude': markers.elementAt(1).position.longitude,
        'routeid' : widget.selectedRouteId,
        'distance': calculateDistanceInKm(
          markers.elementAt(0).position.latitude,
          markers.elementAt(0).position.longitude,
          markers.elementAt(1).position.latitude,
          markers.elementAt(1).position.longitude,
        ),
        'startTime': DateTime.now(),
        'liveTrackingCoordinates': [], // Add live tracking coordinates later
        'vehicleId': widget.selectedVehicleId, // Add selectedVehicleId from widget
        'selectedVehicleName': widget.selectedVehicleName,
        'tripstatus': 0,
      };

      // Upload trip data to Firestore for the user
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(userId)
          .collection('userTrips')
          .add(tripData);

      print('Trip details uploaded successfully');


      // If tripstatus is  equal to 0, save to activetrips collection
      if (tripData['tripstatus'] == 0) {

        await FirebaseFirestore.instance
            .collection('activetrips')
            .doc(userId)
            .set(tripData);
      }

      // Navigate back to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverHome()),
      );


    } catch (e) {
      print('Error uploading trip details: $e');
    }
  }

  double calculateDistanceInKm(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      destinationLatitude,
      destinationLongitude,
    );

    return distanceInMeters / 1000; // Convert meters to kilometers
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];
      setState(() {
        _currentAddress = "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print("ERROR ADDRESS $e");
    }
  }

  getCurrentLocation() async {
    var status = await Permission.location.status;
    var permissionGranted = false;

    permissionGranted = status.isGranted;
    if (!permissionGranted) {
      permissionGranted = await Permission.location.request().isGranted;
    }
    if (permissionGranted) {
      if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
        await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high)
            .then((Position position) async {
          setState(() {
            _currentPosition = position;
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 14.0,
                ),
              ),
            );
          });
          await _getAddress();
        }).catchError((e) {
          print("ERROR $e");
        });
      } else {
        print("Location services are disabled");
      }
    } else {
      print("Permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trip Route",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: <Widget>[
          // Map View
          GoogleMap(
            markers: markers != null ? Set<Marker>.from(markers) : Set<Marker>(),
            initialCameraPosition: initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            polylines: Set<Polyline>.of(polylines.values),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),

          // Show zoom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ClipOval(
                    child: Material(
                      color: Colors.blue.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.add),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ClipOval(
                    child: Material(
                      color: Colors.blue.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.remove),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),






      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showConfirmationDialog();
        },
        label: Text(
          _confirmingTrip ? 'Confirm Trip' : 'Trip Confirmed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: Icon(Icons.directions_car),
      ),
    );
  }
}
