import 'dart:convert';

/// 清理记录类型
enum CleanupRecordType {
  procurement, // 采购记录
  returnRecord, // 退货记录
}

/// 被清理的记录信息
class DeletedRecord {
  final int originalId;
  final String data; // JSON 格式的记录数据
  final CleanupRecordType type;

  DeletedRecord({
    required this.originalId,
    required this.data,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'originalId': originalId, 'data': data, 'type': type.index};
  }

  factory DeletedRecord.fromMap(Map<String, dynamic> map) {
    return DeletedRecord(
      originalId: map['originalId'] as int,
      data: map['data'] as String,
      type: CleanupRecordType.values[map['type'] as int],
    );
  }
}

/// 清理日志
class CleanupLog {
  final int? id;
  final String cleanupTime;
  final int totalDeleted;
  final int procurementDeleted;
  final int returnDeleted;
  final String deletedRecords; // JSON 数组格式的 DeletedRecord 列表
  final bool isRolledBack;
  final String? rollbackTime;

  CleanupLog({
    this.id,
    required this.cleanupTime,
    required this.totalDeleted,
    required this.procurementDeleted,
    required this.returnDeleted,
    required this.deletedRecords,
    this.isRolledBack = false,
    this.rollbackTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cleanupTime': cleanupTime,
      'totalDeleted': totalDeleted,
      'procurementDeleted': procurementDeleted,
      'returnDeleted': returnDeleted,
      'deletedRecords': deletedRecords,
      'isRolledBack': isRolledBack ? 1 : 0,
      'rollbackTime': rollbackTime,
    };
  }

  factory CleanupLog.fromMap(Map<String, dynamic> map) {
    return CleanupLog(
      id: map['id'] as int?,
      cleanupTime: map['cleanupTime'] as String,
      totalDeleted: map['totalDeleted'] as int,
      procurementDeleted: map['procurementDeleted'] as int,
      returnDeleted: map['returnDeleted'] as int,
      deletedRecords: map['deletedRecords'] as String,
      isRolledBack: map['isRolledBack'] == 1,
      rollbackTime: map['rollbackTime'] as String?,
    );
  }

  /// 获取被删除的记录列表
  List<DeletedRecord> getDeletedRecordsList() {
    try {
      final List<dynamic> list = jsonDecode(deletedRecords) as List<dynamic>;
      return list
          .map((e) => DeletedRecord.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 设置被删除的记录列表
  static String setDeletedRecordsList(List<DeletedRecord> records) {
    return jsonEncode(records.map((e) => e.toMap()).toList());
  }
}
