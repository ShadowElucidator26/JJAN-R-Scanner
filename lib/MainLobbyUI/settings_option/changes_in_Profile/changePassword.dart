import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jjan/services/color_extension.dart';

class ChangePasswordUI extends StatefulWidget {
  const ChangePasswordUI({super.key});

  @override
  State<ChangePasswordUI> createState() => _ChangePasswordUIState();
}

class _ChangePasswordUIState extends State<ChangePasswordUI> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool obscureCurrent = true;
  bool obscureNew = true;

  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      // 🔹 Reauthenticate first using current password
      final cred = EmailAuthProvider.credential(
        email: userEmail!,
        password: currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // 🔹 Then update password
      await user.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully."), backgroundColor: Colors.green,),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error: ${e.message}";
      if (e.code == 'wrong-password') {
        errorMsg = "Incorrect current password.";
      } else if (e.code == 'requires-recent-login') {
        errorMsg = "Please log in again to change password.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red,),
        
      );
    } finally {
      setState(() => _isLoading = false);
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
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(thickness: 2,),
                          const SizedBox(height: 20),
                          Text("Current User's Email:", 
                            style: const TextStyle(
                              fontSize: 16, 
                              color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userEmail ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: TColor.blue500.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // 🔹 Current Password Field
                          TextFormField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrent,
                            obscuringCharacter: '*',
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter your current password';
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text('Current Password'),
                              hintText: 'Enter current password',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.lock_outline, color: Colors.white),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    obscureCurrent = !obscureCurrent;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 🔹 New Password Field
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            obscuringCharacter: '*',
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter a new password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text('New Password'),
                              hintText: 'Enter new password',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.lock, color: Colors.white),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    obscureNew = !obscureNew;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 🔹 Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue100,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _updatePassword,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'UPDATE PASSWORD',
                                      style: TextStyle(
                                        fontSize: 18,
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
      bottomNavigationBar: 
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          "BACK",
          style: TextStyle(fontSize: 18, color: TColor.blue500, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
