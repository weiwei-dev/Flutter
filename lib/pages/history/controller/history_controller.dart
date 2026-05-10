import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../services/export_service.dart';
import '../../../services/import_service.dart';

/// 历史记录页面控制器
class HistoryController extends ChangeNotifier {
  // 日期范围
  String _startDate = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(const Duration(days: 7)));
  String _endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 加载状态
  bool _isExporting = false;
  bool _isImporting = false;

  // Getters
  String get startDate => _startDate;
  String get endDate => _endDate;
  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String get dateRange => '$_startDate 至 $_endDate';

  /// 设置开始日期
  void setStartDate(String date) {
    _startDate = date;
    notifyListeners();
  }

  /// 设置结束日期
  void setEndDate(String date) {
    _endDate = date;
    notifyListeners();
  }

  /// 选择日期
  void selectDate(bool isStartDate, String date) {
    if (isStartDate) {
      _startDate = date;
    } else {
      _endDate = date;
    }
    notifyListeners();
  }

  /// 导出 Excel（日期范围）
  Future<ExportResult> exportExcel() async {
    _isExporting = true;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await ExportService.instance.exportExcel(_startDate, _endDate);
      _isExporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ExportResult.success();
    } catch (e) {
      _isExporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ExportResult.failure(e.toString());
    }
  }

  /// 导出所有 Excel
  Future<ExportResult> exportAllExcel() async {
    _isExporting = true;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await ExportService.instance.exportAllExcel();
      _isExporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ExportResult.success();
    } catch (e) {
      _isExporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ExportResult.failure(e.toString());
    }
  }

  /// 导入 Excel
  Future<ImportResult> importExcel() async {
    _isImporting = true;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final result = await ImportService.instance.importExcel();
      _isImporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ImportResult(
        success: result.success,
        successCount: result.successCount,
        failCount: result.failCount,
        message: result.message,
        errors: result.errors,
      );
    } catch (e) {
      _isImporting = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return ImportResult.failure(e.toString());
    }
  }
}

/// 导出结果
class ExportResult {
  final bool success;
  final String? error;

  ExportResult._({required this.success, this.error});

  factory ExportResult.success() => ExportResult._(success: true);
  factory ExportResult.failure(String error) =>
      ExportResult._(success: false, error: error);
}

/// 导入结果
class ImportResult {
  final bool success;
  final int successCount;
  final int failCount;
  final String message;
  final List<String> errors;

  ImportResult({
    required this.success,
    this.successCount = 0,
    this.failCount = 0,
    this.message = '',
    this.errors = const [],
  });

  factory ImportResult.failure(String error) =>
      ImportResult(success: false, message: error);
}
