import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/procurement.dart';
import '../../services/db_service.dart';

/// 外地回货管理页
///
/// 汇总所有「外地回货」记录：
/// - 未结账：可跨日期批量勾选结账，顶部展示累计欠款
/// - 已结账：查看历史结账记录，可取消结账
class ReturnGoodsPage extends StatelessWidget {
  const ReturnGoodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReturnGoodsController(),
      child: const _ReturnGoodsView(),
    );
  }
}

class _ReturnGoodsView extends StatefulWidget {
  const _ReturnGoodsView();

  @override
  State<_ReturnGoodsView> createState() => _ReturnGoodsViewState();
}

class _ReturnGoodsViewState extends State<_ReturnGoodsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnGoodsController>().loadData();
    });
  }

  Future<void> _settle(ReturnGoodsController controller) async {
    if (controller.selectedIds.isEmpty) {
      TDToast.showText(
        '请选择要结账的${PurchaseType.label(controller.activeType)}',
        context: context,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(TDIcons.check_circle, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            const Text('确认结账'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定对选中的 ${controller.selectedIds.length} 笔${PurchaseType.label(controller.activeType)}执行结账吗？',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
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
                    '结账金额: ¥${controller.selectedAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '结账金额将计入今日出账。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TDButton(
            text: '确认结账',
            theme: TDButtonTheme.primary,
            size: TDButtonSize.small,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.settleSelected();
    if (!mounted) return;
    if (success) {
      TDToast.showSuccess('结账成功', context: context);
    } else {
      TDToast.showText('结账失败', context: context);
    }
  }

  Future<void> _unsettle(
    ReturnGoodsController controller,
    ProcurementRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消结账'),
        content: Text(
          '确定将「${record.category}」恢复为未结账吗？\n涉及金额 ¥${record.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TDButton(
            text: '确认',
            theme: TDButtonTheme.danger,
            size: TDButtonSize.small,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.unsettleRecord(record);
      if (mounted) TDToast.showSuccess('已恢复为未结账', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<ReturnGoodsController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              _buildHeader(context, controller),
              Expanded(child: _buildBody(context, controller)),
              if (!controller.showSettled) _buildBottomBar(context, controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReturnGoodsController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TDTheme.of(context).brandNormalColor,
            TDTheme.of(context).brandNormalColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                  const Text(
                    '欠款管理',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTypeTabs(controller),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${PurchaseType.label(controller.activeType)}欠款（累计未结账）',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${controller.totalDebt.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${controller.unsettled.length} 笔未结账${PurchaseType.label(controller.activeType)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSegment(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// 欠款类型切换（外地回货 / 本地赊账）
  Widget _buildTypeTabs(ReturnGoodsController controller) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTypeTab(
            controller,
            '外地回货',
            PurchaseType.returnGoods,
          ),
          _buildTypeTab(
            controller,
            '本地赊账',
            PurchaseType.credit,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab(
    ReturnGoodsController controller,
    String text,
    int type,
  ) {
    final selected = controller.activeType == type;
    final isCredit = type == PurchaseType.credit;
    final selectedColor = isCredit
        ? const Color(0xFFFFC107)
        : const Color(0xFFFF5722);
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setActiveType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? (isCredit ? Colors.black87 : Colors.white)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(ReturnGoodsController controller) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildSegmentItem(controller, '未结账', false),
          _buildSegmentItem(controller, '已结账', true),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    ReturnGoodsController controller,
    String text,
    bool value,
  ) {
    final selected = controller.showSettled == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setShowSettled(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? TDTheme.of(context).brandNormalColor
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReturnGoodsController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final records = controller.showSettled
        ? controller.settled
        : controller.unsettled;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TDIcons.info_circle, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              controller.showSettled
                  ? '暂无已结账${PurchaseType.label(controller.activeType)}'
                  : '暂无未结账${PurchaseType.label(controller.activeType)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 按到货日期分组
    final groups = <String, List<ProcurementRecord>>{};
    for (final record in records) {
      final date = record.createTime.substring(0, 10);
      groups.putIfAbsent(date, () => []).add(record);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final items = groups[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    TDIcons.calendar,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$date（${items.length} 笔）',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((record) => _buildRecordCard(context, controller, record)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    ReturnGoodsController controller,
    ProcurementRecord record,
  ) {
    final isSelected = controller.selectedIds.contains(record.id);
    return GestureDetector(
      onTap: controller.showSettled
          ? null
          : () => controller.toggle(record.id!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? TDTheme.of(context).brandNormalColor
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (!controller.showSettled) ...[
              Icon(
                isSelected ? TDIcons.check_rectangle : TDIcons.rectangle,
                size: 20,
                color: isSelected
                    ? TDTheme.of(context).brandNormalColor
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.quantity} ${record.unit} × ¥${record.price}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (record.supplierLocation != null &&
                      record.supplierLocation!.isNotEmpty)
                    Text(
                      '来源: ${record.supplierLocation}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  if (controller.showSettled && record.settleTime != null)
                    Text(
                      '结账时间: ${record.settleTime!.substring(0, 16)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${record.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TDTheme.of(context).brandNormalColor,
                  ),
                ),
                if (controller.showSettled) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _unsettle(controller, record),
                    child: Text(
                      '取消结账',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
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

  Widget _buildBottomBar(
    BuildContext context,
    ReturnGoodsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: controller.selectAll,
              child: Row(
                children: [
                  Icon(
                    controller.isAllSelected
                        ? TDIcons.check_rectangle
                        : TDIcons.rectangle,
                    size: 20,
                    color: controller.isAllSelected
                        ? TDTheme.of(context).brandNormalColor
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  const Text('全选', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '已选 ${controller.selectedIds.length} 笔',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '¥${controller.selectedAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 130,
              child: TDButton(
                text: '结账',
                size: TDButtonSize.large,
                theme: TDButtonTheme.primary,
                disabled: controller.selectedIds.isEmpty,
                onTap: () => _settle(controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 欠款管理控制器（外地回货 / 本地赊账）
class ReturnGoodsController extends ChangeNotifier {
  List<ProcurementRecord> _unsettled = [];
  List<ProcurementRecord> _settled = [];
  final Set<int> _selectedIds = <int>{};
  bool _isLoading = true;
  bool _showSettled = false;
  int _activeType = PurchaseType.returnGoods;

  List<ProcurementRecord> get unsettled => _unsettled;
  List<ProcurementRecord> get settled => _settled;
  int get activeType => _activeType;
  Set<int> get selectedIds => _selectedIds;
  bool get isLoading => _isLoading;
  bool get showSettled => _showSettled;

  /// 累计欠款（未结账回货金额合计）
  double get totalDebt =>
      _unsettled.fold(0.0, (sum, r) => sum + r.totalAmount);

  /// 选中金额
  double get selectedAmount => _unsettled
      .where((r) => _selectedIds.contains(r.id))
      .fold(0.0, (sum, r) => sum + r.totalAmount);

  bool get isAllSelected =>
      _unsettled.isNotEmpty && _selectedIds.length == _unsettled.length;

  void setShowSettled(bool value) {
    _showSettled = value;
    notifyListeners();
  }

  void toggle(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    if (isAllSelected) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(
        _unsettled.where((r) => r.id != null).map((r) => r.id!),
      );
    }
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _unsettled = await DbService.instance.getDebtRecords(
        purchaseType: _activeType,
        settleStatus: 0,
      );
      _settled = await DbService.instance.getDebtRecords(
        purchaseType: _activeType,
        settleStatus: 1,
      );
      // 移除已不存在的选中项
      final validIds = _unsettled.map((r) => r.id).toSet();
      _selectedIds.removeWhere((id) => !validIds.contains(id));
    } catch (e) {
      debugPrint('Error loading debt records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换欠款类型（外地回货 / 本地赊账）
  Future<void> setActiveType(int type) async {
    if (_activeType == type) return;
    _activeType = type;
    _selectedIds.clear();
    await loadData();
  }

  /// 对选中的回货结账，金额计入今日出账
  Future<bool> settleSelected() async {
    if (_selectedIds.isEmpty) return false;

    try {
      final amount = selectedAmount;
      final now = DateTime.now();
      await DbService.instance.settleProcurementRecords(
        _selectedIds.toList(),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      );

      // 结账金额计入今日出账（钱是今天付的）
      final today = DateFormat('yyyy-MM-dd').format(now);
      final finance = await DbService.instance.getDailyFinance(today);
      final income = (finance['income'] as num?)?.toDouble() ?? 0.0;
      final expense = (finance['expense'] as num?)?.toDouble() ?? 0.0;
      final newExpense = expense + amount;
      await DbService.instance.updateDailyFinance(
        today,
        income,
        newExpense,
        income - newExpense,
        '${PurchaseType.label(_activeType)}结账',
      );

      _selectedIds.clear();
      await loadData();
      return true;
    } catch (e) {
      debugPrint('Error settling return goods: $e');
      return false;
    }
  }

  /// 将某笔回货恢复为未结账
  Future<bool> unsettleRecord(ProcurementRecord record) async {
    try {
      await DbService.instance.updateRecordSettleStatus(record.id!, 0, null);
      await loadData();
      return true;
    } catch (e) {
      debugPrint('Error unsettling return goods: $e');
      return false;
    }
  }
}
