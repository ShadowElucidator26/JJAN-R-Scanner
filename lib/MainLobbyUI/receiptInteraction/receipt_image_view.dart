// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/services/firestore_services.dart';
import '/services/color_extension.dart';
import '/services/get_clicked_image_info.dart';
import 'package:intl/intl.dart';

class ReceiptImageView extends StatefulWidget {
  final String receiptUrl;
  final String receiptDate; // formatted as 'yyyy-MM-dd'
  final String docId;

  const ReceiptImageView({
    super.key,
    required this.receiptUrl,
    required this.receiptDate,
    required this.docId,
  });

  @override
  State<ReceiptImageView> createState() => _ReceiptImageViewState();
}

class _ReceiptImageViewState extends State<ReceiptImageView> {
  Map<String, dynamic>? _originalData;
  Map<String, dynamic>? _editableData;
  bool _loading = true;
  // final currentUid = "test_user_1";
  final currentUid = FirebaseAuth.instance.currentUser!.uid;


  // Controllers
  late TextEditingController _storeController;
  late TextEditingController _totalController;
  late TextEditingController _noteController;
  late TextEditingController _dateController;
  late String _cashFlow;
  late DateTime _receiptDateTime;

  @override
  void initState() {
    super.initState();
    _fetchAndShow();
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

  Future<void> _fetchAndShow() async {
    final data = await getClickedImageInfo(
      receiptDate: widget.receiptDate,
      receiptId: widget.docId,
    );

    if (!mounted) return;

    _originalData = Map<String, dynamic>.from(data);
    _editableData = Map<String, dynamic>.from(_originalData!);

    _storeController =
        TextEditingController(text: (_editableData!['store_name'] ?? "").toUpperCase());
    _totalController =
        TextEditingController(text: (_editableData!['total'] ?? 0).toString());
    _noteController =
        TextEditingController(text: _editableData!['note'] ?? "");
    _cashFlow = _editableData!['cashflow'] ?? "EXPENSE";
    _receiptDateTime = _editableData!['date'] != null
        ? (_editableData!['date'] as Timestamp).toDate()
        : DateTime.now();
    _dateController =
        TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm:ss').format(_receiptDateTime));

    setState(() {
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReceiptInfoSheet();
    });
  }

  void _showReceiptInfoSheet() {
    if (_editableData == null) return;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "INFO",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDateRow(),
                  const SizedBox(height: 12),
                  _buildEditableRow(Icons.receipt, "RECEIPT NAME", _storeController),
                  const SizedBox(height: 12),
                  _buildEditableRow(Icons.attach_money, "TOTAL", _totalController, isNumber: true),
                  const SizedBox(height: 12),
                  _buildCashFlowDropdown(),
                  const SizedBox(height: 12),
                  _buildEditableRow(Icons.note, "NOTE (OPTIONAL)", _noteController),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateReceipt,
                          style: ElevatedButton.styleFrom(backgroundColor: TColor.blue100),
                          child: const Text("Update"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _trashReceipt,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Move to Trash"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---- UPDATE LOGIC ----
  void _updateReceipt() async {
    _editableData!['store_name'] = _storeController.text;
    _editableData!['total'] = double.tryParse(_totalController.text) ?? 0;
    _editableData!['note'] = _noteController.text;
    _editableData!['cashflow'] = _cashFlow;
    _editableData!['date'] = Timestamp.fromDate(_receiptDateTime);

    if (mapEquals(_originalData, _editableData)) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Update Failed:'),
            content: const Text("There's no changes with the information.\nThank you!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK',  style: TextStyle(color: TColor.blue100,)),
              ),
            ],
          );
        },
      );
      return;
    }

    // Confirm update
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Update"),
        content: const Text("Are you sure you want to update this receipt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No",  style: TextStyle(color: Colors.green,)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes",  style: TextStyle(color: Colors.red,))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingPopup("Processing...");

    try {

    final db = FirebaseFirestore.instance;
    final dailyRef = db
        .collection("users")
        .doc(currentUid)
        .collection("daily_summaries")
        .doc(widget.receiptDate);

    double originalTotal = (_originalData!['total'] ?? 0).toDouble();
    String originalCashFlow = _originalData!['cashflow'] ?? "EXPENSE";
    double newTotal = _editableData!['total'] ?? 0.0;
    String newCashFlow = _editableData!['cashflow'] ?? "EXPENSE";
    String newNote = _editableData!['note']?? "";
    final FirestoreService _firestoreService = FirestoreService();


    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(dailyRef);
      double currentIncome = 0.0;
      double currentExpense = 0.0;
      if (snapshot.exists) {
        final data = snapshot.data()!;
        currentIncome = (data["total_daily_income"] ?? 0.0).toDouble();
        currentExpense = (data["total_daily_expense"] ?? 0.0).toDouble();
      }

      // ---- Your Logic ----
      if (originalCashFlow == newCashFlow) {
        if (newCashFlow == "INCOME") {
          currentIncome = currentIncome - originalTotal + newTotal;
        } else {
          currentExpense = currentExpense - originalTotal + newTotal;
        }
      } else {
        if (originalCashFlow == "INCOME" && newCashFlow == "EXPENSE") {
          currentIncome -= originalTotal;
          currentExpense += newTotal;
        } else if (originalCashFlow == "EXPENSE" && newCashFlow == "INCOME") {
          currentExpense -= originalTotal;
          currentIncome += newTotal;
        }
      }

      transaction.set(dailyRef, {
        "total_daily_income": currentIncome,
        "total_daily_expense": currentExpense,
        "last_update": FieldValue.serverTimestamp(),
        "date": DateTime.parse(widget.receiptDate),
        "note": newNote,
      });
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('receipts')
        .doc(widget.receiptDate)
        .collection('items')
        .doc(widget.docId)
        .update(_editableData!);

    _originalData = Map<String, dynamic>.from(_editableData!);

    await _firestoreService.addActionHistory(
        userId: currentUid, 
        receiptName:  _editableData!['image_public_id'] ,
        dateTime: DateTime.now(),
        action: "UPDATED",
      );
        print("ActionHistory Created");
        print("$_editableData!['image_public_id']");

    // ---- SUCCESS DIALOG for UPDATE ----
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
                "Receipt UPDATED successfully.",
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
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // close success dialog
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const mainLobby_Page()),
        (route) => false,
      );
    });

    } catch(e){
      Navigator.pop(context); // close loading popup if open
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Update Failed", style: TextStyle(color: TColor.blue100,)),
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



  // ---- TRASH LOGIC ----
  void _trashReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Moving to Trash"),
        content: const Text("Are you sure you want to trash this receipt?\nNote: 30 days after this action, this receipt will be deleted\n(unless the user retrieve it from the ''Recently Deleted Receipt'' located at the settings)"),
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

    try {
    final FirestoreService _firestoreService = FirestoreService();
    //for the dailys summaries
    final db = FirebaseFirestore.instance;
    final dailyRef = db
        .collection("users")
        .doc(currentUid)
        .collection("daily_summaries")
        .doc(widget.receiptDate);

    double originalTotal = (_originalData!['total'] ?? 0).toDouble();
    String originalCashFlow = _originalData!['cashflow'] ?? "EXPENSE";

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(dailyRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        double currentIncome = (data["total_daily_income"] ?? 0.0).toDouble();
        double currentExpense = (data["total_daily_expense"] ?? 0.0).toDouble();

        if (originalCashFlow == "INCOME") {
          currentIncome -= originalTotal;
        } else {
          currentExpense -= originalTotal;
        }

        transaction.update(dailyRef, {
          "total_daily_income": currentIncome,
          "total_daily_expense": currentExpense,
          "last_update": FieldValue.serverTimestamp(),
        });
      }
    });

    await _firestoreService.saveToTrashReceipt(
      beforeDate: widget.receiptDate,
      receiptId: widget.docId,
      storeName: _storeController.text.trim(),
      total: double.parse(_totalController.text.trim()),
      cashFlow: _cashFlow,
      imageUrl: widget.receiptUrl,
      imagePublicId: _editableData!['image_public_id'] ,
      note: _noteController.text.trim(),
      date: _receiptDateTime,
      userId: currentUid, 
    );

    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUid)
      .collection('receipts')
      .doc(widget.receiptDate)
      .collection('items')
      .doc(widget.docId)
      .delete();

    await _firestoreService.addActionHistory(
        userId: currentUid, 
        receiptName:  _editableData!['image_public_id'] ,
        dateTime: DateTime.now(),
        action: "TRASHED",
      );
        print("ActionHistory Created");
        print("$_editableData!['image_public_id']");

      
    // ---- SUCCESS DIALOG for TRASH ----
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
                "Receipt TRASHED successfully.",
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

    } catch(e){
      Navigator.pop(context); // close loading popup if open
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Trash Failed"),
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


  Widget _buildEditableRow(IconData icon, String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            inputFormatters: label == "RECEIPT NAME" ? [UpperCaseTextFormatter()] : [],
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _receiptDateTime,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  _receiptDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    _receiptDateTime.hour,
                    _receiptDateTime.minute,
                    _receiptDateTime.second,
                  );
                  _dateController.text =
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(_receiptDateTime);
                });
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "DATE",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowDropdown() {
    return Row(
      children: [
        const Icon(Icons.compare_arrows, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _cashFlow,
            items: const [
              DropdownMenuItem(value: "INCOME", child: Text("INCOME")),
              DropdownMenuItem(value: "EXPENSE", child: Text("EXPENSE")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _cashFlow = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: "Cash Flow",
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.blue20,
      appBar: AppBar(
        backgroundColor: TColor.blue20,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [ Text(_editableData?['image_public_id'] ?? "Loading...", style: TextStyle(fontSize: 16), maxLines: 1,
                      overflow: TextOverflow.ellipsis, ),
          // SizedBox(width: 2),
          // InkWell(
          //   onTap: _downloadImage,
          //   child: Image.asset(
          //           'assets/images/downloadImagesss.png', // 🔹 replace with your image path
          //           height: 20,
          //           width: 20,
          //           ),
          // ),
          ],
        ),
        centerTitle: true,
        
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                if (_editableData != null) {
                  _showReceiptInfoSheet();
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.receiptUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
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
