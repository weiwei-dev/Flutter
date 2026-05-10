import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../components/tab_bar.dart';
import '../../app/providers/procurement_provider.dart';
import '../../models/procurement.dart';
import '../record_detail/record_detail.dart';
import 'controller/settle_controller.dart';
import 'widgets/settle_widgets.dart';

/// 每日清账页 - UI骨架
class SettlePage extends StatelessWidget {
  final String? initialDate;

  const SettlePage({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettleController(),
      child: _SettleView(initialDate: initialDate),
    );
  }
}

class _SettleView extends StatefulWidget {
  final String? initialDate;

  const _SettleView({this.initialDate});

  @override
  State<_SettleView> createState() => _SettleViewState();
}

class _SettleViewState extends State<_SettleView>
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

    // 如果有初始日期，则设置
    if (widget.initialDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SettleController>().selectDate(widget.initialDate!);
        _loadData();
      });
    } else {
      _loadData();
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ProcurementProvider>();
    await context.read<SettleController>().loadData(provider);
  }

  void _showDatePicker(SettleController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _DatePickerSheet(
          currentDate: controller.selectedDate,
          onDateSelected: (date) {
            controller.selectDate(DateFormat('yyyy-MM-dd').format(date));
            _loadData();
          },
        );
      },
    );
  }

  Future<void> _settleRecords(SettleController controller) async {
    if (!controller.hasSelection) {
      TDToast.showText('请选择要清账的记录', context: context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SettleConfirmDialog(
        count: controller.selectedRecordIds.length,
        amount: controller.selectedAmount,
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ProcurementProvider>();
      await controller.settleRecords(provider);

      if (mounted) {
        TDToast.showSuccess('清账成功', context: context);
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<SettleController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildHeader(context, controller),
              _buildContent(context, controller),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<SettleController>(
        builder: (context, controller, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.hasSelection)
                SettleBottomBar(
                  selectedCount: controller.selectedRecordIds.length,
                  selectedAmount: controller.selectedAmount,
                  onSettleTap: () => _settleRecords(controller),
                ),
              const TabBarWidgetWrapper(activeIndex: 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SettleController controller) {
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
                _buildHeaderTitle(context),
                const SizedBox(height: 8),
                SettleSummaryCard(
                  selectedAmount: controller.selectedAmount,
                  selectedDate: controller.selectedDate,
                  onDateTap: () => _showDatePicker(controller),
                ),
                const SizedBox(height: 10),
                TodayFinanceCard(
                  income: controller.todayIncome,
                  expense: controller.todayExpense,
                  balance: controller.todayBalance,
                  onIncomeTap: () => _showIncomeInputDialog(controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showIncomeInputDialog(SettleController controller) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AmountInputDialog(
        title: '今日入账',
        initialAmount: controller.todayIncome,
        hintText: '请输入今日入账金额',
      ),
    );
    if (amount != null && mounted) {
      await controller.setTodayIncome(amount);
      if (mounted) {
        TDToast.showSuccess('今日入账已更新', context: context);
      }
    }
  }

  /// 显示取消清账确认对话框
  Future<void> _showCancelSettleDialog(
    BuildContext parentContext,
    SettleController controller,
    ProcurementRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(TDIcons.info_circle, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('确认取消清账'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要取消 "${record.category}" 的清账状态吗？',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              '取消清账后，该记录将恢复为"未清账"状态，您可以进行修改。修改完成后需要重新执行清账操作。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(TDIcons.money, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '涉及金额: ¥${record.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TDButton(
            text: '确认取消清账',
            theme: TDButtonTheme.danger,
            size: TDButtonSize.small,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && parentContext.mounted) {
      final provider = Provider.of<ProcurementProvider>(
        parentContext,
        listen: false,
      );
      final success = await controller.unsettleRecord(record.id!, provider);
      if (success && parentContext.mounted) {
        TDToast.showSuccess('取消清账成功', context: parentContext);
      } else if (parentContext.mounted) {
        TDToast.showText('取消清账失败', context: parentContext);
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext parentContext,
    SettleController controller,
    ProcurementRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(TDIcons.error_circle, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要删除 "${record.category}" 这条记录吗？',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              '删除后该记录将无法恢复，请谨慎操作。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(TDIcons.money, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '涉及金额: ¥${record.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TDButton(
            text: '确认删除',
            theme: TDButtonTheme.danger,
            size: TDButtonSize.small,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && parentContext.mounted) {
      final provider = Provider.of<ProcurementProvider>(
        parentContext,
        listen: false,
      );
      final success = await controller.deleteRecord(record.id!, provider);
      if (success && parentContext.mounted) {
        TDToast.showSuccess('删除成功', context: parentContext);
      } else if (parentContext.mounted) {
        TDToast.showText('已清账记录请先取消清账后再删除', context: parentContext);
      }
    }
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Row(
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
          '每日清账',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SettleController controller) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.unsettledCount > 0) ...[
                _buildSectionHeader(
                  '待清账记录',
                  controller.isAllSelected ? '取消全选' : '全选',
                  controller.isAllSelected
                      ? TDIcons.check_rectangle
                      : TDIcons.rectangle,
                  () => controller.selectAll(),
                ),
                const SizedBox(height: 10),
                ...controller.unsettledRecords.map(
                  (record) => RecordCard(
                    record: record,
                    isSettled: false,
                    isSelected: controller.isSelected(record.id!),
                    onTap: () async {
                      // 点击卡片跳转到详情页编辑
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecordDetailPage(recordId: record.id!),
                        ),
                      );
                      // 如果返回结果需要刷新，则重新加载数据
                      if (result != null &&
                          result is Map &&
                          result['refresh'] == true &&
                          mounted) {
                        if (context.mounted) {
                          final provider = context.read<ProcurementProvider>();
                          await controller.loadData(provider);
                        }
                      }
                    },
                    onCheckboxTap: () =>
                        controller.toggleRecordSelection(record.id!),
                    onDelete: () =>
                        _showDeleteConfirmDialog(context, controller, record),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (controller.settledCount > 0) ...[
                _buildSectionTitle('已清账记录 (点击可取消清账)'),
                const SizedBox(height: 10),
                ...controller.settledRecords.map(
                  (record) => RecordCard(
                    record: record,
                    isSettled: true,
                    isSelected: false,
                    onCancelSettle: () =>
                        _showCancelSettleDialog(context, controller, record),
                    // 已清账记录不显示删除按钮，必须先取消清账才能删除
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (controller.isEmpty) const EmptySettleState(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    IconData actionIcon,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        TDButton(
          text: actionText,
          size: TDButtonSize.extraSmall,
          type: TDButtonType.text,
          icon: actionIcon,
          onTap: onAction,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
}

/// 日期选择弹窗
class _DatePickerSheet extends StatelessWidget {
  final String currentDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerSheet({
    required this.currentDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '选择清账日期',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TDTheme.of(context).textColorPrimary,
              ),
            ),
          ),
          Expanded(
            child: TDCalendar(
              onChange: (value) {
                if (value.isNotEmpty) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value[0]);
                  onDateSelected(date);
                  Navigator.of(context).pop();
                }
              },
              value: [DateTime.parse(currentDate).millisecondsSinceEpoch],
              minDate: DateTime(2024).millisecondsSinceEpoch,
              maxDate: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        ],
      ),
    );
  }
}
