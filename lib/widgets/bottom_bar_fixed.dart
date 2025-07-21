import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../screens/report_screen.dart';
import '../screens/list_screen.dart';

class BottomBar extends StatelessWidget {
  final List<EventCategory> selectedCategories;
  final VoidCallback onCategorySelectorTap;

  const BottomBar({
    super.key,
    required this.selectedCategories,
    required this.onCategorySelectorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 16, // เพิ่ม padding ด้านล่างเพื่อขยับเนื้อหาลง
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), // เพิ่มความโค้งจาก 0 เป็น 24
            topRight: Radius.circular(24), // เพิ่มความโค้งจาก 0 เป็น 24
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ปุ่มเลือกประเภท
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCategorySelectorTap,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                  highlightColor:
                      const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: Color(0xFF424743),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ประเภท (${selectedCategories.length})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424743),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ปุ่มแจ้งด่วน (ตรงกลาง)
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                  highlightColor:
                      const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'แจ้งด่วน',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424743),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ปุ่มรายการ
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                  highlightColor:
                      const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '📋',
                          style: TextStyle(
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'รายการ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424743),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
