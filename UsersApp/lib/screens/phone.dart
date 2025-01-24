import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class DialPadScreen extends StatefulWidget {
  @override
  _DialPadScreenState createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  String? driverPhoneNumber;
  String? adminPhoneNumber;
  String? driverName;
  String? adminEmail; // Added to store admin's email

  @override
  void initState() {
    super.initState();
    _fetchDriverAndAdminInfo();
  }

  Future<void> _fetchDriverAndAdminInfo() async {
    try {
      // Fetch driver ID from tracking collection
      DocumentSnapshot trackingDoc = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(currentUserUid)
          .get();

      String? driverId = trackingDoc['driverId'];

      // Fetch driver info from users collection
      if (driverId != null) {
        DocumentSnapshot driverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(driverId)
            .get();

        setState(() {
          driverPhoneNumber = driverDoc['phone_number'];
          driverName = driverDoc['username'];
        });
      }

      // Fetch admin info from users collection where role is admin
      QuerySnapshot adminQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1) // Assuming there's only one admin
          .get();

      if (adminQuerySnapshot.docs.isNotEmpty) {
        DocumentSnapshot adminDoc = adminQuerySnapshot.docs.first;

        setState(() {
          adminPhoneNumber = adminDoc['phone_number'];
          adminEmail = adminDoc['email']; // Fetching admin's email
        });
      }
    } catch (e) {
      // Handle error
      print('Error fetching driver or admin info: $e');
    }
  }

  void _loadDialPad(String phoneNumber) async {
    if (await Permission.phone.request().isGranted) {
      String formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\s+\b|\b\s'), '');
      String url = 'tel:$formattedPhoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        // Handle error: Could not launch phone dialer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer. You might need a default phone app or check the app\'s permissions.'),
          ),
        );
      }
    } else {
      // Handle case when permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone permission is required to make calls.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call List'),
      ),
      body: ListView(
        children: [
          if (driverPhoneNumber != null && driverName != null)
            ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.account_circle, size: 40.0),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    driverName!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone),
                    onPressed: () {
                      _loadDialPad(driverPhoneNumber!);
                    },
                  ),
                ],
              ),
              subtitle: Text(driverPhoneNumber!),
            ),
          if (adminPhoneNumber != null && adminEmail != null)
            ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.admin_panel_settings, size: 40.0),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    adminEmail!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              subtitle: Text(adminPhoneNumber!),
              trailing: IconButton(
                icon: Icon(Icons.phone),
                onPressed: () {
                  _loadDialPad(adminPhoneNumber!);
                },
              ),
            ),
        ],
      ),
    );
  }
}
