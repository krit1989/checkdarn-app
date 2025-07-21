import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  static const List<Map<String, String>> emergencyContacts = [
    {'name': 'ตำรวจ', 'number': '191'},
    {'name': 'จราจร', 'number': '1197'},
    {'name': 'กรมทางหลวง', 'number': '1586'},
    {'name': 'ทางหลวงชนบท', 'number': '1146'},
    {'name': 'ดับเพลิง', 'number': '199'},
    {'name': 'หน่วยแพทย์ฉุกเฉิน (EMS)', 'number': '1669'},
    {'name': 'ศูนย์เอราวัณ (กทม.)', 'number': '1646'},
    {'name': 'เตือนภัยพิบัติ', 'number': '192'},
    {'name': 'วางเพลิง / ก่อการร้าย', 'number': '191'},
    {'name': 'ศูนย์ควบคุมโรค', 'number': '1422'},
    {'name': 'ป้องกันและบรรเทาสาธารณภัย (ปภ.)', 'number': '1784'},
    {'name': 'มูลนิธิร่วมกตัญญู', 'number': '0-2494-3000'},
    {'name': 'มูลนิธิป่อเต็กตึ๊ง', 'number': '0-2225-0020'},
    {'name': 'สายด่วนไซเบอร์', 'number': '1441'},
    {'name': 'สำนักงานคุ้มครองผู้บริโภค (สคบ.)', 'number': '1166'},
    {'name': 'จส.100', 'number': '1137'},
    {'name': 'ตำรวจท่องเที่ยว', 'number': '1155'},
    {'name': 'การท่องเที่ยวแห่งประเทศไทย (ททท.)', 'number': '1672'},
    {'name': 'กรมเจ้าท่า', 'number': '1199'},
    {'name': 'อุบัติเหตุทางน้ำ', 'number': '1199'},
    {'name': 'การทางพิเศษแห่งประเทศไทย (ทางด่วน)', 'number': '1543'},
    {'name': 'ขสมก.', 'number': '1348'},
    {'name': 'รถโดยสาร / รถตู้', 'number': '1584'},
    {'name': 'แท็กซี่ / Grab', 'number': '1584'},
    {'name': 'การไฟฟ้านครหลวง (MEA)', 'number': '1130'},
    {'name': 'การไฟฟ้าส่วนภูมิภาค (PEA)', 'number': '1129'},
  ];

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    // ทำความสะอาดเบอร์โทร - เอาเครื่องหมายขีดและช่องว่างออก
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      // ใช้ launchUrl โดยตรงโดยไม่ต้องตรวจสอบ canLaunchUrl ก่อน
      await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication, // บังคับให้เปิดแอปภายนอก
      );
    } catch (e) {
      print('Error making phone call: $e');
      // แสดงข้อความเตือนในกรณีเกิดข้อผิดพลาด
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ไม่สามารถโทรหาเบอร์ $phoneNumber ได้\nกรุณาตรวจสอบว่าอุปกรณ์รองรับการโทรออก'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เบอร์ฉุกเฉิน',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFDC621),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF0F3F8),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = emergencyContacts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  // ชื่อหน่วยงาน
                  Expanded(
                    child: Text(
                      contact['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // เบอร์โทร
                  Text(
                    contact['number']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่มโทร
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4673E5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4673E5).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 18,
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          _makePhoneCall(contact['number']!, context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
