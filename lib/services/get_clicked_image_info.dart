import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jjan/services/firestore_services.dart';

/// Fetch receipt info using date + docId
/// Returns map including all fields
Future<Map<String, dynamic>> getClickedImageInfo({
  required String receiptDate,
  required String receiptId,
}) async {
  final userId = FirestoreService().uid;
  // final userId = "test_user_1";
  if (userId == null) {
    print("❌ No logged-in user found.");
    return {};
  }

  try {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId) 
        .collection('receipts')
        .doc(receiptDate)
        .collection('items')
        .doc(receiptId);

    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['docId'] = docSnapshot.id; // include docId just in case
      print("Receipt Info: $data"); // print all info in console
      return data;
    } else {
      print("No receipt found for docId: $receiptId on date: $receiptDate");
      return {};
    }
  } catch (e) {
    print("Error fetching receipt info: $e");
    return {};
  }
}
