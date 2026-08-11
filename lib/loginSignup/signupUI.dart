import 'package:flutter/material.dart';
import 'package:jjan/loginSignup/forgot_passwordUI.dart';
import 'package:jjan/loginSignup/verify_emailUI.dart';
//import 'package:jjan/loginSignup/phone_number_verification.dart';
import 'package:jjan/services/transition_BottomUp.dart';
import '../services/color_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginUI.dart';

class Signupui extends StatefulWidget {
  const Signupui({super.key});

  @override
  State<Signupui> createState() => _SignupuiState();
}

class _SignupuiState extends State<Signupui> {
  final _formSignupKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  // ✅ Loading popup
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

  // ✅ Validators
  bool isValidGmail(String email) {
    // Check if it ends with @gmail.com and has at least one character before @
    final pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }
  bool isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
    return regex.hasMatch(password);
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
                      key: _formSignupKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2,),
                          const SizedBox(height: 45),
                          // Email
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
                              hintStyle: const TextStyle(color: Colors.black26),
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 45),
                          // Password
                          TextFormField(
                            obscureText: obscurePassword,
                            obscuringCharacter: '*',
                            controller: passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Password';
                              }
                              if (!isValidPassword(value)) {
                                return 'Password must be 8+ chars, include upper, lower, number, special';
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
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                          // Signup Button
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
                                if (!_formSignupKey.currentState!.validate()) return;

                                _showLoadingPopup("Creating Account...");
                                try {
                                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );

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
                                              "Saved Successfully",
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


                                  //Email Verification                              
                                  User? user = FirebaseAuth.instance.currentUser;
                                  if (user != null && !user.emailVerified) {
                                    await user.sendEmailVerification();
                                  }                                   

                                  // ✅ Show success dialog
                                  if (Navigator.canPop(context)) Navigator.pop(context); // close success popup

                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text("Verify Your Email"),
                                      content: Text(
                                        "A verification link has been sent to ${emailController.text.trim()}. \n"
                                        "Please check your INBOX/SPAM before logging in.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (_) => VerifyEmailUI(email: emailController.text.trim())),
                                            );
                                          },
                                          child: Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                } on FirebaseAuthException catch (e) {
                                  if (Navigator.canPop(context)) Navigator.pop(context); // close loading popup if open

                                  String message = "Please try again.";
                                  if (e.code == 'email-already-in-use') {
                                    message = "This email is already registered. Please use another.";
                                  } else if (e.code == 'invalid-email') {
                                    message = "The email address is invalid.";
                                  } else if (e.code == 'weak-password') {
                                    message = "Password is too weak. Please use a stronger password.";
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Failed to create an Account"),
                                      content: Text(message),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                } catch (e) {
                                  if (Navigator.canPop(context)) Navigator.pop(context); // fallback
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Error"),
                                      content: const Text("Something went wrong. Please try again."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: Text('SIGN UP', style: TextStyle(fontSize: 19, color: TColor.white, fontWeight: FontWeight.bold,),),
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
            const Text("Already have an account? "),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  slideTransition(
                      const loginUI(),
                      SlideDirection.rightToLeft),
                );
              },
              child: Text(
                "Login",
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