import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileStorageService {
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
  
  static Future<String?> uploadFile(File file, String fileType) async {
    try {
      CloudinaryResourceType resourceType;
      
      // Xác định resource type dựa vào file type
      if (fileType == 'pdf' || fileType == 'docx' || fileType == 'txt') {
        resourceType = CloudinaryResourceType.Raw;
      } else {
        resourceType = CloudinaryResourceType.Auto;
      }
      
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'chat_app',
          resourceType: resourceType,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading file to Cloudinary: $e');
      return null;
    }
  }
}