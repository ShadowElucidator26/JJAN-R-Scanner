import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/services/cloudinary_services.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/services/firestore_services.dart';

class RecognizerScreen extends StatefulWidget {
  final String? storeName;
  final double? total;
  final String? cashFlow; // "INCOME" or "EXPENSE"
  final String? imagePath;
  final DateTime? date;

  // Legacy constructor support
  final File? imageFile;
  final Map<String, dynamic>? resultFromBackend;

  const RecognizerScreen({
    super.key,
    this.storeName,
    this.total,
    this.cashFlow,
    this.imagePath,
    this.date,
    this.imageFile,
    this.resultFromBackend,
  });

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  late TextEditingController _storeController;
  late TextEditingController _totalController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  late String _cashFlow;
  late String _imagePath;
  late DateTime _receiptDateTime;

  // UI & state
  bool _isProcessing = false; // disables the Save button while active

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    String finalStoreName = "Unknown Store";
    double finalTotal = 0.0;
    String finalCashFlow = "EXPENSE";
    DateTime finalDate = DateTime.now();
    _receiptDateTime = finalDate;

    if (widget.resultFromBackend != null) {
      final backend = widget.resultFromBackend!;
      finalStoreName = backend["store_name"] ?? "Unknown Store";
      finalTotal =
          double.tryParse(backend["total_numeric"]?.toString() ?? "0") ?? 0.0;
      finalCashFlow = backend["cashflow"] == 1 ? "INCOME" : "EXPENSE";
      finalDate = DateTime.now();
      _imagePath = widget.imageFile?.path ?? "";
    } else {
      finalStoreName = widget.storeName ?? "Unknown Store";
      finalTotal = widget.total ?? 0.0;
      finalCashFlow = widget.cashFlow ?? "EXPENSE";
      finalDate = widget.date ?? DateTime.now();
      _imagePath = widget.imagePath ?? "";
    }

    _storeController = TextEditingController(
      text: finalStoreName.toUpperCase(),
    );
    _totalController =
        TextEditingController(text: finalTotal.toStringAsFixed(2));
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDate),
    );
    _noteController = TextEditingController();
    _cashFlow = finalCashFlow;
    _receiptDateTime = finalDate;
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm:ss').format(_receiptDateTime),
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _totalController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ---- The main orchestrator when Save pressed ----
  Future<void> _handleSavePressed() async {
    // Validation
    if (_storeController.text.trim().isEmpty) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Warning!'),
              content: Text("Store name is required."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: TColor.blue500),),
                ),
              ],
            );
          },
        );
      return;
    }

    if (_totalController.text.trim().isEmpty ||
        double.tryParse(_totalController.text) == null) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Reminder:'),
              content: Text("Valid total amount is required.\nThank you!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: TColor.blue500),),
                ),
              ],
            );
          },
      );
      return;
    }

    if (_imagePath.isEmpty || !File(_imagePath).existsSync()) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Warning!'),
              content: Text("Receipt image not found.\nThank you!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: TColor.blue500),),
                ),
              ],
            );
          }
      );
      return;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      print("No logged-in user found.");
      // Show error to user or prevent saving
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Error"),
          content: Text("No logged-in user found. Please login first."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: TColor.blue500),),
            )
          ],
        ),
      );
      return; // stop the save operation
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });

    // Variables to track status
    bool imageUploadDone = false;
    bool imageUploadSuccess = false;
    String? uploadedPublicId;
    String? uploadedUrl;

    bool firestoreDone = false;
    bool firestoreSuccess = false;

    // Show modal dialog with live status
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future.microtask(() async {
            if (!imageUploadDone && !imageUploadSuccess && !firestoreDone) {
              // Upload image
              // For testing, we can skip checking FirebaseAuth or just use
              final uploadResp = await CloudinaryService.uploadImage(
                _imagePath,
                userId: currentUid, 
                //userId: currentUid, // <-- for production later

              );

              imageUploadDone = true;
              imageUploadSuccess = uploadResp['success'] == true;
              if (imageUploadSuccess) {
                uploadedPublicId = uploadResp['public_id'];
                uploadedUrl = uploadResp['secure_url'];
              }
              try {
                  setModalState(() {
                    // update UI inside modal
                  });
                } catch (e) {
                  // modal was closed, ignore
                }


              // Save to Firestore if image upload succeeded
              if (imageUploadSuccess) {
                final saveResp = await _firestoreService.saveReceipt(
                  storeName: _storeController.text.trim(),
                  total: double.parse(_totalController.text.trim()),
                  cashFlow: _cashFlow,
                  imageUrl: uploadedUrl,
                  imagePublicId: uploadedPublicId,
                  note: _noteController.text.trim(),
                  date: _receiptDateTime,
                  userId: currentUid, 
                );
                firestoreDone = true;
                firestoreSuccess = saveResp['success'] == true;
                try {
                  setModalState(() {
                    // update UI inside modal
                  });
                } catch (e) {
                  // modal was closed, ignore
                }

                
              }

              // Delay briefly so user sees final status
              await Future.delayed(const Duration(milliseconds: 600));
              try {
                  if (Navigator.canPop(context)) Navigator.of(context).pop();
                } catch (e) {
                  // modal was closed, ignore
                }
              
            }
          });

          Widget statusIcon(bool isDone, bool isSuccess) {
            if (!isDone) return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
            return Icon(isSuccess ? Icons.check_circle : Icons.cancel, color: isSuccess ? Colors.green : Colors.red);
          }

          return AlertDialog(
            title: const Text("Processing"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text("Saving image to storage")),
                    statusIcon(imageUploadDone, imageUploadSuccess),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text("Saving information to database")),
                    statusIcon(firestoreDone, firestoreSuccess),
                  ],
                ),
                const SizedBox(height: 18),
                if (imageUploadDone && firestoreDone && imageUploadSuccess && firestoreSuccess)
                  const Text("Successful: the receipt is saved."),
                if (imageUploadDone && !imageUploadSuccess)
                  const Text("Error: failed to upload image."),
                if (imageUploadDone && firestoreDone && imageUploadSuccess && !firestoreSuccess)
                  const Text("Error: failed saving data to database."),
              ],
            ),
            actions: [
              if ((imageUploadDone && firestoreDone) || (!imageUploadDone && !firestoreDone && !imageUploadSuccess))
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("CANCEL", style: TextStyle(color: TColor.blue500),),
                ),
            ],
          );
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    if (imageUploadSuccess && firestoreSuccess) {

      // Add action history entry
      await _firestoreService.addActionHistory(
        userId: currentUid, 
        receiptName:  uploadedPublicId ?? _imagePath.split('/').last,
        dateTime: DateTime.now(),
        action: "CREATED",
      );
        print("ActionHistory Created");

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
                  "Receipt saved successfully!",
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


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const mainLobby_Page()),
        (route) => false,
      );
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('ERROR!'),
              content: Text("Something went wrong. Please try again.\nThank you!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: TColor.blue500),),
                ),
              ],
            );
          },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RECEIPT DETAILS"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scrollable content including image and fields
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                // inside build() -> Column of fields
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rounded Image
                    if (_imagePath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // 🔹 Added RESULT label
                    Center(
                      child: const Text(
                        "RESULT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildDateRow(),
                    const SizedBox(height: 12),
                    buildEditableRow(Icons.store, "STORE NAME", _storeController),
                    const SizedBox(height: 12),
                    buildEditableRow(Icons.attach_money, "TOTAL", _totalController,
                        isNumber: true),
                    const SizedBox(height: 12),
                    buildCashFlowDropdown(),
                    const SizedBox(height: 12),
                    buildEditableRow(Icons.note, "NOTE (OPTIONAL)", _noteController),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _isProcessing ? Colors.blueGrey : Colors.blue,
              ),
              onPressed: _isProcessing
                  ? null
                  : () {
                _handleSavePressed();
              },
              icon: _isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(_isProcessing ? "SAVING..." : "SAVE & RETURN"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableRow(IconData icon, String label,
      TextEditingController controller,
      {bool isNumber = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            inputFormatters: label == "STORE NAME"
                ? [
              UpperCaseTextFormatter(),
            ]
                : [],
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

  Widget buildDateRow() {
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
                DateTime today = DateTime.now();
                // Reset time part of today for comparison
                today = DateTime(today.year, today.month, today.day);

                if (pickedDate.isAfter(today)) {
                  // Show warning dialog if date is in the future
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Invalid Date"),
                      content: Text(
                          "You can only add receipts on or before today\nDate Today: ${DateFormat('yyyy-MM-dd').format(today)}."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("OK", style: TextStyle(color: TColor.blue500),),
                        ),
                      ],
                    ),
                  );
                  return; // exit without updating the date
                }

                if (!mounted) return;
                setState(() {
                  // keep original time, change only the date
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


  Widget buildCashFlowDropdown() {
    return Row(
      children: [
        const Icon(Icons.compare_arrows, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _cashFlow == "INCOME" ? "INCOME" : "EXPENSE",
            items: const [
              DropdownMenuItem(
                value: "INCOME",
                child: Text("INCOME"),
              ),
              DropdownMenuItem(
                value: "EXPENSE",
                child: Text("EXPENSE"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                if (!mounted) return;
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
