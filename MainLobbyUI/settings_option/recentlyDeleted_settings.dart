import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:intl/intl.dart';
import 'package:jjan/services/firestore_services.dart';

class RecentlyDeletedReceiptUI extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> trashFiles;

  const RecentlyDeletedReceiptUI({
    Key? key,
    required this.trashFiles,
  }) : super(key: key);


  @override
  State<RecentlyDeletedReceiptUI> createState() =>
      _RecentlyDeletedReceiptUIState();
}

class _RecentlyDeletedReceiptUIState extends State<RecentlyDeletedReceiptUI> {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;

  
  // ---- DELETE LOGIC ----
  void _deleteReceipt(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this receipt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No", style: TextStyle(color: Colors.green,),),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.red,),),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingPopup("Processing...");

    try{

    final _originalData = widget.trashFiles[index];
    final data = _originalData.data();
    final receiptId = data['receiptID'];


    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUid)
      .collection('trash')
      .doc(receiptId)
      .delete();

    

    final FirestoreService _firestoreService = FirestoreService();

    await _firestoreService.addActionHistory(
        userId: currentUid,
        receiptName:  data['image_public_id'] ,
        dateTime: DateTime.now(),
        action: "DELETED",
      );
        print("ActionHistory Created");
        print("${data['image_public_id']}");
        
    // ---- SUCCESS DIALOG for DELETE ----
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
                "Receipt DELETED successfully.",
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

    // Wait for 1.5s, then close dialog and navigate to main lobby
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // close success dialog
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const mainLobby_Page()),
        (route) => false,
      );
    });

    }catch(e){
      Navigator.pop(context); // close loading popup if open
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Deletion Failed"),
          content: const Text("Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: TColor.blue100,)),
            ),
          ],
        ),
      );
    }
  }
  
  // ---- RETRIEVE LOGIC ----
  void _retrieveReceipt(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Retrieval of Receipt?"),
        content: const Text("Are you sure you want to RETRIEVE this receipt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No", style: TextStyle(color: Colors.red,),),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.green,),),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingPopup("Processing...");

    try{

    final _originalData = widget.trashFiles[index];
    final data = _originalData.data();
    final receiptId = data['receiptID'];
    final dateStr = receiptId.substring(0, 10);

    print("File path: users/$currentUid/receipts/$dateStr/items/$receiptId/");

    await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUid)
          .collection("receipts")
          .doc(dateStr)
          .collection("items")
          .doc(receiptId)
          .set({
            "store_name": data["store_name"],
            "total": data["total"],
            "cashflow": data["cashflow"],
            "note": data["note"],
            "date": data["date"], // original receipt date
            "image_url": data["image_url"],
            "image_public_id": data["image_public_id"],
            "last_update": FieldValue.serverTimestamp(),
          });

      
    // 2️⃣ Update daily summary
    final cashFlow = data["cashflow"] as String;
    final total = (data["total"] ?? 0.0).toDouble();
    final db = FirebaseFirestore.instance;
    final dailyRef = db
        .collection("users")
        .doc(currentUid)
        .collection("daily_summaries")
        .doc(dateStr);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(dailyRef);
      double currentIncome = 0.0;
      double currentExpense = 0.0;

      if (snapshot.exists) {
        final dailyData = snapshot.data()!;
        currentIncome = (dailyData["total_daily_income"] ?? 0.0).toDouble();
        currentExpense = (dailyData["total_daily_expense"] ?? 0.0).toDouble();
      }

      if (cashFlow == "INCOME") {
        currentIncome += total;
      } else {
        currentExpense += total;
      }

      transaction.set(dailyRef, {
        "total_daily_income": currentIncome,
        "total_daily_expense": currentExpense,
        "last_update": FieldValue.serverTimestamp(),
        "date": DateTime.parse(dateStr),
      });
    });

    // 3️⃣ Remove from trash
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('trash')
        .doc(receiptId)
        .delete();


    //4 update action history
    final FirestoreService _firestoreService = FirestoreService();

    await _firestoreService.addActionHistory(
        userId: currentUid, 
        receiptName:  data['image_public_id'] ,
        dateTime: DateTime.now(),
        action: "RETRIEVED",
      );
        print("ActionHistory Created");
        print("${data['image_public_id']}");

    // ---- SUCCESS DIALOG for RETRIEVAL of receipt ----
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
                "Successful RETRIEVAL of receipt.",
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

    // Wait for 1.5s, then close dialog and navigate to main lobby
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // close success dialog
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const mainLobby_Page()),
        (route) => false,
      );
    });

    }catch(e){
      Navigator.pop(context); // close loading popup if open
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Failed to Retrieve Receipt", style: TextStyle(color: Colors.red),),
          content: const Text("Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: TColor.blue100,)),
            ),
          ],
        ),
      );
    }
  }


  
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
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text(
          "Recently Deleted Receipt",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: TColor.blue20,
        toolbarHeight: 80,
        shadowColor: TColor.blue500,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
      padding: const EdgeInsets.all(16),
      child: widget.trashFiles.isEmpty
          ? const Center(
              child: Text(
                "No recently deleted receipts.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: widget.trashFiles.length,
              itemBuilder: (context, index) {
                final doc = widget.trashFiles[index];
                final data = doc.data();

                // Extract info
                final String imagePublicId = data["image_public_id"] ?? "Unknown File";
                final deletedAt = (data["deleted_at"] as Timestamp?)?.toDate();

                // Compute permanent deletion date (30 days after deletion)
                final DateTime? permanentDeleteAt =
                    deletedAt != null ? deletedAt.add(const Duration(days: 30)) : null;

                // Format for display
                final String trashedDate = deletedAt != null
                    ? DateFormat('yyyy-MM-dd').format(deletedAt)
                    : "Unknown";
                final String deletionDate = permanentDeleteAt != null
                    ? DateFormat('yyyy-MM-dd').format(permanentDeleteAt)
                    : "Unknown";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: Text(
                      imagePublicId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text("Trashed on: $trashedDate"),
                        const SizedBox(height: 3),
                        Text("Will be deleted on: $deletionDate"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () {
                            _retrieveReceipt(index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () {
                            _deleteReceipt(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),

    );
  }
}
