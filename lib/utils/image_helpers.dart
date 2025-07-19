import 'package:flutter/material.dart';

class ImageHelpers {
  static Widget buildImageLoadingIndicator(
    BuildContext context,
    ImageChunkEvent loadingProgress,
    Color? color,
  ) {
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  static Widget buildImageErrorWidget(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'ไม่สามารถโหลดรูปภาพได้',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
