import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jjan/MainLobbyUI/receiptInteraction/view_All_Receipts.dart';
import 'package:jjan/MainLobbyUI/receipt_selector.dart';
import 'package:jjan/services/transition_BottomUp.dart';
import 'package:jjan/services/select_date_services.dart';
import '../services/color_extension.dart';
import 'package:jjan/rscanner/ScannerScreen.dart';
import 'package:jjan/rscanner/RecognizerScreen.dart';
import 'package:jjan/services/prediction_handling.dart';
import 'package:jjan/services/backend_service.dart';



class homeUI extends StatefulWidget {
  const homeUI({super.key});

  @override
  State<homeUI> createState() => _homeUIState();
}

class _homeUIState extends State<homeUI> with TickerProviderStateMixin {
  List<String> dailyReceiptUrls = []; // will store all image_url for the selected date
  List<Map<String, dynamic>> _recentActions = [];
  List<String> dailyReceiptDocIds = [];
  int? _expandedIndex; // stores the tapped row index, null if none

  
  bool _isLoadingActions = false;
  

  Future<List<Map<String, dynamic>>> fetchRecentActions(String uid) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(uid) // use the passed uid
          .collection('action_history')
          .orderBy('dateTime', descending: true)
          .limit(50)
          .get();

      print('UID: $uid');

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": data['name'] ?? "",
          "dateTime": data['dateTime'] ?? "", 
          "action": data['action'] ?? "",
        };
      }).toList();
    } catch (e) {
      print("Error fetching recent actions: $e");
      return [];
    }
  }


  final ImagePicker imagePicker = ImagePicker();
  bool _overlayVisible = false;
  bool isImagePickerActive = false;
  bool isUploading = false;
  DateTime? _selectedDate;
  
  double income = 0;
  double expense = 0;
  double weeklySummary = 0;
  double monthlySummary = 0;
  double peekMargin = 16.0;
  

  late AnimationController _controller;
  late Animation<double> _myAnimation;
  late ScrollController _actionsScrollController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _myAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    _actionsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _actionsScrollController.dispose(); 
    super.dispose();
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
  
  Widget transactionHistoryRow(String name, String date, String action, int index) {
    final isExpanded = _expandedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle expand/collapse
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: isExpanded ? 13 : 1, child: Text(name, overflow: TextOverflow.ellipsis)), 
            Expanded(flex: 2, child: Text(date, textAlign: TextAlign.center)), 
            Expanded(flex: 1, child: Text(action, textAlign: TextAlign.center)), 
          ],
        ),
      ),
    );
  }

  void _pickImageFromGallery() async {
    if (isImagePickerActive) return;
    isImagePickerActive = true;

    XFile? xfile = await imagePicker.pickImage(source: ImageSource.gallery);
    isImagePickerActive = false;

    if (xfile != null) {

    // Ask the user what type of receipt it is
    String? endpoint = await ReceiptSelector.showReceiptTypeDialog(
        context, File(xfile.path));

    if (endpoint == null) {
      return;
    }
    print("User selected endpoint: $endpoint");

      await _processImage(File(xfile.path), endpoint);
    }
  }

  Future<void> _processImage(File imageFile, String endpoint) async {
    setState(() => isUploading = true);
    _showLoadingPopup("Waiting for backend results...");

    // Ask the user what type of receipt it is

    try {
      // Removed storeName parameter
      // 1️⃣ Get UID
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user logged in");

      // 2️⃣ Fetch store name
      final storeData = await fetchUserStore(uid);
      final storeName = storeData?['storeName']?.toString().toUpperCase() ?? "UNKNOWN STORE";
      print("Sending image with storeName: $storeName");

      // 3️⃣ Call backend with storeName
      final backendResult = await BackendService.sendImageToBackend(
        imageFile,
        endpoint,
        storeName,
      );

      setState(() => isUploading = false);

      // ✅ Check if backend says error
      final ok = await handlePredictionResponse(context, backendResult);
      if (!ok) {
        return;
      }
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => RecognizerScreen(
            storeName: BackendService.parseStoreName(backendResult["store_name"]),
            total: BackendService.parseTotal(backendResult["total_numeric"]),
            cashFlow: BackendService.convertCashFlow(backendResult["cashflow"]),
            imagePath: imageFile.path,
            date: DateTime.now(),
          ),
        ),
      );

    } catch (e) {
      setState(() => isUploading = false);
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      // Show a warning dialog instead of a snackbar
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Upload Failed:'),
            content: Text(
                'Failed to locate Store Name or Total.\nPlease try a different Receipt.\nThank you!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
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
      backgroundColor: TColor.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekly + Monthly Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: customBoxDecoration(),
                          padding: const EdgeInsets.all(16),
                          child: SummaryCard(
                            title: "Weekly Summary:", 
                            amount: weeklySummary.toStringAsFixed(0),
                            colorAmount: TColor.gray,
                            height: 80,
                            titleFontSize: 14,
                            amountFontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: customBoxDecoration(),
                          padding: const EdgeInsets.all(16),
                          child: SummaryCard(
                            title: "Monthly Summary:", 
                            amount: monthlySummary.toStringAsFixed(0),
                            colorAmount: TColor.gray,
                            height: 80,
                            titleFontSize: 14,
                            amountFontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Daily Summary Container
                  Container(
                    decoration: customBoxDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Daily Summary:", style: TextStyle(color: TColor.gray, fontSize: 14)),
                            const Icon(Icons.analytics, color: Colors.black54),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Income
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Income:", style: TextStyle(color: Colors.grey[800], fontSize: 16)),
                            Text("₱ ${income.toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _calculateMaxValue(income, expense) == 0 ? 0 : income / _calculateMaxValue(income, expense),
                          minHeight: 8,
                          color: Colors.green[700],
                          backgroundColor: Colors.green[100],
                        ),
                        const SizedBox(height: 16),
                        // Expense
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Expense:", style: TextStyle(color: Colors.grey[800], fontSize: 16)),
                            Text("₱ ${expense.toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700])),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _calculateMaxValue(income, expense) == 0 ? 0 : expense / _calculateMaxValue(income, expense),
                          minHeight: 8,
                          color: Colors.red[700],
                          backgroundColor: Colors.red[100],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.black54, thickness: 1.2),
                        // Net Worth
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Net Worth:", style: TextStyle(color: Colors.grey[800], fontSize: 16)),
                            Text("₱ ${(income - expense).toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selected Date & Receipts Container
                  Container(
                    decoration: customBoxDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Selected Date:", style: TextStyle(color: TColor.gray, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDate != null
                                        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                                        : "No date selected", // Monday, Sep 22
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.black),
                              onPressed: () async {
                                await CalendarService.pickDateAndCalculateSummary(
                                  context: context,
                                  selectedDate: _selectedDate,
                                  onDateSelected: (date) {
                                    setState(() => _selectedDate = date);
                                  },
                                  onDailyUrlsUpdated: (urls) {
                                    setState(() => dailyReceiptUrls = urls);
                                    print("📸 Daily receipt URLs: $urls");

                                    // ✅ Check if there are no receipts for the selected date
                                    if (urls.isEmpty) {
                                      setState(() {
                                        income = 0;
                                        expense = 0;
                                        weeklySummary = 0;
                                        monthlySummary = 0;
                                      }); 
                                    } else {
                                      // ✅ Update the summaries normally
                                      setState(() => income = income); // keep existing or fetched values
                                      setState(() => expense = expense);
                                      setState(() => weeklySummary = weeklySummary);
                                      setState(() => monthlySummary = monthlySummary);
                                    }
                                  },
                                  onDailyDocIdsUpdated: (docIds) { 
                                    setState(() => dailyReceiptDocIds = docIds);
                                    print("📸 Daily receipt Doc IDs: $docIds");
                                  },
                                  onDailyIncomeUpdated: (value) => setState(() => income = value),
                                  onDailyExpenseUpdated: (value) => setState(() => expense = value),
                                  onWeeklySummaryUpdated: (value) => setState(() => weeklySummary = value),
                                  onMonthlySummaryUpdated: (value) => setState(() => monthlySummary = value),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: Colors.black54, thickness: 1.2),
                        const SizedBox(height: 14),

                        // Receipts Section
                        Text("Receipts:", style: TextStyle(color: TColor.gray, fontSize: 14)),
                        const SizedBox(height: 8),

                        dailyReceiptUrls.isNotEmpty
                            ? SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: dailyReceiptUrls.length > 6 ? 6 : dailyReceiptUrls.length,
                                  itemBuilder: (context, index) {
                                    double peekMargin = 16.0;

                                    // If there are more than 6 receipts, show "View All" button at index 5
                                    if (dailyReceiptUrls.length > 6 && index == 5) {
                                      return Container(
                                        width: 120,
                                        margin: EdgeInsets.only(right: peekMargin),
                                        child: GestureDetector(
                                          onTap: () {
                                            // Navigate to "View All Receipts"
                                            Navigator.push(
                                              context,
                                              slideTransition(
                                                view_All_Receipts(
                                                  allReceipts: dailyReceiptUrls,
                                                  selectedDate: _selectedDate,
                                                  allDocIds: dailyReceiptDocIds,
                                                  initialIndex: index, // open starting at "View All"
                                                ),
                                                SlideDirection.leftToRight,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: TColor.primary10,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add, size: 40, color: TColor.primary),
                                                const SizedBox(height: 8),
                                                Text("View All", style: TextStyle(color: TColor.primaryText)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    // Show receipt preview (tap goes directly to "View All" at correct index)
                                    return Container(
                                      width: 120,
                                      margin: EdgeInsets.only(right: peekMargin),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            slideTransition(
                                              view_All_Receipts(
                                                allReceipts: dailyReceiptUrls,
                                                selectedDate: _selectedDate,
                                                allDocIds: dailyReceiptDocIds,
                                                initialIndex: index, // 👈 start at tapped index
                                              ),
                                              SlideDirection.leftToRight,
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            dailyReceiptUrls[index],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text("No receipts for this date", style: TextStyle(color: Colors.grey)),

                        ],
                    ),
                  ),
                        const SizedBox(height: 20),
                  // Transaction History Section 
                          Container(
                            decoration: customBoxDecoration(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children:[
                                     Column( 
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text("Action History:", style: TextStyle(color: TColor.gray, fontSize: 14)),
                                            const SizedBox(height: 4,),
                                            Text("*Tap the receipt name to read it in full*",style: TextStyle(fontSize: 11.5, color: Colors.black54, fontStyle: FontStyle.italic,),),]),IconButton(
                                      icon: const Icon(Icons.history, color: Colors.black),
                                      onPressed: () async {
                                        setState(() => _isLoadingActions = true);
                                        _showLoadingPopup("Extracting Action History Data...");

                                        try {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            print("❌ No logged-in user");
                                            return ;
                                          }
                                          final uid = user.uid;

                                          final actions = await fetchRecentActions(uid);

                                          if (!mounted) return;
                                          setState(() {
                                            // ✅ Limit to max 50 actions
                                            if (actions.length > 50) {
                                              actions.removeRange(50, actions.length); 
                                            }
                                            _recentActions = actions;
                                            _isLoadingActions = false;
                                          });
                                        } catch (e) {
                                          setState(() => _isLoadingActions = false);
                                          print("Failed to fetch actions: $e");
                                        }

                                        if (Navigator.of(context, rootNavigator: true).canPop()) {
                                          Navigator.of(context, rootNavigator: true).pop();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Table-like container
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black54),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      // Table header
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(color: Colors.grey[200]),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: const [
                                            Expanded(flex: 1, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                            Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                            Expanded(flex: 1, child: Text("Action", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                          ],
                                        ),
                                      ),

                                      // Table rows dynamically from _recentActions
                                      if (_isLoadingActions)
                                        const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      else if (_recentActions.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Center(child: Text("No recent actions")),
                                        )
                                      else
                                        // ✅ Scrollable container for action history
                                        SizedBox(
                                        height: 4 * 40.0,
                                        child: Scrollbar(
                                          controller:_actionsScrollController,// attach controller
                                          thumbVisibility: true,
                                          child: ListView.builder(
                                            controller: _actionsScrollController, // attach controller
                                            itemCount: _recentActions.length,
                                            itemBuilder: (context, index) {
                                              final action = _recentActions[index];
                                              return transactionHistoryRow(
                                                action['name'] ?? "",
                                                action['dateTime'] ?? "",
                                                action['action'] ?? "",
                                                index,
                                              );                                          
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )


                ],
              ),
            ),
          ), 

          // Overlay
          IgnorePointer(
            ignoring: !_overlayVisible,
            child: AnimatedOpacity(
              opacity: _overlayVisible ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.black87],
                  ),
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _myAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: FloatingActionButton(
                                heroTag: "cameraButton",
                                backgroundColor: TColor.blue20,
                                onPressed: () {
                                  setState(() => _overlayVisible = false);
                                  _controller.reverse();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                                  );
                                },
                                child: const Icon(Icons.camera_alt, size: 45, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text("Camera", style: TextStyle(color: Colors.white, fontSize: 20)),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: FloatingActionButton(
                                heroTag: "galleryButton",
                                backgroundColor: TColor.blue20,
                                onPressed: () {
                                  setState(() => _overlayVisible = false);
                                  _controller.reverse();
                                  _pickImageFromGallery();
                                },
                                child: const Icon(Icons.photo_library, size: 50, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30, right: 6), // keeps it above nav bar
        child: FloatingActionButton(
          backgroundColor: TColor.blue500,
          onPressed: () {
            setState(() {
              _overlayVisible = !_overlayVisible;
              if (_overlayVisible) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            });
          },
          child: Icon(_overlayVisible ? Icons.close : Icons.add, size: 35),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color colorAmount;
  final double height;
  final double titleFontSize;
  final double amountFontSize;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.colorAmount,
    this.height = 120,
    this.titleFontSize = 14,
    this.amountFontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: TColor.gray, fontSize: titleFontSize)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: amountFontSize, fontWeight: FontWeight.bold, color: colorAmount)),
        ],
      ),
    );
  }
} 




BoxDecoration customBoxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.black),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.51),
        blurRadius: 6,
        offset: const Offset(2, 4),
      ),
    ],
  );

}
double _calculateMaxValue(double income, double expense) {
  double highest = income > expense ? income : expense;
  if (highest <= 0) return 1; // avoid division by zero
  double limit = 10;

  while (highest > limit && limit < 1000000) {
    limit *= 10;
  }
  return limit;
}

