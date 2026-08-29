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

  /// 导出库存盘点表（多栏布局：产品名称+库存数量 横向并列，默认3组，库存数量留空由用户手填）
  /// [categories] 为已勾选、需要盘点的品类清单（由用户在选择页筛选）
  /// [rangeLabel] 用于文件名的范围描述；「全部历史」模式下没有日期范围，需显式传入
  Future<void> exportInventoryCheck(
    List<String> categories,
    String startDate,
    String endDate, {
    String? rangeLabel,
  }) async {

    // 每组「产品名称 + 库存数量」两列，横向并列 3 组，节省打印纸张
    const int groups = 3;

    // 创建Excel文件
    var excel = Excel.createExcel();
    var sheet = excel.sheets.values.first;

    // 表头与产品名称单元格样式
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: 'FFE0E0E0', // 浅灰底色
      horizontalAlign: HorizontalAlign.Center,
    );
    // 产品名称单元格：自动换行，长名称不截断、不遮挡
    final nameStyle = CellStyle(textWrapping: TextWrapping.WrapText);

    // 表头：每组 2 列
    final header = <String>[];
    for (int g = 0; g < groups; g++) {
      header.add('产品名称');
      header.add('库存数量');
    }
    sheet.appendRow(header);

    // 设置表头样式与列宽，长名称也能完整显示
    for (int c = 0; c < header.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
        ..cellStyle = headerStyle;
      sheet.setColWidth(c, c % 2 == 0 ? 22.0 : 10.0);
    }

    // 将品类按行数平分到各列：每列 rowsPerCol 个，纵向填充
    final total = categories.length;
    final rowsPerCol = (total / groups).ceil();

    // 逐行写入：第 r 行取每一列的第 r 个品类
    for (int r = 0; r < rowsPerCol; r++) {
      final row = <dynamic>[];
      for (int g = 0; g < groups; g++) {
        final index = g * rowsPerCol + r;
        if (index < total) {
          row.add(categories[index]); // 产品名称
          row.add(''); // 库存数量留空
        } else {
          row.add('');
          row.add('');
        }
      }
      sheet.appendRow(row);

      // 产品名称单元格（偶数列）开启自动换行
      for (int g = 0; g < groups; g++) {
        final col = g * 2;
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: r + 1,
              ),
            )
            .cellStyle = nameStyle;
      }
    }

    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Excel编码失败');
    }

    final tempDir = await getTemporaryDirectory();
    final label =
        (rangeLabel == null || rangeLabel.isEmpty) ? '$startDate至$endDate' : rangeLabel;
    final fileName = '库存盘点表_$label.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excelBytes);

    final xFile = XFile(filePath, name: fileName);
    await Share.shareXFiles([xFile], text: '库存盘点表');
  }

  /// 导出已填写库存数量的盘点表（历史记录导出）
  /// [categories] 为盘点品类清单，[quantities] 为品类对应的库存数量
  Future<void> exportInventoryCheckFilled(
    List<String> categories,
    Map<String, String> quantities,
    String startDate,
    String endDate, {
    String? rangeLabel,
  }) async {
    const int groups = 3;

    var excel = Excel.createExcel();
    var sheet = excel.sheets.values.first;

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: 'FFE0E0E0',
      horizontalAlign: HorizontalAlign.Center,
    );
    final nameStyle = CellStyle(textWrapping: TextWrapping.WrapText);

    final header = <String>[];
    for (int g = 0; g < groups; g++) {
      header.add('产品名称');
      header.add('库存数量');
    }
    sheet.appendRow(header);

    for (int c = 0; c < header.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
        ..cellStyle = headerStyle;
      sheet.setColWidth(c, c % 2 == 0 ? 22.0 : 10.0);
    }

    final total = categories.length;
    final rowsPerCol = (total / groups).ceil();

    for (int r = 0; r < rowsPerCol; r++) {
      final row = <dynamic>[];
      for (int g = 0; g < groups; g++) {
        final index = g * rowsPerCol + r;
        if (index < total) {
          final category = categories[index];
          row.add(category);
          row.add(quantities[category] ?? '');
        } else {
          row.add('');
          row.add('');
        }
      }
      sheet.appendRow(row);

      for (int g = 0; g < groups; g++) {
        final col = g * 2;
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: r + 1,
              ),
            )
            .cellStyle = nameStyle;
      }
    }

    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Excel编码失败');
    }

    final tempDir = await getTemporaryDirectory();
    final label =
        (rangeLabel == null || rangeLabel.isEmpty) ? '$startDate至$endDate' : rangeLabel;
    final fileName = '库存盘点表_已填_$label.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excelBytes);

    final xFile = XFile(filePath, name: fileName);
    await Share.shareXFiles([xFile], text: '库存盘点表（已填写）');
  }
}
