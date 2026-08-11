import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jjan/loginSignup/infoFormUI.dart';
import '../services/color_extension.dart';

class VerifyEmailUI extends StatefulWidget {
  final String email; // from signup

  const VerifyEmailUI({super.key, required this.email});

  @override
  State<VerifyEmailUI> createState() => _VerifyEmailUIState();
}

class _VerifyEmailUIState extends State<VerifyEmailUI> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // 🔁 Resend Verification Link
  Future<void> _resendVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email resent to ${widget.email}"), backgroundColor: TColor.blue100,),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend email: $e"), backgroundColor: Colors.red,),
      );
    }
  }

  // ✅ Check if email is verified
  Future<void> _checkVerification() async {
    _showLoadingPopup("Checking verification...");

    await _auth.currentUser?.reload(); // refresh user
    User? user = _auth.currentUser;

    if (Navigator.canPop(context)) Navigator.pop(context); // close success popup


    if (user != null && user.emailVerified) {
      // 🎉 Go to next step
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
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Email Verified Successfully",
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

      await Future.delayed(const Duration(seconds: 2));
      if (Navigator.canPop(context)) Navigator.pop(context); // close success popup

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => infoFormUI(email: widget.email),
        ),
      );
    } else {
      // ⚠️ Not verified
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Email not verified"),
          content: const Text(
            "Your email is still not verified. Please check your inbox or resend the link.",
          ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2,),
                          const SizedBox(height: 30),

                        Text(
                          "We sent a verification link to\n${widget.email}\n\n"
                          "Please check your INBOX/SPAM before continuing.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),

                        const SizedBox(height: 50),

                        // 🔁 Resend Email
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _resendVerification,
                            icon: const Icon(Icons.email),
                            label: const Text("Resend Verification Email"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.blue100,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ✅ Check Verification
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _checkVerification,
                            icon: const Icon(Icons.check_circle),
                            label: const Text("I Verified, Continue"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
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
            const Text("Verify your email later? "),
            GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("ARE YOU SURE?", style: TextStyle(
                  color: Colors.red,
                ),
                  ),
                      content: const Text(
                        "Skipping this will prevent you from retrieving your account later.\n\n(You can verify your account in settings later.)",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: TextStyle(color: TColor.blue100,fontWeight: FontWeight.bold,)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => infoFormUI(email: widget.email),
                              ),
                            );
                          },
                          child: const Text("Confirm", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
              },
              child: Text(
                "SKIP EMAIL VERFICATION",
                style: TextStyle(
                  color: Colors.red,
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
