import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/services/cloudinary_services.dart';

class UpdateUserImageUI extends StatefulWidget {

  const UpdateUserImageUI({
    super.key,
  });

  @override
  State<UpdateUserImageUI> createState() => _UpdateUserImageUIState();
}

class _UpdateUserImageUIState extends State<UpdateUserImageUI> {
  File? _newImageFile;
  String? _currentImageUrl;
  final picker = ImagePicker();
  bool _isUpdating = false;
  bool _isNewImageEmpty = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentImage();
  }

  Future<void> _loadCurrentImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    setState(() {
      _currentImageUrl = doc.data()?['profileImage'];
    });
  }

  Future<void> _pickNewImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
      _isNewImageEmpty = false;
    }
  }

  Future<void> _updateImage() async {
    if (_isNewImageEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Choose New Image first, before proceeding..."), backgroundColor: TColor.blue100,),
      );
      return;
    };

    setState(() => _isUpdating = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Upload the new image to Cloudinary
      final uploadResp = await CloudinaryProfileService.uploadUserProfile(
        _newImageFile!.path,
        userId: user.uid,
      );

      if (uploadResp['success'] == true) {
        final newUrl = uploadResp['secure_url'];

        // Update the Firestore document with the new image URL
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({"profileImage": newUrl}, SetOptions(merge: true));

        setState(() {
          _currentImageUrl = newUrl;
          _newImageFile = null;
        });

        // Optionally navigate back or show a success dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image updated successfully!"), backgroundColor: Colors.green,),
        );
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update image: $e"), backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              TColor.blue50,
              TColor.blue10,
              TColor.blue5,
              TColor.blue20,
              TColor.blue20,
              TColor.blue10,
              TColor.blue5,
              TColor.blue100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Expanded(flex: 1, child: SizedBox(height: 10)),
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 45, 25, 20),
                  decoration: BoxDecoration(
                    color: TColor.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Update User Image',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(thickness: 2),
                          const SizedBox(height: 30),
                          const Text(
                            "Choose a new profile picture to update your account.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Circle layout with arrow
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Current Image
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: TColor.blue10,
                                backgroundImage:
                                    _currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null,
                                child: _currentImageUrl == null
                                    ? const Icon(Icons.image, size: 60, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Icon(Icons.arrow_right_alt, size: 40, color: TColor.blue500),
                              const SizedBox(width: 15),
                              // New Image
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: TColor.blue10,
                                backgroundImage:
                                    _newImageFile != null ? FileImage(_newImageFile!) : null,
                                child: _newImageFile == null
                                    ? const Icon(Icons.image, size: 60, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: _pickNewImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.blue20,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.image, color: Colors.white),
                            label: const Text(
                              "Choose New Image",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _updateImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue500,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isUpdating
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "UPDATE USER IMAGE",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: 
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          "BACK",
          style: TextStyle(fontSize: 18, color: TColor.blue500, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
