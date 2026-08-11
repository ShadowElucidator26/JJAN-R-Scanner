import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class BackendService {
  //static const String _baseUrl = "http://10.0.2.2:8000";
  //static const String _baseUrl = "http://192.168.228.36:7860";
  static const String _baseUrl = "https://shadow314-jjan-r-scanner-backend.hf.space";
  //static const String _baseUrl = "http://192.168.135.36:8000";
  
  /// Send image to backend and return parsed JSON response
  static Future<Map<String, dynamic>> sendImageToBackend(
    File imageFile, String endpoint, String storename) async {
  var uri = Uri.parse("$_baseUrl/$endpoint/"); // dynamic endpoint
  var request = http.MultipartRequest('POST', uri);

  print(" uri is : $uri");

  request.files.add(await http.MultipartFile.fromPath(
    'file',
    imageFile.path,
    filename: p.basename(imageFile.path),
  ));

  // Add storeName as a form field
  request.fields['storeName'] = storename;

  var streamedResponse = await request.send();

  if (streamedResponse.statusCode == 200) {
    var responseData = await streamedResponse.stream.bytesToString();
    var data = jsonDecode(responseData);
    return Map<String, dynamic>.from(data);
  } else {
    var body = await streamedResponse.stream.bytesToString();
    throw Exception("Upload failed with status: ${streamedResponse.statusCode}. Body: $body");
  }
}


  /// Convert backend cashflow value to UI string
  static String convertCashFlow(dynamic cashflow) {
    return cashflow == 1 ? "INCOME" : "EXPENSE";
  }

  /// Parse total value from backend response
  static double parseTotal(dynamic totalNumeric) {
    return double.tryParse(totalNumeric?.toString() ?? "0") ?? 0.0;
  }

  /// Parse store name from backend response
  static String parseStoreName(dynamic storeName) {
    return storeName?.toString() ?? "Unknown Store";
  }

}
