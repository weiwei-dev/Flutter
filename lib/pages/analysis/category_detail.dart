import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../models/procurement.dart';
import '../../services/db_service.dart';
import '../record_detail/record_detail.dart';

/// 品类详情页 - 显示指定品类的所有采购记录
class CategoryDetailPage extends StatelessWidget {
  final String category;
  final String startDate;
  final String endDate;

  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryDetailController(
        category: category,
        startDate: startDate,
        endDate: endDate,
      ),
      child: const _CategoryDetailView(),
    );
  }
}

class _CategoryDetailView extends StatelessWidget {
  const _CategoryDetailView();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CategoryDetailController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, controller),
          if (controller.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.groupedRecords.isEmpty)
            const SliverFillRemaining(child: _EmptyView())
          else
            _buildRecordList(context, controller),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CategoryDetailController controller,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TDTheme.of(context).brandNormalColor,
              TDTheme.of(context).brandNormalColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 统计卡片
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '采购笔数',
                        '${controller.totalCount}笔',
                        TDIcons.file_copy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        '采购总额',
                        '¥${controller.totalAmount.toStringAsFixed(2)}',
                        TDIcons.money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.startDate} 至 ${controller.endDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(
    BuildContext context,
    CategoryDetailController controller,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  TDIcons.history,
                  size: 18,
                  color: TDTheme.of(context).brandNormalColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '采购明细',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 按日期分组的记录列表
            ...controller.groupedRecords.entries.map((entry) {
              return _buildDateGroup(context, entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    String date,
    List<ProcurementRecord> records,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TDTheme.of(
                context,
              ).brandNormalColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.mediumRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      TDIcons.calendar,
                      size: 14,
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${records.length}笔',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 记录列表
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;
            return _buildRecordItem(context, record, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context,
    ProcurementRecord record,
    bool isLast,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordDetailPage(recordId: record.id!),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${record.quantity}${record.unit} × ¥${record.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppConstants.fontMedium,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: record.settleStatus == 1
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.settleStatus == 1 ? '已清账' : '待清账',
                          style: TextStyle(
                            fontSize: 10,
                            color: record.settleStatus == 1
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (record.grade != null && record.grade!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '规格: ${record.grade}',
                      style: TextStyle(
                        fontSize: AppConstants.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (record.supplierLocation != null &&
                      record.supplierLocation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '供应商: ${record.supplierLocation}',
                      style: TextStyle(
                        fontSize: AppConstants.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '时间: ${record.createTime.substring(11, 16)}',
                    style: TextStyle(
                      fontSize: AppConstants.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${record.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TDTheme.of(null).brandNormalColor,
                  ),
                ),
                if (record.serviceFee > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '含服务费¥${record.serviceFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TDIcons.file_copy, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            '暂无采购记录',
            style: TextStyle(
              fontSize: AppConstants.fontMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 品类详情控制器
class CategoryDetailController extends ChangeNotifier {
  final String category;
  final String startDate;
  final String endDate;

  List<ProcurementRecord> _records = [];
  bool _isLoading = true;

  List<ProcurementRecord> get records => _records;
  bool get isLoading => _isLoading;

  int get totalCount => _records.length;
  double get totalAmount => _records.fold(0.0, (sum, r) => sum + r.totalAmount);

  /// 按日期分组的记录
  Map<String, List<ProcurementRecord>> get groupedRecords {
    final Map<String, List<ProcurementRecord>> groups = {};
    for (var record in _records) {
      final date = record.createTime.substring(0, 10); // yyyy-MM-dd
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(record);
    }
    // 按日期降序排列
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var key in sortedKeys) key: groups[key]!};
  }

  CategoryDetailController({
    required this.category,
    required this.startDate,
    required this.endDate,
  }) {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final startStr = '$startDate 00:00:00';
      final endStr = '$endDate 23:59:59';

      final allRecords = await DbService.instance.getRecordsByDateRange(
        startStr,
        endStr,
      );
      _records = allRecords.where((r) => r.category == category).toList();

      // 按时间降序排列
      _records.sort((a, b) => b.createTime.compareTo(a.createTime));
    } catch (e) {
      debugPrint('Error loading category detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
