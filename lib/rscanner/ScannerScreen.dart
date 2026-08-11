import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jjan/MainLobbyUI/receipt_selector.dart';
import 'package:jjan/rscanner/RecognizerScreen.dart';
import 'package:jjan/services/backend_service.dart';
import 'package:jjan/services/prediction_handling.dart';
import 'package:jjan/widgets/loading_dialog.dart';
import '../services/color_extension.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late ImagePicker imagePicker;
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  bool isImagePickerActive = false;
  bool isUploading = false;
  bool isFlipped = false;
  bool isFlashOn = false; // 🔦 Added flashlight state
  bool onContinue = false;
  String result = "";

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    _setupCameraController();
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.blue500,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: 
                GestureDetector(
                  onTap: ()=>{
                    _disposeCamera(),
                    _setupCameraController(),
                    print("dispose camera and setup camera was used"),
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0, left: 8.0, right: 8.0),
                    child: Card(
                      color: TColor.blue500,
                      child: _rotateScreen(),
                    ),
                  ),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
          if (isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
             Positioned(
              bottom: 150,
              right: 10,
              child: InkWell(
                onTap: (){
                  setState(() {
                    isFlipped = !isFlipped; // ✅ toggle between true/false
                  });
                }, // 👈 reuse your existing function
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/flip.png', // 🔹 replace with your image path
                    height: 60,
                    width: 60,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _rotateScreen() {
    if(isFlipped == true){
      return _buildLandscapeCameraPreview();
    }
    else{
      return _buildCameraPreview();
    }
  }

  Widget _showCapturedImage(File capturedfile){
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.file(
              capturedfile,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: (){
                      Navigator.pop(context, false); // ❌ Retake pressed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake"),
                ),
                ElevatedButton.icon(
                  onPressed: (){
                      Navigator.pop(context, true); // ❌ Retake pressed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Continue"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Rotate and scale to fit portrait properly
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8), // same as Card’s rounded corners
          child: Transform.rotate(
            angle: pi / 2, // 90 degrees rotation
            child: SizedBox(
              width: constraints.maxHeight,  // swapped because of rotation
              height: constraints.maxWidth,  
              child: FittedBox(
                fit: BoxFit.cover, // fill the card nicel
                child: SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CameraPreview(cameraController!, 
                  ),
                ),
              ),
            ),
          )
        );
      },
    );
  }

  Widget _buildLandscapeCameraPreview() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Rotate and scale to fit portrait properly
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8), // same as Card’s rounded corners
            child: SizedBox(
              child: FittedBox(
                fit: BoxFit.cover, // fill the card nicel
                child: SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
        );
      },
    );
  }



  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 8, right: 8, top: 5),
      child: Card(
        color: TColor.blue20,
        child: SizedBox(
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ⚡ Flashlight toggle (NEW)
              InkWell(
                onTap: _toggleFlash,
                child: Icon(
                  isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  size: 40,
                  color: isFlashOn ? Colors.amber : Colors.black54,
                ),
              ),

              // Capture
              InkWell(
                onTap: _shutter, 
                child: const Icon(
                  Icons.camera,
                  size: 75,
                  color: Colors.black87,
                ),
              ),

              // Gallery
              InkWell(
                onTap: _pickImageFromGallery,
                child: const Icon(
                  Icons.image_rounded,
                  size: 40,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _shutter() async{
    if (cameraController == null) return;
    isUploading ? null : _captureImage();
  }

  Future<void> _setupCameraController() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        await cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
      _disposeCamera();
    }
  }

  Future<void> _disposeCamera() async {
  if (cameraController != null && cameraController!.value.isInitialized) {
    try {
      if (isFlashOn == true) {
        await cameraController!.setFlashMode(FlashMode.off);
        setState(() => isFlashOn = false);
      }
      await cameraController!.dispose();
    } catch (e) {
      debugPrint("Failed to turn off flash: $e");
      await cameraController!.dispose();
    try {
        await cameraController!.dispose();
      } catch (_) {}
    } finally {
      cameraController = null;
      if (mounted) setState(() {});
      }
  }
}



  // 🔦 NEW: Flashlight toggle function
  Future<void> _toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    try {
      isFlashOn = !isFlashOn;
      await cameraController!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint("Flashlight toggle failed: $e");
    }
  }

  Future<void> _captureImage() async {
    if (cameraController == null || isUploading) return;

    try {
      final xfile = await cameraController!.takePicture();
      final File file = File(xfile.path);

      // ✅ Turn off the flash first before disposing
      if (isFlashOn && cameraController!.value.isInitialized) {
        await cameraController!.setFlashMode(FlashMode.off);
        setState(() => isFlashOn = false);
        await Future.delayed(const Duration(milliseconds: 200)); // give hardware time
      }

      // Stop camera preview to free resources
      await _disposeCamera();

      bool? continueCapture = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _showCapturedImage(file)),
      );

      // If user chose to retake
      if (continueCapture == false || continueCapture == null) {
        await _setupCameraController();
        return;
      }
      
      // Ask receipt type first
      // ignore: use_build_context_synchronously
      String? endpoint = await ReceiptSelector.showReceiptTypeDialog(context, File(file.path));
      if (endpoint == null) {
        await _setupCameraController();
        return;
      }

      await _processImage(File(file.path), endpoint);

    } catch (e) {
      setState(() => isUploading = false);
      LoadingDialog.dismiss(context);
      debugPrint("Error: $e");
    }
  }

  void _pickImageFromGallery() async {
    if (isImagePickerActive) return;
    isImagePickerActive = true;

    XFile? xfile = await imagePicker.pickImage(source: ImageSource.gallery);
    isImagePickerActive = false;
    if (isFlashOn == true){
          if (cameraController != null && cameraController!.value.isInitialized) {
            await cameraController!.setFlashMode(FlashMode.off);
          }
          setState(() => isFlashOn = false);
        }

    if (xfile != null) {
      _disposeCamera();

      // Ask the user what type of receipt it is
      String? endpoint = await ReceiptSelector.showReceiptTypeDialog(
        context, File(xfile.path));

      if (endpoint == null) {
        await _setupCameraController();
        return;
      }
      print("User selected endpoint: $endpoint");

      await _processImage(File(xfile.path), endpoint);
    }
  }

  Future<void> _processImage(File imageFile, String endpoint) async {
    setState(() => isUploading = true);
    _showLoadingPopup("Waiting for backend results...");
    if (isFlashOn == true){
          await cameraController!.setFlashMode(FlashMode.off);
          setState(() => isFlashOn = false);
        }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user logged in");

      final storeData = await fetchUserStore(uid);
      final storeName = storeData?['storeName']?.toString().toUpperCase() ?? "UNKNOWN STORE";
      print("Sending image with storeName: $storeName");

      final backendResult = await BackendService.sendImageToBackend(
        imageFile,
        endpoint,
        storeName,
      );

      setState(() => isUploading = false);

      final ok = await handlePredictionResponse(context, backendResult);
      LoadingDialog.dismiss(context);

      if (!ok) {
        await _setupCameraController();
        return;
      } else {
        if (isFlashOn == true){
          if (cameraController != null && cameraController!.value.isInitialized) {
            await cameraController!.setFlashMode(FlashMode.off);
          }setState(() => isFlashOn = false);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => RecognizerScreen(
              storeName: BackendService.parseStoreName(backendResult["store_name"]),
              total: BackendService.parseTotal(backendResult["total_numeric"]),
              cashFlow: BackendService.convertCashFlow(backendResult["cashflow"]),
              imagePath: imageFile.path,
              date: DateTime.now(),
            ),
          ),
        ).then((_) => _setupCameraController());
      }
    } catch (e) {
      setState(() => isUploading = false);
      LoadingDialog.dismiss(context);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Upload Failed:'),
            content: Text(
                'Failed to locate Store Name or Total.\nCapture image is unclear, please retake a clearer photo.\nThank you!'),
            actions: [
              TextButton(
                onPressed: () { 
                  Navigator.of(context).pop();
                  _setupCameraController();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showLoadingPopup(String message) {
    LoadingDialog.show(context, message);
  }
}
