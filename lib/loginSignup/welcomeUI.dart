import 'package:flutter/material.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:jjan/loginSignup/loginUI.dart';
import 'package:jjan/services/transition_BottomUp.dart';

class Welcomeui extends StatefulWidget {
  const Welcomeui({super.key});

  @override
  State<Welcomeui> createState() => _WelcomeuiState();
}

class _WelcomeuiState extends State<Welcomeui> {
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
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Flexible(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 40.0,
                      ),
                      child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App logo
                          Container(
                            width: 350, // adjust as needed
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(75),
                              boxShadow: [ BoxShadow( 
                                  color: TColor.blue.withOpacity(0.3), 
                                  blurRadius: 50, offset: const Offset(4, 12), 
                                ), 
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/jjanLogo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 0, height: 30),
                          // Welcome text
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '',
                                  style: TextStyle(
                                    fontSize: 2.6,
                                    fontWeight: FontWeight.w600,
                                    color: TColor.white, 
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Turns Receipt chaos into business clarity.\n',
                                  style: TextStyle(
                                    fontSize: 22.0,
                                    color: TColor.white,
                                    shadows: [ BoxShadow( 
                                        color: TColor.gray70.withOpacity(0.5), 
                                        blurRadius: 40, offset: const Offset(2, 6), 
                                      ), 
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          // ✅ Replaced Log in / Sign up row with single START button
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
                              Navigator.push(
                                context,
                                slideTransition(const loginUI(), SlideDirection.leftToRight),
                              );
                            },
                            child: const Text(
                              "  START  ",
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
          ],
        ),
      ),
    );
  }
}
