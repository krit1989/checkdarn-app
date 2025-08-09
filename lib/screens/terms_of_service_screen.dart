import 'package:flutter/material.dart';
import '../generated/gen_l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0F7),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).termsOfServiceTitle,
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
                    AppLocalizations.of(context).termsOfServiceHeader,
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
                    AppLocalizations.of(context).lastUpdated,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'NotoSansThai',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. การยอมรับเงื่อนไข
                _buildSection(
                  title: AppLocalizations.of(context).acceptanceOfTermsTitle,
                  content:
                      AppLocalizations.of(context).acceptanceOfTermsContent,
                ),

                // 2. วัตถุประสงค์การใช้งาน
                _buildSection(
                  title: AppLocalizations.of(context).purposeOfUseTitle,
                  content: AppLocalizations.of(context).purposeOfUseContent,
                ),

                // 3. การใช้งานที่เหมาะสม
                _buildSection(
                  title: AppLocalizations.of(context).appropriateUseTitle,
                  content: AppLocalizations.of(context).appropriateUseContent,
                ),

                // 4. ความเป็นส่วนตัว
                _buildSection(
                  title: AppLocalizations.of(context).privacyTitle,
                  content: AppLocalizations.of(context).privacyContent,
                ),

                // 5. การรับผิดชอบ
                _buildSection(
                  title: AppLocalizations.of(context).responsibilityTitle,
                  content: AppLocalizations.of(context).responsibilityContent,
                ),

                // 6. การแก้ไขเงื่อนไข
                _buildSection(
                  title: AppLocalizations.of(context).modificationsTitle,
                  content: AppLocalizations.of(context).modificationsContent,
                ),

                // 7. การติดต่อ
                _buildSection(
                  title: AppLocalizations.of(context).contactTitle,
                  content: AppLocalizations.of(context).contactContent,
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
                      Text(
                        AppLocalizations.of(context).thankYouForUsing,
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
                        AppLocalizations.of(context).communityMessage,
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
