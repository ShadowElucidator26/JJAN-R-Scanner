import 'package:flutter/material.dart';
import 'package:jjan/services/color_extension.dart';

class AboutUsCreator extends StatelessWidget {
  AboutUsCreator({super.key});
  
  // Your creator data
  final List<Map<String, String>> _creatorProfile = [
    {
      "FullName": "Aaron Justin Ortiz", 
      "Email": "aaronortiz31426@gmail.com",
      "Contact": "+63 961 265 8621",
      "images": "assets/images/21.jpg",
      "AboutMe": "A passionate developer with a strong interest in full stack developing, that focuses on mobile app design, UI/UX, and backend integration using Yolov8 and FastAPI for this application development.",
      "Skills": "• Flutter (Dart)\n• Python (FastAPI)\n• Machine Learning (YOLOv8)\n• Optical Character Recognition (EasyOCR)\n• Firebase\n• Cloudinary \n• HuggingFace(Model Hosting)",
      "Role": "Fullstack Developer – coded the app, integrated OCR, machine learning, and backend services with Flutter as the frontend.",
      "ToolsTech": "VS Code, Android Studio, Roboflow, Cloudinary, Firebase, Python, Flutter SDK, Google Colab",
      "Education": "Bachelor of Science in Computer Science\n– City College of Calamba",
      "Contribution": "• Built TALASCAN’s mobile UI/UX, backend, and database.\n• Trained the Yolov8 ML Model used in this TALASCAN app.\n• Designed and implemented receipt OCR workflow.",
    },
    {
      "FullName": "Julia Sophia Mendoza",
      "Email": "mendozajuliasophia@gmail.com",
      "Contact": "+63 991 180 9570",
      "images": "assets/images/19.jpg",
      "AboutMe": "A dedicated and organized project leader experienced in annotating datasets using Roboflow and efficiently managing team tasks.",
      "Skills": "• Microsoft Office: Proficient in MS Word and Excel\n• Leadership & Team Coordination\n• UI Design: Experience with Figma\n• Time Management\n• Organized",
      "Role": "Project Leader – Supervised project development, delegated responsibilities, and ensured effective collaboration among members.",
      "ToolsTech": "MS Word, Figma, Canva, Roboflow",
      "Education": "Bachelor of Science in Computer Science\n– City College of Calamba",
      "Contribution": "• Annotated handwritten and digital receipts using Roboflow for dataset preparation.\n• Handled documentation and content editing using Microsoft Word and Canva.\n• Helped with annotating the datasets needed for the ML Model Training.",
    },
    {
      "FullName": "Janna Marie Mamlayan",
      "Email": "janna15mamalayan@gmail.com",
      "Contact": "+63 993 501 7229",
      "images": "assets/images/18.jpg",
      "AboutMe": "I’m a detail-oriented designer with a strong focus on creating clean, effective, and visually engaging designs. I bring creativity and structure together to deliver high-quality results.",
      "Skills": "• Microsoft Office: Proficient in MS Word and Excel\n• UI Design: Experience with Figma\n• Creative\n• Time Management\n• Organized\n• Good Communication",
      "Role": "UI/UX Desiner / Documentation – contributed to desinging the applicaiton, as well as writing, editing, and organizing the research paper.",
      "ToolsTech": "Figma, Canva, Roboflow",
      "Education": "Bachelor of Science in Computer Science",
      "Contribution": "• Documented research and findings in the thesis paper\n• Developed initial design concepts and prototypes\n• Helped with annotating the datasets needed for the ML Model Training.",
    },
    {
      "FullName": "Ma. Nouelle Azenith Natividad",
      "Email": "azenithnatividad@gmail.com",
      "Contact": "+63 961 522 4781",
      "images": "assets/images/20.jpg",
      "AboutMe": "I’m a passionate and dedicated team member focused on documentation and UI design. I value creativity and teamwork in delivering clear, engaging, and meaningful project outcomes.",
      "Skills": "• Microsoft Office (Word, Excel)\n• UI Design (Figma)\n• Collaboration and Teamwork\n• Time Management",
      "Role": "Documentation / UI Designer – contributed to designing the user interface, as well as writing, editing, and organizing the research paper.",
      "ToolsTech": "Figma, Canva, Roboflow",
      "Education": "Bachelor of Science in Computer Science",
      "Contribution": "• Collected related articles for the research paper\n• Recorded all interviews for the study\n• Helped annotate datasets needed for ML model training"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text(
          "About Us / Creator",
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

      // 🧩 ListView builder to generate one resume per creator
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _creatorProfile.length,
        itemBuilder: (context, index) {
          final creator = _creatorProfile[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: ResumePage(
              FullName: creator["FullName"] ?? "",
              images: AssetImage(creator["images"] ?? "assets/images/userImage.jpg"),
              Email: creator["Email"] ?? "",
              Contact: creator["Contact"] ?? "",
              AboutMe: creator["AboutMe"] ?? "",
              Skills: creator["Skills"] ?? "",
              Role: creator["Role"] ?? "",
              ToolsTech: creator["ToolsTech"] ?? "",
              Education: creator["Education"] ?? "",
              Contribution: creator["Contribution"] ?? "",
            ),
          );
          
        },
      ),
    );
  }
}

// 🧾 Resume Page Widget
class ResumePage extends StatelessWidget {
  const ResumePage({
    super.key,
    required this.FullName,
    required this.images,
    required this.Email,
    required this.Contact,
    required this.AboutMe,
    required this.Skills,
    required this.Role,
    required this.ToolsTech,
    required this.Education,
    required this.Contribution,
  });

  final String FullName;
  final AssetImage images;
  final String Email;
  final String Contact;
  final String AboutMe;
  final String Skills;
  final String Role;
  final String ToolsTech;
  final String Education;
  final String Contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(FullName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Email: $Email", style: const TextStyle(fontSize: 16)),
                    Text("Contact: $Contact", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              // Profile image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Image(image: images, fit: BoxFit.cover),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(thickness: 2, color: Colors.black),

          section("About Me", AboutMe),
          section("Skills", Skills),
          section("Role in Project", Role),
          section("Tools & Technologies", ToolsTech),
          section("Education", Education),
          section("Contributions / Achievements", Contribution),
        ],
      ),
    );
    
  }

  // 🔹 Helper for sections
  Widget section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content,
              style: const TextStyle(fontSize: 16, height: 1.4),
              textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
