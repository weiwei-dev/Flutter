import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../models/return_record.dart';
import '../../../utils/db.dart';

/// 退货列表页控制器
class ReturnsController extends ChangeNotifier {
  // 数据
  List<ReturnRecord> _returnRecords = [];
  bool _isLoading = true;

  // 日期范围
  DateTime? _startDate;
  DateTime? _endDate;

  // 状态筛选 - 默认显示未退货(0)和处理中(1)
  List<int> _selectedStatuses = [0, 1];

  // 统计
  double _totalReturnAmount = 0;

  // Getters
  List<ReturnRecord> get returnRecords => _filterRecords();
  List<ReturnRecord> get allRecords => _returnRecords;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<int> get selectedStatuses => _selectedStatuses;
  double get totalReturnAmount => _totalReturnAmount;
  bool get isEmpty => returnRecords.isEmpty;
  int get recordCount => returnRecords.length;
  int get allRecordCount => _returnRecords.length;

  /// 筛选记录
  List<ReturnRecord> _filterRecords() {
    if (_selectedStatuses.isEmpty) {
      return _returnRecords;
    }
    return _returnRecords
        .where((r) => _selectedStatuses.contains(r.status))
        .toList();
  }

  /// 加载退货记录
  Future<void> loadReturnRecords() async {
    _isLoading = true;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      List<ReturnRecord> records;
      if (_startDate != null && _endDate != null) {
        final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
        final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
        records = await DatabaseHelper.instance.getReturnRecordsByDateRange(
          startStr,
          endStr,
        );
      } else {
        records = await DatabaseHelper.instance.getAllReturnRecords();
      }

      double total = 0;
      for (var record in records) {
        total += record.totalAmount;
      }

      _returnRecords = records;
      _totalReturnAmount = total;
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      rethrow;
    }
  }

  /// 设置日期范围
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  /// 重置日期范围
  void resetDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  /// 设置状态筛选
  void setStatusFilter(List<int> statuses) {
    _selectedStatuses = statuses;
    notifyListeners();
  }

  /// 切换单个状态
  void toggleStatus(int status) {
    if (_selectedStatuses.contains(status)) {
      _selectedStatuses.remove(status);
    } else {
      _selectedStatuses.add(status);
    }
    notifyListeners();
  }

  /// 重置状态筛选为默认值
  void resetStatusFilter() {
    _selectedStatuses = [0, 1]; // 默认未退货和处理中
    notifyListeners();
  }

  /// 显示全部状态
  void showAllStatuses() {
    _selectedStatuses = [];
    notifyListeners();
  }

  /// 删除退货记录
  Future<void> deleteReturnRecord(ReturnRecord record) async {
    await DatabaseHelper.instance.deleteReturnRecord(record.id!);
    await loadReturnRecords();
  }

  /// 添加退货记录后刷新
  Future<void> refreshAfterAdd() async {
    await loadReturnRecords();
  }

  /// 获取日期范围显示文本
  String getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}';
    }
    return '全部时间';
  }

  /// 获取状态筛选文本
  String getStatusFilterText() {
    if (_selectedStatuses.isEmpty) {
      return '全部状态';
    }
    if (_selectedStatuses.length == ReturnStatus.values.length) {
      return '全部状态';
    }
    if (_selectedStatuses.length == 1) {
      return ReturnStatus.fromValue(_selectedStatuses.first).label;
    }
    return '${_selectedStatuses.length}个状态';
  }

  /// 更新退货状态
  Future<void> updateReturnStatus(int recordId, int newStatus) async {
    final recordIndex = _returnRecords.indexWhere((r) => r.id == recordId);
    if (recordIndex == -1) return;

    final record = _returnRecords[recordIndex];
    final updatedRecord = record.copyWith(status: newStatus);

    await DatabaseHelper.instance.updateReturnRecord(updatedRecord);

    // 更新本地列表
    _returnRecords[recordIndex] = updatedRecord;
    notifyListeners();
  }
}
