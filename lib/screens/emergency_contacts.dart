import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/gen_l10n/app_localizations.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  List<Map<String, String>> _getEmergencyContacts(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {'name': l10n.police, 'number': '191'},
      {'name': l10n.traffic, 'number': '1197'},
      {'name': l10n.highway, 'number': '1586'},
      {'name': l10n.ruralRoad, 'number': '1146'},
      {'name': l10n.fireDepartment, 'number': '199'},
      {'name': l10n.emergencyMedical, 'number': '1669'},
      {'name': l10n.erawanCenter, 'number': '1646'},
      {'name': l10n.disasterAlert, 'number': '192'},
      {'name': l10n.bombThreatTerrorism, 'number': '191'},
      {'name': l10n.diseaseControl, 'number': '1422'},
      {'name': l10n.disasterPrevention, 'number': '1784'},
      {'name': l10n.ruamkatanyu, 'number': '0-2494-3000'},
      {'name': l10n.pohtecktung, 'number': '0-2225-0020'},
      {'name': l10n.cyberCrimeHotline, 'number': '1441'},
      {'name': l10n.consumerProtection, 'number': '1166'},
      {'name': l10n.js100, 'number': '1137'},
      {'name': l10n.touristPolice, 'number': '1155'},
      {'name': l10n.tourismAuthority, 'number': '1672'},
      {'name': l10n.harborDepartment, 'number': '1199'},
      {'name': l10n.waterAccident, 'number': '1199'},
      {'name': l10n.expressway, 'number': '1543'},
      {'name': l10n.transportCooperative, 'number': '1348'},
      {'name': l10n.busVan, 'number': '1584'},
      {'name': l10n.taxiGrab, 'number': '1584'},
      {'name': l10n.meaElectricity, 'number': '1130'},
      {'name': l10n.peaElectricity, 'number': '1129'},
    ];
  }

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
              AppLocalizations.of(context).cannotCallPhone(phoneNumber),
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyContacts = _getEmergencyContacts(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).emergencyNumbers,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'NotoSansThai',
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
      body: SafeArea(
        bottom: true, // ให้ SafeArea จัดการ bottom padding อัตโนมัติ
        child: ListView.builder(
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
                          fontFamily: 'NotoSansThai',
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
                        fontFamily: 'NotoSansThai',
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
        ), // ปิด ListView.builder
      ), // ปิด SafeArea
    ); // ปิด Scaffold
  }
}
