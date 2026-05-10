import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../components/tab_bar.dart';
import '../../models/procurement.dart';
import '../record_detail/record_detail.dart';
import 'controller/search_controller.dart' as search_ctrl;

/// 全局搜索页面
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => search_ctrl.GlobalSearchController(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [_buildHeader(context), _buildContent(context)],
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                _buildTitleRow(context),
                const SizedBox(height: 16),
                _buildSearchInput(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            const Text(
              '全局搜索',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return Consumer<search_ctrl.GlobalSearchController>(
      builder: (context, controller, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TDInput(
              type: TDInputType.normal,
              size: TDInputSize.large,
              backgroundColor: Colors.white,
              leftIcon: Icon(
                TDIcons.search,
                color: Colors.grey.shade400,
                size: 22,
              ),
              hintText: '输入关键字自动搜索，支持模糊匹配',
              hintTextStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              onChanged: (value) {
                controller.setKeyword(value);
              },
              onSubmitted: (_) {
                controller.search();
              },
              onClearTap: () {
                controller.clear();
              },
              needClear: controller.keyword.isNotEmpty,
              clearBtnColor: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            // 搜索提示
            Text(
              '💡 提示：输入"西瓜"可匹配"李明星西瓜"、"麒麟西瓜"等',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<search_ctrl.GlobalSearchController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!controller.hasSearched) {
              return _buildInitialState();
            }

            if (controller.results.isEmpty) {
              return _buildEmptyState();
            }

            return _buildResultsList(controller);
          },
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TDTheme.of(
                context,
              ).brandNormalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              TDIcons.search,
              size: 48,
              color: TDTheme.of(context).brandNormalColor,
            ),
          ),
          const SizedBox(height: 20),
          TDText(
            '输入关键字开始搜索',
            font: TDTheme.of(context).fontBodyLarge,
            textColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          TDText(
            '支持搜索品类、等级、供应商、备注',
            font: TDTheme.of(context).fontBodySmall,
            textColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: TDEmpty(type: TDEmptyType.plain, emptyText: '未找到相关记录'),
    );
  }

  Widget _buildResultsList(search_ctrl.GlobalSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 结果统计 + 视图切换
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: TDTheme.of(
                    context,
                  ).brandNormalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TDIcons.search,
                      size: 16,
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                    const SizedBox(width: 8),
                    TDText(
                      '找到 ${controller.results.length} 条记录',
                      font: TDTheme.of(context).fontBodySmall,
                      textColor: TDTheme.of(context).brandNormalColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              // 视图切换按钮
              _buildViewModeToggle(controller),
            ],
          ),
          const SizedBox(height: 16),
          // 根据视图模式显示列表或卡片
          controller.isListMode
              ? _buildListView(controller)
              : _buildCardView(controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 视图模式切换按钮
  Widget _buildViewModeToggle(search_ctrl.GlobalSearchController controller) {
    return GestureDetector(
      onTap: controller.toggleViewMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controller.isListMode ? TDIcons.view_list : TDIcons.view_module,
              size: 16,
              color: TDTheme.of(context).brandNormalColor,
            ),
            const SizedBox(width: 4),
            TDText(
              controller.isListMode ? '列表' : '卡片',
              font: TDTheme.of(context).fontBodySmall,
              textColor: TDTheme.of(context).brandNormalColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 卡片视图
  Widget _buildCardView(search_ctrl.GlobalSearchController controller) {
    return Column(
      children: controller.results
          .map((item) => _buildResultCard(item))
          .toList(),
    );
  }

  /// 列表视图
  Widget _buildListView(search_ctrl.GlobalSearchController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TDText(
                    '品类/等级/供应商',
                    font: TDTheme.of(context).fontBodySmall,
                    textColor: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TDText(
                    '金额',
                    font: TDTheme.of(context).fontBodySmall,
                    textColor: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 56,
                  child: TDText(
                    '状态',
                    font: TDTheme.of(context).fontBodySmall,
                    textColor: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 列表项
          ...controller.results.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildResultListItem(item, index, controller.results.length);
          }),
        ],
      ),
    );
  }

  /// 列表项
  Widget _buildResultListItem(
    search_ctrl.SearchResultItem item,
    int index,
    int totalCount,
  ) {
    final bool isReturn =
        item.type == search_ctrl.SearchResultType.returnRecord;
    final parts = item.subtitle.split(' · ');
    final grade = parts.isNotEmpty ? parts[0] : '';
    final supplier = parts.length > 1 ? parts[1] : '';

    return GestureDetector(
      onTap: () {
        if (item.type == search_ctrl.SearchResultType.procurement) {
          final record = item.data as ProcurementRecord;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordDetailPage(recordId: record.id!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: index < totalCount - 1
              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：品类 + 等级/供应商/日期
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 第一行：品类
                  TDText(
                    item.title.replaceAll(' (退货)', ''),
                    font: TDTheme.of(context).fontBodyMedium,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 第二行：等级 · 供应商 | 日期（日期靠右）
                  Row(
                    children: [
                      // 等级和供应商（可收缩）
                      Expanded(
                        child: TDText(
                          '$grade · $supplier',
                          font: TDTheme.of(context).fontBodySmall,
                          textColor: Colors.grey.shade500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 日期（固定宽度，确保显示完整）
                      TDText(
                        item.date.substring(5, 16),
                        font: TDTheme.of(context).fontBodySmall,
                        textColor: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 金额（固定宽度）
            SizedBox(
              width: 85,
              child: TDText(
                item.amount,
                font: Font(size: 14, lineHeight: 20),
                fontWeight: FontWeight.bold,
                textColor: isReturn
                    ? const Color(0xFFFFA726)
                    : TDTheme.of(context).brandNormalColor,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // 状态标签（固定宽度）
            SizedBox(
              width: 52,
              child: TDTag(
                item.status!,
                size: TDTagSize.small,
                theme: _getTagTheme(item.status!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(search_ctrl.SearchResultItem item) {
    final bool isReturn =
        item.type == search_ctrl.SearchResultType.returnRecord;

    return GestureDetector(
      onTap: () {
        if (item.type == search_ctrl.SearchResultType.procurement) {
          final record = item.data as ProcurementRecord;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordDetailPage(recordId: record.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // 左侧类型标识条
              Container(
                width: 4,
                height: 100,
                color: isReturn
                    ? const Color(0xFFFFA726)
                    : TDTheme.of(context).brandNormalColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：标题 + 金额
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TDText(
                              item.title,
                              font: TDTheme.of(context).fontTitleSmall,
                              fontWeight: FontWeight.bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TDText(
                            item.amount,
                            font: Font(size: 16, lineHeight: 24),
                            fontWeight: FontWeight.bold,
                            textColor: isReturn
                                ? const Color(0xFFFFA726)
                                : TDTheme.of(context).brandNormalColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 第二行：详细信息
                      TDText(
                        item.subtitle,
                        font: TDTheme.of(context).fontBodySmall,
                        textColor: Colors.grey.shade600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // 第三行：时间 + 状态标签
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                TDIcons.time,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              TDText(
                                item.date,
                                font: TDTheme.of(context).fontBodySmall,
                                textColor: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          if (item.status != null)
                            TDTag(
                              item.status!,
                              size: TDTagSize.small,
                              theme: _getTagTheme(item.status!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧箭头
              if (!isReturn)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    TDIcons.chevron_right,
                    color: Colors.grey.shade300,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TDTagTheme _getTagTheme(String status) {
    switch (status) {
      case '已清账':
        return TDTagTheme.success;
      case '退货':
        return TDTagTheme.warning;
      default:
        return TDTagTheme.primary;
    }
  }
}
