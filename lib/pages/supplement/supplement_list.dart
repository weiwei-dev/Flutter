import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/procurement.dart';
import '../../utils/db.dart';
import '../../components/tab_bar.dart';
import '../settle/settle.dart';
import '../screenshot/screenshot.dart';

/// 补入采购列表页面
class SupplementListPage extends StatefulWidget {
  const SupplementListPage({super.key});

  @override
  State<SupplementListPage> createState() => _SupplementListPageState();
}

class _SupplementListPageState extends State<SupplementListPage> {
  List<ProcurementRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplementRecords();
  }

  /// 加载补单记录
  Future<void> _loadSupplementRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await DatabaseHelper.instance.getSupplementRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('加载失败: $e', context: context);
      }
    }
  }

  /// 获取日期字符串（yyyy-MM-dd）
  String _getDateString(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return dateTime.substring(0, 10);
    }
  }

  /// 格式化日期时间
  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  /// 跳转到清账页面
  void _navigateToSettle(String date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettlePage(initialDate: date)),
    );
  }

  /// 跳转到截图页面
  void _navigateToScreenshot(String date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenshotPage(initialDate: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(slivers: [_buildHeader(), _buildContent()]),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 4),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFAB47BC),
              const Color(0xFFAB47BC).withValues(alpha: 0.8),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          TDIcons.chevron_left,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '补入采购记录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 统计信息
                Row(
                  children: [
                    _buildStatCard(
                      '补单总数',
                      '${_records.length}',
                      TDIcons.file_1,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '总金额',
                      '¥${_records.fold<double>(0, (sum, r) => sum + r.totalAmount).toStringAsFixed(2)}',
                      TDIcons.money,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: TDCircleIndicator()),
      );
    }

    if (_records.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(TDIcons.file_1, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              TDText(
                '暂无补入采购记录',
                font: TDTheme.of(context).fontBodyLarge,
                textColor: Colors.grey.shade500,
              ),
              const SizedBox(height: 8),
              TDText(
                '在首页使用"补录采购"功能添加',
                font: Font(size: 12, lineHeight: 16),
                textColor: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildRecordCard(_records[index]),
          childCount: _records.length,
        ),
      ),
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(ProcurementRecord record) {
    final date = _getDateString(record.createTime);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '补单',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAB47BC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: record.settleStatus == 1
                        ? const Color(0xFF26A69A).withValues(alpha: 0.1)
                        : const Color(0xFFFFA726).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.settleStatus == 1 ? '已清账' : '未清账',
                    style: TextStyle(
                      fontSize: 11,
                      color: record.settleStatus == 1
                          ? const Color(0xFF26A69A)
                          : const Color(0xFFFFA726),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 详细信息
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '数量',
                    '${record.quantity}${record.unit}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '单价',
                    '¥${record.price.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '总价',
                    '¥${record.totalAmount.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 时间信息
            Row(
              children: [
                Icon(TDIcons.calendar, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '采购时间: ${_formatDateTime(record.createTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            if (record.orderTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(TDIcons.time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '补录时间: ${_formatDateTime(record.orderTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToSettle(date),
                    icon: const Icon(TDIcons.wallet, size: 16),
                    label: const Text('去清账'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA726),
                      side: const BorderSide(color: Color(0xFFFFA726)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToScreenshot(date),
                    icon: const Icon(TDIcons.camera, size: 16),
                    label: const Text('截图导出'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF42A5F5),
                      side: const BorderSide(color: Color(0xFF42A5F5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFFEF5350) : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
