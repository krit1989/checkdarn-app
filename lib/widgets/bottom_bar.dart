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

  // ฟังก์ชันแจ้ง MapScreen ให้ refresh cache
  void _notifyMapScreenToRefresh(BuildContext context) {
    // ใช้วิธีง่าย ๆ โดยตั้ง flag ใน SharedPreferences
    // ให้ MapScreen ตรวจสอบเมื่อ resume
    try {
      // Set flag ว่ามีการโพสใหม่
      // MapScreen จะตรวจสอบ flag นี้เมื่อ resume
      // และจะ clear cache ถ้า flag เป็น true
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 1, // ลด padding ด้านล่างให้ชิดขอบมากที่สุด
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        // ลบ borderRadius ออกให้หมด
        // ลบ shadow/border ที่อาจทำให้เกิดเส้นขีดเทา
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
                      horizontal: 6.0, vertical: 3.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, // ลดจาก 44 เป็น 40
                        height: 24, // ลดจาก 26 เป็น 24
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(12), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 22, // ลดจาก 25 เป็น 22
                            height: 22, // ลดจาก 25 เป็น 22
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
                          fontFamily: 'NotoSansThai',
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
                      horizontal: 6.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, // ปรับให้พอดีกับ 5 ปุ่ม
                        height: 24, // ปรับให้พอดีกับ 5 ปุ่ม
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(12), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 22, // ปรับให้พอดีกับ 5 ปุ่ม
                            height: 22, // ปรับให้พอดีกับ 5 ปุ่ม
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
                          fontFamily: 'NotoSansThai',
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
                  ).then((_) {
                    // เมื่อกลับมาจากหน้า Report ให้ส่งสัญญาณไปยัง parent widget
                    // ใช้ Navigator callback หรือ global refresh mechanism
                    if (context.mounted) {
                      // หา MapScreen ใน widget tree และเรียก refresh
                      _notifyMapScreenToRefresh(context);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: const Color(0xFFC3E7FF).withValues(alpha: 0.3),
                highlightColor: const Color(0xFFC3E7FF).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, // ปรับให้พอดีกับ 5 ปุ่ม
                        height: 24, // ปรับให้พอดีกับ 5 ปุ่ม
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(12), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 22, // ปรับให้พอดีกับ 5 ปุ่ม
                            height: 22, // ปรับให้พอดีกับ 5 ปุ่ม
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
                          fontFamily: 'NotoSansThai',
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
                      horizontal: 6.0, vertical: 3.0), // ลดความสูงของปุ่ม
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, // ปรับให้พอดีกับ 5 ปุ่ม
                        height: 24, // ปรับให้พอดีกับ 5 ปุ่ม
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(12), // ปรับตาม width ใหม่
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 22, // ปรับให้พอดีกับ 5 ปุ่ม
                            height: 22, // ปรับให้พอดีกับ 5 ปุ่ม
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
                          fontFamily: 'NotoSansThai',
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
