import 'package:flutter/material.dart';
import '../generated/gen_l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).privacyPolicyTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'NotoSansThai',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDC621),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    AppLocalizations.of(context).privacyPolicyHeader,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'NotoSansThai',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppLocalizations.of(context).effectiveFrom,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. ข้อมูลที่เราเก็บรวบรวม
                const SizedBox(height: 16),
                // 1. การเก็บรวบรวมข้อมูล
                _buildSection(
                  title: AppLocalizations.of(context).dataCollectionTitle,
                  content: AppLocalizations.of(context).dataCollectionContent,
                ),
                // 2. การใช้งานข้อมูล
                _buildSection(
                  title: AppLocalizations.of(context).dataUsageTitle,
                  content: AppLocalizations.of(context).dataUsageContent,
                ),
                // 3. การแบ่งปันข้อมูล
                _buildSection(
                  title: AppLocalizations.of(context).dataSharingTitle,
                  content: AppLocalizations.of(context).dataSharingContent,
                ),
                // 4. ความปลอดภัยของข้อมูล
                _buildSection(
                  title: AppLocalizations.of(context).dataSecurityTitle,
                  content: AppLocalizations.of(context).dataSecurityContent,
                ),
                // 5. สิทธิของผู้ใช้
                _buildSection(
                  title: AppLocalizations.of(context).userRightsTitle,
                  content: AppLocalizations.of(context).userRightsContent,
                ),
                // 6. คุกกี้และการติดตาม
                _buildSection(
                  title: AppLocalizations.of(context).cookiesTitle,
                  content: AppLocalizations.of(context).cookiesContent,
                ),
                // 7. การเปลี่ยนแปลงนโยบาย
                _buildSection(
                  title: AppLocalizations.of(context).policyChangesTitle,
                  content: AppLocalizations.of(context).policyChangesContent,
                ),
                // 8. ติดต่อเรา
                _buildSection(
                  title: AppLocalizations.of(context).contactTitle,
                  content: AppLocalizations.of(context).contactContent,
                ), // 2. วัตถุประสงค์การใช้ข้อมูล
                _buildSection(
                  title: '2. วัตถุประสงค์การใช้ข้อมูล',
                  content: 'เราใช้ข้อมูลของคุณเพื่อ:\n\n'
                      '• ให้บริการรายงานและแจ้งเตือนเหตุการณ์\n'
                      '• แสดงเหตุการณ์บนแผนที่ตามตำแหน่งที่เหมาะสม\n'
                      '• ปรับปรุงและพัฒนาคุณภาพแอปพลิเคชัน\n'
                      '• ส่งการแจ้งเตือนที่จำเป็นและเกี่ยวข้อง\n'
                      '• รักษาความปลอดภัยและป้องกันการใช้งานที่ผิดต้อง',
                ),

                const SizedBox(height: 20),
                // Shield Icon and Footer

                // 4. ความปลอดภัยของข้อมูล
                _buildSection(
                  title: '4. ความปลอดภัยของข้อมูล',
                  content: 'เราให้ความสำคัญกับการปกป้องข้อมูลของคุณ:\n\n'
                      '• ใช้การเข้ารหัสข้อมูลขณะส่งและจัดเก็บ\n'
                      '• มีระบบยืนยันตัวตนที่ปลอดภัย\n'
                      '• จำกัดการเข้าถึงข้อมูลเฉพาะบุคลากรที่จำเป็น\n'
                      '• ตรวจสอบและอัพเดตระบบความปลอดภัยอย่างสม่ำเสมอ',
                ),

                // 5. สิทธิของผู้ใช้
                _buildSection(
                  title: '5. สิทธิของผู้ใช้',
                  content: 'คุณมีสิทธิต่อข้อมูลส่วนบุคคลของคุณ:\n\n'
                      '• สิทธิเข้าถึง: ขอดูข้อมูลที่เราเก็บรวบรวม\n'
                      '• สิทธิแก้ไข: ขอแก้ไขข้อมูลที่ไม่ถูกต้อง\n'
                      '• สิทธิลบ: ขอลบข้อมูลส่วนบุคคล\n'
                      '• สิทธิถอนความยินยอม: ยกเลิกการใช้บริการได้ตลอดเวลา\n'
                      '• สิทธิร้องเรียน: แจ้งปัญหาเกี่ยวกับการใช้ข้อมูล',
                ),

                // 6. Cookies และเทคโนโลยีติดตาม
                _buildSection(
                  title: '6. Cookies และเทคโนโลยีติดตาม',
                  content: 'แอปพลิเคชันอาจใช้เทคโนโลยีเหล่านี้:\n\n'
                      '• Local Storage: เก็บการตั้งค่าและข้อมูลชั่วคราว\n'
                      '• Analytics: วิเคราะห์การใช้งานเพื่อปรับปรุงแอป\n'
                      '• Push Notifications: ส่งการแจ้งเตือนที่จำเป็น\n'
                      '• Firebase Services: บริการคลาวด์สำหรับจัดเก็บข้อมูล',
                ),

                // 7. การเปลี่ยนแปลงนโยบาย
                _buildSection(
                  title: '7. การเปลี่ยนแปลงนโยบาย',
                  content:
                      'เราอาจปรับปรุงนโยบายความเป็นส่วนตัวเป็นครั้งคราว\n\n'
                      '• จะแจ้งให้ทราบล่วงหน้าหากมีการเปลี่ยนแปลงสำคัญ\n'
                      '• การใช้งานต่อไปถือว่ายอมรับนโยบายใหม่\n'
                      '• ควรตรวจสอบนโยบายอัพเดตอย่างสม่ำเสมอ',
                ),

                // 8. การติดต่อ
                _buildSection(
                  title: '8. การติดต่อ',
                  content: 'หากมีคำถามเกี่ยวกับนโยบายความเป็นส่วนตัว:\n\n'
                      '• ติดต่อผ่านแอปพลิเคชัน\n'
                      '• ส่งอีเมลไปยังทีมสนับสนุน\n'
                      '• ใช้ฟีเจอร์ "ติดต่อเรา" ในหน้าการตั้งค่า',
                  isLast: true,
                ),

                const SizedBox(height: 32),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.privacy_tip,
                        color: Color(0xFF4CAF50),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).respectPrivacy,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'NotoSansThai',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).securityMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'NotoSansThai',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
            fontFamily: 'NotoSansThai',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
            fontFamily: 'NotoSansThai',
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 20),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
