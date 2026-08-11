import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firestore_services.dart';
import 'package:jjan/services/get_daily_images.dart';

class CalendarService {
  // Main function to pick date and calculate summaries
  static Future<void> pickDateAndCalculateSummary({
    required BuildContext context,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required Function(double) onDailyIncomeUpdated,
    required Function(double) onDailyExpenseUpdated,
    required Function(double) onWeeklySummaryUpdated,
    required Function(double) onMonthlySummaryUpdated,
    required Function(List<String>) onDailyUrlsUpdated,
    required Function(List<String>) onDailyDocIdsUpdated,  
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final pickedDate = DateTime(picked.year, picked.month, picked.day);
    onDateSelected(pickedDate);
    onDailyUrlsUpdated([]);

    final docId = DateFormat('yyyy-MM-dd').format(pickedDate);
    try {
      
    // Show persistent loading popup
    _showLoadingPopup(context, "Fetching daily summary...");
      // Ensure daily summary exists
      await FirestoreService().ensureDailySummaryExists(pickedDate);
      final summary = await FirestoreService().getDailySummaryById(docId);
      if (summary["total_daily_income"] == 0 && summary["total_daily_expense"] == 0)
      { if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      
       showDialog( context: context, builder: (_) => AlertDialog( title: const Text("No Data"), content: Text( "There are no receipts for ${DateFormat('MMMM d, yyyy').format(pickedDate)}."), actions: [ TextButton( onPressed: () => Navigator.pop(context), child: const Text("OK"), ), ], ), ); return; }
      }

      // Update daily summary
      onDailyIncomeUpdated(summary["total_daily_income"] ?? 0);
      onDailyExpenseUpdated(summary["total_daily_expense"] ?? 0);


      // ✅ Fetch receipt URLs and doc IDs
      await ReceiptService.getDailyReceiptURL(
        selectedDate: pickedDate,
        onUrlsFetched: (urls) {
          onDailyUrlsUpdated(urls);
        },
        onDocIdsFetched: (docIds) {
          onDailyDocIdsUpdated(docIds); // passes docIds to homeUI
        },
      );


      // Update loading message
      _updateLoadingPopupMessage(context, "Calculating weekly summary...");

      // Weekly summary
      int firstDayOffset = 1 - pickedDate.weekday;
      int lastDayOffset = 7 - pickedDate.weekday;
      DateTime firstDayOfWeek = pickedDate.add(Duration(days: firstDayOffset));
      DateTime lastDayOfWeek = pickedDate.add(Duration(days: lastDayOffset));

      

      double weeklyIncomeSum = 0;
      for (DateTime day = firstDayOfWeek;
          !day.isAfter(lastDayOfWeek);
          day = day.add(const Duration(days: 1))) {
        final dayDocId = DateFormat('yyyy-MM-dd').format(day);
        final daySummary = await FirestoreService().getDailySummaryById(dayDocId);
        weeklyIncomeSum += daySummary["total_daily_income"] ?? 0;
      }

      onWeeklySummaryUpdated(weeklyIncomeSum);

      // Update loading message
      _updateLoadingPopupMessage(context, "Calculating monthly summary...");

      // Monthly summary
      await calculateMonthlySummary(
        context: context,
        selectedDate: pickedDate,
        onMonthlySummaryUpdated: onMonthlySummaryUpdated,
      );

      print("Summary calculation completed for $pickedDate");

    } catch (e) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }// close loading popup if still open
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch summary: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  // Monthly summary calculation
  static Future<void> calculateMonthlySummary({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(double) onMonthlySummaryUpdated,
  }) async {
    int year = selectedDate.year;
    int month = selectedDate.month;

    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    double monthlyIncomeSum = 0;

    for (int day = 1; day <= lastDayOfMonth; day++) {
      DateTime currentDay = DateTime(year, month, day);
      String dayDocId = DateFormat('yyyy-MM-dd').format(currentDay);

      final daySummary = await FirestoreService().getDailySummaryById(dayDocId);
      monthlyIncomeSum += daySummary["total_daily_income"] ?? 0;
    }

    onMonthlySummaryUpdated(monthlyIncomeSum);
    print("Monthly Income Sum for $month/$year: $monthlyIncomeSum");
  }

  // Persistent loading popup
  static void _showLoadingPopup(BuildContext context, String message) {
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

  // Update the loading message dynamically
  static void _updateLoadingPopupMessage(BuildContext context, String newMessage) {
    // Pop current dialog
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    // Show new dialog with updated message
    _showLoadingPopup(context, newMessage);
  }
}
