import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Select_Route.dart';

class SelectVehicle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle List'),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('activetrips').get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> activeTripsSnapshot) {
          if (!activeTripsSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Extract vehicle IDs from activetrips collection
          List<String> activeVehicleIds = activeTripsSnapshot.data!.docs
              .map((doc) => doc['vehicleId'] as String)
              .toList();

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> vehiclesSnapshot) {
              if (!vehiclesSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // Map vehicles and their status (in use or not)
              var availableVehicles = vehiclesSnapshot.data!.docs.map((doc) {
                var vehicle = doc.data() as Map<String, dynamic>;
                var isInUse = activeVehicleIds.contains(doc.id);
                return {
                  'id': doc.id,
                  'data': vehicle,
                  'isInUse': isInUse,
                };
              }).toList();

              if (availableVehicles.isEmpty) {
                return Center(child: Text('There are no vehicles to select at this moment.'));
              }

              return ListView.builder(
                itemCount: availableVehicles.length,
                itemBuilder: (context, index) {
                  var vehicle = availableVehicles[index];
                  var vehicleData = vehicle['data'] as Map<String, dynamic>;
                  var isInUse = vehicle['isInUse'] as bool;

                  return ListTile(
                    title: Text(vehicleData['sltbnumber'] + ' '),
                    subtitle: Text('Registered Number: ' + vehicleData['registeredNumber']),
                    leading: FadeInImage.assetNetwork(
                      placeholder: 'assets/vehicle_placeholder.png',
                      image: vehicleData['imageUrl'][0],
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.directions_bus);
                      },
                      fit: BoxFit.cover,
                    ),
                    tileColor: isInUse ? Colors.green.shade100 : null,
                    trailing: isInUse ? Text(
                      'In Use',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ) : null,
                    enabled: !isInUse, // Disable selection if in use
                    onTap: isInUse ? null : () {
                      String selectedVehicleId = vehicle['id'] as String; // Get the document ID as the vehicle ID
                      String selectedVehicleName = vehicleData['sltbnumber'];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectRoute(
                            selectedVehicleId: selectedVehicleId,
                            selectedVehicleName: selectedVehicleName,
                          ),
                        ),
                      );
                    },
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
