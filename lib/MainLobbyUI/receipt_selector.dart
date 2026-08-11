// receipt_selector.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReceiptSelector {
  /// Shows a dialog asking "What type of receipt is it?"
  /// Returns a string indicating the selected endpoint, or null if dismissed
  static Future<String?> showReceiptTypeDialog(
      BuildContext context, File imageFile) async {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "What receipt did you capture?",
            style: TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: _ReceiptOptions(imageFile: imageFile),
        );
      },
    );
  }
}
Future<Map<String, dynamic>?> fetchUserStore(String uid) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final docSnapshot = await firestore.collection('users').doc(uid).get();

    if (!docSnapshot.exists) {
      print("Document for UID $uid does not exist.");
      return null;
    }

    final data = docSnapshot.data()!;
    final storeName = data['storeName'] ?? "";

    print("Store name for UID $uid: $storeName");

    return {
      "storeName": storeName,
    };
  } catch (e) {
    print("Error fetching user store: $e");
    return null;
  }
}

class _ReceiptOptions extends StatelessWidget {
  final File imageFile;
  const _ReceiptOptions({Key? key, required this.imageFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Button builder
    Widget _receiptTypeButton({
  required String label,
  required String endpoint,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context, endpoint);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _receiptTypeButton(
        label: "Digital Receipt",
        endpoint: "upload-digital-image",
      ),
      const SizedBox(height: 20),
      _receiptTypeButton(
        label: "Handwritten Receipt",
        endpoint: "upload-handwritten-image",
      ),
    ],
  );
  }
}