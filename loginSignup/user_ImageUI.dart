import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jjan/loginSignup/user_welcomeUI.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/services/transition_BottomUp.dart';
import 'package:jjan/services/cloudinary_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserImageUI extends StatefulWidget {
  final String email;
  final String storeName;

  const UserImageUI({
    super.key,
    required this.email,
    required this.storeName,
  });

  @override
  State<UserImageUI> createState() => _UserImageUIState();
}

class _UserImageUIState extends State<UserImageUI> {
  File? _imageFile;
  final picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {      
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      bool uploadDone = false;
      bool uploadSuccess = false;
      String? uploadedUrl;

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            Future.microtask(() async {
              if (!uploadDone) {
                // Upload using CloudinaryProfileService
                final uploadResp = await CloudinaryProfileService.uploadUserProfile(
                  _imageFile!.path,
                  userId: user.uid,
                );

                uploadDone = true;
                uploadSuccess = uploadResp['success'] == true;
                if (uploadSuccess) uploadedUrl = uploadResp['secure_url'];

                try { setModalState(() {}); } catch (_) {}

                if (uploadSuccess) {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .set({"profileImage": uploadedUrl}, SetOptions(merge: true));
                }

                await Future.delayed(const Duration(milliseconds: 600));
                if (Navigator.canPop(context)) Navigator.of(context).pop();
              }
            });

            Widget statusIcon(bool done, bool success) {
              if (!done) return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
              return Icon(success ? Icons.check_circle : Icons.cancel, color: success ? Colors.green : Colors.red);
            }

            return AlertDialog(
              title: const Text("Uploading Profile Picture"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text("Uploading to Cloudinary")),
                      statusIcon(uploadDone, uploadSuccess),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (uploadDone && !uploadSuccess)
                    const Text("Failed to upload image.", style: TextStyle(color: Colors.red)),
                ],
              ),
            );
          });
        },
      );

      setState(() => _isUploading = false);

      if (uploadSuccess && uploadedUrl != null) {
        Navigator.pushAndRemoveUntil(
          context,
          slideTransition(
            welcomeUserUI(email: widget.email, storeName: widget.storeName, isLogin: false,),
            SlideDirection.leftToRight,
          ),
          (route) => false,
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Upload Failed"),
            content: const Text("Could not upload profile picture. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Upload Failed"),
          content: Text("Error: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
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
                      child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              'User Image',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: TColor.blue500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(thickness: 2,),
                            const SizedBox(height: 30),
                            
                            const Text(
                              "Upload your profile picture to personalize your account.",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: TColor.blue10,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : null,
                              child: _imageFile == null
                                  ? const Icon(Icons.person,
                                      size: 80, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue20,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.image, color: Colors.white),
                              label: const Text(
                                "Choose Image",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUploading ? null : _uploadImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColor.blue500,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isUploading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        "CONFIRM",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}