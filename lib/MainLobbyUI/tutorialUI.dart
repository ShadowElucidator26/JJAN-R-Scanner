import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/services/transition_BottomUp.dart';

class TutorialPage extends StatefulWidget {

  const TutorialPage({
    super.key,
  });

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _tutorialData = [
    {"image": "assets/images/imageTutorial.png", "text": "Open the scanner app and\nplace your document on a\nflat surface with good lighting.\nAlign your camera,\nlet the app detect the \nedges, and capture the image!"},
    {"image": "assets/images/imageTutorial1.png", "text": "Check the scanned document for\nclarity and ensure\nall important details are visible!"},
    {"image": "assets/images/imageTutorial2.png", "text": "Review the scanned document and\ncompare it with the original.\nIf needed, adjust or rescan for\nbetter quality!"},
    {"image": "assets/images/imageTutorial3.png", "text": "The system processes the confirmed data and automatically creates a corresponding ledger entry. It assigns values to the correct accounts, ensuring accurate financial records."},
  ];

  void _onStartPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      slideTransition(const mainLobby_Page(), SlideDirection.leftToRight),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tutorialData.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: 30,
          decoration: BoxDecoration(
            color: isActive ? TColor.white.withOpacity(0.6) : TColor.blue30.withOpacity(0.4),
            
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.blue20,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              TColor.blue50,
              TColor.blue10,
              TColor.blue20,
              TColor.blue20,
              TColor.blue10,
              TColor.blue100,
            ],
          ),
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _tutorialData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final data = _tutorialData[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    if (_currentPage==0)...[
                    Container(
                      width: 350,
                      height: 260,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: TColor.blue500.withOpacity(0.30),
                            blurRadius: 50,
                            offset: const Offset(6, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: Image.asset(
                          data["image"]!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        data["text"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: TColor.blue.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  ]else...[
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: TColor.blue500.withOpacity(0.30),
                              blurRadius: 50,
                              offset: const Offset(6, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(75),
                          child: Image.asset(
                            data["image"]!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Text(
                          data["text"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                color: TColor.blue.withOpacity(0.5),
                                blurRadius: 30,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                );
              },
            ),

            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),

            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage == _tutorialData.length - 1)
                      ElevatedButton(
                        onPressed: () => _onStartPressed(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "START",
                          style: TextStyle(color: TColor.blue100, fontSize: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
