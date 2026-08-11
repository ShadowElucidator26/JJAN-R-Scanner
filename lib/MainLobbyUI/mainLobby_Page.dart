import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/MonthlySummaryAnalysis/pdf_dataUI.dart';
import 'package:jjan/MainLobbyUI/homeUI.dart';
import 'package:jjan/MainLobbyUI/settingsUI.dart';
import '../services/color_extension.dart';

class mainLobby_Page extends StatefulWidget {
  const mainLobby_Page({super.key});

  @override
  State<mainLobby_Page> createState() => _mainLobby_PageState();
}

class _mainLobby_PageState extends State<mainLobby_Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _pageLabel = "Home Screen";
  double _labelOpacity = 0.0;
  Timer? _labelTimer;

  final List<String> _pageNames = [
    "Home Screen",
    "Monthly Summary",
    "Settings",
  ];

  void _showPageLabel(int index) {
    _labelTimer?.cancel();
    setState(() {
      _pageLabel = _pageNames[index];
      _labelOpacity = 1.0;
    });
    // Fade out after 1.2 seconds
    _labelTimer = Timer(const Duration(milliseconds: 1200), () {
      setState(() {
        _labelOpacity = 0.0;
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _showPageLabel(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _labelTimer?.cancel();
    super.dispose();
  }
  

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: 30,
          decoration: BoxDecoration(
            color: isActive ? TColor.blue20 : TColor.blue20.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              if (isActive)
                const BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.blue5,
      appBar: AppBar(
        title: const Text(
          "TALASCAN",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
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
      ),

      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              homeUI(key: ValueKey("home")),
              pdfDataUI(key: ValueKey("monthly summary")),
              settingsUI(key: ValueKey("settings")),
            ],
          ),
          // Page label floating below AppBar
          Positioned(
            top: 9, // just below the AppBar
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _labelOpacity,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: TColor.blue10,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _pageLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
          // Page indicator at the bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }
}
