import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Helper to get userId (falls back to test user if not logged in)
  String? get uid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<Map<String, dynamic>> saveToTrashReceipt({
    required String beforeDate,
    required String receiptId,
    required String storeName,
    required double total,
    required String cashFlow,
    required String? imageUrl,
    required String? imagePublicId,
    required String note,
    required DateTime date,
    String? userId, // optional override
  }) async {
    try {
      final effectiveUid = userId ?? uid;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      await db
          .collection("users")
          .doc(effectiveUid)
          .collection("trash")
          .doc(receiptId)
          .set({
        "beforeDate": beforeDate,
        "receiptID": receiptId,
        "deleted_at": FieldValue.serverTimestamp(),
        "cashflow": cashFlow,
        "date": date,
        "image_public_id": imagePublicId,
        "image_url": imageUrl,
        "note": note,
        "store_name": storeName,
        "total": total,
          });
      return {"success": true, "id": "$dateStr/$receiptId"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveReceipt({
    required String storeName,
    required double total,
    required String cashFlow,
    required String? imageUrl,
    required String? imagePublicId,
    required String note,
    required DateTime date,
    String? userId, // optional override
  }) async {
    try {
      final effectiveUid = userId ?? uid;

      // --- Date folder string for receipts ---
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // --- Receipt ID ---
      final receiptId = DateFormat('yyyy-MM-dd-HH-mm-ss').format(date);

      // --- Save receipt ---
      await db
          .collection("users")
          .doc(effectiveUid)
          .collection("receipts")
          .doc(dateStr)
          .collection("items")
          .doc(receiptId)
          .set({
        "store_name": storeName,
        "total": total,
        "cashflow": cashFlow,
        "note": note,
        "date": date,
        "image_url": imageUrl,
        "image_public_id": imagePublicId,
        "last_update": FieldValue.serverTimestamp(),
      });

      // --- Daily summary with midnight time ---
      final dailyDate = DateTime(date.year, date.month, date.day); // 00:00:00.000
      final dailyStr = DateFormat('yyyy-MM-dd').format(dailyDate);

      final dailyRef = db
          .collection("users")
          .doc(effectiveUid)
          .collection("daily_summaries")
          .doc(dailyStr);

      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(dailyRef);
        if (snapshot.exists) {
          final currentData = snapshot.data()!;
          double currentIncome =
              (currentData["total_daily_income"] ?? 0.0).toDouble();
          double currentExpense =
              (currentData["total_daily_expense"] ?? 0.0).toDouble();

          if (cashFlow == "INCOME") {
            currentIncome += total;
          } else {
            currentExpense += total;
          }

          transaction.update(dailyRef, {
            "total_daily_income": currentIncome,
            "total_daily_expense": currentExpense,
            "last_update": FieldValue.serverTimestamp(),
            "date": dailyDate, // always midnight
          });
        } else {
          transaction.set(dailyRef, {
            "total_daily_income": cashFlow == "INCOME" ? total : 0.0,
            "total_daily_expense": cashFlow == "EXPENSE" ? total : 0.0,
            "date": dailyDate, // always midnight
            "last_update": FieldValue.serverTimestamp(),
          });
        }
      });

      return {"success": true, "id": "$dateStr/$receiptId"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Get daily summary for a given date
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final uid = this.uid;
    final docId = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month, date.day));
    final doc = await db
        .collection('users')
        .doc(uid)
        .collection('daily_summaries')
        .doc(docId)
        .get();

    if (!doc.exists) return {"total_daily_income": 0, "total_daily_expense": 0};

    return {
      "total_daily_income": (doc.data()?["total_daily_income"] ?? 0).toDouble(),
      "total_daily_expense": (doc.data()?["total_daily_expense"] ?? 0).toDouble(),
    };
  }

  /// Ensure daily summary exists
  Future<void> ensureDailySummaryExists(DateTime date) async {
    final uid = this.uid;
    final dailyDate = DateTime(date.year, date.month, date.day); // 00:00:00.000
    final docId = DateFormat('yyyy-MM-dd').format(dailyDate);
    final docRef = db.collection('users').doc(uid).collection('daily_summaries').doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        "total_daily_income": 0.0,
        "total_daily_expense": 0.0,
        "date": dailyDate, // always midnight
        "last_update": FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, double>> getDailySummaryById(String docId) async {
      // final uid = "test_user_1";
    final uid = this.uid;
    final doc = await db.collection('users')
        .doc(uid)
        .collection('daily_summaries')
        .doc(docId)
        .get();
        print("doc id: $docId");
    if (!doc.exists) return {"total_daily_income": 0, "total_daily_expense": 0};

    return {
      "total_daily_income": (doc.data()?["total_daily_income"] ?? 0).toDouble(),
      "total_daily_expense": (doc.data()?["total_daily_expense"] ?? 0).toDouble(),
    };
  }

  Future<List<String>> getReceiptUrlsByDate(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection('receipts')
        .doc(docId)
        .get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || data['receipts'] == null) return [];

    // Assuming 'receipts' is a list of maps with 'image_url'
    final List<dynamic> receipts = data['receipts'];
    return receipts.map<String>((r) => r['image_url'] as String).toList();
  }
  Future<Map<String, dynamic>> addActionHistory({
    required String userId,
    required String receiptName,
    required DateTime dateTime,
    required String action,
  }) async {
    try {
      String docId = DateFormat('yyyy-MM-dd-HH-mm-ss').format(dateTime);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('action_history')
          .doc(docId)
          .set({
        'name': receiptName,
        'dateTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime),
        'action': action, // always "CREATED" for save
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<List<Map<String, dynamic>>> getDailySummariesForMonth(int year, int month) async {
    // final uid = "test_user_1";
    final uid = this.uid;
    if (uid == null) return [];

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0); // last day of month

    final query = await db
        .collection('users')
        .doc(uid)
        .collection('daily_summaries')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .orderBy('date')
        .get();

    // 🟠 If no data found, return an empty list
    if (query.docs.isEmpty) {
      print("⚠️ No data found for $month/$year");
      return [];
    }    

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        "date": (data["date"] as Timestamp).toDate(),
        "total_daily_income": (data["total_daily_income"] ?? 0.0).toDouble(),
        "total_daily_expense": (data["total_daily_expense"] ?? 0.0).toDouble(),
      };
    }).toList();
  }
}