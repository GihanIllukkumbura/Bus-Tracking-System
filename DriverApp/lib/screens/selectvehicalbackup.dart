// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'Select_Route.dart';
//
// class SelectVehicle extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Vehicle List'),
//       ),
//       body: FutureBuilder(
//         future: FirebaseFirestore.instance.collection('activetrips').get(),
//         builder: (context, AsyncSnapshot<QuerySnapshot> activeTripsSnapshot) {
//           if (!activeTripsSnapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           // Extract vehicle IDs from activetrips collection
//           List<String> activeVehicleIds = activeTripsSnapshot.data!.docs
//               .map((doc) => doc['vehicleId'] as String)
//               .toList();
//
//           return StreamBuilder(
//             stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
//             builder: (context, AsyncSnapshot<QuerySnapshot> vehiclesSnapshot) {
//               if (!vehiclesSnapshot.hasData) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               // Filter vehicles to exclude those in activeVehicleIds
//               var availableVehicles = vehiclesSnapshot.data!.docs.where((doc) {
//                 var vehicle = doc.data() as Map<String, dynamic>;
//                 return !activeVehicleIds.contains(doc.id);
//               }).toList();
//
//               if (availableVehicles.isEmpty) {
//                 return Center(child: Text('There is no vehicle to select at this moment.'));
//               }
//
//               return ListView.builder(
//                 itemCount: availableVehicles.length,
//                 itemBuilder: (context, index) {
//                   var vehicle = availableVehicles[index].data() as Map<String, dynamic>;
//                   return ListTile(
//                     title: Text(vehicle['sltbnumber'] + ' '),
//                     subtitle: Text('Registered Number: ' + vehicle['registeredNumber']),
//                     leading: FadeInImage.assetNetwork(
//                       placeholder: 'assets/vehicle_placeholder.png',
//                       image: vehicle['imageUrl'][0],
//                       imageErrorBuilder: (context, error, stackTrace) {
//                         return Icon(Icons.directions_bus);
//                       },
//                       fit: BoxFit.cover,
//                     ),
//                     onTap: () {
//                       String selectedVehicleId = availableVehicles[index].id;
//                       String selectedVehicleName = vehicle['sltbnumber'];
//
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SelectRoute(
//                             selectedVehicleId: selectedVehicleId,
//                             selectedVehicleName: selectedVehicleName,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
