import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/camera_report_model.dart';
import '../services/camera_report_service.dart';
import '../widgets/camera_report_form_widget.dart';
import '../widgets/camera_report_card_widget.dart';

class CameraReportScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialRoadName;

  const CameraReportScreen({
    super.key,
    this.initialLocation,
    this.initialRoadName,
  });

  @override
  State<CameraReportScreen> createState() => _CameraReportScreenState();
}

class _CameraReportScreenState extends State<CameraReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CameraReport> _pendingReports = [];
  List<String> _userVotedReports = [];
  Map<String, int> _userStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        CameraReportService.getPendingReports(
          userLat: widget.initialLocation?.latitude,
          userLng: widget.initialLocation?.longitude,
        ),
        CameraReportService.getUserVotedReports(),
        CameraReportService.getUserStats(),
      ]);

      setState(() {
        _pendingReports = futures[0] as List<CameraReport>;
        _userVotedReports = futures[1] as List<String>;
        _userStats = futures[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'รายงานกล้องจับความเร็ว',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1158F2),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'Kanit',
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.add_location), text: 'รายงานใหม่'),
            Tab(icon: Icon(Icons.how_to_vote), text: 'โหวต'),
            Tab(icon: Icon(Icons.bar_chart), text: 'สถิติ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportTab(),
          _buildVotingTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Information card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1158F2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1158F2).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF1158F2),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'วิธีการรายงาน',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1158F2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• รายงานกล้องใหม่ที่คุณพบเจอ\n'
                  '• รายงานกล้องที่ถูกถอดออก\n'
                  '• รายงานการเปลี่ยนจำกัดความเร็ว\n'
                  '• ข้อมูลจะถูกตรวจสอบโดยชุมชน',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Report form
          CameraReportFormWidget(
            initialLocation: widget.initialLocation,
            initialRoadName: widget.initialRoadName,
            onReportSubmitted: () {
              _loadData(); // Refresh data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ส่งรายงานเรียบร้อยแล้ว! รอการตรวจสอบจากชุมชน',
                    style: TextStyle(fontFamily: 'Kanit'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVotingTab() {
    if (_isLoading) {
      return const Center(
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
      );
    }

    if (_pendingReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่มีรายงานที่รอการโหวต',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ขอบคุณที่ช่วยตรวจสอบข้อมูล!',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReports.length,
        itemBuilder: (context, index) {
          final report = _pendingReports[index];
          final hasVoted = _userVotedReports.contains(report.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CameraReportCardWidget(
              report: report,
              hasVoted: hasVoted,
              onVoteSubmitted: (voteType) async {
                try {
                  await CameraReportService.submitVote(
                    reportId: report.id,
                    voteType: voteType,
                  );

                  setState(() {
                    _userVotedReports.add(report.id);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        voteType == VoteType.upvote
                            ? 'โหวต "มีจริง" เรียบร้อยแล้ว'
                            : 'โหวต "ไม่มี" เรียบร้อยแล้ว',
                        style: const TextStyle(fontFamily: 'Kanit'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data after a short delay
                  Future.delayed(const Duration(seconds: 1), _loadData);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User contribution stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1158F2),
                  const Color(0xFF1158F2).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1158F2).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'คะแนนการมีส่วนร่วม',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_userStats['total_contributions'] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'การมีส่วนร่วมทั้งหมด',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detailed stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.add_location,
                  title: 'รายงานส่ง',
                  value: '${_userStats['reports_submitted'] ?? 0}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.how_to_vote,
                  title: 'โหวตให้',
                  value: '${_userStats['votes_submitted'] ?? 0}',
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Community impact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: const Color(0xFF1158F2),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ผลกระทบต่อชุมชน',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'การมีส่วนร่วมของคุณช่วยให้:\n'
                  '• ข้อมูลกล้องจับความเร็วมีความแม่นยำ\n'
                  '• ชุมชนมีข้อมูลที่ทันสมัย\n'
                  '• การขับขี่ปลอดภัยยิ่งขึ้น',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Leaderboard teaser (future feature)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upcoming,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'กำลังจะมาเร็วๆ นี้',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const Text(
                        'อันดับผู้มีส่วนร่วม และรางวัลพิเศษ',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Kanit',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
