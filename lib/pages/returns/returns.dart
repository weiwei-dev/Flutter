import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../components/tab_bar.dart';
import '../../models/return_record.dart';
import 'return_entry.dart';
import 'controller/returns_controller.dart';
import 'widgets/returns_widgets.dart';

/// 退货管理页 - UI骨架
class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReturnsController(),
      child: const _ReturnsView(),
    );
  }
}

class _ReturnsView extends StatefulWidget {
  const _ReturnsView();

  @override
  State<_ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<_ReturnsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await context.read<ReturnsController>().loadReturnRecords();
    } catch (e) {
      if (mounted) {
        TDToast.showText('加载失败: $e', context: context);
      }
    }
  }

  Future<void> _selectDateRange(ReturnsController controller) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    DateTime? start = controller.startDate;
    // 默认结束时间是今天（但保持 nullable 类型以支持重置）
    DateTime? end = controller.endDate ?? DateTime.now();

    // 使用 TDCalendar 弹窗
    // 创建本地变量避免 null 安全问题
    DateTime? selectedStart = start;
    DateTime? selectedEnd = end;

    final result = await showModalBottomSheet<List<int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 520,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Expanded(
                child: TDCalendar(
                  title: '选择日期范围',
                  type: CalendarType.range,
                  minDate: firstDate.millisecondsSinceEpoch,
                  maxDate: lastDate.millisecondsSinceEpoch,
                  value: <int>[
                    if (selectedStart != null)
                      selectedStart!.millisecondsSinceEpoch,
                    if (selectedEnd != null)
                      selectedEnd!.millisecondsSinceEpoch,
                  ],
                  onChange: (value) {
                    if (value.length >= 2) {
                      selectedStart = DateTime.fromMillisecondsSinceEpoch(
                        value[0],
                      );
                      selectedEnd = DateTime.fromMillisecondsSinceEpoch(
                        value[1],
                      );
                    } else if (value.length == 1) {
                      selectedStart = DateTime.fromMillisecondsSinceEpoch(
                        value[0],
                      );
                      selectedEnd = null;
                    }
                  },
                  cellHeight: 44,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TDButton(
                        text: '重置',
                        size: TDButtonSize.large,
                        type: TDButtonType.outline,
                        onTap: () {
                          Navigator.pop(context, <int>[]);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TDButton(
                        text: '确定',
                        size: TDButtonSize.large,
                        type: TDButtonType.fill,
                        onTap: () {
                          final selectedDates = <int>[];
                          if (selectedStart != null) {
                            selectedDates.add(
                              selectedStart!.millisecondsSinceEpoch,
                            );
                          }
                          if (selectedEnd != null) {
                            selectedDates.add(
                              selectedEnd!.millisecondsSinceEpoch,
                            );
                          }
                          Navigator.pop(context, selectedDates);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      if (result.isEmpty) {
        // 重置
        controller.setDateRange(null, null);
      } else if (result.length >= 2) {
        controller.setDateRange(
          DateTime.fromMillisecondsSinceEpoch(result[0]),
          DateTime.fromMillisecondsSinceEpoch(result[1]),
        );
      }
      await _loadData();
    }
  }

  Future<void> _addReturnRecord() async {
    final result = await Navigator.push<ReturnRecord>(
      context,
      MaterialPageRoute(builder: (context) => const ReturnEntryPage()),
    );

    if (result != null) {
      await _loadData();
      if (mounted) {
        TDToast.showSuccess('退货记录添加成功', context: context);
      }
    }
  }

  Future<void> _deleteReturnRecord(
    ReturnsController controller,
    ReturnRecord record,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmDialog(category: record.category),
    );

    if (confirm == true) {
      try {
        await controller.deleteReturnRecord(record);
        if (mounted) {
          TDToast.showSuccess('删除成功', context: context);
        }
      } catch (e) {
        if (mounted) {
          TDToast.showText('删除失败: $e', context: context);
        }
      }
    }
  }

  void _showReturnDetail(ReturnsController controller, ReturnRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReturnDetailSheet(
        record: record,
        onDelete: () => _deleteReturnRecord(controller, record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<ReturnsController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildStatistics(controller),
              _buildFilterBar(controller),
              controller.isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : controller.isEmpty
                  ? const EmptyReturnsState()
                  : _buildReturnList(controller),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReturnRecord,
        backgroundColor: TDTheme.of(context).brandNormalColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增退货', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 2),
    );
  }

  Widget _buildHeader() {
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '退货管理',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '管理退货记录与退款',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
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

  Widget _buildStatistics(ReturnsController controller) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ReturnStatisticsCard(
              totalAmount: controller.totalReturnAmount,
              recordCount: controller.recordCount,
              filteredCount: controller.allRecordCount,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ReturnsController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            FilterBar(
              dateRangeText: controller.getDateRangeText(),
              onDateTap: () => _selectDateRange(controller),
              onRefreshTap: _loadData,
            ),
            const SizedBox(height: 10),
            StatusFilterBar(
              selectedStatuses: controller.selectedStatuses,
              onStatusChanged: (statuses) {
                controller.setStatusFilter(statuses);
              },
              onReset: () {
                controller.resetStatusFilter();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示状态选择弹窗
  Future<void> _showStatusPicker(
    BuildContext context,
    ReturnsController controller,
    ReturnRecord record,
  ) async {
    final currentStatus = ReturnStatus.fromValue(record.status);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '选择退货状态',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ...ReturnStatus.values.map((status) {
                  final isSelected = status.value == currentStatus.value;
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(status.label),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: TDTheme.of(context).brandNormalColor,
                          )
                        : null,
                    onTap: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      if (status.value != currentStatus.value) {
                        controller
                            .updateReturnStatus(record.id!, status.value)
                            .then((_) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('状态已更新为：${status.label}'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            });
                      }
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReturnList(ReturnsController controller) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final record = controller.returnRecords[index];
          return _DismissibleReturnCard(
            record: record,
            onTap: () => _showReturnDetail(controller, record),
            onStatusChange: () =>
                _showStatusPicker(context, controller, record),
            onDismissed: () => controller.deleteReturnRecord(record),
            onConfirmDismiss: () async {
              return await showDialog<bool>(
                context: context,
                builder: (context) =>
                    DeleteConfirmDialog(category: record.category),
              );
            },
          );
        }, childCount: controller.returnRecords.length),
      ),
    );
  }
}

/// 可滑动的退货卡片
class _DismissibleReturnCard extends StatelessWidget {
  final ReturnRecord record;
  final VoidCallback onTap;
  final VoidCallback? onStatusChange;
  final VoidCallback onDismissed;
  final Future<bool?> Function() onConfirmDismiss;

  const _DismissibleReturnCard({
    required this.record,
    required this.onTap,
    this.onStatusChange,
    required this.onDismissed,
    required this.onConfirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      confirmDismiss: (_) => onConfirmDismiss(),
      child: ReturnRecordCard(
        record: record,
        onTap: onTap,
        onStatusChange: onStatusChange,
      ),
    );
  }
}
