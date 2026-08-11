import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jjan/loginSignup/forgot_passwordUI.dart';
import 'package:jjan/loginSignup/user_welcomeUI.dart';
import 'package:jjan/services/transition_BottomUp.dart';
import '../services/color_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signupUI.dart';

class loginUI extends StatefulWidget {
  const loginUI({super.key});

  @override
  State<loginUI> createState() => _loginUIState();
}

class _loginUIState extends State<loginUI> {
  final _formLoginKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  bool isLogin = false;
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  bool isValidGmail(String email) {
    // Check if it ends with @gmail.com and has at least one character before @
    final pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              const Expanded(flex: 1, child: SizedBox(height: 10)),
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 45, 25, 20),
                  decoration: BoxDecoration(
                    color: TColor.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formLoginKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2,),
                          const SizedBox(height: 45),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Email';
                              }
                              if (!isValidGmail(value)) {
                                return 'Email must end with @gmail.com';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text('Email'),
                              hintText: 'Enter Email',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20, // background of the icon
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.email, color: Colors.white),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 45),
                          TextFormField(
                            obscureText: obscurePassword,
                            obscuringCharacter: '*',
                            controller: passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Password';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text('Password'),
                              hintText: 'Enter Password',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20, // background of the icon
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.lock, color: Colors.white),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordUI()),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: TColor.blue500, fontWeight: FontWeight.bold,),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue100, // set the background color
                                foregroundColor: Colors.white, // optional: text color
                                padding: const EdgeInsets.symmetric(vertical: 12), // optional: button height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // optional: rounded corners
                                ),
                              ),
                              onPressed: () async {
                                if (!_formLoginKey.currentState!.validate()) return;

                                _showLoadingPopup("Logging in...");
                                try {
                                  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                  
                                  final uid = userCredential.user!.uid;

                                  // Fetch storeName from Firestore
                                  final doc = await FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(uid)
                                      .get();

                                  final storeName = doc.data()?["storeName"] ?? "";


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
                                              "Login Successful",
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => welcomeUserUI(
                                          email: userCredential.user?.email ?? "",
                                          storeName: storeName, // make sure you got this from Firestore or state
                                          isLogin: true,
                                        ),
                                      ),
                                    );
                                  });

                                } catch (e) {
                                  Navigator.pop(context); // close loading popup if open
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Login Failed"),
                                      content: const Text("Incorrect email or password.\nPlease try again."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("OK", style: TextStyle(color: TColor.blue100),),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 19,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? "),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  slideTransition(const Signupui(), SlideDirection.leftToRight),
                );
              },
              child: Text(
                "Sign up",
                style: TextStyle(
                  color: TColor.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
