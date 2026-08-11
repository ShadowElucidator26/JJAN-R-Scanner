import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/services/color_extension.dart';
class ChangeStoreNameUI extends StatefulWidget {
  const ChangeStoreNameUI({super.key});

  @override
  State<ChangeStoreNameUI> createState() => _ChangeStoreNameUIState();
}

class _ChangeStoreNameUIState extends State<ChangeStoreNameUI> {
  final _formKey = GlobalKey<FormState>();
  final storeNameController = TextEditingController();

  String? currentStoreName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStoreName();
  }

  Future<void> _loadCurrentStoreName() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          currentStoreName = doc.data()?["storeName"] ?? "N/A";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load store name: $e"), backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStoreName() async {
    if (!_formKey.currentState!.validate()) return;

    final newStoreName = storeNameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Update", style: TextStyle(color: TColor.blue100)),
        content: Text("Change store name to:\n\n$newStoreName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes", style: TextStyle(color: Colors.red),)),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "storeName": newStoreName,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Show success dialog
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Fetched Data Successful",
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

      // Wait for 1.5s, then close dialog and navigate
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // close success dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const mainLobby_Page()), // go back to Profile page
          (Route<dynamic> route) => false,
        );
      });


    } catch (e) {
      Navigator.pop(context); // close loading popup if open
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Update Failed"),
            content: const Text("Incorrect email or password.\nPlease try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating store name: $e"), backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isLoading = false);
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
              TColor.blue100,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                                Text(
                                  'Change Store Name',
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.w900,
                                    color: TColor.blue500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Divider(thickness: 2),
                                const SizedBox(height: 20),

                                if (currentStoreName != null)
                                  Text(
                                    "Current Store Name:",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentStoreName ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: TColor.blue500.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 40),

                                TextFormField(
                                  controller: storeNameController,
                                  inputFormatters: [UpperCaseTextFormatter()],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your new Store Name";
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    label: const Text("New Store Name"),
                                    hintText: "Enter new store name",
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: TColor.blue500,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.store, color: Colors.white),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _updateStoreName,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TColor.blue500,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'UPDATE STORE NAME',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
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
