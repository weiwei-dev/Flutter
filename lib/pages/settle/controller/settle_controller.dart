import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../app/providers/procurement_provider.dart';
import '../../../models/procurement.dart';
import '../../../models/return_record.dart';
import '../../../services/db_service.dart';

/// 每日财务记录
class DailyFinance {
  final String date;
  double income; // 今日入账
  double expense; // 今日出账
  double balance; // 今日结余
  final String remark;

  DailyFinance({
    required this.date,
    this.income = 0,
    this.expense = 0,
    this.balance = 0,
    this.remark = '',
  });
}

/// 清账页面控制器
class SettleController extends ChangeNotifier {
  // 日期
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 数据
  List<ProcurementRecord> _records = [];
  List<ReturnRecord> _returnRecords = [];
  List<int> _selectedRecordIds = [];

  // 统计
  double _totalAmount = 0.0;
  double _selectedAmount = 0.0;
  double _settledAmount = 0.0; // 已清账金额
  double _returnTotal = 0.0; // 退货总额

  // 今日财务数据
  DailyFinance _dailyFinance = DailyFinance(
    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  // Getters
  String get selectedDate => _selectedDate;
  List<ProcurementRecord> get records => _records;
  List<int> get selectedRecordIds => _selectedRecordIds;
  double get totalAmount => _totalAmount;
  double get selectedAmount => _selectedAmount;

  /// 未清账记录数
  int get unsettledCount => _records.where((r) => r.settleStatus == 0).length;

  /// 已清账记录数
  int get settledCount => _records.where((r) => r.settleStatus == 1).length;

  /// 是否为空
  bool get isEmpty => _records.isEmpty;

  /// 是否有选中
  bool get hasSelection => _selectedRecordIds.isNotEmpty;

  /// 是否全选
  bool get isAllSelected {
    final unsettledIds = _records
        .where((record) => record.settleStatus == 0)
        .map((record) => record.id!)
        .toList();
    return _selectedRecordIds.length == unsettledIds.length &&
        unsettledIds.isNotEmpty;
  }

  /// 获取未清账记录
  List<ProcurementRecord> get unsettledRecords =>
      _records.where((r) => r.settleStatus == 0).toList();

  /// 获取已清账记录
  List<ProcurementRecord> get settledRecords =>
      _records.where((r) => r.settleStatus == 1).toList();

  /// 选择日期
  void selectDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 切换记录选择
  void toggleRecordSelection(int id) {
    if (_selectedRecordIds.contains(id)) {
      _selectedRecordIds.remove(id);
    } else {
      _selectedRecordIds.add(id);
    }
    _calculateSelectedAmount();
    notifyListeners();
  }

  /// 全选/取消全选
  void selectAll() {
    final unsettledIds = _records
        .where((record) => record.settleStatus == 0)
        .map((record) => record.id!)
        .toList();
    if (_selectedRecordIds.length == unsettledIds.length) {
      _selectedRecordIds.clear();
    } else {
      _selectedRecordIds = List.from(unsettledIds);
    }
    _calculateSelectedAmount();
    notifyListeners();
  }

  /// 计算选中金额
  void _calculateSelectedAmount() {
    _selectedAmount = _records
        .where((record) => _selectedRecordIds.contains(record.id))
        .fold(0, (sum, record) => sum + record.totalAmount);
  }

  /// 清账
  Future<bool> settleRecords(ProcurementProvider provider) async {
    if (_selectedRecordIds.isEmpty) return false;

    await provider.settleRecords(
      _selectedRecordIds,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );

    // 清账后更新财务数据：保留已有入账，累加出账
    final newExpense = _settledAmount + _selectedAmount;
    // 结余 = 入账 - 出账 + 退货（反映实际现金结余，只算已清账的）
    final newBalance = _dailyFinance.income - newExpense + _returnTotal;
    await DbService.instance.updateDailyFinance(
      _selectedDate,
      _dailyFinance.income, // 保留已有入账金额
      newExpense, // 新的出账金额 = 原已清账 + 新清账
      newBalance,
      '每日清账',
    );

    return true;
  }

  /// 取消清账
  Future<bool> unsettleRecord(
    int recordId,
    ProcurementProvider provider,
  ) async {
    // 获取记录
    final record = _records.firstWhere((r) => r.id == recordId);
    final recordAmount = record.totalAmount;

    // 更新数据库 - 将记录状态改为未清账
    await DbService.instance.updateRecordSettleStatus(
      recordId,
      0, // 未清账
      null, // 清空清账时间
    );

    // 更新财务数据 - 减少出账金额
    final newExpense = _settledAmount - recordAmount;
    // 结余 = 入账 - 出账 + 退货（反映实际现金结余，只算已清账的）
    final balance = _dailyFinance.income - newExpense + _returnTotal;
    await DbService.instance.updateDailyFinance(
      _selectedDate,
      _dailyFinance.income,
      newExpense,
      balance,
      '取消清账',
    );

    // 刷新数据
    await loadData(provider);

    return true;
  }

  /// 删除记录（只能删除未清账的记录）
  Future<bool> deleteRecord(int recordId, ProcurementProvider provider) async {
    // 获取记录信息
    final record = _records.firstWhere((r) => r.id == recordId);
    final wasSettled = record.settleStatus == 1;

    // 已清账的记录不允许直接删除，必须先取消清账
    if (wasSettled) {
      return false;
    }

    // 删除数据库记录
    await DbService.instance.deleteProcurementRecord(recordId);

    // 刷新数据
    await loadData(provider);

    return true;
  }

  /// 检查记录是否被选中
  bool isSelected(int id) => _selectedRecordIds.contains(id);

  // 今日财务数据 Getters
  DailyFinance get dailyFinance => _dailyFinance;
  double get todayIncome => _dailyFinance.income;
  // 今日出账 = 已清账金额
  double get todayExpense => _settledAmount;
  // 今日退货总额
  double get todayReturnTotal => _returnTotal;
  // 今日结余 = 入账 - 出账 + 退货（反映实际现金结余，只算已清账的）
  double get todayBalance =>
      _dailyFinance.income - _settledAmount + _returnTotal;

  /// 加载今日财务数据
  Future<void> _loadDailyFinance() async {
    final finance = await DbService.instance.getDailyFinance(_selectedDate);
    // 如果没有财务数据，默认入账10000
    final hasData =
        finance.isNotEmpty &&
        (finance['income'] != null || finance['expense'] != null);
    // 结余实时计算：入账 - 出账 + 退货（只算已清账的）
    final balance = _dailyFinance.income - _settledAmount + _returnTotal;
    _dailyFinance = DailyFinance(
      date: _selectedDate,
      income: hasData
          ? ((finance['income'] as num?)?.toDouble() ?? 0.0)
          : 10000.0, // 默认入账10000
      expense: (finance['expense'] as num?)?.toDouble() ?? 0.0,
      balance: balance,
      remark: finance['remark'] as String? ?? '',
    );
    // 如果是新日期（没有数据），保存默认入账到数据库
    if (!hasData) {
      await DbService.instance.updateDailyFinance(
        _selectedDate,
        10000.0,
        0.0,
        balance,
        '默认入账',
      );
    }
  }

  /// 设置今日入账金额
  Future<void> setTodayIncome(double amount, {String remark = '今日入账'}) async {
    _dailyFinance.income = amount;
    // 结余 = 入账 - 出账 + 退货（反映实际现金结余，只算已清账的）
    final balance = amount - _settledAmount + _returnTotal;
    await DbService.instance.updateDailyFinance(
      _selectedDate,
      amount,
      _settledAmount, // 出账 = 已清账金额
      balance,
      remark,
    );
    notifyListeners();
  }

  /// 计算已清账金额
  void _calculateSettledAmount() {
    _settledAmount = _records
        .where((record) => record.settleStatus == 1)
        .fold(0, (sum, record) => sum + record.totalAmount);
  }

  /// 计算退货总额
  void _calculateReturnTotal() {
    _returnTotal = _returnRecords.fold(
      0,
      (sum, record) => sum + record.totalAmount,
    );
  }

  /// 加载退货记录
  Future<void> _loadReturnRecords() async {
    final startDate = '$_selectedDate 00:00:00';
    final endDate = '$_selectedDate 23:59:59';
    _returnRecords = await DbService.instance.getReturnRecordsByDateRange(
      startDate,
      endDate,
    );
  }

  /// 加载数据（包含财务数据）
  Future<void> loadData(ProcurementProvider provider) async {
    await provider.loadRecords(_selectedDate);
    _records = provider.records;
    _totalAmount = _records.fold(0, (sum, record) => sum + record.totalAmount);
    _selectedRecordIds = _records
        .where((record) => record.settleStatus == 0)
        .map((record) => record.id!)
        .toList();
    _calculateSelectedAmount();
    _calculateSettledAmount(); // 计算已清账金额
    // 加载退货记录并计算退货总额
    await _loadReturnRecords();
    _calculateReturnTotal();
    // 加载今日财务数据
    await _loadDailyFinance();
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
