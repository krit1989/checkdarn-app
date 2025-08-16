import 'package:flutter/material.dart';
import '../services/budget_monitoring_service.dart';

/// Widget สำหรับแสดง Budget Alert และสถิติการใช้งาน
class BudgetAlertWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const BudgetAlertWidget({
    super.key,
    this.showDetails = true,
    this.onTap,
  });

  @override
  State<BudgetAlertWidget> createState() => _BudgetAlertWidgetState();
}

class _BudgetAlertWidgetState extends State<BudgetAlertWidget> {
  Map<String, dynamic>? _budgetStatus;
  Map<String, dynamic>? _storageStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      setState(() => _isLoading = true);

      final budgetStatus =
          await BudgetMonitoringService.getCurrentBudgetStatus();
      final storageStats = await BudgetMonitoringService.getStorageStatistics();

      setState(() {
        _budgetStatus = budgetStatus;
        _storageStats = storageStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading budget data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'กำลังตรวจสอบ Budget...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_budgetStatus == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap ?? () => _showBudgetDetails(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getBudgetGradient(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBudgetHeader(),
                if (widget.showDetails) ...[
                  const SizedBox(height: 12),
                  _buildBudgetDetails(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetHeader() {
    final status = _budgetStatus!['status'] ?? 'normal';
    final usagePercent = _budgetStatus!['usage_percent'] ?? 0.0;
    final costAmount = _budgetStatus!['cost_amount'] ?? 0.0;
    final message = _budgetStatus!['message'] ?? '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getBudgetIcon(status),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase Budget',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${costAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${usagePercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetDetails() {
    final currentSizeGB = _storageStats?['current_size_gb'] ?? 0.0;
    final currentImages = _storageStats?['current_images'] ?? 0;
    final dailyGrowthMB = _storageStats?['daily_average_mb'] ?? 0.0;
    final trend = _storageStats?['trend'] ?? 'stable';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'ขนาดรวม',
                '${currentSizeGB.toStringAsFixed(1)} GB',
                Icons.storage,
              ),
              _buildStatItem(
                'รูปภาพ',
                '$currentImages รูป',
                Icons.photo_library,
              ),
              _buildStatItem(
                'เติบโต/วัน',
                '${dailyGrowthMB.toStringAsFixed(0)} MB',
                _getTrendIcon(trend),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  LinearGradient _getBudgetGradient() {
    final status = _budgetStatus!['status'] ?? 'normal';

    switch (status) {
      case 'emergency':
        return const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'critical':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'warning':
        return const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getBudgetIcon(String status) {
    switch (status) {
      case 'emergency':
        return Icons.error;
      case 'critical':
        return Icons.warning;
      case 'warning':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increasing_fast':
        return Icons.trending_up;
      case 'increasing':
        return Icons.arrow_upward;
      case 'decreasing':
        return Icons.arrow_downward;
      default:
        return Icons.trending_flat;
    }
  }

  void _showBudgetDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: BudgetDetailsScreen(
                    budgetStatus: _budgetStatus!,
                    storageStats: _storageStats!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// หน้าจอแสดงรายละเอียด Budget
class BudgetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> budgetStatus;
  final Map<String, dynamic> storageStats;

  const BudgetDetailsScreen({
    super.key,
    required this.budgetStatus,
    required this.storageStats,
  });

  @override
  State<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  Map<String, dynamic>? _monthlyEstimate;
  List<String>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    try {
      final monthlyEstimate =
          await BudgetMonitoringService.estimateMonthlyBudget();
      final recommendations =
          await BudgetMonitoringService.getCostSavingRecommendations();

      setState(() {
        _monthlyEstimate = monthlyEstimate;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading additional data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รายละเอียด Budget Firebase',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),

        // Current Status
        _buildCurrentStatusCard(),
        const SizedBox(height: 16),

        // Storage Statistics
        _buildStorageStatsCard(),
        const SizedBox(height: 16),

        // Monthly Estimate
        if (!_isLoading && _monthlyEstimate != null) ...[
          _buildMonthlyEstimateCard(),
          const SizedBox(height: 16),
        ],

        // Recommendations
        if (!_isLoading && _recommendations != null) ...[
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
        ],

        // Actions
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildCurrentStatusCard() {
    final costAmount = widget.budgetStatus['cost_amount'] ?? 0.0;
    final budgetAmount = widget.budgetStatus['budget_amount'] ?? 25.0;
    final usagePercent = widget.budgetStatus['usage_percent'] ?? 0.0;
    final alertLevel = widget.budgetStatus['alert_level'] ?? 'info';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถานะปัจจุบัน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: usagePercent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(alertLevel),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ใช้ไป: \$${costAmount.toStringAsFixed(2)}'),
                Text('งบประมาณ: \$${budgetAmount.toStringAsFixed(2)}'),
              ],
            ),
            Text(
              '${usagePercent.toStringAsFixed(1)}% ของงบประมาณ',
              style: TextStyle(
                color: _getProgressColor(alertLevel),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStatsCard() {
    final currentSizeGB = widget.storageStats['current_size_gb'] ?? 0.0;
    final currentImages = widget.storageStats['current_images'] ?? 0;
    final dailyGrowthMB = widget.storageStats['daily_average_mb'] ?? 0.0;
    final costEstimate = widget.storageStats['cost_estimate_usd'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติ Storage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'ขนาดรวม',
                    '${currentSizeGB.toStringAsFixed(2)} GB',
                    Icons.storage,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'รูปภาพ',
                    '$currentImages รูป',
                    Icons.photo_library,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'เติบโต/วัน',
                    '${dailyGrowthMB.toStringAsFixed(1)} MB',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'ต้นทุนประมาณ',
                    '\$${costEstimate.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.red,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyEstimateCard() {
    final totalCost = _monthlyEstimate!['total_estimated_cost_usd'] ?? 0.0;
    final projectedSizeGB = _monthlyEstimate!['projected_size_gb'] ?? 0.0;
    final isWithinBudget = _monthlyEstimate!['is_within_budget'] ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ประมาณการรายเดือน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isWithinBudget ? Icons.check_circle : Icons.warning,
                  color: isWithinBudget ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isWithinBudget ? 'อยู่ในงบประมาณ' : 'อาจเกินงบประมาณ',
                  style: TextStyle(
                    color: isWithinBudget ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ประมาณการต้นทุน: \$${totalCost.toStringAsFixed(2)}/เดือน'),
            Text('ขนาดคาดการณ์: ${projectedSizeGB.toStringAsFixed(1)} GB'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แนะนำการประหยัดต้นทุน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._recommendations!.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                )),
          ],
        ),
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
            Text(
              'การดำเนินการ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // เปิด Firebase Console
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('เปิด Firebase Console'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // รีเฟรชข้อมูล
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('รีเฟรชข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(String alertLevel) {
    switch (alertLevel) {
      case 'emergency':
        return Colors.red;
      case 'critical':
        return Colors.orange;
      case 'warning':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }
}
