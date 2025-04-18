import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CompletedSchedulesPage extends StatelessWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  // Constructor with dependency injection
  CompletedSchedulesPage({
    super.key,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  final Color primaryColor = Color(0xFF2E7D32);
  final Color secondaryColor = Color(0xFF4CAF50);
  final Color backgroundColor = Colors.grey[200]!;
  final Color accentColor = Colors.red[100]!;
  final Color cardColor = Color(0xFF81C784);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            "Please log in first",
            style: TextStyle(fontSize: 18, color: primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Completed Special Schedules',
          style: TextStyle(color: primaryColor),
        ),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: firestore
            .collection('specialschedule')
            .where('wasteCollectorId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: secondaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No completed schedules found.",
                style: TextStyle(fontSize: 18, color: primaryColor),
              ),
            );
          }

          final schedules = snapshot.data!.docs;
          double totalWasteCollected = _calculateTotalWaste(schedules);

          return Column(
            children: [
              _buildTotalWasteCollected(totalWasteCollected),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return _buildScheduleCard(schedule, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ✅ *Function to calculate total waste collected*
  double _calculateTotalWaste(List<QueryDocumentSnapshot> schedules) {
    double totalWaste = 0.0;
    for (var schedule in schedules) {
      for (var waste in schedule['wasteTypes']) {
        totalWaste += (waste['weight'] as num).toDouble();
      }
    }
    return totalWaste;
  }

  /// ✅ *Widget to show total waste collected*
  Widget _buildTotalWasteCollected(double totalWasteCollected) {
    return Container(
      padding: EdgeInsets.all(16),
      color: secondaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Total Waste Collected:  ",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "${totalWasteCollected.toStringAsFixed(2)} kg",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// ✅ *Widget to build each schedule card*
  Widget _buildScheduleCard(QueryDocumentSnapshot schedule, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: backgroundColor,
      child: ExpansionTile(
        title: Text(
          "Schedule #${index + 1}",
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        subtitle: Text(
          "Date: ${_formatDate(schedule['scheduledDate'])}",
          style: TextStyle(color: secondaryColor),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: ${schedule['status']}",
                    style: TextStyle(color: primaryColor)),
                SizedBox(height: 8),
                Text("Waste Types:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                ...schedule['wasteTypes'].map<Widget>((waste) {
                  return Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${waste['type']}:",
                            style: TextStyle(color: Colors.black)),
                        Text("${waste['weight']} kg",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ *Function to format date correctly*
  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy').format(date.toDate());
    } else if (date is String) {
      return date;
    }
    return 'Invalid Date';
  }
}