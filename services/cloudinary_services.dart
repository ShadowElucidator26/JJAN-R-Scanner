import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class CloudinaryService {
  // --- CONFIG: update these with your values ---
  // Cloudinary unsigned upload. You must create an unsigned upload preset in Cloudinary.
  static const String cloudinaryCloudName = "dhrvvbrfy";
  static const String cloudinaryUploadPreset = "jjan_rscanner";

  // Backend endpoint that deletes an uploaded image by public_id.
  // You must implement a small server endpoint that calls Cloudinary's API server-side.
  // Example: POST https://yourserver.com/delete-cloudinary-image { "public_id": "<id>" }

  // ---- Cloudinary upload (unsigned) with per-user real folders ----
  static Future<Map<String, dynamic>> uploadImage(
    String localPath, {
    required String userId, // pass the current user's ID
  }) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload",
      );

      // Generate timestamp
      final now = DateTime.now();
      final timestamp = "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')}-"
          "${now.hour.toString().padLeft(2, '0')}-"
          "${now.minute.toString().padLeft(2, '0')}-"
          "${now.second.toString().padLeft(2, '0')}";

      // Generate short random ID
      final shortId = const Uuid().v4().substring(0, 6); // e.g., xyz123

      // --- Folder path ---
      final dateFolder = "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')}";
      final assetFolder = "users/$userId/receipts/$dateFolder";

      // --- Only filename as public_id ---
      final publicId = "receipt_${timestamp}_$shortId";

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..fields['asset_folder'] = assetFolder // 👈 real folder structure
        ..fields['public_id'] = publicId
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          localPath,
          filename: p.basename(localPath),
        ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonResp = jsonDecode(resp.body);
        return {
          "success": true,
          "public_id": jsonResp['public_id'], // includes folder path
          "secure_url": jsonResp['secure_url'],
          "raw": jsonResp,
        };
      } else {
        return {
          "success": false,
          "message": "Cloudinary upload failed: ${resp.statusCode} ${resp.body}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }  
}
class CloudinaryProfileService {
  // --- CONFIG: same as your main Cloudinary ---
  static const String cloudinaryCloudName = "dhrvvbrfy";
  static const String cloudinaryUploadPreset = "jjan_rscanner";

  // ---- Cloudinary upload specifically for User Profile Images ----
  static Future<Map<String, dynamic>> uploadUserProfile(
    String localPath, {
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload",
      );

      // Timestamp
      final now = DateTime.now();
      final timestamp = "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')}-"
          "${now.hour.toString().padLeft(2, '0')}-"
          "${now.minute.toString().padLeft(2, '0')}-"
          "${now.second.toString().padLeft(2, '0')}";

      // Short random ID
      final shortId = const Uuid().v4().substring(0, 6);

      // Folder path for profile images
      final assetFolder = "users/$userId/profile";

      // Public ID for profile image
      final publicId = "profile_${timestamp}_$shortId";

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..fields['asset_folder'] = assetFolder
        ..fields['public_id'] = publicId
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          localPath,
          filename: p.basename(localPath),
        ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonResp = jsonDecode(resp.body);
        return {
          "success": true,
          "public_id": jsonResp['public_id'],
          "secure_url": jsonResp['secure_url'],
          "raw": jsonResp,
        };
      } else {
        return {
          "success": false,
          "message": "Cloudinary upload failed: ${resp.statusCode} ${resp.body}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }
}
