import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({Key? key}) : super(key: key);

  @override
  _TripHistoryPageState createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  late Future<List<DocumentSnapshot>?> _tripHistoryFuture;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tripHistoryFuture = _loadTripHistory();
  }

  Future<List<DocumentSnapshot>?> _loadTripHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(userId)
          .collection('userTrips')
          .orderBy('startTime', descending: true) // Order by startTime in descending order
          .get();
      return snapshot.docs;
    }
    return null; // Return null if user is null
  }

  List<DocumentSnapshot> _filterTripsByMonthAndYear(
      List<DocumentSnapshot> trips, String month, int year) {
    return trips.where((trip) {
      final tripData = trip.data() as Map<String, dynamic>;
      if (tripData['startTime'] != null) {
        final tripDate = (tripData['startTime'] as Timestamp).toDate();
        final tripMonth = DateFormat('MMMM').format(tripDate);
        final tripYear = DateFormat('yyyy').format(tripDate);
        return tripMonth == month && tripYear == year.toString();
      }
      return false;
    }).toList();
  }

  Widget _buildTripInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis, // Use ellipsis if the text is too long
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trip['date'] ?? ''),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTripInfo('Start Address', trip['startAddress'] ?? ''),
            _buildTripInfo('Destination Address', trip['destinationAddress'] ?? ''),
            _buildTripInfo(
                'Distance',
                trip['distance'] != null
                    ? '${(trip['distance'] as double).round()} km'
                    : ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History'),
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      items: DateFormat().dateSymbols.MONTHS.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMonth = newValue!;
                          _tripHistoryFuture = _loadTripHistory();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(10, (index) => DateTime.now().year - index)
                          .map((int year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedYear = newValue!;
                          _tripHistoryFuture = _loadTripHistory();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DocumentSnapshot>?>(
                future: _tripHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No trip history available'));
                  } else {
                    final filteredTrips = _filterTripsByMonthAndYear(
                        snapshot.data!, _selectedMonth, _selectedYear);
                    if (filteredTrips.isEmpty) {
                      return Center(child: Text('No trip history available for $_selectedMonth $_selectedYear'));
                    } else {
                      return ListView.builder(
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          var trip = filteredTrips[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => _showTripDetails(context, trip),
                            child: Card(
                              color: Color.fromRGBO(229, 253, 207, 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              margin: EdgeInsets.all(8.0),
                              elevation: 2.0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text(
                                    trip['date'] ?? '',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTripInfo('Start Address', trip['startAddress'] ?? ''),
                                      _buildTripInfo('Destination Address', trip['destinationAddress'] ?? ''),
                                      _buildTripInfo(
                                          'Distance',
                                          trip['distance'] != null
                                              ? '${(trip['distance'] as double).round()} km'
                                              : ''),
                                      _buildTripInfo(
                                          'Start Date',
                                          trip['startTime'] != null
                                              ? DateFormat('MMMM d, yyyy')
                                              .format(trip['startTime'].toDate())
                                              : ''),
                                      _buildTripInfo(
                                          'Start Time',
                                          trip['startTime'] != null
                                              ? DateFormat.Hm().format(trip['startTime'].toDate())
                                              : ''),
                                      _buildTripInfo(
                                          'Bus used', trip['selectedVehicleName'] ?? ''),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
