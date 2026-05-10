import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/procurement.dart';
import '../../../app/providers/procurement_provider.dart';

/// 首页控制器
class HomeController extends ChangeNotifier {
  // 状态
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  double _totalAmount = 0.0;
  double _totalServiceFee = 0.0;
  List<ProcurementRecord> _records = [];
  List<ProcurementRecord> _sortedRecords = [];
  bool _isListMode = true;
  String _sortField = 'grade';
  bool _sortAscending = false;

  // Getters
  String get selectedDate => _selectedDate;
  double get totalAmount => _totalAmount;
  double get totalServiceFee => _totalServiceFee;
  List<ProcurementRecord> get records => _records;
  List<ProcurementRecord> get sortedRecords => _sortedRecords;
  bool get isListMode => _isListMode;
  String get sortField => _sortField;
  bool get sortAscending => _sortAscending;
  int get recordCount => _records.length;
  bool get isEmpty => _records.isEmpty;

  /// 加载数据
  Future<void> loadData(ProcurementProvider provider) async {
    await provider.loadRecords(_selectedDate);
    _records = provider.records;
    _sortedRecords = List.from(_records);
    _calculateTotals();
    _sortRecords();
    notifyListeners();
  }

  /// 计算总计
  void _calculateTotals() {
    _totalAmount = _records.fold(0, (sum, r) => sum + r.totalAmount);
    _totalServiceFee = _records.fold(0, (sum, r) => sum + r.serviceFee);
  }

  /// 选择日期
  void selectDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 切换视图模式
  void toggleViewMode() {
    _isListMode = !_isListMode;
    notifyListeners();
  }

  /// 排序记录
  void _sortRecords() {
    _sortedRecords.sort((a, b) {
      int result;
      switch (_sortField) {
        case 'amount':
          result = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'category':
          result = a.category.compareTo(b.category);
          break;
        case 'grade':
        default:
          result = (a.grade ?? '').compareTo(b.grade ?? '');
          break;
      }
      return _sortAscending ? result : -result;
    });
  }

  /// 点击排序
  void onSort(String field) {
    if (_sortField == field) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = field;
      _sortAscending = true;
    }
    _sortRecords();
    notifyListeners();
  }
}
