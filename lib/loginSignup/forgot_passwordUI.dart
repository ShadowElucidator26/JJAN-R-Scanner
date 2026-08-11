import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/color_extension.dart';

class ForgotPasswordUI extends StatefulWidget {
  const ForgotPasswordUI({super.key});

  @override
  State<ForgotPasswordUI> createState() => _ForgotPasswordUIState();
}

class _ForgotPasswordUIState extends State<ForgotPasswordUI> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      // ✅ Show success popup
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Password Reset"),
          content: Text(
            "A password reset link has been sent to ${emailController.text.trim()}. "
            "Please check your inbox.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to loginUI
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Failed to send reset email.";
      if (e.code == "user-not-found") {
        message = "No account found with this email.";
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  bool isValidGmail(String email) {
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
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Forgot Password",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2),
                          const SizedBox(height: 25),
                          Text(
                            'Note: You can recover your password only if\n'
                            'You Verified your account during sign up\n'
                            'or Verified account at settings',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Email input
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
                              hintText: 'Enter your email',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.email, color: Colors.white),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 45),

                          // Reset button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue100,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Send Reset Link",
                                style: TextStyle(
                                  fontSize: 19,
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
    );
  }
}
