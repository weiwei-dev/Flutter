import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/db_service.dart';

/// 搜索结果类型枚举
enum SearchResultType {
  procurement, // 采购记录
  returnRecord, // 退货记录
}

/// 搜索结果项
class SearchResultItem {
  final SearchResultType type;
  final dynamic data;
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final String? status;

  SearchResultItem({
    required this.type,
    required this.data,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.status,
  });
}

class GlobalSearchController extends ChangeNotifier {
  String _keyword = '';
  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isListMode = false; // 默认为卡片视图
  Timer? _debounceTimer;

  String get keyword => _keyword;
  List<SearchResultItem> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;
  bool get hasResults => _results.isNotEmpty;
  bool get isListMode => _isListMode;

  /// 更新搜索关键字（带防抖自动搜索）
  void setKeyword(String value) {
    _keyword = value;
    notifyListeners();

    // 防抖：500ms后自动搜索
    _debounceTimer?.cancel();
    if (value.trim().isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        search();
      });
    } else {
      clear();
    }
  }

  /// 执行搜索
  Future<void> search() async {
    if (_keyword.trim().isEmpty) {
      _results = [];
      _hasSearched = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasSearched = true;
    notifyListeners();

    try {
      // 搜索采购记录
      final procurementRecords = await DbService.instance
          .searchProcurementRecords(_keyword);
      // 搜索退货记录
      final returnRecords = await DbService.instance.searchReturnRecords(
        _keyword,
      );

      // 转换为统一的结果格式
      List<SearchResultItem> items = [];

      // 添加采购记录结果
      for (var record in procurementRecords) {
        items.add(
          SearchResultItem(
            type: SearchResultType.procurement,
            data: record,
            title: record.category,
            subtitle: '${record.grade} · ${record.supplierLocation}',
            amount: '¥${record.totalAmount.toStringAsFixed(2)}',
            date: record.createTime.substring(0, 16),
            status: record.settleStatus == 1 ? '已清账' : '未清账',
          ),
        );
      }

      // 添加退货记录结果
      for (var record in returnRecords) {
        items.add(
          SearchResultItem(
            type: SearchResultType.returnRecord,
            data: record,
            title: '${record.category} (退货)',
            subtitle: '${record.grade} · ${record.quantity}${record.unit}',
            amount: '¥${record.totalAmount.toStringAsFixed(2)}',
            date: record.returnTime.substring(0, 16),
            status: '退货',
          ),
        );
      }

      // 按日期倒序排序
      items.sort((a, b) => b.date.compareTo(a.date));

      _results = items;
    } catch (e) {
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除搜索
  void clear() {
    _debounceTimer?.cancel();
    _keyword = '';
    _results = [];
    _hasSearched = false;
    notifyListeners();
  }

  /// 切换视图模式（列表/卡片）
  void toggleViewMode() {
    _isListMode = !_isListMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
