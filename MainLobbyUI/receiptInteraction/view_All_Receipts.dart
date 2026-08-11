import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jjan/MainLobbyUI/receiptInteraction/receipt_image_view.dart';
import '../../services/color_extension.dart';
import 'package:intl/intl.dart';

class view_All_Receipts extends StatefulWidget {
  final List<String> allReceipts;
  final DateTime? selectedDate;
  final List<String> allDocIds;
  final int initialIndex;

  const view_All_Receipts({
    super.key,
    required this.allReceipts,
    required this.allDocIds,
    required this.selectedDate,
    this.initialIndex = 0,
  });

  @override
  State<view_All_Receipts> createState() => _view_All_ReceiptsState();
}

class _view_All_ReceiptsState extends State<view_All_Receipts>
    with SingleTickerProviderStateMixin {
  PageController pageController = PageController();
  int currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextEditingController pageControllerText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    pageController = PageController(initialPage: widget.initialIndex);
    
    currentIndex = widget.initialIndex;
    pageControllerText.text = "${widget.initialIndex + 1}";
  }

  @override
  void dispose() {
    pageController.dispose();
    _animationController.dispose();
    pageControllerText.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    await _animationController.forward();
    await _animationController.reverse();
  }

  void goToFirst() async {
    if (currentIndex != 0) {
      await _playAnimation();
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToLast() async {
    if (currentIndex != widget.allReceipts.length - 1) {
      await _playAnimation();
      pageController.animateToPage(
        widget.allReceipts.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPage(int page) async {
    int target = page.clamp(1, widget.allReceipts.length) - 1;
    pageControllerText.text = "${target + 1}";
    await _playAnimation();
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.blue50,
      appBar: AppBar(
        backgroundColor: TColor.blue20,
        shadowColor: TColor.blue500,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.allReceipts.isNotEmpty
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: currentIndex == 0 ? null : goToFirst,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        "First",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentIndex == 0 ? Colors.grey : TColor.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: TextField(
                      controller: pageControllerText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (value) {
                        if (value.isEmpty) return;
                        int page = int.tryParse(value) ?? 1;
                        goToPage(page);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white24,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  Text(
                    "/${widget.allReceipts.length}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: currentIndex == widget.allReceipts.length - 1 ? null : goToLast,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        "Last",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentIndex == widget.allReceipts.length - 1
                              ? Colors.grey
                              : TColor.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Text("All Receipts"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: widget.allReceipts.isEmpty
          ? const Center(
              child: Text(
                "No receipts available",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: PageView.builder(
                controller: pageController,
                itemCount: widget.allReceipts.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                    pageControllerText.text = "${index + 1}";
                  });
                },
                itemBuilder: (context, index) {
                  String receiptUrl = widget.allReceipts[index];
                  String docId = widget.allDocIds[index];
                  String formattedDate = widget.selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(widget.selectedDate!)
                      : "";

                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptImageView(
                              receiptUrl: receiptUrl,
                              receiptDate: formattedDate,
                              docId: docId,
                            ),
                          ),
                        );
                              print("Index: $receiptUrl");
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          receiptUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
