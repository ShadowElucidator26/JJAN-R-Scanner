import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/services/firestore_services.dart';
import 'package:month_year_picker/month_year_picker.dart';
import './generate_PDFui.dart';

class pdfDataUI extends StatefulWidget {
  const pdfDataUI({super.key});

  @override
  State<pdfDataUI> createState() => _pdfDataUIState();
}

class _pdfDataUIState extends State<pdfDataUI>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _myAnimation;
  bool _overlayVisible = false; 
  List weeks = ["Week 1","Week 2","Week 3","Week 4","Week 5"];
  int _daysInMonth = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  List<double> _weeklyIncome = [];
  List<double> _weeklyExpense= [];
  List<double> _dailyIncome = [];
  List<double> _dailyExpense = [];


  DateTime? _selectedDate;

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
  }

  @override
  void dispose() {
    _controller.dispose();
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


  

  Future<void> _pickMonthYear() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
                  bodyLarge: const TextStyle(fontSize: 14),
                  bodyMedium: const TextStyle(fontSize: 12),
                ),
            dialogTheme: const DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final pickedMonth = DateTime(picked.year, picked.month);
      final currentMonth = DateTime(now.year, now.month);

      if (pickedMonth.isAfter(currentMonth)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("You cannot select a date ahead of the current month."),
            backgroundColor: Colors.red,
          ),
        );
      } else {

        _showLoadingPopup("Fetching Data...");

        //the month starts at day 1
        int startDay= 1;
        //this is the last day of week 1
        int lastDayOfWeek = (7 - picked.weekday +1);
        //this computes how many days there are on the selected month
        int daysInMonth = DateTime(picked.year, picked.month + 1, 0).day;
        List<double> weeklyIncome = [];
        List<double> weeklyExpense = [];
    
        final dailySummaries = await FirestoreService().getDailySummariesForMonth(picked.year, picked.month);

        if (dailySummaries.isEmpty) {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("The date you selected is Empty."),
              backgroundColor: Colors.red,
            ),
          );
           // Reset all state related to charts
          setState(() {
            _selectedDate = null;
            _daysInMonth = 0;
            _dailyIncome = [];
            _dailyExpense = [];
            _weeklyIncome = [];
            _weeklyExpense = [];
            _monthlyIncome = 0;
            _monthlyExpense = 0;
          });

          // Stop execution early — charts won't be built
          return;
        }

        // Initialize 0 for all days so if empty it wont crash
        final income = List<double>.filled(daysInMonth, 0);
        final expense = List<double>.filled(daysInMonth, 0);

        for (var dayData in dailySummaries) {
          final day = (dayData['date'] as DateTime).day - 1;
          income[day] = dayData['total_daily_income'];
          expense[day] = dayData['total_daily_expense'];
        }
        
        //weekly summary code
        while (startDay <= daysInMonth){
          if (lastDayOfWeek > daysInMonth) lastDayOfWeek = daysInMonth;

          List<double> weekIncome = income.sublist(startDay - 1, lastDayOfWeek);
          List<double> weekExpense = expense.sublist(startDay - 1, lastDayOfWeek);

          double totalWeekIncome = weekIncome.isNotEmpty ? weekIncome.reduce((a, b) => a + b) : 0;
          double totalWeekExpense = weekExpense.isNotEmpty ?weekExpense.reduce((a, b) => a + b) : 0;
          

          weeklyIncome.add(totalWeekIncome);
          weeklyExpense.add(totalWeekExpense);

          startDay = lastDayOfWeek + 1;
          lastDayOfWeek = startDay + 6;
        }


        double monthlyIncome = weeklyIncome.reduce((a, b) => a + b);
        double monthlyExpense = weeklyExpense.reduce((a, b) => a + b);
        
        setState(() {
          _selectedDate = picked;
          _daysInMonth = daysInMonth; 
          _dailyIncome = income;
          _dailyExpense = expense;
          _weeklyIncome = weeklyIncome;
          _weeklyExpense = weeklyExpense;
          _monthlyIncome = monthlyIncome;
          _monthlyExpense = monthlyExpense;
        }
        );

        
        Navigator.pop(context); // close loading popup

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
                    "Fetched Data Successful",
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

        // Wait for 1.5s, then close dialog and navigate
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // close success dialog
        });

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                  Image.asset(
                    'assets/images/jjanLogo copy1.png', // 🔹 replace with your image path
                    height: 60,
                    width: 60,
                  ),

                SizedBox(width: 10),

                _selectDate(),

                SizedBox(width: 10),

                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: TColor.blue20, size: 35),
                  onPressed: () async {
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a date first.")),
                      );
                      return;
                    }

                    // Generate PDF bytes
                    Uint8List pdfBytes = await PdfMonthlyReportService().createMonthlyReport(
                      selectedDate: _selectedDate!,
                      dailyIncome: _dailyIncome,
                      dailyExpense: _dailyExpense,
                      monthlyIncome: _monthlyIncome,
                      monthlyExpense: _monthlyExpense,
                      weeklyIncome: _weeklyIncome,
                      weeklyExpense: _weeklyExpense,
                    );

                    // Preview in-app
                    await PdfMonthlyReportService().saveAndPreviewPdf(pdfBytes, _selectedDate!,);
                  },
                )


              ],
            ),
          ),

          Divider(color: Colors.grey.shade400, thickness: 1.5, height: 1.5),

          // Main content
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDate == null)...[
                        Padding( padding: EdgeInsets.only( top: 300,),
                        child: Text("Please Select a Date to Start.", 
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                      // 🟢 MONTHLY SUMMARY
                      if (_selectedDate != null)...[
                        const Divider(thickness: 2),
                        _buildMonthlySummaryTable(_selectedDate!, _monthlyIncome, _monthlyExpense),
                        const Divider(thickness: 2),
                      ],

                      // 🔵 WEEKLY SUMMARY
                      if (_selectedDate != null)...[
                        const Divider(thickness: 2),
                        _buildWeeklySummaryTable(_selectedDate!),
                        const Divider(thickness: 2),
                      ],
                      
                      // 🟡 DAILY SUMMARY
                      if (_selectedDate != null)...[
                        const Divider(thickness: 2),
                        _buildDailySummaryTable(_selectedDate!, _dailyIncome, _dailyExpense),
                        const Divider(thickness: 2),
                      ]
                    ],
                  ),
                ),

                // Overlay buttons
                if (_overlayVisible)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FadeTransition(
                      opacity: _myAnimation,
                      child: Row(
                        children: [
                          _buildOverlayButton(
                              "File", Icons.insert_drive_file, "fileBtn"),
                          const SizedBox(width: 20),
                          _buildOverlayButton("Share", Icons.share, "shareBtn"),
                          const SizedBox(width: 20),
                          _buildOverlayButton(
                              "Camera", Icons.camera_alt, "cameraBtn"),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      );
  }

  // --- 🟢 BUILDERS ---
  Widget _selectDate(){
    return Row(  
      crossAxisAlignment: CrossAxisAlignment.center,   
      children: [ 
        Text(
          _selectedDate == null
              ? "Select Date:"
              : "${_monthName(_selectedDate!.month)} ${_selectedDate!.year}",
          style: TextStyle(
            fontSize: 18,
            color: _selectedDate == null ? Colors.grey : TColor.blue500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.calendar_today, color: TColor.blue20),
          onPressed: _pickMonthYear,
        ),
      ],
    );

  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }


  //MONTHLY SUMMARY
  Widget _buildMonthlySummaryTable(DateTime selectedDate, double monthlyIncome, double monthlyExpense){
    return Column(  
      crossAxisAlignment: CrossAxisAlignment.start,   
      children: [
        const Text("Monthly Summary:",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // 🟢 Pie Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: monthlyIncome,
                  color: Colors.green.shade600,
                  title: "Income\n₱${monthlyIncome.toInt()}",
                  radius: 70,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                PieChartSectionData(
                  value: monthlyExpense,
                  color: Colors.red.shade400,
                  title: "Expense\n₱${monthlyExpense.toInt()}",
                  radius: 70,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _monthlySummaryHeader(),
        _monthlySummaryRow("₱${monthlyIncome.toInt()}", "₱${monthlyExpense.toInt()}"),
      ]
    );

  }

  Widget _monthlySummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: const Row(
        children: [
          Expanded(
              flex: 1,
              child: Text("Income",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(
              flex: 1,
              child: Text("Expense",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
        ],
      ),
    );
  }
  
  Widget _monthlySummaryRow(String income, String expense) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(income, textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(expense, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  //WEEKLY SUMMARY  
  Widget _buildWeeklySummaryTable(DateTime selectedDate){
    return Column(  
      crossAxisAlignment: CrossAxisAlignment.start,   
      children: [
          const Text("Weekly Summary:",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            height: 400,
            padding: const EdgeInsets.all(12),
            child: _buildWeeklyBarChart(_weeklyIncome, _weeklyExpense),
          ),
          Divider(thickness: 2,),
          
          _weeklySummaryHeader(),
          for (int i = 0; i < _weeklyIncome.length; i++) 
          _weeklySummaryRow(weeks[i], _weeklyIncome[i], _weeklyExpense[i]),
      ]
    );

  }

  Widget _weeklySummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: const Row(
        children: [
          Expanded(
              flex: 1,
              child: Text("Label",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 1,
              child: Text("Income",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(
              flex: 1,
              child: Text("Expense",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          Expanded(
              flex: 1,
              child: Text("Networth",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<double> weeklyIncome, List<double> weeklyExpense) {
    // Same weekly data as your table
    final week = ["W1", "W2", "W3", "W4", "W5"];
    
    double highestIncome = weeklyIncome.reduce((a, b) => a > b ? a : b).toDouble();
    double highestExpense = weeklyExpense.reduce((a, b) => a > b ? a : b).toDouble();

    double highestTotal = (highestIncome > highestExpense) ? highestIncome : highestExpense;

    return BarChart(
      BarChartData(
        maxY: (highestTotal),
        minY: -(highestTotal),
        barGroups: List.generate(week.length, (i) {
          var networth = weeklyIncome[i] - weeklyExpense[i];
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: weeklyIncome[i].toDouble(),
                color: Colors.green.shade600,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: weeklyExpense[i].toDouble(),
                color: Colors.red.shade400,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: networth.toDouble(),
                color: Colors.blueAccent.shade400,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: highestTotal/4,
              reservedSize: 50,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < week.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(week[index],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: (1000)),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {              
              return BarTooltipItem(
                "${rod.color == Colors.green.shade600 ? "Income" : "Expense"}: ₱${rod.toY.toInt()}",
                const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _weeklySummaryRow(String label, double income, double expense) {
    double networth = income - expense;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(label, textAlign: TextAlign.left)),
          Expanded(flex: 1, child: Text(income.toString(), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(expense.toString(), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(networth.toString(), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  
  //DAILY SUMMARY
  Widget _buildDailySummaryTable(DateTime selectedDate, List<double> dailyIncome, List<double> dailyExpense ){
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    List<double> safeIncome = List.generate(
      lastDay, (i) => i < dailyIncome.length ? dailyIncome[i] : 0);
    List<double> safeExpense = List.generate(
      lastDay, (i) => i < dailyExpense.length ? dailyExpense[i] : 0);
  
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Daily Summary:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
        height: 400,
        padding: const EdgeInsets.all(12),
        child: _buildDailyLineChart(safeIncome, safeExpense),
      ),
      const SizedBox(height: 10),

        _buildDailyRow(safeIncome, safeExpense, lastDay),
      ],
    );
  }

  Widget _buildDailyLineChart(List<double> income, List<double> expense) {
  final days = List.generate(income.length, (i) => (i + 1).toDouble());
  List<double> networth = List.generate(income.length, (i) => income[i] - expense[i]);
  double lowestNetworth = networth.reduce((a, b) => a < b ? a : b).toDouble();

  if (income.isEmpty || expense.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text("The date you selected is Empty."),
        backgroundColor: Colors.red,
      ),
    );
  }
  double maxY = [
    income.reduce((a, b) => a > b ? a : b),
    expense.reduce((a, b) => a > b ? a : b), 
  ].reduce((a, b) => a > b ? a : b).toDouble();
  if (maxY == 0) maxY = 1;


  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true, 
        horizontalInterval: (maxY) / 6),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: maxY / 5,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (days.length / 10).floorToDouble().clamp(1, 5),
            getTitlesWidget: (value, meta) {
              int day = value.toInt();
              if (day > 0 && day <= days.length) {
                return Text("$day");
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        // 🟩 Income line
        LineChartBarData(
          spots: List.generate(income.length, (i) => FlSpot(days[i], income[i])),
          color: Colors.green.shade600,
          isCurved: true,
          dotData: FlDotData(show: false),
          barWidth: 3,
        ),
        // 🟥 Expense line
        LineChartBarData(
          spots: List.generate(expense.length, (i) => FlSpot(days[i], expense[i])),
          color: Colors.red.shade400,
          isCurved: true,
          dotData: FlDotData(show: false),
          barWidth: 3,
        ),
        LineChartBarData(
          spots: List.generate(networth.length, (i) => FlSpot(days[i], networth[i])),
          color: Colors.blueAccent.shade400,
          isCurved: true,
          dotData: FlDotData(show: false),
          barWidth: 3,
        ),
      ],
      borderData: FlBorderData(show: true),
      minY: (lowestNetworth*=1.2) ,
      maxY: (maxY*=1.1),
    ),
  );
}

  

  Widget _buildDailyRow(List<double> income, List<double> expense, int lastDay) {
    List<double> networth = List.generate(lastDay, (i) => income[i] - expense[i]);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Labels column
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Text("Income",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),),
                SizedBox(height: 20),
                Text("Expense",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                SizedBox(height: 20),
                Text("Networth",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),              ],
            ),
          ),

          // Scrollable data column
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      lastDay,
                      (day) => _cell("${day+1}",isColor: true,
                    ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      lastDay,
                      (day) => _cell("₱${income[day]}"),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      lastDay,
                      (day) => _cell("₱${expense[day]}"),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      lastDay,
                      (day) => _cell("₱${networth[day]}"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text,{bool  isColor = false}) => Container(
    color:  isColor? Colors.grey.shade200 : Colors.white,
    width: 110,
    alignment: Alignment.center,
    child: Text(text),
  );


  Widget _buildOverlayButton(String label, IconData icon, String heroTag) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: TColor.blue500,
          onPressed: () {},
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }  
}
