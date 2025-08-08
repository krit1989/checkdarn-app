import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: const Text(
          'เงื่อนไขการใช้งาน',
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
                    '📋 เงื่อนไขการใช้งาน CheckDarn',
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
                    'อัปเดตล่าสุด: 8 สิงหาคม 2568',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. การยอมรับเงื่อนไข
                _buildSection(
                  title: '1. การยอมรับเงื่อนไข',
                  content:
                      'การใช้งานแอปพลิเคชัน CheckDarn ถือว่าท่านยอมรับและตกลงที่จะปฏิบัติตามเงื่อนไขการใช้งานทั้งหมด หากท่านไม่ยอมรับเงื่อนไขเหล่านี้ กรุณาหยุดใช้งานแอปพลิเคชันทันที',
                ),

                // 2. วัตถุประสงค์การใช้งาน
                _buildSection(
                  title: '2. วัตถุประสงค์การใช้งาน',
                  content:
                      'CheckDarn เป็นแอปพลิเคชันสำหรับรายงานและแจ้งเตือนเหตุการณ์ต่างๆ ในพื้นที่ เช่น การจราจร อุบัติเหตุ หรือเหตุการณ์สำคัญอื่นๆ เพื่อช่วยให้ชุมชนได้รับข้อมูลข่าวสารที่เป็นประโยชน์',
                ),

                // 3. การใช้งานที่เหมาะสม
                _buildSection(
                  title: '3. การใช้งานที่เหมาะสม',
                  content:
                      'ผู้ใช้ต้องใช้งานแอปพลิเคชันด้วยความรับผิดชอบ ไม่โพสต์ข้อมูลที่เป็นเท็จ หยาบคาย หรือผิดกฎหมาย ข้อมูลที่รายงานควรเป็นข้อเท็จจริงและเป็นประโยชน์ต่อส่วนรวม',
                ),

                // 4. ความเป็นส่วนตัว
                _buildSection(
                  title: '4. ความเป็นส่วนตัว',
                  content:
                      'เราให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้ ข้อมูลส่วนบุคคลจะถูกเก็บรักษาอย่างปลอดภัยและใช้เฉพาะเพื่อการพัฒนาและปรับปรุงบริการเท่านั้น',
                ),

                // 5. การรับผิดชอบ
                _buildSection(
                  title: '5. การรับผิดชอบ',
                  content:
                      'ผู้พัฒนาแอปพลิเคชันไม่รับผิดชอบต่อความเสียหายใดๆ ที่เกิดจากการใช้งานแอปพลิเคชัน ผู้ใช้ต้องใช้วิจารณญาณในการตัดสินใจจากข้อมูลที่ได้รับ',
                ),

                // 6. การแก้ไขเงื่อนไข
                _buildSection(
                  title: '6. การแก้ไขเงื่อนไข',
                  content:
                      'เราสงวนสิทธิ์ในการแก้ไขเงื่อนไขการใช้งานได้ตลอดเวลา การแก้ไขจะมีผลทันทีหลังจากประกาศในแอปพลิเคชัน',
                ),

                // 7. การติดต่อ
                _buildSection(
                  title: '7. การติดต่อ',
                  content:
                      'หากมีข้อสงสัยหรือต้องการติดต่อเกี่ยวกับเงื่อนไขการใช้งาน สามารถติดต่อผ่านทางแอปพลิเคชันหรือช่องทางที่กำหนด',
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
                        Icons.verified_user,
                        color: Color(0xFF4CAF50),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '✅ ขอบคุณที่ใช้งาน CheckDarn',
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
                        'ร่วมสร้างชุมชนที่ปลอดภัยและมีข้อมูลข่าวสารที่ดี',
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
