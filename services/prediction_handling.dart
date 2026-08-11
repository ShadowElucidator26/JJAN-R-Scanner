import 'package:flutter/material.dart';

/// Handles backend prediction results.
/// If status = "error", show dialog and return false.
/// If success, return true.
Future<bool> handlePredictionResponse(
    BuildContext context, Map<String, dynamic> backendResult) async {
  if (backendResult["status"] == "error") {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Prediction Failed"),
        content: Text(
          backendResult["message"] ??
              "Could not detect both store name and total. Please try again.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return false;
  }
  return true;
}
