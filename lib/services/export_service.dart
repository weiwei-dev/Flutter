import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/procurement.dart';
import '../services/db_service.dart';

class ExportService {
  static final ExportService instance = ExportService._privateConstructor();

  ExportService._privateConstructor();

  /// 导出指定日期范围的Excel
  Future<void> exportExcel(String startDate, String endDate) async {
    // 将日期格式转换为数据库查询格式（添加时间部分）
    // 数据库中存储格式为: yyyy-MM-dd HH:mm:ss
    final startDateTime = '$startDate 00:00:00';
    final endDateTime = '$endDate 23:59:59';

    // 获取指定日期范围的采购记录
    List<ProcurementRecord> records = await DbService.instance
        .getRecordsByDateRange(startDateTime, endDateTime);

    // 创建Excel文件
    var excel = Excel.createExcel();
    // 直接使用默认的 Sheet1 作为采购记录表
    var sheet = excel.sheets.values.first;

    // 设置表头
    sheet.appendRow([
      '序号',
      '水果名称',
      '数量',
      '单位',
      '单价',
      '总价',
      '服务费用',
      '等级',
      '供应商位置',
      '创建时间',
      '清账状态',
      '清账时间',
      '备注',
    ]);

    // 填充数据
    for (int i = 0; i < records.length; i++) {
      var record = records[i];
      sheet.appendRow([
        i + 1,
        record.category,
        record.quantity,
        record.unit,
        record.price,
        record.totalAmount,
        record.serviceFee,
        record.grade,
        record.supplierLocation,
        record.createTime,
        record.settleStatus == 1 ? '已清账' : '未清账',
        record.settleTime ?? '',
        record.remark ?? '',
      ]);
    }

    // 计算总计
    double totalAmount = records.fold(
      0,
      (sum, record) => sum + record.totalAmount,
    );
    sheet.appendRow([]);
    sheet.appendRow(['总计', '', '', '', '', totalAmount]);

    // 获取Excel字节数据
    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Excel编码失败');
    }

    // 保存到临时文件以确保文件名正确
    final tempDir = await getTemporaryDirectory();
    final fileName = '采购记录_$startDate至$endDate.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excelBytes);

    // 使用 XFile 分享文件
    final xFile = XFile(filePath, name: fileName);
    await Share.shareXFiles([xFile], text: '采购记录报表');
  }

  /// 导出所有采购记录
  Future<void> exportAllExcel() async {
    // 获取所有采购记录
    List<ProcurementRecord> records = await DbService.instance
        .getAllProcurementRecords();

    // 创建Excel文件
    var excel = Excel.createExcel();
    // 直接使用默认的 Sheet1 作为采购记录表
    var sheet = excel.sheets.values.first;

    // 设置表头
    sheet.appendRow([
      '序号',
      '水果名称',
      '数量',
      '单位',
      '单价',
      '总价',
      '服务费用',
      '等级',
      '供应商位置',
      '创建时间',
      '清账状态',
      '清账时间',
      '备注',
    ]);

    // 填充数据
    for (int i = 0; i < records.length; i++) {
      var record = records[i];
      sheet.appendRow([
        i + 1,
        record.category,
        record.quantity,
        record.unit,
        record.price,
        record.totalAmount,
        record.serviceFee,
        record.grade,
        record.supplierLocation,
        record.createTime,
        record.settleStatus == 1 ? '已清账' : '未清账',
        record.settleTime ?? '',
        record.remark ?? '',
      ]);
    }

    // 计算总计
    double totalAmount = records.fold(
      0,
      (sum, record) => sum + record.totalAmount,
    );
    sheet.appendRow([]);
    sheet.appendRow(['总计', '', '', '', '', totalAmount]);

    // 获取Excel字节数据
    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Excel编码失败');
    }

    // 保存到临时文件以确保文件名正确
    final tempDir = await getTemporaryDirectory();
    const fileName = '采购记录_全部数据.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excelBytes);

    // 使用 XFile 分享文件
    final xFile = XFile(filePath, name: fileName);
    await Share.shareXFiles([xFile], text: '采购记录报表（全部数据）');
  }
}
