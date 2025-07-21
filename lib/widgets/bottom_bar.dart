import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/event_model.dart';
import '../screens/report_screen.dart';
import '../screens/list_screen.dart';
import '../screens/emergency_contacts.dart';

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
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 1, // ลด padding ด้านล่างให้ชิดขอบมากที่สุด
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), // ลดความโค้งจาก 12 เป็น 6
          topRight: Radius.circular(6), // ลดความโค้งจาก 12 เป็น 6
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ปุ่มเบอร์ฉุกเฉิน (ซ้ายสุด)
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                highlightColor: const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44, // เพิ่มจาก 38 เป็น 44 (+15%)
                        height: 26, // เพิ่มจาก 23 เป็น 26 (+15%)
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(13), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            height: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            child: SvgPicture.asset(
                              'assets/icons/bottom_bar/sos.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ฉุกเฉิน',
                        style: TextStyle(
                          fontSize: 10.5, // เพิ่มจาก 10 เป็น 10.5 (+5%)
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

          // ปุ่มเลือกประเภท
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCategorySelectorTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                highlightColor: const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44, // เพิ่มจาก 38 เป็น 44 (+15%)
                        height: 26, // เพิ่มจาก 23 เป็น 26 (+15%)
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(13), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            height: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            child: SvgPicture.asset(
                              'assets/icons/bottom_bar/sort.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ประเภท',
                        style: TextStyle(
                          fontSize: 10.5, // เพิ่มจาก 10 เป็น 10.5 (+5%)
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
                highlightColor: const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44, // เพิ่มจาก 38 เป็น 44 (+15%)
                        height: 26, // เพิ่มจาก 23 เป็น 26 (+15%)
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(13), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            height: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            child: SvgPicture.asset(
                              'assets/icons/bottom_bar/siren.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'แจ้งอะไร?',
                        style: TextStyle(
                          fontSize: 10.5, // เพิ่มจาก 10 เป็น 10.5 (+5%)
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
                highlightColor: const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44, // เพิ่มจาก 38 เป็น 44 (+15%)
                        height: 26, // เพิ่มจาก 23 เป็น 26 (+15%)
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(13), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            height: 25, // เพิ่มจาก 22 เป็น 25 (+15%)
                            child: SvgPicture.asset(
                              'assets/icons/bottom_bar/near_me.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ใกล้ฉัน',
                        style: TextStyle(
                          fontSize: 10.5, // เพิ่มจาก 10 เป็น 10.5 (+5%)
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
    );
  }
}
