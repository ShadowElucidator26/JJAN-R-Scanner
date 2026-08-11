import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jjan/services/color_extension.dart';

class ChangeEmailUI extends StatefulWidget {
  const ChangeEmailUI({super.key});

  @override
  State<ChangeEmailUI> createState() => _ChangeEmailUIState();
}

class _ChangeEmailUIState extends State<ChangeEmailUI> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  bool isValidGmail(String email) {
    final pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  Future<void> _updateEmail() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Update:", style: TextStyle(color: TColor.blue100),),
        content: const Text("Are you sure you want to change your email\nSuccessful changes can not revert the previous email anymore?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No",style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;


    setState(() => _isLoading = true);
    try {
      await user.verifyBeforeUpdateEmail(emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification email sent. Please check your inbox."), backgroundColor: TColor.blue100,),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Update Failed:", style: TextStyle(color: Colors.red),),
          content: const Text("Error: User needs to be logged in within 20 sec. before changing email due to sensitive actions"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: TColor.blue),),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                            'Change Email',
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.w900,
                              color: TColor.blue500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Divider(thickness: 2),
                          const SizedBox(height: 20),
                          Text("Current User's Email:", 
                            style: const TextStyle(
                              fontSize: 16, 
                              color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${user?.email}",
                            style: TextStyle(
                              fontSize: 16,
                              color: TColor.blue500.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a new email';
                              if (!isValidGmail(value)) return 'Email must end with @gmail.com';
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text('New Email'),
                              hintText: 'Enter new email',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColor.blue20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.email, color: Colors.white),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.blue100,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _updateEmail,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'UPDATE EMAIL',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
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
      bottomNavigationBar: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          "BACK",
          style: TextStyle(fontSize: 18, color: TColor.blue500, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
