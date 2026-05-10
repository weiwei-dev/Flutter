import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../components/tab_bar.dart';
import '../../core/constants/app_constants.dart';
import 'category_detail.dart';
import 'controller/analysis_controller.dart';
import 'widgets/analysis_widgets.dart';

/// 品类分析页面
class CategoryAnalysisPage extends StatelessWidget {
  const CategoryAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: AnalysisController(),
      child: const _CategoryAnalysisView(),
    );
  }
}

class _CategoryAnalysisView extends StatelessWidget {
  const _CategoryAnalysisView();

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
              else if (controller.categoryStats.isEmpty)
                const SliverFillRemaining(
                  child: EmptyDataView(message: '该时间段暂无采购数据'),
                )
              else ...[
                _buildCategoryStats(context, controller),
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
                      '品类分析',
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

  Widget _buildCategoryStats(
    BuildContext context,
    AnalysisController controller,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: '采购品类统计', icon: TDIcons.chart_pie),
                Text(
                  '共${controller.categoryStats.length}个品类',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
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
                children: [
                  // 表头
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.mediumRadius),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 34),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '品类',
                            style: TextStyle(
                              fontSize: AppConstants.fontSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '金额/占比',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: AppConstants.fontSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 70),
                      ],
                    ),
                  ),
                  // 列表
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.categoryStats.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final stat = controller.categoryStats[index];
                      return CategoryStatItem(
                        stat: stat,
                        index: index,
                        onTap: () => _navigateToCategoryDetail(
                          context,
                          controller,
                          stat.category,
                        ),
                      );
                    },
                  ),
                ],
              ),
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

  void _navigateToCategoryDetail(
    BuildContext context,
    AnalysisController controller,
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(
          category: category,
          startDate: controller.startDateStr,
          endDate: controller.endDateStr,
        ),
      ),
    );
  }
}
