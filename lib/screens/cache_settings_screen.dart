import 'package:flutter/material.dart';
import '../services/map_cache_manager.dart';
import '../services/connection_manager.dart';

class CacheSettingsScreen extends StatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  State<CacheSettingsScreen> createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends State<CacheSettingsScreen> {
  Map<String, dynamic>? _cacheStats;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _isLoading = true);

    final stats = await MapCacheManager.getCacheStats();

    setState(() {
      _cacheStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _clearCache() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ล้างแผนที่ออฟไลน์',
          style: TextStyle(fontFamily: 'Kanit'),
        ),
        content: const Text(
          'ต้องการลบแผนที่ออฟไลน์ทั้งหมดใช่หรือไม่?\n'
          'หลังจากลบแล้ว แผนที่จะต้องโหลดจากอินเทอร์เน็ตใหม่',
          style: TextStyle(fontFamily: 'Kanit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontFamily: 'Kanit'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ลบ',
              style: TextStyle(fontFamily: 'Kanit', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);

      try {
        await MapCacheManager.clearCache();
        await _loadCacheStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ลบแผนที่ออฟไลน์เรียบร้อยแล้ว',
                style: TextStyle(fontFamily: 'Kanit'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: $e',
                style: const TextStyle(fontFamily: 'Kanit'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'จัดการแผนที่ออฟไลน์',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(fontFamily: 'Kanit'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status Card
                  _buildConnectionStatusCard(),
                  const SizedBox(height: 16),

                  // Cache Statistics Card
                  _buildCacheStatsCard(),
                  const SizedBox(height: 16),

                  // How it Works Card
                  _buildHowItWorksCard(),
                  const SizedBox(height: 16),

                  // Actions Card
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getConnectionIcon(),
                  color: _getConnectionColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'สถานะการเชื่อมต่อ',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getConnectionColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getConnectionColor().withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getConnectionIcon(),
                    color: _getConnectionColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ConnectionManager.getConnectionDescription(),
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 14,
                        color: _getConnectionColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Color(0xFF1158F2), size: 24),
                SizedBox(width: 12),
                Text(
                  'แผนที่ออฟไลน์ที่บันทึก',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cacheStats != null) ...[
              _buildStatRow(
                  'จำนวนชิ้นแผนที่', '${_cacheStats!['tileCount']} ชิ้น'),
              _buildStatRow('ขนาดที่ใช้', '${_cacheStats!['totalSizeMB']} MB'),
              _buildStatRow('ขนาดสูงสุด', '${_cacheStats!['maxSizeMB']} MB'),
              _buildStatRow('การใช้งาน', '${_cacheStats!['usagePercent']}%'),

              const SizedBox(height: 12),

              // Progress bar
              LinearProgressIndicator(
                value: double.parse(_cacheStats!['usagePercent']) / 100,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  double.parse(_cacheStats!['usagePercent']) > 80
                      ? Colors.red
                      : const Color(0xFF1158F2),
                ),
                minHeight: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Kanit',
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Kanit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1158F2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'ระบบแผนที่อัจฉริยะ',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHowItWorksStep(
              '1',
              'ออนไลน์ก่อน',
              'ใช้แผนที่ออนไลน์เมื่อมีอินเทอร์เน็ต',
              Colors.green,
            ),
            _buildHowItWorksStep(
              '2',
              'บันทึกอัตโนมัติ',
              'เก็บแผนที่ที่ใช้งานแล้วไว้ในเครื่อง',
              Colors.blue,
            ),
            _buildHowItWorksStep(
              '3',
              'ออฟไลน์สำรอง',
              'ใช้แผนที่ที่บันทึกเมื่อไม่มีสัญญาณ',
              Colors.orange,
            ),
            _buildHowItWorksStep(
              '4',
              'โหลดล่วงหน้า',
              'โหลดแผนที่รอบๆ ตำแหน่งปัจจุบัน',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(
      String number, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Kanit',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.grey, size: 24),
                SizedBox(width: 12),
                Text(
                  'การจัดการ',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Clear cache button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClearing ? null : _clearCache,
                icon: _isClearing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_sweep),
                label: Text(
                  _isClearing ? 'กำลังลบ...' : 'ลบแผนที่ออฟไลน์ทั้งหมด',
                  style: const TextStyle(fontFamily: 'Kanit'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'หมายเหตุ: การลบแผนที่ออฟไลน์จะช่วยเพิ่มพื้นที่ว่างในเครื่อง แต่แผนที่จะต้องโหลดจากอินเทอร์เน็ตใหม่',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConnectionColor() {
    final status = ConnectionManager.currentStatus;
    switch (status) {
      case ConnectionStatus.good:
        return Colors.green;
      case ConnectionStatus.mobile:
        return Colors.blue;
      case ConnectionStatus.poor:
        return Colors.orange;
      case ConnectionStatus.offline:
        return Colors.red;
      case ConnectionStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getConnectionIcon() {
    final status = ConnectionManager.currentStatus;
    switch (status) {
      case ConnectionStatus.good:
        return Icons.wifi;
      case ConnectionStatus.mobile:
        return Icons.signal_cellular_alt;
      case ConnectionStatus.poor:
        return Icons.signal_wifi_bad;
      case ConnectionStatus.offline:
        return Icons.wifi_off;
      case ConnectionStatus.unknown:
        return Icons.help_outline;
    }
  }
}
