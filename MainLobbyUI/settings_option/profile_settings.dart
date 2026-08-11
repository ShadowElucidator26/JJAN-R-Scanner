import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/settings_option/changes_in_Profile/changeEmail.dart';
import 'package:jjan/MainLobbyUI/settings_option/changes_in_Profile/changePassword.dart';
import 'package:jjan/MainLobbyUI/settings_option/changes_in_Profile/changeStoreNameUI.dart';
import 'package:jjan/MainLobbyUI/settings_option/changes_in_Profile/changeUserImage.dart';
import 'package:jjan/MainLobbyUI/settings_option/changes_in_Profile/verifyEmail.dart';
import 'package:jjan/services/color_extension.dart';

class ProfileUI extends StatelessWidget {
  const ProfileUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // Change Profile Picture
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.blueAccent),
              title: const Text(
                "Change User Image",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateUserImageUI()),
                );
              },
            ),
            const Divider(),

             // Change Store Name
            ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined, color: Colors.blueAccent),
              title: const Text(
                "Change Store Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeStoreNameUI()),
                );
              },
            ),
            const Divider(),

            // Change Email
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.blueAccent),
              title: const Text(
                "Change Email",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailUI()));
              },
            ),
            const Divider(),

            // Verify Email
            ListTile(
              leading: const Icon(Icons.verified_outlined, color: Colors.blueAccent),
              title: const Text(
                "Verify Email",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyCurrentEmailUI()),
                );
              },
            ),
            const Divider(),

            // Change Password
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.blueAccent),
              title: const Text(
                "Change Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordUI()));
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
