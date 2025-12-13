import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class CloudinaryService {
  // Lấy từ environment variables
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  
  static CloudinaryPublic? _cloudinary;
  
  static CloudinaryPublic get cloudinary {
    if (_cloudinary == null) {
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception('Cloudinary credentials not found in .env file');
      }
      _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
    }
    return _cloudinary!;
  }
  
  static Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'chat_app',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}