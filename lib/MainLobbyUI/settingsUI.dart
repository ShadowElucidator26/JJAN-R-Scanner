import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jjan/MainLobbyUI/settings_option/aboutUsCreator_settings.dart';
import 'package:jjan/MainLobbyUI/settings_option/faq_settings.dart';
import 'package:jjan/MainLobbyUI/settings_option/profile_settings.dart';
import 'package:jjan/MainLobbyUI/settings_option/recentlyDeleted_settings.dart';
import 'package:jjan/services/firestore_services.dart';
import '../services/color_extension.dart';
import 'package:jjan/loginSignup/welcomeUI.dart';

class settingsUI extends StatefulWidget {
  const settingsUI({super.key});

  @override
  State<settingsUI> createState() => _settingsUIState();
}

class _settingsUIState extends State<settingsUI> {

  final user = FirebaseAuth.instance.currentUser;  
  String? storeName;

  @override
  void initState() {
    super.initState();
    _loadStoreName();
  }
  
  Future<void> openRecentlyDeletedReceipts(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    if (user == null) return;

    // 1️⃣ Get all files in trash
    final trashSnap = await db
        .collection("users")
        .doc(user.uid)
        .collection("trash")
        .get();

    // 2️⃣ Get server timestamp for accurate comparison
    final serverNowSnap = await db.collection("server_time").add({
      "now": FieldValue.serverTimestamp(),
    });
    final serverNowDoc = await serverNowSnap.get();
    final Timestamp? serverNowTs = serverNowDoc.data()?["now"];
    final DateTime? serverNow = serverNowTs?.toDate();
    // final DateTime serverNow = DateTime(2025, 12, 02);
    await db.collection("server_time").doc(serverNowSnap.id).delete();

    if (serverNow == null) return;

    // 3️⃣ Filter and delete expired files
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredTrashFiles = [];
    
    for (final doc in trashSnap.docs) {
      final data = doc.data();
      final deletedAt = (data["deleted_at"] as Timestamp?)?.toDate();

      if (deletedAt != null) {
        // Compute the permanent deletion date dynamically
        final permanentDeleteAt = deletedAt.add(const Duration(days: 30));

        if (serverNow.isAfter(permanentDeleteAt) ||
            serverNow.isAtSameMomentAs(permanentDeleteAt)) {
          // Expired → delete permanently
          await doc.reference.delete();

          final FirestoreService _firestoreService = FirestoreService();

          await _firestoreService.addActionHistory(
              // userId: user.uid, 
              userId: user.uid, 
              receiptName:  data['image_public_id'] ,
              dateTime: DateTime.now(),
              action: "DELETED",
            );
              print("ActionHistory Created");
              print("${data['image_public_id']}");
              
        } else {
          // Still valid → keep
          filteredTrashFiles.add(doc);
        }
      }
    }


    // 4️⃣ Go to RecentlyDeletedReceiptUI with filtered files
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RecentlyDeletedReceiptUI(
          trashFiles: filteredTrashFiles,
        ),
      ),
    );
  }

  Future<void> _loadStoreName() async {
    final name = await getCurrentStoreName();
    setState(() {
      storeName = name;
    });
  }
  Future<String?> getCurrentStoreName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    return doc.data()?["storeName"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 50),
          child: Column(
            children: [
              // Profile image
              SizedBox(
                width: 170,
                height: 170,
                child: FutureBuilder<String?>(
                  future: getProfileImageUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 85,
                        backgroundColor: TColor.blue10,
                        child: const CircularProgressIndicator(color: Colors.white),
                      );
                    } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return CircleAvatar(
                        radius: 85,
                        backgroundColor: TColor.blue10,
                        child: const Icon(Icons.person, size: 80, color: Colors.white),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 25),
              Text(
                storeName ?? "Loading store name...",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("${user?.email}", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              const Divider(thickness: 3),
              const SizedBox(height: 20),

              // Settings menu
              settingMenuWidget(
                title: 'Profile',
                images: const AssetImage('assets/images/settings.png'),
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const ProfileUI(),
                    ),
                  );
                },
                endIcon: false,
              ),
              settingMenuWidget(
                title: 'Recently Deleted Receipt',
                images: const AssetImage('assets/images/trash.png'),
                onPress: () { openRecentlyDeletedReceipts(context);
                },
                endIcon: false,
              ),
              settingMenuWidget(
                title: 'FAQs',
                images: const AssetImage('assets/images/help.png'),
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const FAQPage(),
                    ),
                  );
                },
                endIcon: false,
              ),
              settingMenuWidget(
                title: 'About Us/Creator',
                images: const AssetImage('assets/images/aboutUs.png'),
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AboutUsCreator(),
                    ),
                  );
                },
                endIcon: false,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
        child: ElevatedButton(
          onPressed: () {
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
                        "Logout Successful",
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
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context); // close success dialog
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Welcomeui()),
                (Route<dynamic> route) => false,
              );
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: TColor.blue20,
          ),
          child: const Text(
            'LOGOUT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
  Future<String?> getProfileImageUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    return doc.data()?["profileImage"];
  }

}

// ✅ FIXED: ListTile now responds to taps properly
class settingMenuWidget extends StatelessWidget {
  const settingMenuWidget({
    super.key,
    required this.title,
    required this.images,
    required this.onPress,
    required this.endIcon,
    this.textColor,
  });

  final String title;
  final AssetImage images;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress, 
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: TColor.blue0,
        ),
        child: Image(image: images, color: TColor.blue10),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor ?? TColor.gray60,
        ),
      ),
      trailing: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: TColor.blue0,
        ),
        child: Image.asset(
          'assets/images/lessThan.png',
          color: TColor.gray30,
        ),
      ),
    );
  }
  
}
