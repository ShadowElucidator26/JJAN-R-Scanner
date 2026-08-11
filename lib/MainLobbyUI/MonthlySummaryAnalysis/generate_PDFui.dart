import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// Service that generates the monthly PDF report
class PdfMonthlyReportService {
  Future<Uint8List> createMonthlyReport({
    required DateTime selectedDate,
    required List<double> dailyIncome,
    required List<double> dailyExpense,
    required double monthlyIncome,
    required double monthlyExpense,
    required List<double> weeklyIncome,
    required List<double> weeklyExpense,
  }) async {
    final pdf = pw.Document();
    final imageBytes = await rootBundle.load('assets/images/jjanLogo copy1.png');
    final logo = pw.MemoryImage(imageBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            child: pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                pw.Positioned(
                  left: 0,
                  child: pw.Image(logo, height: 40, width: 40, fit: pw.BoxFit.cover),
                ),
                pw.Center(
                  child: pw.Text(
                    "TALASCAN Monthly Report",
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          pw.Text("Date: ${_monthName(selectedDate.month)} ${selectedDate.year}"),
          pw.SizedBox(height: 10),
          pw.Text("Monthly Summary:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Monthly Income:  ${monthlyIncome.toStringAsFixed(2)}"),
          pw.Text("Monthly Expense:  ${monthlyExpense.toStringAsFixed(2)}"),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Text("Weekly Summary:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ["Week", "Income", "Expense", "Networth"],
            data: List.generate(
              weeklyIncome.length,
              (i) => [
                "Week ${i + 1}",
                weeklyIncome[i].toStringAsFixed(2),
                weeklyExpense[i].toStringAsFixed(2),
                (weeklyIncome[i] - weeklyExpense[i]).toStringAsFixed(2),
              ],
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text("Daily Summary:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ["Day", "Income", "Expense", "Networth"],
            data: List.generate(
              dailyIncome.length,
              (i) => [
                "${i + 1}",
                dailyIncome[i].toStringAsFixed(2),
                dailyExpense[i].toStringAsFixed(2),
                (dailyIncome[i] - dailyExpense[i]).toStringAsFixed(2),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _monthName(int month) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[month - 1];
  }
  
  Future<void> saveAndPreviewPdf(Uint8List pdfBytes, DateTime selectedDate,) async {
    // Save to temporary directory
    final output = await getTemporaryDirectory();
    final fileName =
        "TALASCAN_Monthly_Report_${selectedDate.year}_${selectedDate.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}";
    final filePath = "${output.path}/report.pdf";
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    // Preview in-app using printing package
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
      usePrinterSettings: false,
      
    );
  }
}

