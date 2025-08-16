import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// หน้า Admin Dashboard สำหรับดู Traffic Log Statistics
/// ตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26
class TrafficLogAdminScreen extends StatefulWidget {
  const TrafficLogAdminScreen({super.key});

  @override
  State<TrafficLogAdminScreen> createState() => _TrafficLogAdminScreenState();
}

class _TrafficLogAdminScreenState extends State<TrafficLogAdminScreen> {
  Map<String, dynamic>? _statsData;
  bool _isLoading = false;
  String? _errorMessage;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTrafficStats();
  }

  /// โหลดสถิติ Traffic Logs จาก Cloud Function
  Future<void> _loadTrafficStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('getTrafficLogsStats');

      final result = await callable.call({
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
      });

      setState(() {
        _statsData = Map<String, dynamic>.from(result.data);
        _isLoading = false;
      });

      if (kDebugMode) {
        print('✅ Traffic stats loaded successfully');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading traffic stats: ${e.toString()}';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('❌ Error loading traffic stats: $e');
      }
    }
  }

  /// เลือกช่วงวันที่
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTrafficStats();
    }
  }

  /// Request Export (สำหรับกรณีที่หน่วยงานราชการร้องขอ)
  Future<void> _requestExport() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Traffic Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุเหตุผลในการขอ export ข้อมูล:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'เช่น คำร้องขอจากศาล, คำสั่งจากหน่วยงานราชการ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final callable =
            FirebaseFunctions.instanceFor(region: 'asia-southeast1')
                .httpsCallable('exportTrafficLogs');

        final result = await callable.call({
          'startDate': _startDate.toIso8601String(),
          'endDate': _endDate.toIso8601String(),
          'requestReason': reason,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Export request submitted: ${result.data['message']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Traffic Logs Admin',
          style: TextStyle(fontFamily: 'NotoSansThai'),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrafficStats,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _requestExport,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังโหลดสถิติ...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrafficStats,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    if (_statsData == null) {
      return const Center(child: Text('ไม่มีข้อมูล'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceInfo(),
          const SizedBox(height: 24),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildOverviewStats(),
          const SizedBox(height: 24),
          _buildActionBreakdown(),
          const SizedBox(height: 24),
          _buildPlatformBreakdown(),
          const SizedBox(height: 24),
          _buildDailyChart(),
        ],
      ),
    );
  }

  Widget _buildComplianceInfo() {
    final compliance = _statsData!['compliance_info'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'ข้อมูลการปฏิบัติตามกฎหมาย',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (compliance != null) ...[
              _buildInfoRow('กฎหมายที่ปฏิบัติตาม:', compliance['law'] ?? 'N/A'),
              _buildInfoRow('ระยะเวลาเก็บข้อมูล:',
                  '${compliance['retention_period_days']} วัน'),
              _buildInfoRow('การปกป้องข้อมูลส่วนตัว:',
                  compliance['data_anonymization'] ?? 'N/A'),
              _buildInfoRow(
                  'การปกป้องตำแหน่ง:', compliance['location_privacy'] ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ช่วงเวลาที่ดูข้อมูล',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ตั้งแต่: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ถึง: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectDateRange,
                  child: const Text('เปลี่ยน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถิติรวม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'จำนวน Events ทั้งหมด',
                    _statsData!['total_events']?.toString() ?? '0',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'ผู้ใช้ที่ไม่ซ้ำ',
                    _statsData!['unique_users']?.toString() ?? '0',
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'NotoSansThai',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBreakdown() {
    final actionBreakdown =
        _statsData!['action_breakdown'] as Map<String, dynamic>?;

    if (actionBreakdown == null || actionBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กิจกรรมแยกตามประเภท',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 16),
            ...actionBreakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getActionDisplayName(entry.key),
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformBreakdown() {
    final platformBreakdown =
        _statsData!['platform_breakdown'] as Map<String, dynamic>?;

    if (platformBreakdown == null || platformBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แยกตาม Platform',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 16),
            ...platformBreakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            entry.key == 'android'
                                ? Icons.android
                                : entry.key == 'ios'
                                    ? Icons.phone_iphone
                                    : Icons.help,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(fontFamily: 'NotoSansThai'),
                          ),
                        ],
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    final dailyBreakdown =
        _statsData!['daily_breakdown'] as Map<String, dynamic>?;

    if (dailyBreakdown == null || dailyBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    // Simple daily breakdown list (could be enhanced with charts later)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กิจกรรมรายวัน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansThai',
              ),
            ),
            const SizedBox(height: 16),
            ...dailyBreakdown.entries.take(7).map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'NotoSansThai',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'NotoSansThai'),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionDisplayName(String action) {
    const actionNames = {
      'user_login': 'เข้าสู่ระบบ',
      'user_logout': 'ออกจากระบบ',
      'post_camera_report': 'โพสรายงานกล้อง',
      'view_reports': 'ดูรายงาน',
      'update_location': 'อัปเดตตำแหน่ง',
      'search_reports': 'ค้นหารายงาน',
      'vote_report': 'โหวตรายงาน',
      'comment_report': 'แสดงความคิดเห็น',
      'delete_report': 'ลบรายงาน',
      'app_start': 'เปิดแอป',
      'app_resume': 'กลับเข้าแอป',
    };

    return actionNames[action] ?? action;
  }
}
