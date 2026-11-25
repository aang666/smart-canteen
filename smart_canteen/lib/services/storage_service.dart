import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Kunci API ImgBB pribadi pengguna
  static const String defaultImgBBApiKey = 'd2daf8496c46e14dd0873634270e81ef';

  // Upload foto berbasis XFile (Mendukung Web, Android, iOS, Desktop)
  Future<String> uploadXFileToImgBB({
    required XFile file,
    String? customApiKey,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadBytesToImgBB(
      bytes: bytes,
      fileName: fileName,
      customApiKey: customApiKey,
    );
  }

  // Upload foto berbasis Uint8List (Universal multiplatform)
  Future<String> uploadBytesToImgBB({
    required Uint8List bytes,
    required String fileName,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : defaultImgBBApiKey;

    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      // Mengambil direct URL gambar hasil hosting ImgBB
      return data['url'] as String? ?? data['display_url'] as String;
    } else {
      throw Exception('Gagal mengunggah gambar ke ImgBB: ${response.statusCode} - ${response.body}');
    }
  }

  // Upload foto ke ImgBB berbasis File (Android/Desktop)
  Future<String> uploadToImgBB({
    required File imageFile,
    String? customApiKey,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    return uploadBytesToImgBB(
      bytes: bytes,
      fileName: fileName,
      customApiKey: customApiKey,
    );
  }
}
