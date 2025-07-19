import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'image_compression_service.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery with compression
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // เพิ่มคุณภาพเล็กน้อยเพราะจะบีบอัดอีกรอบ
      );

      if (image != null) {
        final file = File(image.path);

        // บีบอัดรูปให้เล็กกว่า 300KB
        print(
            'Debug: Original image size: ${ImageCompressionService.formatFileSize(file.lengthSync())}');
        final compressedFile =
            await ImageCompressionService.compressImage(file);

        if (compressedFile == null) {
          throw Exception('ไม่สามารถบีบอัดรูปภาพได้ กรุณาเลือกรูปใหม่');
        }

        final compressedSize = compressedFile.lengthSync();
        print(
            'Debug: Compressed image size: ${ImageCompressionService.formatFileSize(compressedSize)}');

        if (compressedSize > 300 * 1024) {
          // เช็คอีกครั้งว่าเล็กกว่า 300KB
          throw Exception(
              'รูปภาพยังใหญ่เกินไป (สูงสุด ${ImageCompressionService.maxFileSizeString})');
        }

        return compressedFile;
      }

      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick image from camera with compression
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // เพิ่มคุณภาพเล็กน้อยเพราะจะบีบอัดอีกรอบ
      );

      if (image != null) {
        final file = File(image.path);

        // บีบอัดรูปให้เล็กกว่า 300KB
        print(
            'Debug: Original camera image size: ${ImageCompressionService.formatFileSize(file.lengthSync())}');
        final compressedFile =
            await ImageCompressionService.compressImage(file);

        if (compressedFile == null) {
          throw Exception('ไม่สามารถบีบอัดรูปภาพได้ กรุณาถ่ายรูปใหม่');
        }

        final compressedSize = compressedFile.lengthSync();
        print(
            'Debug: Compressed camera image size: ${ImageCompressionService.formatFileSize(compressedSize)}');

        if (compressedSize > 300 * 1024) {
          // เช็คอีกครั้งว่าเล็กกว่า 300KB
          throw Exception(
              'รูปภาพยังใหญ่เกินไป (สูงสุด ${ImageCompressionService.maxFileSizeString})');
        }

        return compressedFile;
      }

      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Upload image to Firebase Storage
  static Future<String?> uploadImage(File imageFile, String eventId) async {
    try {
      // Create unique filename
      final String fileName =
          '${eventId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create reference to Firebase Storage
      final Reference ref =
          _storage.ref().child('event_images').child(fileName);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Show image picker dialog
  static Future<File?> showImagePickerDialog() async {
    // This would typically show a dialog in the UI
    // For now, we'll just return camera option
    return await pickImageFromCamera();
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final String path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif');
  }

  /// Get image file size in KB (updated for 300KB limit)
  static Future<double> getImageSizeInKB(File file) async {
    final int fileSizeInBytes = await file.length();
    return fileSizeInBytes / 1024;
  }

  /// Validate image file size (300KB limit)
  static bool isValidImageSize(File file) {
    return file.lengthSync() <= 300 * 1024; // 300KB
  }
}
