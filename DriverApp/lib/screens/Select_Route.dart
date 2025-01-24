import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MapPage.dart';
import 'TripMapPage.dart';

class SelectRoute extends StatelessWidget {
  final String selectedVehicleId;
  final String selectedVehicleName;

  SelectRoute({required this.selectedVehicleId, required this.selectedVehicleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Route'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('route').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var route = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Route Number: ${route['routenumber']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start: ${route['start']}'),
                    Text('Destination: ${route['destination']}'),
                  ],
                ),
                onTap: () {
                  String selectedRouteId = snapshot.data!.docs[index].id;
                  String startLocation = route['start'];
                  String destinationLocation = route['destination'];

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripMapPage(
                        selectedVehicleId: selectedVehicleId,
                        selectedVehicleName : selectedVehicleName,
                        selectedRouteId: selectedRouteId,
                        startLocation: startLocation,
                        destinationLocation: destinationLocation,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
