import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AssignedTrips extends StatefulWidget {
  @override
  _AssignedTripsState createState() => _AssignedTripsState();
}

class _AssignedTripsState extends State<AssignedTrips> {
  String? lastNotifiedRoute; // Keep track of the last route we notified the user about
  String? lastNotifiedVehicle; // Keep track of the last vehicle we notified the user about

  @override
  void initState() {
    super.initState();
    _checkForRouteChanges(); // Check for route changes when the widget is first created
  }

  // Function to show notification
  void _showNotification(String routeNumber, String vehicleNumber, String tripId) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Changed Your Trip!',
        body: 'Route Number: $routeNumber, Vehicle: $vehicleNumber',
        notificationLayout: NotificationLayout.Default,
        payload: {'trip_id': tripId},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'details',
          label: 'Click here to get more',
        ),
      ],
    );
  }

  void _checkForRouteChanges() {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid == null) return;

    FirebaseFirestore.instance
        .collection('adminTrips')
        .where('driver', isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final tripData = doc.data() as Map<String, dynamic>;
        final tripId = doc.id;
        final destination = tripData['destination'] ?? 'Unknown';
        final vehicleId = tripData['vehicle'] ?? 'No vehicle specified';

        String routeNumber = getRouteNumber(destination);

        try {
          final vehicleSnapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .get();
          final vehicleData = vehicleSnapshot.data() as Map<String, dynamic>?;
          final sltbNumber = vehicleData?['sltbnumber'] ?? 'Unknown';

          bool hasRouteChanged = routeNumber != lastNotifiedRoute;
          bool hasVehicleChanged = sltbNumber != lastNotifiedVehicle;

          // Debugging prints
          print('Checking trip: $tripId');
          print('Route number: $routeNumber, Last notified route: $lastNotifiedRoute');
          print('SLTB number: $sltbNumber, Last notified vehicle: $lastNotifiedVehicle');

          if (hasRouteChanged || hasVehicleChanged) {
            _showNotification(routeNumber, sltbNumber, tripId);
            lastNotifiedRoute = routeNumber;
            lastNotifiedVehicle = sltbNumber;
          }
        } catch (e) {
          print('Error fetching vehicle data: $e');
        }
      }
    });
  }


  // Function to get route number based on destination
  String getRouteNumber(String destination) {
    switch (destination) {
      case 'Kurunagala':
        return 'A10';
      case 'Colombo':
        return 'A3';
      default:
        return 'No route number';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Trips'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminTrips')
            .where('driver', isEqualTo: userUid)
            .snapshots(),
        builder: (context, snapshot) {
          // Check for connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }

          // Check for no data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No trips available.'));
          }

          return ListView(
            padding: EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              final tripData = doc.data() as Map<String, dynamic>;

              // Helper function to handle conversion from various types
              DateTime? parseDate(dynamic date) {
                if (date is Timestamp) {
                  return date.toDate();
                } else if (date is String) {
                  try {
                    return DateTime.parse(date);
                  } catch (e) {
                    return null; // Handle parsing error
                  }
                }
                return null;
              }

              // Extract fields and handle types
              final createdAt = parseDate(tripData['createdAt']);
              final date = parseDate(tripData['date']);
              final description = tripData['description'] ?? 'No description provided';
              final destination = tripData['destination'] ?? 'Unknown';
              final driver = tripData['driver'] ?? 'Unknown';
              final time = tripData['time'] ?? 'No time provided';
              final vehicleId = tripData['vehicle'] ?? 'No vehicle specified';

              // Get route number based on destination
              final routenumber = getRouteNumber(destination);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicleId)
                    .get(),
                builder: (context, vehicleSnapshot) {
                  if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading vehicle info...'),
                    );
                  }

                  if (vehicleSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error loading vehicle info'),
                    );
                  }

                  final vehicleData = vehicleSnapshot.data?.data() as Map<String, dynamic>?;
                  final sltbnumber = vehicleData?['sltbnumber'] ?? 'Unknown';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        'Destination: $destination',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Date: ${date != null ? DateFormat('yyyy-MM-dd').format(date) : 'No date provided'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Start Time: $time',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Description: $description',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Vehicle: $sltbnumber',
                            style: TextStyle(fontSize: 16),
                          ),
                          if (routenumber != 'No route number') ...[
                            SizedBox(height: 4),
                            Text(
                              'Route Number: $routenumber',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                          SizedBox(height: 4),
                          Text(
                            'Created At: ${createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt) : 'No creation date provided'}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
