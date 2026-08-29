import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../../models/procurement.dart';
import '../../../services/db_service.dart';
import '../../../utils/category_classifier.dart';

final logger = Logger();

/// 用于Isolate计算的数据传输类
class _AnalysisData {
  final List<Map<String, dynamic>> recordsData;

  _AnalysisData({required this.recordsData});
}

/// 用于Isolate计算的返回结果
class _AnalysisResult {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final double maxAmount;
  final double minAmount;
  final List<Map<String, dynamic>> categoryStatsData;
  final List<Map<String, dynamic>> dailyStatsData;

  _AnalysisResult({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.maxAmount,
    required this.minAmount,
    required this.categoryStatsData,
    required this.dailyStatsData,
  });
}

/// 采购数据分析控制器
class AnalysisController extends ChangeNotifier {
  // 日期范围
  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 7),
  ); // 默认7天，减少数据量
  DateTime _endDate = DateTime.now();

  // 数据
  List<ProcurementRecord> _records = [];
  bool _isLoading = false;

  // 统计数据
  double _totalAmount = 0.0;
  int _totalCount = 0;
  double _averageAmount = 0.0;
  double _maxAmount = 0.0;
  double _minAmount = 0.0;

  // 品类统计
  List<CategoryStat> _categoryStats = [];

  // 每日统计
  List<DailyStat> _dailyStats = [];

  // 大类统计
  List<GroupStat> _groupStats = [];

  // 欠款统计（统计日期范围内）
  double _returnGoodsTotal = 0.0; // 外地回货总额
  double _returnGoodsDebt = 0.0; // 回货未结账金额（欠款）
  double _creditTotal = 0.0; // 本地赊账总额
  double _creditDebt = 0.0; // 赊账未结账金额（欠款）

  // 缓存
  final Map<String, List<ProcurementRecord>> _recordsCache = {};
  Timer? _cacheClearTimer;

  // Getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<ProcurementRecord> get records => _records;
  bool get isLoading => _isLoading;
  double get totalAmount => _totalAmount;
  int get totalCount => _totalCount;
  double get averageAmount => _averageAmount;
  double get maxAmount => _maxAmount;
  double get minAmount => _minAmount;
  List<CategoryStat> get categoryStats => _categoryStats;
  List<DailyStat> get dailyStats => _dailyStats;
  List<GroupStat> get groupStats => _groupStats;
  double get returnGoodsTotal => _returnGoodsTotal;
  double get returnGoodsDebt => _returnGoodsDebt;
  double get creditTotal => _creditTotal;
  double get creditDebt => _creditDebt;
  double get totalDebt => _returnGoodsDebt + _creditDebt;
  int get returnGoodsCount => _records
      .where((r) => r.purchaseType == PurchaseType.returnGoods)
      .length;
  int get creditCount =>
      _records.where((r) => r.purchaseType == PurchaseType.credit).length;

  String get startDateStr => DateFormat('yyyy-MM-dd').format(_startDate);
  String get endDateStr => DateFormat('yyyy-MM-dd').format(_endDate);

  AnalysisController() {
    logger.d('AnalysisController initialized');
    _initCacheClearTimer();
    loadData();
  }

  void _initCacheClearTimer() {
    // 每5分钟清理一次缓存
    _cacheClearTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _recordsCache.clear();
      logger.d('Analysis cache cleared');
    });
  }

  /// 设置开始日期
  void setStartDate(DateTime date) {
    _startDate = date;
    if (_startDate.isAfter(_endDate)) {
      _endDate = _startDate;
    }
    notifyListeners();
    loadData();
  }

  /// 设置结束日期
  void setEndDate(DateTime date) {
    _endDate = date;
    if (_endDate.isBefore(_startDate)) {
      _startDate = _endDate;
    }
    notifyListeners();
    loadData();
  }

  /// 加载数据
  Future<void> loadData() async {
    final cacheKey = '$startDateStr-$endDateStr';

    // 检查缓存
    if (_recordsCache.containsKey(cacheKey)) {
      logger.d('Using cached data for $cacheKey');
      _records = _recordsCache[cacheKey]!;
      _isLoading = true;
      notifyListeners();

      // 异步计算统计数据
      await _calculateStatsAsync();

      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final startStr = DateFormat('yyyy-MM-dd 00:00:00').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd 23:59:59').format(_endDate);

      logger.d('Loading analysis data from $startStr to $endStr');

      _records = await DbService.instance.getRecordsByDateRange(
        startStr,
        endStr,
      );

      // 保存到缓存
      _recordsCache[cacheKey] = List.unmodifiable(_records);

      logger.d('Analysis data loaded: ${_records.length} records');

      // 异步计算统计数据
      await _calculateStatsAsync();
    } catch (e) {
      logger.e('Error loading analysis data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 使用Isolate异步计算统计数据
  Future<void> _calculateStatsAsync() async {
    if (_records.isEmpty) {
      _totalAmount = 0.0;
      _totalCount = 0;
      _averageAmount = 0.0;
      _maxAmount = 0.0;
      _minAmount = 0.0;
      _categoryStats = [];
      _dailyStats = [];
      _returnGoodsTotal = 0.0;
      _returnGoodsDebt = 0.0;
      _creditTotal = 0.0;
      _creditDebt = 0.0;
      return;
    }

    try {
      // 如果数据量小，直接计算
      if (_records.length < 100) {
        _calculateStatsSync();
        return;
      }

      // 大数据量使用Isolate计算
      final recordsData = _records.map((r) => r.toMap()).toList();
      final inputData = _AnalysisData(recordsData: recordsData);

      final result = await compute(_analyzeDataInIsolate, inputData);

      _totalAmount = result.totalAmount;
      _totalCount = result.totalCount;
      _averageAmount = result.averageAmount;
      _maxAmount = result.maxAmount;
      _minAmount = result.minAmount;

      _categoryStats = result.categoryStatsData
          .map(
            (data) => CategoryStat(
              category: data['category'] as String,
              count: data['count'] as int,
              totalAmount: data['totalAmount'] as double,
              percentage: data['percentage'] as double,
            ),
          )
          .toList();

      _dailyStats = result.dailyStatsData
          .map(
            (data) => DailyStat(
              date: data['date'] as String,
              count: data['count'] as int,
              totalAmount: data['totalAmount'] as double,
            ),
          )
          .toList();

      // 计算大类统计（在主线程中计算，因为需要访问 CategoryClassifier）
      _calculateGroupStatsSync();
      _calculateReturnGoodsStats();
    } catch (e) {
      logger.e('Error calculating stats: $e');
      // 出错时回退到同步计算
      _calculateStatsSync();
    }
  }

  /// 同步计算统计数据（小数据量或Isolate失败时使用）
  void _calculateStatsSync() {
    _calculateBasicStats();
    _calculateCategoryStatsSync();
    _calculateDailyStatsSync();
    _calculateGroupStatsSync();
    _calculateReturnGoodsStats();
  }

  /// 计算欠款统计（外地回货 + 本地赊账，各自的总额与未结账欠款）
  void _calculateReturnGoodsStats() {
    final returnRecords = _records
        .where((r) => r.purchaseType == PurchaseType.returnGoods)
        .toList();
    final creditRecords = _records
        .where((r) => r.purchaseType == PurchaseType.credit)
        .toList();

    _returnGoodsTotal = returnRecords.fold(
      0.0,
      (sum, r) => sum + r.totalAmount,
    );
    _returnGoodsDebt = returnRecords
        .where((r) => r.settleStatus == 0)
        .fold(0.0, (sum, r) => sum + r.totalAmount);

    _creditTotal = creditRecords.fold(
      0.0,
      (sum, r) => sum + r.totalAmount,
    );
    _creditDebt = creditRecords
        .where((r) => r.settleStatus == 0)
        .fold(0.0, (sum, r) => sum + r.totalAmount);
  }

  /// 计算基础统计数据
  void _calculateBasicStats() {
    if (_records.isEmpty) {
      _totalAmount = 0.0;
      _totalCount = 0;
      _averageAmount = 0.0;
      _maxAmount = 0.0;
      _minAmount = 0.0;
      return;
    }

    _totalCount = _records.length;
    _totalAmount = _records.fold(0.0, (sum, r) => sum + r.totalAmount);
    _averageAmount = _totalAmount / _totalCount;

    final amounts = _records.map((r) => r.totalAmount).toList();
    _maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    _minAmount = amounts.reduce((a, b) => a < b ? a : b);
  }

  /// 计算品类统计
  void _calculateCategoryStatsSync() {
    final Map<String, CategoryStatData> categoryMap = {};

    for (var record in _records) {
      final category = record.category;
      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = CategoryStatData(
          category: category,
          count: 0,
          totalAmount: 0.0,
        );
      }
      categoryMap[category]!.count++;
      categoryMap[category]!.totalAmount += record.totalAmount;
    }

    _categoryStats = categoryMap.values
        .map(
          (data) => CategoryStat(
            category: data.category,
            count: data.count,
            totalAmount: data.totalAmount,
            percentage: _totalAmount > 0
                ? data.totalAmount / _totalAmount
                : 0.0,
          ),
        )
        .toList();

    _categoryStats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  /// 计算每日统计
  void _calculateDailyStatsSync() {
    final Map<String, DailyStatData> dailyMap = {};

    for (var record in _records) {
      final date = record.createTime.substring(0, 10);
      if (!dailyMap.containsKey(date)) {
        dailyMap[date] = DailyStatData(date: date, count: 0, totalAmount: 0.0);
      }
      dailyMap[date]!.count++;
      dailyMap[date]!.totalAmount += record.totalAmount;
    }

    _dailyStats = dailyMap.values
        .map(
          (data) => DailyStat(
            date: data.date,
            count: data.count,
            totalAmount: data.totalAmount,
          ),
        )
        .toList();

    _dailyStats.sort((a, b) => a.date.compareTo(b.date));
  }

  /// 计算大类统计
  void _calculateGroupStatsSync() {
    final Map<String, GroupStatData> groupMap = {};

    for (var record in _records) {
      final group = CategoryClassifier.getGroup(record.category);
      if (!groupMap.containsKey(group)) {
        groupMap[group] = GroupStatData(
          group: group,
          count: 0,
          totalAmount: 0.0,
          categories: {},
          categoryCount: {},
        );
      }
      groupMap[group]!.count++;
      groupMap[group]!.totalAmount += record.totalAmount;
      groupMap[group]!.categories.add(record.category);
      groupMap[group]!.categoryCount[record.category] =
          (groupMap[group]!.categoryCount[record.category] ?? 0) + 1;
    }

    _groupStats = groupMap.values
        .map(
          (data) => GroupStat(
            group: data.group,
            count: data.count,
            totalAmount: data.totalAmount,
            percentage: _totalAmount > 0
                ? data.totalAmount / _totalAmount
                : 0.0,
            categories: data.categories.toList(),
            categoryCount: data.categoryCount,
          ),
        )
        .toList();

    _groupStats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  /// 清除缓存
  void clearCache() {
    _recordsCache.clear();
    logger.d('Analysis cache manually cleared');
  }

  @override
  void dispose() {
    _cacheClearTimer?.cancel();
    _recordsCache.clear();
    logger.d('AnalysisController disposed');
    super.dispose();
  }
}

/// 在Isolate中执行数据分析
_AnalysisResult _analyzeDataInIsolate(_AnalysisData data) {
  final records = data.recordsData;

  if (records.isEmpty) {
    return _AnalysisResult(
      totalAmount: 0.0,
      totalCount: 0,
      averageAmount: 0.0,
      maxAmount: 0.0,
      minAmount: 0.0,
      categoryStatsData: [],
      dailyStatsData: [],
    );
  }

  // 基础统计
  final totalCount = records.length;
  double totalAmount = 0.0;
  double maxAmount = 0.0;
  double minAmount = double.infinity;

  for (var record in records) {
    final amount = (record['total_amount'] as num).toDouble();
    totalAmount += amount;
    if (amount > maxAmount) maxAmount = amount;
    if (amount < minAmount) minAmount = amount;
  }

  final averageAmount = totalAmount / totalCount;

  // 品类统计
  final Map<String, Map<String, dynamic>> categoryMap = {};
  for (var record in records) {
    final category = record['category'] as String;
    final amount = (record['total_amount'] as num).toDouble();

    if (!categoryMap.containsKey(category)) {
      categoryMap[category] = {
        'category': category,
        'count': 0,
        'totalAmount': 0.0,
      };
    }
    categoryMap[category]!['count'] = categoryMap[category]!['count'] + 1;
    categoryMap[category]!['totalAmount'] =
        categoryMap[category]!['totalAmount'] + amount;
  }

  final categoryStatsData = categoryMap.values
      .map(
        (data) => {
          'category': data['category'] as String,
          'count': data['count'] as int,
          'totalAmount': data['totalAmount'] as double,
          'percentage': totalAmount > 0
              ? (data['totalAmount'] as double) / totalAmount
              : 0.0,
        },
      )
      .toList();

  categoryStatsData.sort(
    (a, b) =>
        (b['totalAmount'] as double).compareTo(a['totalAmount'] as double),
  );

  // 每日统计
  final Map<String, Map<String, dynamic>> dailyMap = {};
  for (var record in records) {
    final createTime = record['create_time'] as String;
    final date = createTime.substring(0, 10);
    final amount = (record['total_amount'] as num).toDouble();

    if (!dailyMap.containsKey(date)) {
      dailyMap[date] = {'date': date, 'count': 0, 'totalAmount': 0.0};
    }
    dailyMap[date]!['count'] = dailyMap[date]!['count'] + 1;
    dailyMap[date]!['totalAmount'] = dailyMap[date]!['totalAmount'] + amount;
  }

  final dailyStatsData = dailyMap.values
      .map(
        (data) => {
          'date': data['date'] as String,
          'count': data['count'] as int,
          'totalAmount': data['totalAmount'] as double,
        },
      )
      .toList();

  dailyStatsData.sort(
    (a, b) => (a['date'] as String).compareTo(b['date'] as String),
  );

  return _AnalysisResult(
    totalAmount: totalAmount,
    totalCount: totalCount,
    averageAmount: averageAmount,
    maxAmount: maxAmount,
    minAmount: minAmount == double.infinity ? 0.0 : minAmount,
    categoryStatsData: categoryStatsData,
    dailyStatsData: dailyStatsData,
  );
}

/// 品类统计数据
class CategoryStat {
  final String category;
  final int count;
  final double totalAmount;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });
}

/// 每日统计数据
class DailyStat {
  final String date;
  final int count;
  final double totalAmount;

  DailyStat({
    required this.date,
    required this.count,
    required this.totalAmount,
  });
}

/// 内部品类统计数据结构
class CategoryStatData {
  String category;
  int count;
  double totalAmount;

  CategoryStatData({
    required this.category,
    required this.count,
    required this.totalAmount,
  });
}

/// 内部每日统计数据结构
class DailyStatData {
  String date;
  int count;
  double totalAmount;

  DailyStatData({
    required this.date,
    required this.count,
    required this.totalAmount,
  });
}

/// 内部大类统计数据结构
class GroupStatData {
  String group;
  int count;
  double totalAmount;
  Set<String> categories;
  Map<String, int> categoryCount;

  GroupStatData({
    required this.group,
    required this.count,
    required this.totalAmount,
    required this.categories,
    required this.categoryCount,
  });
}
