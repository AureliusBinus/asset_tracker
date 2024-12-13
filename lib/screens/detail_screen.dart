import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatelessWidget {
  DetailScreen({
    super.key,
    required this.assetID,
    required this.assetName,
  });

  final String assetID;
  final String assetName;

  final authenticatedUser = FirebaseAuth.instance.currentUser!;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchHistory(String assetID) async {
    QuerySnapshot historySnapshot = await _firestore
        .collection('assets')
        .doc(authenticatedUser.uid)
        .collection('user_asset')
        .doc(assetID)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();

    return historySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset History for $assetName'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchHistory(assetID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No transaction history available.'),
            );
          }

          final history = snapshot.data!;
          final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final transaction = history[index];
              final DateTime dateTime =
                  (transaction['timestamp'] as Timestamp).toDate();
              final String formattedDate = formatter.format(dateTime);

              return ListTile(
                title: Text(transaction['type']),
                subtitle: Text(
                  '${transaction['quantity']} units on $formattedDate',
                ),
                trailing: Text(transaction['comment'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
