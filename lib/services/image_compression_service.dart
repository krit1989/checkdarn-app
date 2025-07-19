import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  static const int _maxFileSize = 300 * 1024; // 300KB ในหน่วย bytes
  static const int _defaultQuality = 70; // คุณภาพ 70%
  static const int _maxWidth = 1080; // ความกว้างสูงสุด 1080px
  static const int _maxHeight = 1080; // ความสูงสูงสุด 1080px

  /// บีบอัดรูปภาพให้เล็กกว่า 300KB
  static Future<File?> compressImage(File imageFile) async {
    try {
      print('Debug: Starting image compression...');
      print('Debug: Original file size: ${imageFile.lengthSync()} bytes');

      // ตรวจสอบขนาดไฟล์เดิม
      final originalSize = imageFile.lengthSync();
      if (originalSize <= _maxFileSize) {
        print('Debug: Image already under size limit, no compression needed');
        return imageFile;
      }

      // หาไดเรกทอรีชั่วคราว
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // เริ่มต้นด้วยคุณภาพ 70%
      int quality = _defaultQuality;
      File? compressedFile;

      // ลองบีบอัดหลายรอบจนกว่าจะได้ขนาดที่ต้องการ
      for (int attempt = 0; attempt < 5; attempt++) {
        print(
            'Debug: Compression attempt ${attempt + 1} with quality $quality%');

        final result = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: quality,
          minWidth: _maxWidth,
          minHeight: _maxHeight,
          format: CompressFormat.jpeg,
        );

        if (result != null) {
          compressedFile = File(result.path);
          final compressedSize = compressedFile.lengthSync();

          print('Debug: Compressed file size: $compressedSize bytes');

          if (compressedSize <= _maxFileSize) {
            print(
                'Debug: Image compression successful! Size: ${compressedSize / 1024} KB');
            return compressedFile;
          }

          // ถ้ายังใหญ่เกินไป ลดคุณภาพลง
          quality = (quality * 0.8).round();
          if (quality < 20) quality = 20; // คุณภาพต่ำสุด 20%
        }
      }

      // ถ้าบีบอัดไม่สำเร็จ หรือยังใหญ่เกินไป
      if (compressedFile != null) {
        final finalSize = compressedFile.lengthSync();
        print(
            'Warning: Could not compress below ${_maxFileSize / 1024}KB. Final size: ${finalSize / 1024}KB');
        return compressedFile;
      }

      print('Error: Image compression failed completely');
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// ตรวจสอบขนาดไฟล์
  static bool isFileSizeValid(File file) {
    return file.lengthSync() <= _maxFileSize;
  }

  /// แปลงขนาดไฟล์เป็น KB สำหรับแสดงผล
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// ได้ขนาดไฟล์สูงสุดที่อนุญาต (สำหรับแสดงข้อความ)
  static String get maxFileSizeString => formatFileSize(_maxFileSize);
}
