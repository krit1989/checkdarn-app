import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: const Text(
          'นโยบายความเป็นส่วนตัว',
          style: TextStyle(
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
                const Center(
                  child: Text(
                    '🔒 นโยบายความเป็นส่วนตัว CheckDarn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'NotoSansThai',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'มีผลตั้งแต่: 8 สิงหาคม 2568',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. ข้อมูลที่เราเก็บรวบรวม
                _buildSection(
                  title: '1. ข้อมูลที่เราเก็บรวบรวม',
                  content:
                      'เราเก็บรวบรวมข้อมูลเมื่อคุณใช้งานแอปพลิเคชัน CheckDarn ประกอบด้วย:\n\n'
                      '• ข้อมูลบัญชี: อีเมล ชื่อผู้ใช้ รูปโปรไฟล์\n'
                      '• ข้อมูลตำแหน่ง: GPS location เพื่อแสดงและรายงานเหตุการณ์\n'
                      '• ข้อมูลการใช้งาน: เวลาการเข้าใช้ ประเภทการรายงาน\n'
                      '• ข้อมูลอุปกรณ์: รุ่นมือถือ ระบบปฏิบัติการ',
                ),

                // 2. วัตถุประสงค์การใช้ข้อมูล
                _buildSection(
                  title: '2. วัตถุประสงค์การใช้ข้อมูล',
                  content: 'เราใช้ข้อมูลของคุณเพื่อ:\n\n'
                      '• ให้บริการรายงานและแจ้งเตือนเหตุการณ์\n'
                      '• แสดงเหตุการณ์บนแผนที่ตามตำแหน่งที่เหมาะสม\n'
                      '• ปรับปรุงและพัฒนาคุณภาพแอปพลิเคชัน\n'
                      '• ส่งการแจ้งเตือนที่จำเป็นและเกี่ยวข้อง\n'
                      '• รักษาความปลอดภัยและป้องกันการใช้งานที่ผิดต้อง',
                ),

                // 3. การแบ่งปันข้อมูล
                _buildSection(
                  title: '3. การแบ่งปันข้อมูล',
                  content:
                      'เราไม่ขายหรือให้เช่าข้อมูลส่วนบุคคลของคุณแก่บุคคลที่สาม\n\n'
                      'เราอาจแบ่งปันข้อมูลในกรณีต่อไปนี้:\n\n'
                      '• เมื่อได้รับความยินยอมจากคุณ\n'
                      '• เพื่อปฏิบัติตามกฎหมายหรือคำสั่งศาล\n'
                      '• เพื่อปกป้องสิทธิและความปลอดภัยของผู้ใช้\n'
                      '• ข้อมูลที่เปิดเผยต่อสาธารณะ (รายงานที่ผู้ใช้เลือกแชร์)',
                ),

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
                      const Text(
                        '🛡️ เราเคารพความเป็นส่วนตัวของคุณ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'NotoSansThai',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ข้อมูลของคุณได้รับการปกป้องด้วยมาตรฐานความปลอดภัยสูงสุด',
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
