import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/auth_service.dart';
import '../../../services/smart_security_service.dart';
import '../../../generated/gen_l10n/app_localizations.dart';
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

  // Settings for location filter
  bool _showAllNationwide = true; // เริ่มต้นแสดงทั่วประเทศ
  double _currentRadius = 1000.0; // รัศมีปัจจุบัน (km)

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

    // ทำความสะอาดข้อมูล verified เก่าเมื่อเปิดแอป
    _performInitialCleanup();

    // เรียก cleanup system เมื่อเปิดแอป
    CameraReportService.initializeCleanup();
  }

  /// ทำความสะอาดข้อมูล verified เก่าเมื่อเปิดแอปครั้งแรก
  /// ✅ ระบบ auto-removal ใหม่จะลบ verified reports อัตโนมัติใน submitVote แล้ว
  Future<void> _performInitialCleanup() async {
    print('ℹ️ Auto-removal system is now integrated into voting process');
    print('✅ Verified reports will be automatically removed after 3 votes');
  }

  Future<void> _initializeSmartSecurity() async {
    await SmartSecurityService.initialize();
    SmartSecurityService.setSecurityLevel(SecurityLevel.high);
  }

  /// Toggle between nationwide and nearby view
  void _toggleLocationView() {
    setState(() {
      _showAllNationwide = !_showAllNationwide;
      if (_showAllNationwide) {
        _currentRadius = 1000.0; // ทั่วประเทศ
        print('🌏 Switched to nationwide view');
      } else {
        _currentRadius = 50.0; // พื้นที่ใกล้เคียง
        print('📍 Switched to nearby view (${_currentRadius}km)');
      }

      // รีเฟรชข้อมูลด้วยการตั้งค่าใหม่
      _dataRefreshKey++;
      _loadData(forceRefresh: true);
    });
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
        SnackBar(
          content: Text(AppLocalizations.of(context).securityValidationFailed),
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

      // ระบบ auto-removal ใหม่จะจัดการใน submitVote แล้ว ไม่ต้อง cleanup ตรงนี้
      if (forceRefresh) {
        print(
            'ℹ️ Force refresh - auto-removal will handle verified reports in voting');
      }

      print('🗺️ USER LOCATION DEBUG:');
      print('   Initial location: ${widget.initialLocation}');
      print('   Latitude: ${widget.initialLocation?.latitude}');
      print('   Longitude: ${widget.initialLocation?.longitude}');

      final futures = await Future.wait([
        CameraReportService.getPendingReports(
          userLat: widget.initialLocation?.latitude,
          userLng: widget.initialLocation?.longitude,
          radiusKm: _currentRadius, // ใช้รัศมีที่ผู้ใช้เลือก
          limit: 50, // เพิ่มจำนวนโพสต์ที่แสดง
          forceRefresh: forceRefresh, // ส่ง force refresh flag
          showAllNationwide: _showAllNationwide, // ใช้การตั้งค่าจากผู้ใช้
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
              content: Text(
                  AppLocalizations.of(context).errorOccurred(e.toString())),
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

      // รอให้ข้อมูลซิงค์กับ server นานขึ้น
      await Future.delayed(const Duration(milliseconds: 2000));

      print('🔄 Step 2: Forcing UI rebuild...');
      // รีเฟรชข้อมูลทันที
      setState(() {
        _dataRefreshKey++;
        _scaffoldRefreshKey++;
      });

      print('🔄 Step 3: Force loading new data from server (1st attempt)...');
      // โหลดข้อมูลใหม่พร้อม force refresh
      await _loadData(forceRefresh: true);

      print('🔄 Step 4: Checking pending reports count after first refresh...');
      print('   _pendingReports.length: ${_pendingReports.length}');

      // ถ้ายังไม่เจอข้อมูลใหม่ ลองรีเฟรชอีกครั้ง
      if (_pendingReports.isEmpty) {
        print('🔄 Step 5: No data found, retrying after 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _dataRefreshKey++;
        });

        await _loadData(forceRefresh: true);
        print(
            '🔄 Step 6: After retry - _pendingReports.length: ${_pendingReports.length}');
      }

      if (_pendingReports.isNotEmpty) {
        print('✅ Pending reports found after refresh:');
        for (int i = 0; i < _pendingReports.take(3).length; i++) {
          final report = _pendingReports[i];
          print('   ${i + 1}. ${report.roadName} - ${report.reportedAt}');
        }
      } else {
        print('❌ NO pending reports found after refresh!');
        print('🔍 This might indicate a sync issue or filtering problem');
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
        title: Text(
          AppLocalizations.of(context).cameraReportTitle,
          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1158F2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ปุ่มสลับโหมดการแสดงผล
          IconButton(
            onPressed: _toggleLocationView,
            icon: Icon(
              _showAllNationwide ? Icons.location_on : Icons.near_me,
              color: Colors.white,
            ),
            tooltip: _showAllNationwide
                ? AppLocalizations.of(context).switchToNearbyView
                : AppLocalizations.of(context).switchToNationwideView,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
                icon: const Icon(Icons.add_location),
                text: AppLocalizations.of(context).newReportTab),
            Tab(
                icon: const Icon(Icons.how_to_vote),
                text: AppLocalizations.of(context).votingTab),
            Tab(
                icon: const Icon(Icons.bar_chart),
                text: AppLocalizations.of(context).statisticsTab),
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
                    Text(
                      AppLocalizations.of(context).howToReportTitle,
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1158F2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).howToReportDescription,
                  style: const TextStyle(
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
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context).securityCheckFailed),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _refreshAfterSubmit(); // ใช้ method แยกสำหรับ refresh หลังโพสใหม่

              // เปลี่ยนไปแท็บโหวตเพื่อให้เห็นโพสต์ใหม่
              _tabController.animateTo(1); // Index 1 = แท็บโหวต

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context).reportSubmissionSuccess,
                    style: const TextStyle(fontFamily: 'NotoSansThai'),
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
    // แสดงข้อมูลการแสดงผล
    return Column(
      children: [
        // Status bar แสดงโหมดการแสดงผล
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _showAllNationwide ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _showAllNationwide
                  ? Colors.blue.shade200
                  : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _showAllNationwide ? Icons.public : Icons.location_on,
                color: _showAllNationwide
                    ? Colors.blue.shade700
                    : Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showAllNationwide
                          ? AppLocalizations.of(context).showPostsFromNationwide
                          : AppLocalizations.of(context).showNearbyPosts,
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w600,
                        color: _showAllNationwide
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _showAllNationwide
                          ? AppLocalizations.of(context).radiusAllPosts(
                              _currentRadius.toInt(), _pendingReports.length)
                          : AppLocalizations.of(context).radiusNearbyPosts(
                              _currentRadius.toInt(), _pendingReports.length),
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 12,
                        color: _showAllNationwide
                            ? Colors.blue.shade600
                            : Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _toggleLocationView,
                icon: Icon(
                  _showAllNationwide ? Icons.near_me : Icons.public,
                  size: 16,
                  color: _showAllNationwide
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                ),
                label: Text(
                  _showAllNationwide
                      ? AppLocalizations.of(context).nearby
                      : AppLocalizations.of(context).nationwide,
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 12,
                    color: _showAllNationwide
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        // เนื้อหาหลักของแท็บโหวต
        Expanded(
          child: _buildVotingContent(),
        ),
      ],
    );
  }

  Widget _buildVotingContent() {
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
              AppLocalizations.of(context).loginRequiredToVote,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).pleaseLoginThroughMapProfile,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).tapProfileButtonOnMap,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadingData,
              style: const TextStyle(fontFamily: 'NotoSansThai'),
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
              AppLocalizations.of(context).noPendingReports,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).thankYouForVerifying,
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
                // ใช้ method แยกสำหรับจัดการ voting
                await _handleVote(report, voteType);
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
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context).securityCheckFailed),
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

  // Method แยกสำหรับจัดการ voting
  Future<void> _handleVote(CameraReport report, VoteType voteType) async {
    try {
      // Smart Security validation for voting
      if (!await _validateCameraReportActionSimple(
        action: 'submit_vote',
        context: {
          'user_email': AuthService.currentUser?.email,
          'report_id': report.id,
          'vote_type': voteType.toString(),
        },
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).securityCheckFailed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ตรวจสอบการล็อกอินก่อนโหวต
      if (!AuthService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseLoginBeforeVoting,
                style: const TextStyle(fontFamily: 'NotoSansThai')),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context).voting,
                style: const TextStyle(fontFamily: 'NotoSansThai'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5), // จะถูกแทนที่เมื่อโหวตเสร็จ
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

      ScaffoldMessenger.of(context).clearSnackBars(); // ลบ loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            voteType == VoteType.upvote
                ? AppLocalizations.of(context).voteExistsSuccess
                : AppLocalizations.of(context).voteNotExistsSuccess,
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

      String errorMessage =
          AppLocalizations.of(context).errorOccurred(e.toString());
      Color errorColor = Colors.red;
      bool shouldRetry = false;

      // จัดการ error แยกประเภทแบบละเอียด
      if (e.toString().contains('คุณได้โหวตรายงานนี้แล้ว') ||
          e.toString().contains('already voted')) {
        // ตรวจสอบว่าเป็น error หลังจากโหวตสำเร็จหรือเปล่า
        // ถ้า voted reports ยังไม่มี report นี้ แสดงว่าเพิ่งโหวตสำเร็จ
        if (!_userVotedReports.contains(report.id)) {
          errorMessage = AppLocalizations.of(context).alreadyVotedDetected;
          errorColor = Colors.green; // เปลี่ยนเป็นสีเขียวเพื่อบอกว่าสำเร็จ
          setState(() {
            _userVotedReports.add(report.id);
          });
          // Refresh data เพื่อดูผลการโหวต
          Future.delayed(
              const Duration(seconds: 1), () => _loadData(forceRefresh: true));
        } else {
          // ถ้า voted reports มี report นี้อยู่แล้ว แสดงว่าโหวตซ้ำจริงๆ
          errorMessage = AppLocalizations.of(context).alreadyVoted;
          errorColor = Colors.orange;
        }
      } else if (e.toString().contains('ไม่มีสิทธิ์') ||
          e.toString().contains('permission') ||
          e.toString().contains('unauthorized')) {
        errorMessage = AppLocalizations.of(context).noVotingPermission;
        errorColor = Colors.red;
        shouldRetry = true;
      } else if (e.toString().contains('ไม่พบรายงาน') ||
          e.toString().contains('not found') ||
          e.toString().contains('report not exist')) {
        errorMessage = AppLocalizations.of(context).reportNotFound;
        errorColor = Colors.red;
        // Refresh data เพื่อลบรายงานที่ไม่มีออกจากรายการ
        Future.delayed(
            const Duration(seconds: 1), () => _loadData(forceRefresh: true));
      } else if (e.toString().contains('ปัญหาการเชื่อมต่อ') ||
          e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage = AppLocalizations.of(context).connectionProblem;
        errorColor = Colors.amber;
        shouldRetry = true;
      } else {
        errorMessage = AppLocalizations.of(context).cannotVoteRetry;
        errorColor = Colors.red;
        shouldRetry = true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 5),
          action: shouldRetry
              ? SnackBarAction(
                  label: AppLocalizations.of(context).tryAgain,
                  textColor: Colors.white,
                  onPressed: () {
                    // Retry voting
                    _handleVote(report, voteType);
                  },
                )
              : null,
        ),
      );

      // ไม่ต้อง refresh data เมื่อเกิด error เพื่อป้องกันโพสต์หายไป
      print('❌ Vote failed - not refreshing data to preserve posts: $e');
    }
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
              AppLocalizations.of(context).loginRequiredToViewStats,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).pleaseLoginThroughMapProfile,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).tapProfileButtonOnMap,
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
                Text(
                  AppLocalizations.of(context).engagementScore,
                  style: const TextStyle(
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
                Text(
                  AppLocalizations.of(context).totalEngagement,
                  style: const TextStyle(
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
                  title: AppLocalizations.of(context).reportsSubmitted,
                  value: '${_userStats['reports_submitted'] ?? 0}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.how_to_vote,
                  title: AppLocalizations.of(context).voteFor,
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
                    Text(
                      AppLocalizations.of(context).communityImpact,
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).communityImpactDescription,
                  style: const TextStyle(
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
                        AppLocalizations.of(context).comingSoon,
                        style: TextStyle(
                          fontFamily: 'NotoSansThai',
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).leaderboardAndRewards,
                        style: const TextStyle(
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
