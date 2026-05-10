import 'dart:convert';
import '../models/procurement.dart';
import '../models/return_record.dart';
import '../models/cleanup_log.dart';
import '../utils/db.dart';

/// 重复数据检测结果
class DuplicateCheckResult {
  final int totalCount;
  final int duplicateCount;
  final int uniqueCount;
  final List<List<ProcurementRecord>> duplicateGroups;
  final List<List<ReturnRecord>> returnDuplicateGroups;

  DuplicateCheckResult({
    required this.totalCount,
    required this.duplicateCount,
    required this.uniqueCount,
    required this.duplicateGroups,
    this.returnDuplicateGroups = const [],
  });
}

/// 清理结果
class CleanupResult {
  final bool success;
  final int deletedCount;
  final int procurementDeleted;
  final int returnDeleted;
  final CleanupLog? log;
  final String message;

  CleanupResult({
    required this.success,
    this.deletedCount = 0,
    this.procurementDeleted = 0,
    this.returnDeleted = 0,
    this.log,
    this.message = '',
  });
}

/// 数据清理服务
class DataCleanupService {
  static final DataCleanupService _instance = DataCleanupService._internal();
  factory DataCleanupService() => _instance;
  DataCleanupService._internal();

  static DataCleanupService get instance => _instance;

  /// 检查采购记录中的重复数据
  Future<List<List<ProcurementRecord>>>
  checkDuplicateProcurementRecords() async {
    final records = await DatabaseHelper.instance.getAllRecords();

    // 按创建时间排序
    records.sort((a, b) => a.createTime.compareTo(b.createTime));

    // 查找重复组
    List<List<ProcurementRecord>> duplicateGroups = [];
    Set<int> processedIds = {};

    for (int i = 0; i < records.length; i++) {
      if (processedIds.contains(records[i].id)) continue;

      List<ProcurementRecord> group = [records[i]];

      for (int j = i + 1; j < records.length; j++) {
        if (processedIds.contains(records[j].id)) continue;

        if (_isDuplicateProcurement(records[i], records[j])) {
          group.add(records[j]);
          processedIds.add(records[j].id!);
        }
      }

      if (group.length > 1) {
        duplicateGroups.add(group);
        processedIds.add(records[i].id!);
      }
    }

    return duplicateGroups;
  }

  /// 检查退货记录中的重复数据
  Future<List<List<ReturnRecord>>> checkDuplicateReturnRecords() async {
    final records = await DatabaseHelper.instance.getAllReturnRecords();

    records.sort((a, b) => a.returnTime.compareTo(b.returnTime));

    List<List<ReturnRecord>> duplicateGroups = [];
    Set<int> processedIds = {};

    for (int i = 0; i < records.length; i++) {
      if (processedIds.contains(records[i].id)) continue;

      List<ReturnRecord> group = [records[i]];

      for (int j = i + 1; j < records.length; j++) {
        if (processedIds.contains(records[j].id)) continue;

        if (_isDuplicateReturn(records[i], records[j])) {
          group.add(records[j]);
          processedIds.add(records[j].id!);
        }
      }

      if (group.length > 1) {
        duplicateGroups.add(group);
        processedIds.add(records[i].id!);
      }
    }

    return duplicateGroups;
  }

  /// 判断两条采购记录是否为重复
  bool _isDuplicateProcurement(ProcurementRecord a, ProcurementRecord b) {
    if (a.category != b.category) return false;
    if ((a.quantity - b.quantity).abs() > 0.01) return false;
    if ((a.price - b.price).abs() > 0.01) return false;

    try {
      DateTime timeA = DateTime.parse(a.createTime);
      DateTime timeB = DateTime.parse(b.createTime);
      return timeB.difference(timeA).inMinutes.abs() <= 1;
    } catch (e) {
      return false;
    }
  }

  /// 判断两条退货记录是否为重复
  bool _isDuplicateReturn(ReturnRecord a, ReturnRecord b) {
    if (a.category != b.category) return false;
    if ((a.quantity - b.quantity).abs() > 0.01) return false;
    if ((a.price - b.price).abs() > 0.01) return false;

    try {
      DateTime timeA = DateTime.parse(a.returnTime);
      DateTime timeB = DateTime.parse(b.returnTime);
      return timeB.difference(timeA).inMinutes.abs() <= 1;
    } catch (e) {
      return false;
    }
  }

  /// 执行清理并记录日志
  Future<CleanupResult> performCleanup() async {
    try {
      // 检查重复数据
      final procurementGroups = await checkDuplicateProcurementRecords();
      final returnGroups = await checkDuplicateReturnRecords();

      if (procurementGroups.isEmpty && returnGroups.isEmpty) {
        return CleanupResult(success: true, message: '未发现重复数据');
      }

      // 准备记录被删除的数据
      List<DeletedRecord> deletedRecords = [];
      int procurementDeleted = 0;
      int returnDeleted = 0;

      // 清理采购记录
      for (var group in procurementGroups) {
        // 保留第一条，记录并删除其余的
        for (int i = 1; i < group.length; i++) {
          if (group[i].id != null) {
            deletedRecords.add(
              DeletedRecord(
                originalId: group[i].id!,
                data: jsonEncode(group[i].toMap()),
                type: CleanupRecordType.procurement,
              ),
            );
            await DatabaseHelper.instance.deleteRecord(group[i].id!);
            procurementDeleted++;
          }
        }
      }

      // 清理退货记录
      for (var group in returnGroups) {
        for (int i = 1; i < group.length; i++) {
          if (group[i].id != null) {
            deletedRecords.add(
              DeletedRecord(
                originalId: group[i].id!,
                data: jsonEncode(group[i].toMap()),
                type: CleanupRecordType.returnRecord,
              ),
            );
            await DatabaseHelper.instance.deleteReturnRecord(group[i].id!);
            returnDeleted++;
          }
        }
      }

      // 创建清理日志
      final log = CleanupLog(
        cleanupTime: DateTime.now().toIso8601String(),
        totalDeleted: procurementDeleted + returnDeleted,
        procurementDeleted: procurementDeleted,
        returnDeleted: returnDeleted,
        deletedRecords: CleanupLog.setDeletedRecordsList(deletedRecords),
      );

      final logId = await DatabaseHelper.instance.insertCleanupLog(log);
      final savedLog = CleanupLog(
        id: logId,
        cleanupTime: log.cleanupTime,
        totalDeleted: log.totalDeleted,
        procurementDeleted: log.procurementDeleted,
        returnDeleted: log.returnDeleted,
        deletedRecords: log.deletedRecords,
      );

      return CleanupResult(
        success: true,
        deletedCount: procurementDeleted + returnDeleted,
        procurementDeleted: procurementDeleted,
        returnDeleted: returnDeleted,
        log: savedLog,
        message: '成功清理 ${procurementDeleted + returnDeleted} 条重复记录',
      );
    } catch (e) {
      return CleanupResult(success: false, message: '清理失败: $e');
    }
  }

  /// 获取所有清理日志
  Future<List<CleanupLog>> getCleanupLogs() async {
    return await DatabaseHelper.instance.getAllCleanupLogs();
  }

  /// 回滚清理操作
  Future<CleanupResult> rollbackCleanup(int logId) async {
    try {
      final logs = await DatabaseHelper.instance.getAllCleanupLogs();
      final log = logs.firstWhere((l) => l.id == logId);

      if (log.isRolledBack) {
        return CleanupResult(success: false, message: '该清理记录已回滚');
      }

      final deletedRecords = log.getDeletedRecordsList();
      int restoredCount = 0;

      for (var record in deletedRecords) {
        try {
          final data = jsonDecode(record.data) as Map<String, dynamic>;
          if (record.type == CleanupRecordType.procurement) {
            final procurementRecord = ProcurementRecord.fromMap(data);
            // 重新插入（不保留原ID，让数据库自动分配）
            await DatabaseHelper.instance.insertRecord(
              ProcurementRecord(
                category: procurementRecord.category,
                quantity: procurementRecord.quantity,
                unit: procurementRecord.unit,
                price: procurementRecord.price,
                totalAmount: procurementRecord.totalAmount,
                serviceFee: procurementRecord.serviceFee,
                grade: procurementRecord.grade,
                supplierLocation: procurementRecord.supplierLocation,
                imagePath: procurementRecord.imagePath,
                createTime: procurementRecord.createTime,
                settleStatus: procurementRecord.settleStatus,
                settleTime: procurementRecord.settleTime,
                remark: procurementRecord.remark,
              ),
            );
            restoredCount++;
          } else {
            final returnRecord = ReturnRecord.fromMap(data);
            await DatabaseHelper.instance.insertReturnRecord(
              ReturnRecord(
                category: returnRecord.category,
                quantity: returnRecord.quantity,
                unit: returnRecord.unit,
                price: returnRecord.price,
                totalAmount: returnRecord.totalAmount,
                grade: returnRecord.grade,
                supplierLocation: returnRecord.supplierLocation,
                imagePath: returnRecord.imagePath,
                returnTime: returnRecord.returnTime,
                originalRecordTime: returnRecord.originalRecordTime,
                remark: returnRecord.remark,
                returnReason: returnRecord.returnReason,
                status: returnRecord.status,
              ),
            );
            restoredCount++;
          }
        } catch (e) {
          // 单条记录恢复失败，继续处理其他记录
        }
      }

      // 更新日志状态
      final updatedLog = CleanupLog(
        id: log.id,
        cleanupTime: log.cleanupTime,
        totalDeleted: log.totalDeleted,
        procurementDeleted: log.procurementDeleted,
        returnDeleted: log.returnDeleted,
        deletedRecords: log.deletedRecords,
        isRolledBack: true,
        rollbackTime: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.updateCleanupLog(updatedLog);

      return CleanupResult(
        success: true,
        deletedCount: restoredCount,
        message: '成功恢复 $restoredCount 条记录',
      );
    } catch (e) {
      return CleanupResult(success: false, message: '回滚失败: $e');
    }
  }

  /// 删除清理日志
  Future<bool> deleteCleanupLog(int logId) async {
    try {
      await DatabaseHelper.instance.deleteCleanupLog(logId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== 脏数据检测与清理 ====================

  /// 检测异常时间的采购记录（如1900年的记录）
  Future<List<ProcurementRecord>> checkDirtyProcurementRecords() async {
    final records = await DatabaseHelper.instance.getAllRecords();
    List<ProcurementRecord> dirtyRecords = [];

    final now = DateTime.now();
    final minValidDate = DateTime(2000, 1, 1); // 最小有效日期：2000年

    for (var record in records) {
      try {
        DateTime createTime = DateTime.parse(record.createTime);
        // 检测条件：时间早于2000年或晚于当前时间
        if (createTime.isBefore(minValidDate) || createTime.isAfter(now)) {
          dirtyRecords.add(record);
        }
      } catch (e) {
        // 解析失败也视为脏数据
        dirtyRecords.add(record);
      }
    }

    return dirtyRecords;
  }

  /// 检测异常时间的退货记录
  Future<List<ReturnRecord>> checkDirtyReturnRecords() async {
    final records = await DatabaseHelper.instance.getAllReturnRecords();
    List<ReturnRecord> dirtyRecords = [];

    final now = DateTime.now();
    final minValidDate = DateTime(2000, 1, 1);

    for (var record in records) {
      try {
        DateTime returnTime = DateTime.parse(record.returnTime);
        if (returnTime.isBefore(minValidDate) || returnTime.isAfter(now)) {
          dirtyRecords.add(record);
        }
      } catch (e) {
        dirtyRecords.add(record);
      }
    }

    return dirtyRecords;
  }

  /// 清理脏数据（异常时间记录）
  Future<CleanupResult> performDirtyDataCleanup() async {
    try {
      // 检测脏数据
      final dirtyProcurement = await checkDirtyProcurementRecords();
      final dirtyReturns = await checkDirtyReturnRecords();

      if (dirtyProcurement.isEmpty && dirtyReturns.isEmpty) {
        return CleanupResult(success: true, message: '未发现脏数据');
      }

      // 准备记录被删除的数据
      List<DeletedRecord> deletedRecords = [];
      int procurementDeleted = 0;
      int returnDeleted = 0;

      // 清理采购记录
      for (var record in dirtyProcurement) {
        if (record.id != null) {
          deletedRecords.add(
            DeletedRecord(
              originalId: record.id!,
              data: jsonEncode(record.toMap()),
              type: CleanupRecordType.procurement,
            ),
          );
          await DatabaseHelper.instance.deleteRecord(record.id!);
          procurementDeleted++;
        }
      }

      // 清理退货记录
      for (var record in dirtyReturns) {
        if (record.id != null) {
          deletedRecords.add(
            DeletedRecord(
              originalId: record.id!,
              data: jsonEncode(record.toMap()),
              type: CleanupRecordType.returnRecord,
            ),
          );
          await DatabaseHelper.instance.deleteReturnRecord(record.id!);
          returnDeleted++;
        }
      }

      // 创建清理日志
      final log = CleanupLog(
        cleanupTime: DateTime.now().toIso8601String(),
        totalDeleted: procurementDeleted + returnDeleted,
        procurementDeleted: procurementDeleted,
        returnDeleted: returnDeleted,
        deletedRecords: CleanupLog.setDeletedRecordsList(deletedRecords),
      );

      final logId = await DatabaseHelper.instance.insertCleanupLog(log);
      final savedLog = CleanupLog(
        id: logId,
        cleanupTime: log.cleanupTime,
        totalDeleted: log.totalDeleted,
        procurementDeleted: log.procurementDeleted,
        returnDeleted: log.returnDeleted,
        deletedRecords: log.deletedRecords,
      );

      return CleanupResult(
        success: true,
        deletedCount: procurementDeleted + returnDeleted,
        procurementDeleted: procurementDeleted,
        returnDeleted: returnDeleted,
        log: savedLog,
        message: '成功清理 ${procurementDeleted + returnDeleted} 条脏数据（异常时间）',
      );
    } catch (e) {
      return CleanupResult(success: false, message: '清理脏数据失败: $e');
    }
  }
}
