import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jjan/loginSignup/user_ImageUI.dart';
import '../services/color_extension.dart';

class infoFormUI extends StatefulWidget {
  final String email;

  const infoFormUI({super.key, required this.email});

  @override
  State<infoFormUI> createState() => _infoFormUIState();
}


class _infoFormUIState extends State<infoFormUI> {
  final _formKey = GlobalKey<FormState>();
  var storeNameController = TextEditingController();
  @override
  void dispose() {
    storeNameController.dispose();
    super.dispose();
  }


  // ✅ Loading popup (optional for future use)
  void _showLoadingPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'Store Name',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          Divider(thickness: 2,),
                          const SizedBox(height: 30),
                          
                          // Note
                          Text(
                            'This will be used to determine\nif a scanned receipt is income or expense.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 50),
                          // TextField for store name
                          TextFormField(
                            controller: storeNameController,
                            inputFormatters: [
                              UpperCaseTextFormatter(), 
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your Store's Name";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text("Enter your Store's Name"),
                              hintText: 'Ex: ChowSing Company',
                              hintStyle: const TextStyle(color: Colors.black26),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue500,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.store, color: Colors.white),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final storeName = storeNameController.text.trim();

                                if (storeName.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Missing Store Name"),
                                      content: const Text("Please enter your store name before confirming."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                // Step 1: Confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Confirm Store Name"),
                                      content: Text("Is this correct?\n\n$storeName"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm != true) return; // user pressed "No"

                                // Step 2: Show loading popup
                                _showLoadingPopup("Saving Store Name...");

                                try {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) throw Exception("User not logged in");

                                  // Save to Firestore (single doc under /users/{uid})
                                  await FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(currentUser.uid)
                                      .set(
                                    {
                                      "email": currentUser.email,
                                      "storeName": storeName,
                                      "createdAt": FieldValue.serverTimestamp(),
                                      "updatedAt": FieldValue.serverTimestamp(), // ✅ track updates too
                                    },
                                    SetOptions(merge: true), // merge so we don’t overwrite
                                  );

                                  if (Navigator.canPop(context)) Navigator.pop(context); // close loading

                                  // Success popup
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle, // makes it round
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              "Saved Successfully",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );


                                  // Auto close + navigate
                                  await Future.delayed(const Duration(seconds: 2));
                                  if (Navigator.canPop(context)) Navigator.pop(context); // close success popup

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserImageUI(email: widget.email, storeName: storeName),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                } catch (e) {
                                  if (Navigator.canPop(context)) Navigator.pop(context); // close loading

                                  // Error dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Upload Failed"),
                                      content: const Text(
                                        "Failed to save Store Name.\nPlease try again.\nThank you!",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'CONFIRM',
                                style: TextStyle(
                                  fontSize: 19,
                                  color: TColor.white,
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
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
