import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../components/tab_bar.dart';
import '../../core/constants/app_constants.dart';
import 'category_analysis_page.dart';
import 'controller/analysis_controller.dart';
import 'group_analysis_page.dart';
import 'widgets/analysis_widgets.dart';
import 'widgets/charts.dart';

/// 采购数据分析主页
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalysisController(),
      child: const _AnalysisView(),
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<AnalysisController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildHeader(context, controller),
              if (controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.records.isEmpty)
                const SliverFillRemaining(
                  child: EmptyDataView(message: '该时间段暂无采购数据'),
                )
              else ...[
                _buildOverviewStats(context, controller),
                _buildTrendChart(context, controller),
                _buildCostStructure(context, controller),
                _buildTopRanking(context, controller),
                _buildQuickAccess(context, controller),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context, AnalysisController controller) {
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
                    const Text(
                      '数据分析',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 日期选择
                Row(
                  children: [
                    Expanded(
                      child: DateRangeButton(
                        label: '开始',
                        dateStr: controller.startDateStr,
                        onTap: () => _showDatePicker(context, controller, true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('至', style: TextStyle(color: Colors.white70)),
                    ),
                    Expanded(
                      child: DateRangeButton(
                        label: '结束',
                        dateStr: controller.endDateStr,
                        onTap: () =>
                            _showDatePicker(context, controller, false),
                      ),
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

  Widget _buildOverviewStats(
    BuildContext context,
    AnalysisController controller,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '概览统计', icon: TDIcons.chart),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  title: '采购总额',
                  value: '¥${controller.totalAmount.toStringAsFixed(0)}',
                  icon: TDIcons.money,
                  color: const Color(0xFF42A5F5),
                ),
                StatCard(
                  title: '采购笔数',
                  value: '${controller.totalCount}笔',
                  icon: TDIcons.file_copy,
                  color: const Color(0xFF66BB6A),
                ),
                StatCard(
                  title: '平均单价',
                  value: '¥${controller.averageAmount.toStringAsFixed(2)}',
                  icon: TDIcons.calculation,
                  color: const Color(0xFFFFA726),
                ),
                StatCard(
                  title: '最高金额',
                  value: '¥${controller.maxAmount.toStringAsFixed(0)}',
                  icon: TDIcons.chart_maximum,
                  color: const Color(0xFFEF5350),
                ),
                if (controller.creditCount > 0) ...[
                  StatCard(
                    title: '本地赊账',
                    value: '¥${controller.creditTotal.toStringAsFixed(0)}',
                    icon: TDIcons.location,
                    color: const Color(0xFFFFA726),
                  ),
                  StatCard(
                    title: '赊账欠款',
                    value: '¥${controller.creditDebt.toStringAsFixed(0)}',
                    icon: TDIcons.money,
                    color: const Color(0xFF8D6E63),
                  ),
                ],
                if (controller.returnGoodsCount > 0) ...[
                  StatCard(
                    title: '外地回货',
                    value: '¥${controller.returnGoodsTotal.toStringAsFixed(0)}',
                    icon: TDIcons.location,
                    color: const Color(0xFFFFA726),
                  ),
                  StatCard(
                    title: '回货欠款',
                    value: '¥${controller.returnGoodsDebt.toStringAsFixed(0)}',
                    icon: TDIcons.money,
                    color: const Color(0xFF8D6E63),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 趋势图表 - 采购金额趋势
  Widget _buildTrendChart(BuildContext context, AnalysisController controller) {
    return SliverToBoxAdapter(
      child: ChartCard(
        title: '采购趋势',
        icon: TDIcons.chart_bar,
        child: TrendComboChart(dailyStats: controller.dailyStats),
      ),
    );
  }

  // 成本结构 - 饼图
  Widget _buildCostStructure(
    BuildContext context,
    AnalysisController controller,
  ) {
    return SliverToBoxAdapter(
      child: ChartCard(
        title: '成本结构',
        icon: TDIcons.chart_pie,
        child: CostPieChart(categoryStats: controller.categoryStats),
      ),
    );
  }

  // Top榜 - 金额和数量
  Widget _buildTopRanking(BuildContext context, AnalysisController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            // 金额Top榜
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Icon(
                        TDIcons.chart_maximum,
                        size: 18,
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '金额Top榜',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TopBarChart(
                    categoryStats: controller.categoryStats,
                    showAmount: true,
                  ),
                ],
              ),
            ),
            // 数量Top榜
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Icon(
                        TDIcons.chart_bar,
                        size: 18,
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '笔数Top榜',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TopBarChart(
                    categoryStats: controller.categoryStats,
                    showAmount: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess(
    BuildContext context,
    AnalysisController controller,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const SectionHeader(title: '详细分析', icon: TDIcons.compass),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAccessCard(
                    context,
                    title: '大类分析',
                    subtitle: '${controller.groupStats.length}个大类',
                    icon: TDIcons.folder_filled,
                    color: const Color(0xFF42A5F5),
                    onTap: () => _navigateToGroupAnalysis(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccessCard(
                    context,
                    title: '品类分析',
                    subtitle: '${controller.categoryStats.length}个品类',
                    icon: TDIcons.chart_pie,
                    color: const Color(0xFF66BB6A),
                    onTap: () => _navigateToCategoryAnalysis(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '查看详情',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    AnalysisController controller,
    bool isStartDate,
  ) async {
    final initialDate = isStartDate ? controller.startDate : controller.endDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    Text(
                      isStartDate ? '选择开始日期' : '选择结束日期',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TDCalendar(
                  title: '',
                  type: CalendarType.single,
                  minDate: DateTime(2020, 1, 1).millisecondsSinceEpoch,
                  maxDate: DateTime(2030, 12, 31).millisecondsSinceEpoch,
                  value: [initialDate.millisecondsSinceEpoch],
                  onChange: (value) {
                    if (value.isNotEmpty) {
                      final selectedDate = DateTime.fromMillisecondsSinceEpoch(
                        value.first,
                      );
                      Navigator.pop(context);
                      if (isStartDate) {
                        controller.setStartDate(selectedDate);
                      } else {
                        controller.setEndDate(selectedDate);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToGroupAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupAnalysisPage()),
    );
  }

  void _navigateToCategoryAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryAnalysisPage()),
    );
  }
}
