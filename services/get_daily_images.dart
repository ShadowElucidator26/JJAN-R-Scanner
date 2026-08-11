import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:jjan/services/firestore_services.dart';

class ReceiptService {
  static Future<void> getDailyReceiptURL({
    required DateTime selectedDate,
    required Function(List<String>) onDocIdsFetched,
    required Function(List<String>) onUrlsFetched,
  }) async {
    final userId = FirestoreService().uid;
    // final userId = "test_user_1";
    if (userId == null) {
      print("❌ No logged-in user found.");
      onUrlsFetched([]);
      onDocIdsFetched([]);
      return;
    }
    try {
      String dayDocId = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Reference to: /users/{uid}/receipts/{dayDocId}/items
      final itemsRef = FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("receipts")
          .doc(dayDocId)
          .collection("items");

      final snapshot = await itemsRef.get();
      List<String> dateTimeData = snapshot.docs.map((doc) => doc.id).toList();
      print("📂 dateTimeData IDs for $dayDocId: $dateTimeData");

      // Loop over each item and extract image_url
      List<String> urls = [];
      List<String> docIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey("image_url")) {
          urls.add(data["image_url"]);
          docIds.add(doc.id);
        }
      }

      onUrlsFetched(urls);
      print("✅ All receipt URLs for $dayDocId: $urls");

      onDocIdsFetched(docIds);
      print("✅ Corresponding doc IDs: $docIds");

    } catch (e) {
      print("❌ Error fetching receipt URLs: $e");
    }
  }
}
