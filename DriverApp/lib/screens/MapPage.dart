import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/dark.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  void getCurrentLiveLocationOfUser() async {
    StreamSubscription<Position> positionStream =
    Geolocator.getPositionStream().listen((Position position) {
      currentPositionOfUser = position;
      LatLng positionOfUserInLatLng =
      LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      CameraPosition cameraPosition =
      CameraPosition(target: positionOfUserInLatLng, zoom: 15);
      controllerGoogleMap!.animateCamera(
          CameraUpdate.newCameraPosition(cameraPosition));

      // Upload user's live location to Firestore
      final user = FirebaseAuth.instance.currentUser!;
      FirebaseFirestore.instance
          .collection('locations')
          .doc(user.uid)
          .set({
        'userid': user.uid,
        'latitude': currentPositionOfUser!.latitude,
        'longitude': currentPositionOfUser!.longitude,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: LatLng(0, 0),
              zoom: 10,
            ),
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              getCurrentLiveLocationOfUser();
            },
          ),
        ],
      ),
    );
  }
}
