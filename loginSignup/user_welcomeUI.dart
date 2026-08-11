import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/MainLobbyUI/transition_HomeUISettings.dart';
import 'package:jjan/MainLobbyUI/tutorialUI.dart';
import 'package:jjan/services/color_extension.dart';

class welcomeUserUI extends StatelessWidget {
  final String email;
  final String storeName;
  final bool isLogin;
  
  const welcomeUserUI({
    super.key,
    required this.email,
    required this.storeName,
    required this.isLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              TColor.blue50,
              TColor.blue10,
              TColor.blue5,
              TColor.blue20,
              TColor.blue20,
              TColor.blue10,
              TColor.blue5,
              TColor.blue100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Flexible(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 40.0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ App logo (same as WelcomeUI)
                        Container(
                          width: 350,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(75),
                            boxShadow: [
                              BoxShadow(
                                color: TColor.blue.withOpacity(0.3),
                                blurRadius: 50,
                                offset: const Offset(4, 12),
                              ),
                            ],
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/jjanLogo.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ✅ Instead of tagline, show user email + store
                        Center(
                          child: Text(
                            email,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: TColor.white,
                              shadows: [
                                BoxShadow(
                                  color: TColor.blue.withOpacity(0.5),
                                  blurRadius: 50,
                                  offset: const Offset(2, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: Text(
                            "Store: $storeName",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: TColor.white,
                              shadows: [
                                BoxShadow(
                                  color: TColor.blue.withOpacity(0.5),
                                  blurRadius: 50,
                                  offset: const Offset(2, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // ✅ START button (same style)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.blue30,
                            foregroundColor: TColor.blue0,
                            shadowColor: TColor.blue500,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: TColor.blue5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 25,
                            ),
                          ),
                          onPressed: () {
                            // Start button will redirect to login first
                            if (isLogin == true){
                              Navigator.pushAndRemoveUntil(
                                context,
                                slideTransition(const mainLobby_Page(), SlideDirection.leftToRight),
                                (Route<dynamic> route) => false,
                              );
                            }
                            else{
                              Navigator.pushAndRemoveUntil(
                                context,
                                slideTransition(const TutorialPage(), SlideDirection.leftToRight),
                                (Route<dynamic> route) => false,
                              );
                            }
                          },
                          child: const Text(
                            "  CONTINUE  ",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
