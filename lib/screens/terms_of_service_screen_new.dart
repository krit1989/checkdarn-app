import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../generated/gen_l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isEnglish = languageProvider.isEnglishSelected;

        return Scaffold(
          backgroundColor: const Color(0xFFEDF0F7),
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).termsOfService,
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
                        isEnglish
                            ? '📋 CheckDarn Terms of Service'
                            : '📋 เงื่อนไขการใช้งาน CheckDarn',
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
                        isEnglish
                            ? 'Last updated: August 8, 2025'
                            : 'อัปเดตล่าสุด: 8 สิงหาคม 2568',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'NotoSansThai',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content sections
                    if (isEnglish)
                      ..._buildEnglishContent()
                    else
                      ..._buildThaiContent(),

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
                          Text(
                            isEnglish
                                ? '✅ Thank you for using CheckDarn'
                                : '✅ ขอบคุณที่ใช้งาน CheckDarn',
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
                            isEnglish
                                ? 'Together building a safe community with good information'
                                : 'ร่วมสร้างชุมชนที่ปลอดภัยและมีข้อมูลข่าวสารที่ดี',
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
      },
    );
  }

  List<Widget> _buildEnglishContent() {
    return [
      _buildSection(
        title: '1. Acceptance of Terms',
        content:
            'By using the CheckDarn application, you agree to comply with all these terms of use. If you do not accept these terms, please stop using the application immediately.',
      ),
      _buildSection(
        title: '2. Purpose of Use',
        content:
            'CheckDarn is an application for reporting and alerting various events in the area, such as traffic, accidents, or other important events to help the community receive useful information.',
      ),
      _buildSection(
        title: '3. Appropriate Use',
        content:
            'Users must use the application responsibly, not post false, offensive, or illegal information. Reported information should be factual and beneficial to the public.',
      ),
      _buildSection(
        title: '4. Privacy',
        content:
            'We value user privacy. Personal information will be kept secure and used only for service development and improvement.',
      ),
      _buildSection(
        title: '5. Responsibility',
        content:
            'The application developers are not responsible for any damages arising from the use of the application. Users must use their judgment when making decisions based on the information received.',
      ),
      _buildSection(
        title: '6. Terms Modification',
        content:
            'We reserve the right to modify the terms of use at any time. Modifications will take effect immediately after being announced in the application.',
      ),
      _buildSection(
        title: '7. Contact',
        content:
            'If you have any questions or need to contact regarding the terms of use, you can contact through the application or designated channels.',
        isLast: true,
      ),
    ];
  }

  List<Widget> _buildThaiContent() {
    return [
      _buildSection(
        title: '1. การยอมรับเงื่อนไข',
        content:
            'การใช้งานแอปพลิเคชัน CheckDarn ถือว่าท่านยอมรับและตกลงที่จะปฏิบัติตามเงื่อนไขการใช้งานทั้งหมด หากท่านไม่ยอมรับเงื่อนไขเหล่านี้ กรุณาหยุดใช้งานแอปพลิเคชันทันที',
      ),
      _buildSection(
        title: '2. วัตถุประสงค์การใช้งาน',
        content:
            'CheckDarn เป็นแอปพลิเคชันสำหรับรายงานและแจ้งเตือนเหตุการณ์ต่างๆ ในพื้นที่ เช่น การจราจร อุบัติเหตุ หรือเหตุการณ์สำคัญอื่นๆ เพื่อช่วยให้ชุมชนได้รับข้อมูลข่าวสารที่เป็นประโยชน์',
      ),
      _buildSection(
        title: '3. การใช้งานที่เหมาะสม',
        content:
            'ผู้ใช้ต้องใช้งานแอปพลิเคชันด้วยความรับผิดชอบ ไม่โพสต์ข้อมูลที่เป็นเท็จ หยาบคาย หรือผิดกฎหมาย ข้อมูลที่รายงานควรเป็นข้อเท็จจริงและเป็นประโยชน์ต่อส่วนรวม',
      ),
      _buildSection(
        title: '4. ความเป็นส่วนตัว',
        content:
            'เราให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้ ข้อมูลส่วนบุคคลจะถูกเก็บรักษาอย่างปลอดภัยและใช้เฉพาะเพื่อการพัฒนาและปรับปรุงบริการเท่านั้น',
      ),
      _buildSection(
        title: '5. การรับผิดชอบ',
        content:
            'ผู้พัฒนาแอปพลิเคชันไม่รับผิดชอบต่อความเสียหายใดๆ ที่เกิดจากการใช้งานแอปพลิเคชัน ผู้ใช้ต้องใช้วิจารณญาณในการตัดสินใจจากข้อมูลที่ได้รับ',
      ),
      _buildSection(
        title: '6. การแก้ไขเงื่อนไข',
        content:
            'เราสงวนสิทธิ์ในการแก้ไขเงื่อนไขการใช้งานได้ตลอดเวลา การแก้ไขจะมีผลทันทีหลังจากประกาศในแอปพลิเคชัน',
      ),
      _buildSection(
        title: '7. การติดต่อ',
        content:
            'หากมีข้อสงสัยหรือต้องการติดต่อเกี่ยวกับเงื่อนไขการใช้งาน สามารถติดต่อผ่านทางแอปพลิเคชันหรือช่องทางที่กำหนด',
        isLast: true,
      ),
    ];
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
