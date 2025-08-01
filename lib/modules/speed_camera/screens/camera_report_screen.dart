import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/auth_service.dart';
import '../../../services/smart_security_service.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  List<CameraReport> _pendingReports = [];
  List<String> _userVotedReports = [];
  Map<String, int> _userStats = {};
  bool _isLoading = true;
  bool _previousLoginState = false;

  // Key สำหรับ force rebuild FutureBuilder เมื่อลบรายงาน
  int _dataRefreshKey = 0;
  int _scaffoldRefreshKey = 0; // Key สำหรับ rebuild หน้าจอทั้งหมด

  // GlobalKey สำหรับ RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initializeSmartSecurity();
    _tabController = TabController(length: 3, vsync: this);
    _previousLoginState = AuthService.isLoggedIn;
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.high);
  }

  Future<bool> _validateCameraReportActionSimple({
    String? action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await SmartSecurityService.checkPageSecurity(
        'camera_report_page',
        context: {
          'action': action ?? 'generic',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...(context ?? {}),
        },
      );
      return result.isAllowed;
    } catch (e) {
      print('Smart Security validation failed: $e');
      return false;
    }
  }

  Future<void> _handleSecureRefresh() async {
    if (!await _validateCameraReportActionSimple(
      action: 'refresh_data',
      context: {
        'user_email': AuthService.currentUser?.email,
        'is_logged_in': AuthService.isLoggedIn,
      },
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _loadData(forceRefresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ตรวจสอบเมื่อกลับมาที่แอป
    if (state == AppLifecycleState.resumed) {
      // ตรวจสอบว่าสถานะล็อกอินเปลี่ยนแปลงหรือไม่
      final currentLoginState = AuthService.isLoggedIn;
      if (_previousLoginState != currentLoginState) {
        _previousLoginState = currentLoginState;
        _loadData(); // รีเฟรชข้อมูลเมื่อสถานะล็อกอินเปลี่ยน
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ตรวจสอบสถานะล็อกอินเมื่อกลับมาที่หน้านี้
    final currentLoginState = AuthService.isLoggedIn;
    if (_previousLoginState != currentLoginState) {
      _previousLoginState = currentLoginState;
      _loadData();
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // ตรวจสอบการล็อกอินก่อน
      if (!AuthService.isLoggedIn) {
        if (mounted) {
          setState(() {
            _pendingReports = [];
            _userVotedReports = [];
            _userStats = {};
            _isLoading = false;
          });
        }
        return;
      }

      print('🗺️ USER LOCATION DEBUG:');
      print('   Initial location: ${widget.initialLocation}');
      print('   Latitude: ${widget.initialLocation?.latitude}');
      print('   Longitude: ${widget.initialLocation?.longitude}');

      final futures = await Future.wait([
        CameraReportService.getPendingReports(
          userLat: widget.initialLocation?.latitude,
          userLng: widget.initialLocation?.longitude,
          radiusKm: 50.0, // เพิ่มจาก 10km เป็น 50km เพื่อให้ครอบคลุมมากขึ้น
          forceRefresh: forceRefresh, // ส่ง force refresh flag
        ),
        CameraReportService
            .getUserVotedReports(), // Force server check แล้วใน service
        CameraReportService.getUserStats(),
      ]);

      if (mounted) {
        setState(() {
          _pendingReports = futures[0] as List<CameraReport>;
          _userVotedReports = futures[1] as List<String>;
          _userStats = futures[2] as Map<String, int>;
          _isLoading = false;
        });

        // Debug log เพื่อดูจำนวนรายงาน
        print('📊 Loaded ${_pendingReports.length} pending reports');
        if (forceRefresh) {
          print(
              'DEBUG: After force refresh - pending reports: ${_pendingReports.length}');
          for (final report in _pendingReports.take(3)) {
            print('   Report: ${report.roadName} at ${report.reportedAt}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // แสดง error เฉพาะเมื่อผู้ใช้ล็อกอินแล้ว
        if (AuthService.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Force refresh ทุกอย่างหลังจากลบรายงาน
  Future<void> _forceRefreshAfterDelete() async {
    // ตรวจสอบว่า widget ยังอยู่หรือไม่
    if (!mounted) return;

    try {
      print('🔄 Starting force refresh after delete...');

      // บังคับรีเฟรช UI ทันที
      setState(() {
        _dataRefreshKey++;
        _scaffoldRefreshKey++;
      });

      // รอสัก 100ms ให้ UI update
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Clear local cache และโหลดข้อมูลใหม่จาก server
      _pendingReports.clear();
      await _loadData(forceRefresh: true);

      if (!mounted) return;

      // รีเฟรชครั้งสุดท้าย เพื่อให้แน่ใจ
      setState(() {
        _dataRefreshKey++;
        _scaffoldRefreshKey++;
      });

      print('✅ Force refresh completed');
    } catch (e) {
      print('❌ Error in _forceRefreshAfterDelete: $e');
    }
  }

  // Refresh หลังจากโพสรายงานใหม่
  Future<void> _refreshAfterSubmit() async {
    if (!mounted) return;

    try {
      print('🔄 === POST-SUBMISSION REFRESH PROCESS ===');
      print('🔄 Step 1: Waiting for server sync...');

      // รอให้ข้อมูลซิงค์กับ server
      await Future.delayed(const Duration(milliseconds: 1500));

      print('🔄 Step 2: Forcing UI rebuild...');
      // รีเฟรชข้อมูลทันที
      setState(() {
        _dataRefreshKey++;
        _scaffoldRefreshKey++;
      });

      print('🔄 Step 3: Force loading new data from server...');
      // โหลดข้อมูลใหม่พร้อม force refresh
      await _loadData(forceRefresh: true);

      print('🔄 Step 4: Checking pending reports count after refresh...');
      print('   _pendingReports.length: ${_pendingReports.length}');

      if (_pendingReports.isNotEmpty) {
        print('✅ Pending reports found after refresh:');
        for (int i = 0; i < _pendingReports.take(3).length; i++) {
          final report = _pendingReports[i];
          print('   ${i + 1}. ${report.roadName} - ${report.reportedAt}');
        }
      } else {
        print('❌ NO pending reports found after refresh!');
      }

      print('✅ Post-submission refresh completed');
    } catch (e) {
      print('❌ Error refreshing after submit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(_scaffoldRefreshKey), // Key สำหรับ force rebuild ทั้งหน้า
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'รายงานกล้องจับความเร็ว',
          style: TextStyle(
            fontFamily: 'NotoSansThai',
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
            fontFamily: 'NotoSansThai',
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
        key: ValueKey(
            _scaffoldRefreshKey), // Force rebuild TabBarView เมื่อ key เปลี่ยน
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
                        fontFamily: 'NotoSansThai',
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
                    fontFamily: 'NotoSansThai',
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
            onReportSubmitted: () async {
              // Smart Security validation for report submission
              if (!await _validateCameraReportActionSimple(
                action: 'submit_report',
                context: {
                  'user_email': AuthService.currentUser?.email,
                  'location': widget.initialLocation?.toString(),
                },
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _refreshAfterSubmit(); // ใช้ method แยกสำหรับ refresh หลังโพสใหม่

              // เปลี่ยนไปแท็บโหวตเพื่อให้เห็นโพสต์ใหม่
              _tabController.animateTo(1); // Index 1 = แท็บโหวต

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ส่งรายงานเรียบร้อยแล้ว! ตรวจสอบในแท็บโหวต',
                    style: TextStyle(fontFamily: 'NotoSansThai'),
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
    // ตรวจสอบการล็อกอินก่อน
    if (!AuthService.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'จำเป็นต้องล็อกอินเพื่อโหวต',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'แตะที่ปุ่มโปรไฟล์มุมขวาบนของแผนที่',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(fontFamily: 'NotoSansThai'),
            ),
          ],
        ),
      );
    }

    // DEBUG: ดูสถานะข้อมูลในหน้าโหวต
    print('🗳️ VOTING TAB DEBUG:');
    print('   _isLoading: $_isLoading');
    print('   _pendingReports.length: ${_pendingReports.length}');
    print('   _userVotedReports.length: ${_userVotedReports.length}');
    if (_pendingReports.isNotEmpty) {
      print('   Recent reports:');
      for (final report in _pendingReports.take(3)) {
        print('     - ${report.roadName} (${report.reportedAt})');
      }
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
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ขอบคุณที่ช่วยตรวจสอบข้อมูล!',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleSecureRefresh,
      child: ListView.builder(
        key: ValueKey(_dataRefreshKey), // บังคับ rebuild เมื่อลบรายงาน
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
                  // Smart Security validation for voting
                  if (!await _validateCameraReportActionSimple(
                    action: 'submit_vote',
                    context: {
                      'vote_type': voteType.toString(),
                      'report_id': report.id,
                      'user_email': AuthService.currentUser?.email,
                    },
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // ตรวจสอบการล็อกอินก่อนโหวต
                  if (!AuthService.isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณาล็อกอินผ่านหน้าแผนที่ก่อนโหวต',
                            style: TextStyle(fontFamily: 'NotoSansThai')),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // แสดง loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'กำลังโหวต...',
                            style: const TextStyle(fontFamily: 'NotoSansThai'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(
                          seconds: 5), // จะถูกแทนที่เมื่อโหวตเสร็จ
                    ),
                  );

                  await CameraReportService.submitVote(
                    reportId: report.id,
                    voteType: voteType,
                  );

                  // เฉพาะเมื่อโหวตสำเร็จถึงจะอัปเดต state และ refresh
                  setState(() {
                    _userVotedReports.add(report.id);
                  });

                  ScaffoldMessenger.of(context)
                      .clearSnackBars(); // ลบ loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        voteType == VoteType.upvote
                            ? 'โหวต "มีจริง" เรียบร้อยแล้ว'
                            : 'โหวต "ไม่มี" เรียบร้อยแล้ว',
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data เฉพาะเมื่อโหวตสำเร็จ
                  Future.delayed(const Duration(seconds: 1), _loadData);
                } catch (e) {
                  // ลบ loading indicator และแสดง error
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'เกิดข้อผิดพลาด: $e',
                        style: const TextStyle(fontFamily: 'NotoSansThai'),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(
                          seconds: 4), // แสดงนานขึ้นเพื่อให้ผู้ใช้อ่าน
                    ),
                  );

                  // ไม่ต้อง refresh data เมื่อเกิด error เพื่อป้องกันโพสต์หายไป
                  print(
                      '❌ Vote failed - not refreshing data to preserve posts');
                }
              },
              onReportDeleted: () async {
                // Smart Security validation for report deletion
                if (!await _validateCameraReportActionSimple(
                  action: 'delete_report',
                  context: {
                    'report_id': report.id,
                    'user_email': AuthService.currentUser?.email,
                  },
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('การตรวจสอบความปลอดภัยล้มเหลว'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // ลบ report ออกจาก local list ทันที
                setState(() {
                  _pendingReports.removeWhere((r) => r.id == report.id);
                });

                // รีเฟรชข้อมูลเมื่อลบรายงานสำเร็จ
                _forceRefreshAfterDelete();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    // ตรวจสอบการล็อกอินก่อน
    if (!AuthService.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'จำเป็นต้องล็อกอินเพื่อดูสถิติ',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'แตะที่ปุ่มโปรไฟล์มุมขวาบนของแผนที่',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

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
                    fontFamily: 'NotoSansThai',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_userStats['total_contributions'] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'การมีส่วนร่วมทั้งหมด',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
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
                        fontFamily: 'NotoSansThai',
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
                    fontFamily: 'NotoSansThai',
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
                          fontFamily: 'NotoSansThai',
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const Text(
                        'อันดับผู้มีส่วนร่วม และรางวัลพิเศษ',
                        style: TextStyle(
                          fontFamily: 'NotoSansThai',
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
              fontFamily: 'NotoSansThai',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
