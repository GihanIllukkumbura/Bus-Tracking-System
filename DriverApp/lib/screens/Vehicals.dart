import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var vehicle = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(vehicle['sltbnumber'] + ' ' ),
                subtitle: Text('Registered Number: ' + vehicle['registeredNumber']),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(vehicle['imageUrl'][0]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
