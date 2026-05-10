import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import '../models/procurement.dart';
import '../services/db_service.dart';

class ImportService {
  static final ImportService instance = ImportService._privateConstructor();

  ImportService._privateConstructor();

  /// 导入Excel文件
  Future<ImportResult> importExcel() async {
    try {
      // 选择文件
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Excel文件',
        extensions: ['xlsx', 'xls'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        return ImportResult(success: false, message: '未选择文件');
      }

      // 读取文件
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // 获取第一个工作表
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return ImportResult(success: false, message: 'Excel文件为空');
      }

      // 跳过表头，从第2行开始读取
      List<ProcurementRecord> records = [];
      int successCount = 0;
      int failCount = 0;
      List<String> errorMessages = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final record = _parseRow(row);
          if (record != null) {
            records.add(record);
            successCount++;
          } else {
            failCount++;
            errorMessages.add('第${i + 1}行数据解析失败');
          }
        } catch (e) {
          failCount++;
          errorMessages.add('第${i + 1}行: $e');
        }
      }

      // 批量插入数据库
      if (records.isNotEmpty) {
        for (var record in records) {
          await DbService.instance.addProcurementRecord(record);
        }
      }

      return ImportResult(
        success: true,
        message: '导入完成',
        totalCount: records.length + failCount,
        successCount: successCount,
        failCount: failCount,
        errors: errorMessages,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入失败: $e');
    }
  }

  /// 解析一行数据
  ProcurementRecord? _parseRow(List<Data?> row) {
    try {
      // 根据导出的Excel列顺序解析（与export_service.dart对应）
      // 0: 序号, 1: 水果名称, 2: 数量, 3: 单位, 4: 单价, 5: 总价,
      // 6: 服务费用, 7: 等级, 8: 供应商位置, 9: 创建时间,
      // 10: 清账状态, 11: 清账时间, 12: 备注

      // 跳过序号列(row[0])
      String category = _parseString(row[1]?.value) ?? '';
      double quantity = _parseNumber(row[2]?.value) ?? 0;
      String unit = _parseString(row[3]?.value) ?? '件';
      double price = _parseNumber(row[4]?.value) ?? 0;
      double totalAmount = _parseNumber(row[5]?.value) ?? 0;
      double serviceFee = _parseNumber(row[6]?.value) ?? 0;
      String? grade = _parseString(row[7]?.value);
      String? supplierLocation = _parseString(row[8]?.value);
      String? createTime = _parseDate(row[9]?.value);
      int settleStatus = _parseSettleStatus(row[10]?.value);
      // row[11] 是清账时间，采购记录中不直接存储
      String? remark = _parseString(row[12]?.value);

      if (category.isEmpty) {
        return null;
      }

      // 如果没有提供总金额，自动计算
      if (totalAmount == 0 && quantity > 0 && price > 0) {
        totalAmount = quantity * price;
      }

      return ProcurementRecord(
        category: category,
        quantity: quantity,
        unit: unit,
        price: price,
        totalAmount: totalAmount,
        serviceFee: serviceFee,
        grade: grade,
        supplierLocation: supplierLocation,
        createTime: createTime ?? DateTime.now().toString().substring(0, 19),
        settleStatus: settleStatus,
        remark: remark,
      );
    } catch (e) {
      debugPrint('解析行数据失败: $e');
      return null;
    }
  }

  /// 解析日期
  String? _parseDate(dynamic value) {
    if (value == null) return null;

    // 如果已经是DateTime类型，直接格式化
    if (value is DateTime) {
      return value.toString().substring(0, 19);
    }

    String dateStr = value.toString().trim();
    if (dateStr.isEmpty) return null;

    // 调试日志
    debugPrint('解析日期: $dateStr, 类型: ${value.runtimeType}');

    // 尝试解析常见日期格式
    try {
      // 2026-04-18 10:30:00 格式（标准格式）
      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(dateStr)) {
        return dateStr;
      }

      // 2026-04-18 格式（日期部分）
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return '$dateStr 00:00:00';
      }

      // Excel日期数字格式（如 45000 表示某个日期）
      // 注意：只处理合理的Excel日期数字（大于30000，即1982年之后）
      if (RegExp(r'^\d+$').hasMatch(dateStr)) {
        final days = int.parse(dateStr);
        // Excel日期从1900-01-00开始，但1900年被当作闰年有bug
        // 实际从1900-01-01开始计数，所以用1899-12-30作为基准
        if (days > 30000 && days < 50000) {
          // 合理范围：1982-2043年
          final baseDate = DateTime(1899, 12, 30);
          final date = baseDate.add(Duration(days: days));
          return date.toString().substring(0, 19);
        }
        // 如果数字太小，可能是序号而不是日期，返回当前时间
        debugPrint('日期数字超出合理范围: $days');
        return DateTime.now().toString().substring(0, 19);
      }

      // 尝试直接解析
      final date = DateTime.tryParse(dateStr);
      if (date != null && date.year > 2000) {
        return date.toString().substring(0, 19);
      }
    } catch (e) {
      debugPrint('日期解析失败: $dateStr, 错误: $e');
    }

    // 默认返回当前时间
    return DateTime.now().toString().substring(0, 19);
  }

  /// 解析字符串
  String? _parseString(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// 解析数字
  double? _parseNumber(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    String numStr = value.toString().trim();
    if (numStr.isEmpty) return null;

    // 移除可能的千分位分隔符
    numStr = numStr.replaceAll(',', '');

    return double.tryParse(numStr);
  }

  /// 解析清账状态
  int _parseSettleStatus(dynamic value) {
    if (value == null) return 0;

    String status = value.toString().trim();
    if (status == '已清账' || status == '1' || status == '是') {
      return 1;
    }
    return 0;
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final int totalCount;
  final int successCount;
  final int failCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.totalCount = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.errors = const [],
  });
}
