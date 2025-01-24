import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../widgets/user_image_picker.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _nicNumberController;
  late TextEditingController _addressController;
  late TextEditingController _licenseNumberController;

  File? _selectedImage;
  bool _isLogin = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _nicNumberController = TextEditingController();
    _addressController = TextEditingController();
    _licenseNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _nicNumberController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    String? imageUrl;

    // Upload image to Firebase Storage if a new image is selected
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');

      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();
    }

    // Update user data in Firestore
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final updateData = {
      'username': _usernameController.text,
      'phone_number': _phoneNumberController.text,
      'nic_number': _nicNumberController.text,
      'address': _addressController.text,
      'licenseNumber': _licenseNumberController.text,
    };

    if (imageUrl != null) {
      updateData['image_url'] = imageUrl;
    }

    await userDoc.update(updateData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic>? userData =
              snapshot.data!.data() as Map<String, dynamic>?;

              _usernameController.text = userData?['username'] ?? '';
              _phoneNumberController.text = userData?['phone_number'] ?? '';
              _nicNumberController.text = userData?['nic_number'] ?? '';
              _addressController.text = userData?['address'] ?? '';
              _licenseNumberController.text = userData?['licenseNumber'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          UserImagePicker(
                            onPickImage: (File pickedImage) {
                              setState(() {
                                _selectedImage = pickedImage;
                              });
                            },
                          ),
                        if (_selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _nicNumberController,
                    decoration: InputDecoration(
                      labelText: 'NIC Number',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Home Address',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _licenseNumberController,
                    decoration: InputDecoration(
                      labelText: 'License Number',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Save Changes'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
