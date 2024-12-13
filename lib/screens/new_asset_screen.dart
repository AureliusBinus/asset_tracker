import 'package:asset_tracker/data/categories.dart';
import 'package:asset_tracker/models/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewAssetScreen extends StatefulWidget {
  const NewAssetScreen({super.key});

  @override
  State<NewAssetScreen> createState() => _NewAssetScreenState();
}

class _NewAssetScreenState extends State<NewAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 0.1;
  var _enteredBuyPrice = 1.0;
  var _selectedCategory = categories[Categories.layer1]!;
  bool _isAdding = true;
  final authenticatedUser = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String colorToHex(Color color) {
    return '#${color.alpha.toRadixString(16).padLeft(2, '0')}'
        '${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  Future<void> submitToDb() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        CollectionReference assetCollection = _firestore
            .collection('assets')
            .doc(authenticatedUser.uid)
            .collection('user_asset');

        QuerySnapshot existingAsset = await assetCollection
            .where('name', isEqualTo: _enteredName)
            .limit(1)
            .get();

        if (_isAdding) {
          if (existingAsset.docs.isNotEmpty) {
            DocumentSnapshot assetDoc = existingAsset.docs.first;
            double currentQuantity = assetDoc['quantity'];
            double currentBuyPrice = assetDoc['buyPrice'];

            double totalQuantity = currentQuantity + _enteredQuantity;
            double averageBuyPrice = ((currentBuyPrice * currentQuantity) +
                    (_enteredBuyPrice * _enteredQuantity)) /
                totalQuantity;

            await assetDoc.reference.update({
              'quantity': totalQuantity,
              'buyPrice': averageBuyPrice,
            });

            await assetDoc.reference.collection('history').add({
              'timestamp': DateTime.now(),
              'type': 'add',
              'quantity': _enteredQuantity,
              'comment': 'Added asset quantity'
            });

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Asset updated successfully!')),
            );
          } else {
            DocumentReference newAssetRef = await assetCollection.add({
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'buyPrice': _enteredBuyPrice,
              'catTitle': _selectedCategory.title,
              'color': colorToHex(_selectedCategory.color),
              'created_date': DateTime.now(),
            });

            await newAssetRef.collection('history').add({
              'timestamp': DateTime.now(),
              'type': 'add',
              'quantity': _enteredQuantity,
              'comment': 'Initial purchase'
            });

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Asset added successfully!')),
            );
          }
        } else {
          if (existingAsset.docs.isNotEmpty) {
            DocumentSnapshot assetDoc = existingAsset.docs.first;
            double currentQuantity = assetDoc['quantity'];

            if (_enteredQuantity >= currentQuantity) {
              await assetDoc.reference.delete();
            } else {
              double newQuantity = currentQuantity - _enteredQuantity;
              await assetDoc.reference.update({
                'quantity': newQuantity,
              });
            }

            await assetDoc.reference.collection('history').add({
              'timestamp': DateTime.now(),
              'type': 'remove',
              'quantity': _enteredQuantity,
              'comment': 'Reduced asset quantity'
            });

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Asset quantity changed!')),
            );
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Asset "$_enteredName" does not exist!')),
            );
          }
        }
        navigator.pop();
        navigator.pop();
      } catch (e) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to add asset: $e')),
        );
        navigator.pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid form input')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new asset'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    isSelected: [_isAdding, !_isAdding],
                    onPressed: (index) {
                      setState(() {
                        _isAdding =
                            index == 0; // Index 0 for "Add", 1 for "Remove"
                      });
                    },
                    fillColor: Colors.transparent,
                    selectedColor: Colors.white,
                    color: Colors.grey,
                    children: [
                      Container(
                        width: 150,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _isAdding ? Colors.green : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: const Center(child: Text('Add Asset')),
                      ),
                      Container(
                        width: 150,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: !_isAdding ? Colors.red : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: const Center(child: Text('Remove Asset')),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Asset Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _enteredName = newValue!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null ||
                            double.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        _enteredQuantity = double.tryParse(newValue!)!;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField(
                      isExpanded: true,
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    category.value.title,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_isAdding) const SizedBox(height: 12),
              if (_isAdding)
                TextFormField(
                  decoration: const InputDecoration(
                    label: Text('Buy Price'),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _enteredBuyPrice.toString(),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null ||
                        double.tryParse(value)! <= 0) {
                      return 'Must be a valid, positive number';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    _enteredBuyPrice = double.tryParse(newValue!)!;
                  },
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _formKey.currentState!.reset();
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: submitToDb,
                    child: Text(_isAdding ? 'Add Item' : 'Update Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
