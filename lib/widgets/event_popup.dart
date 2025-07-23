import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../utils/formatters.dart';
import '../utils/category_helpers.dart' as cat_helpers;
import '../utils/image_helpers.dart' as img_helpers;

class EventPopup extends StatelessWidget {
  final Map<String, dynamic> data;
  final EventCategory category;

  const EventPopup({
    super.key,
    required this.data,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ??
        (data['description']?.toString().isNotEmpty == true
            ? data['description'].toString().length > 30
                ? '${data['description'].toString().substring(0, 30)}...'
                : data['description'].toString()
            : 'ไม่มีหัวข้อ');
    final description = data['description'] ?? 'ไม่มีรายละเอียด';
    final timestamp = DateTimeFormatters.parseTimestamp(data['timestamp']);
    final imageUrl = data['imageUrl'] as String?;
    final location = data['location'] ??
        '${data['district'] ?? ''}, ${data['province'] ?? ''}'
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '') ??
        'ไม่ระบุตำแหน่ง';
    final lat = data['lat'] as double?;
    final lng = data['lng'] as double?;
    final categoryKey = category.toString().split('.').last;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(title, categoryKey, context),
            _buildContent(imageUrl, description, location, timestamp,
                categoryKey, lat, lng),
            _buildActionButtons(categoryKey, context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String categoryKey, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cat_helpers.CategoryHelpers.getCategoryColor(categoryKey),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              cat_helpers.CategoryHelpers.getCategoryIcon(categoryKey),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.2,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    cat_helpers.CategoryHelpers.getCategoryName(categoryKey),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String? imageUrl, String description, String location,
      DateTime? timestamp, String categoryKey, double? lat, double? lng) {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return img_helpers.ImageHelpers
                          .buildImageLoadingIndicator(
                        context,
                        loadingProgress,
                        cat_helpers.CategoryHelpers.getCategoryColor(
                            categoryKey),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return img_helpers.ImageHelpers.buildImageErrorWidget(
                          context);
                    },
                  ),
                ),
              ),
            Text(
              'รายละเอียด: $description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (location.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'สถานที่: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            // แถวที่ 4: พิกัด GPS
            if (lat != null && lng != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'พิกัด: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyCoordinates(lat, lng),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          DateTimeFormatters.formatTimeAgo(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      DateTimeFormatters.formatDateTime(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String categoryKey, BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 300;

            if (isNarrow) {
              return Column(
                children: [
                  _buildCloseButton(context),
                  const SizedBox(height: 8),
                  _buildDetailsButton(categoryKey, context),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildCloseButton(context)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDetailsButton(categoryKey, context)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('ปิด', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildDetailsButton(String categoryKey, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('หน้ารายละเอียดถูกลบออกแล้ว')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              cat_helpers.CategoryHelpers.getCategoryColor(categoryKey),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('ดูรายละเอียด', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  // ฟังก์ชันคัดลอกพิกัด
  void _copyCoordinates(double lat, double lng) {
    final coordinates = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coordinates));

    // แสดงข้อความแจ้งเตือนว่าคัดลอกแล้ว
    // Note: ต้องใช้ context ที่ถูกต้อง ให้แก้ไขตรงนี้ในการใช้งานจริง
  }
}
