import 'package:flutter/material.dart';
import 'package:jjan/services/color_extension.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> faqData = {
      "How to scan a receipt?":
          "1.) Open the TALASCAN app\n2.) Tap 'Scan Receipt'\n3.) Capture or upload your receipt image.\n\nThe app will automatically detect the total amount and store name.",
      "Why is my receipt not being detected?":
          "Make sure your camera is:\n\n• focused,\n• the receipt is flat,\n• and the lighting is clear.\n\n⚠️ Avoid blurry or crumpled receipts.",
      "Can I retrieve a trashed receipt?":
          "You can restore trashed receipts within\n30 days from the Trash section.\nAfter 30 days, they are\nPERMANENTLY DELETED FOREVER.",
      "What should I do if my internet is weak?":
          "TALASCAN cannot be used with weak signal, it needs it to:\n\n• Login/SignUp with the internet\n• to save receipts on the Firestore cloud database.",
      "Are my scanned receipts saved automatically?":
          "Yes. Once confirmed, your receipts\nare automatically uploaded to Firestore under your account,\nand categorized as income or expense.\n(Not unless there's no interruption or problem during the process like internet loss)",
      "Can I edit the receipt details after saving?":
          "Yes. You can open a saved receipt and modify the:\n\n• date,\n• store name,\n• category,\n• or total.",
      "How accurate is the  TALASCAN?":
          "Accuracy depends on lighting and receipt clarity. It uses:\n\n•YOLOv8 for detecting the store name, and total of the scanned receipt, and;\n•EasyOCR for ledger classification, achieving around 80% accuracy in clear images.",
      "What happens if the app crashes during scanning?":
          "You will need to do the process again if the app crashes",
      "Is there a limit to how many receipts I can scan per day?":
          "No, there’s no strict limit.\nYou can scan as many as you want,\nbut internet speed and device storage may affect performance.",
      "Who developed TALASCAN?":
          "TALASCAN was developed by a team of students from City College of Calamba\nto help micro-businesses automatically categorize receipts into income and expense ledgers.",
    };
    
    final List<String> faqs = faqData.keys.toList();

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text(
          "F A Q",
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
        child: ListView.separated(
          itemCount: faqs.length,
          separatorBuilder: (context, index) => Divider(
            color: TColor.blue10,
            thickness: 2,
            height: 20,
          ),
          itemBuilder: (context, index) {
            final question = faqs[index];
            return Card(
              color: TColor.blue10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: ListTile(
                title: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FAQDetailPage(
                        question: question,
                        answer: faqData[question]!,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class FAQDetailPage extends StatelessWidget {
  final String question;
  final String answer;

  const FAQDetailPage({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text(
          "FAQs Details",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: TColor.blue20,
              ),
            ),
            const SizedBox(height: 10),
            Divider(thickness: 2,),
            const SizedBox(height: 10),
            Text(
              answer,
              style: TextStyle(
                fontSize: 20,
                color: TColor.gray70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
