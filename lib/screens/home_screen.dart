import 'package:asset_tracker/screens/detail_screen.dart';
import 'package:asset_tracker/screens/new_asset_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var f = NumberFormat("#,###.###", "en_US");
  var g = NumberFormat("#.##", "en_US");
  final authenticatedUser = FirebaseAuth.instance.currentUser!;
  String? username;

  Future<void> getUsername() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('assets')
          .doc(authenticatedUser.uid)
          .get();

      setState(() {
        username = docSnapshot['username'] ?? 'Anonym';
      });
    } catch (e) {
      username = 'Anonym';
    }
  }

  void _addItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewAssetScreen(),
      ),
    );
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    getUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Asset Tracker'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 1) {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                enabled: false,
                child: Text(
                  'Logged in as: $username',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .doc(authenticatedUser.uid)
            .collection('user_asset')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items added'));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (ctx, index) {
                return Dismissible(
                  key: ValueKey(index),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete'),
                          content:
                              const Text('Are you sure to delete this item?'),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text('DELETE'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text('CANCEL'),
                            )
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await FirebaseFirestore.instance
                          .collection('assets')
                          .doc(authenticatedUser.uid)
                          .collection('user_asset')
                          .doc(snapshot.data!.docs[index].id)
                          .delete();
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            assetID: snapshot.data!.docs[index].id,
                            assetName: snapshot.data!.docs[index]['name'],
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(snapshot.data!.docs[index].data()['name']),
                      subtitle: Text(
                        g.format(snapshot.data!.docs[index].data()['quantity']),
                      ),
                      leading: Container(
                        width: 24,
                        height: 24,
                        color: hexToColor(
                            snapshot.data!.docs[index].data()['color']),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Average Price'),
                          Text(
                            '\$ ${f.format(snapshot.data!.docs[index].data()['buyPrice'])}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          );
        },
      ),
    );
  }
}
