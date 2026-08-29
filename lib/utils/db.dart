import 'package:path/path.dart';
import '../models/procurement.dart';
import '../models/return_record.dart';
import '../models/cleanup_log.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

// 内存存储实现（用于Web平台）
class MemoryDatabase {
  static final MemoryDatabase instance = MemoryDatabase._privateConstructor();
  final List<ProcurementRecord> _procurementRecords = [];
  final List<ReturnRecord> _returnRecords = [];
  final Map<String, Map<String, dynamic>> _dailyFinance = {};
  final List<CleanupLog> _cleanupLogs = [];
  // 库存盘点：sheetId -> 行数据（category / stock_quantity / 元信息）
  final Map<String, List<Map<String, dynamic>>> _inventoryChecks = {};
  int _nextId = 1;
  int _returnNextId = 1;
  int _cleanupLogNextId = 1;

  MemoryDatabase._privateConstructor();

  // 插入采购记录
  Future<int> insertRecord(ProcurementRecord record) async {
    final newRecord = ProcurementRecord(
      id: _nextId++,
      category: record.category,
      quantity: record.quantity,
      unit: record.unit,
      price: record.price,
      totalAmount: record.totalAmount,
      serviceFee: record.serviceFee,
      grade: record.grade,
      supplierLocation: record.supplierLocation,
      imagePath: record.imagePath,
      createTime: record.createTime,
      settleStatus: record.settleStatus,
      settleTime: record.settleTime,
      remark: record.remark,
      isSupplement: record.isSupplement,
      orderTime: record.orderTime,
      purchaseType: record.purchaseType,
    );
    _procurementRecords.add(newRecord);
    return newRecord.id!;
  }

  // 获取今日采购记录
  Future<List<ProcurementRecord>> getTodayRecords(String date) async {
    return _procurementRecords
        .where((record) => record.createTime.startsWith(date))
        .toList();
  }

  // 获取所有采购记录
  Future<List<ProcurementRecord>> getAllRecords() async {
    return _procurementRecords;
  }

  // 更新采购记录
  Future<int> updateRecord(ProcurementRecord record) async {
    final index = _procurementRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _procurementRecords[index] = record;
      return 1;
    }
    return 0;
  }

  // 删除采购记录
  Future<int> deleteRecord(int id) async {
    final initialLength = _procurementRecords.length;
    _procurementRecords.removeWhere((record) => record.id == id);
    return initialLength - _procurementRecords.length;
  }

  // 批量更新清账状态
  Future<int> updateSettleStatus(
    List<int> ids,
    int status,
    String settleTime,
  ) async {
    int updatedCount = 0;
    for (var record in _procurementRecords) {
      if (ids.contains(record.id)) {
        final updatedRecord = ProcurementRecord(
          id: record.id,
          category: record.category,
          quantity: record.quantity,
          unit: record.unit,
          price: record.price,
          totalAmount: record.totalAmount,
          serviceFee: record.serviceFee,
          grade: record.grade,
          supplierLocation: record.supplierLocation,
          imagePath: record.imagePath,
          createTime: record.createTime,
          settleStatus: status,
          settleTime: settleTime,
          remark: record.remark,
          isSupplement: record.isSupplement,
          orderTime: record.orderTime,
          purchaseType: record.purchaseType,
        );
        await updateRecord(updatedRecord);
        updatedCount++;
      }
    }
    return updatedCount;
  }

  // 更新单个记录的清账状态
  Future<int> updateSingleSettleStatus(
    int id,
    int status,
    String? settleTime,
  ) async {
    final index = _procurementRecords.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final record = _procurementRecords[index];
      final updatedRecord = ProcurementRecord(
        id: record.id,
        category: record.category,
        quantity: record.quantity,
        unit: record.unit,
        price: record.price,
        totalAmount: record.totalAmount,
        serviceFee: record.serviceFee,
        grade: record.grade,
        supplierLocation: record.supplierLocation,
        imagePath: record.imagePath,
        createTime: record.createTime,
        settleStatus: status,
        settleTime: settleTime,
        remark: record.remark,
        isSupplement: record.isSupplement,
        orderTime: record.orderTime,
        purchaseType: record.purchaseType,
      );
      _procurementRecords[index] = updatedRecord;
      return 1;
    }
    return 0;
  }

  // 插入退货记录
  Future<int> insertReturnRecord(ReturnRecord record) async {
    final newRecord = ReturnRecord(
      id: _returnNextId++,
      category: record.category,
      quantity: record.quantity,
      unit: record.unit,
      price: record.price,
      totalAmount: record.totalAmount,
      grade: record.grade,
      supplierLocation: record.supplierLocation,
      imagePath: record.imagePath,
      returnTime: record.returnTime,
      originalRecordTime: record.originalRecordTime,
      remark: record.remark,
      returnReason: record.returnReason,
      status: record.status,
    );
    _returnRecords.add(newRecord);
    return newRecord.id!;
  }

  // 获取所有退货记录
  Future<List<ReturnRecord>> getAllReturnRecords() async {
    return _returnRecords;
  }

  // 获取今日退货记录
  Future<List<ReturnRecord>> getTodayReturnRecords(String date) async {
    return _returnRecords
        .where((record) => record.returnTime.startsWith(date))
        .toList();
  }

  // 获取指定日期范围的退货记录
  Future<List<ReturnRecord>> getReturnRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return _returnRecords
        .where(
          (record) =>
              record.returnTime.compareTo(startDate) >= 0 &&
              record.returnTime.compareTo(endDate) <= 0,
        )
        .toList();
  }

  // 更新退货记录
  Future<int> updateReturnRecord(ReturnRecord record) async {
    final index = _returnRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _returnRecords[index] = record;
      return 1;
    }
    return 0;
  }

  // 删除退货记录
  Future<int> deleteReturnRecord(int id) async {
    final initialLength = _returnRecords.length;
    _returnRecords.removeWhere((record) => record.id == id);
    return initialLength - _returnRecords.length;
  }

  // ==================== 清理日志相关方法（Web） ====================

  // 插入清理日志
  Future<int> insertCleanupLog(CleanupLog log) async {
    final newLog = CleanupLog(
      id: _cleanupLogNextId++,
      cleanupTime: log.cleanupTime,
      totalDeleted: log.totalDeleted,
      procurementDeleted: log.procurementDeleted,
      returnDeleted: log.returnDeleted,
      deletedRecords: log.deletedRecords,
      isRolledBack: log.isRolledBack,
      rollbackTime: log.rollbackTime,
    );
    _cleanupLogs.add(newLog);
    return newLog.id!;
  }

  // 获取所有清理日志
  Future<List<CleanupLog>> getAllCleanupLogs() async {
    return List.from(_cleanupLogs.reversed);
  }

  // 更新清理日志
  Future<int> updateCleanupLog(CleanupLog log) async {
    final index = _cleanupLogs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      _cleanupLogs[index] = log;
      return 1;
    }
    return 0;
  }

  // 删除清理日志
  Future<int> deleteCleanupLog(int id) async {
    final initialLength = _cleanupLogs.length;
    _cleanupLogs.removeWhere((log) => log.id == id);
    return initialLength - _cleanupLogs.length;
  }

  // 获取指定日期范围的采购记录
  Future<List<ProcurementRecord>> getRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return _procurementRecords
        .where(
          (record) =>
              record.createTime.compareTo(startDate) >= 0 &&
              record.createTime.compareTo(endDate) <= 0,
        )
        .toList();
  }

  // 获取每日财务统计
  Future<Map<String, dynamic>> getDailyFinance(String date) async {
    if (_dailyFinance.containsKey(date)) {
      return _dailyFinance[date]!;
    }
    // 如果没有数据，返回默认入账10000
    return {
      'date': date,
      'income': 10000.0,
      'expense': 0.0,
      'balance': 10000.0,
      'remark': '',
    };
  }

  // 检查某日是否有财务记录
  Future<bool> hasDailyFinance(String date) async {
    return _dailyFinance.containsKey(date);
  }

  // 更新每日财务统计
  Future<int> updateDailyFinance(
    String date,
    double income,
    double expense,
    double balance,
    String remark,
  ) async {
    _dailyFinance[date] = {
      'date': date,
      'income': income,
      'expense': expense,
      'balance': balance,
      'remark': remark,
    };
    return 1;
  }

  // 获取所有唯一的水果品类
  Future<List<String>> getCategories() async {
    final categories = _procurementRecords
        .map((record) => record.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // 获取品类最新信息（用于退货时自动填充）
  Future<Map<String, dynamic>?> getCategoryLatestInfo(String category) async {
    final records = _procurementRecords
        .where((record) => record.category == category)
        .toList();
    if (records.isEmpty) return null;
    // 按创建时间排序，取最新的一条
    records.sort((a, b) => b.createTime.compareTo(a.createTime));
    final latest = records.first;
    return {
      'category': latest.category,
      'grade': latest.grade,
      'supplierLocation': latest.supplierLocation,
      'unit': latest.unit,
      'price': latest.price,
    };
  }

  // 根据品类获取最近一条采购记录（用于智能回填）
  Future<ProcurementRecord?> getLastRecordByCategory(String category) async {
    final records = _procurementRecords
        .where((record) => record.category == category)
        .toList();
    if (records.isEmpty) return null;
    // 按创建时间排序，取最新的一条
    records.sort((a, b) => b.createTime.compareTo(a.createTime));
    return records.first;
  }

  // 获取指定日期的水果品类
  Future<List<String>> getCategoriesByDate(String date) async {
    final records = _procurementRecords
        .where((record) => record.createTime.startsWith(date))
        .toList();
    final categories = records
        .map((record) => record.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // 获取指定日期范围内的水果品类（用于库存盘点）
  Future<List<String>> getCategoriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final records = _procurementRecords
        .where(
          (record) =>
              record.createTime.compareTo(startDate) >= 0 &&
              record.createTime.compareTo(endDate) <= 0,
        )
        .toList();
    final categories = records
        .map((record) => record.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // 获取欠款类记录（purchaseType 为 null 表示所有欠款类型：回货+赊账）
  Future<List<ProcurementRecord>> getDebtRecords({
    int? purchaseType,
    int? settleStatus,
  }) async {
    return _procurementRecords
        .where(
          (record) => purchaseType == null
              ? record.isDebtRecord
              : record.purchaseType == purchaseType,
        )
        .where(
          (record) =>
              settleStatus == null || record.settleStatus == settleStatus,
        )
        .toList();
  }

  // 获取指定日期范围内结账的欠款记录（用于财货详情：今天结账的欠款也要算到今天）
  Future<List<ProcurementRecord>> getSettledDebtRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return _procurementRecords
        .where(
          (record) =>
              record.settleStatus == 1 &&
              record.isDebtRecord &&
              record.settleTime != null &&
              record.settleTime!.compareTo(startDate) >= 0 &&
              record.settleTime!.compareTo(endDate) <= 0,
        )
        .toList();
  }

  // ===== 库存盘点记录（Web 内存实现） =====

  Future<void> saveInventoryCheck(
    String sheetId,
    List<String> categories,
    String startDate,
    String endDate,
    String createdAt, {
    Map<String, String>? quantities,
  }) async {
    // 与 SQLite 版一致：覆盖保存时沿用首次创建时间，只刷新 updated_at
    final oldRows = _inventoryChecks[sheetId];
    final effectiveCreatedAt =
        (oldRows != null && oldRows.isNotEmpty)
            ? (oldRows.first['created_at'] as String? ?? createdAt)
            : createdAt;
    final rows = categories
        .map(
          (c) => {
            'sheet_id': sheetId,
            'category': c,
            'stock_quantity': quantities?[c] ?? '',
            'start_date': startDate,
            'end_date': endDate,
            'created_at': effectiveCreatedAt,
            'updated_at': createdAt,
          },
        )
        .toList();
    _inventoryChecks[sheetId] = rows;
  }

  Future<void> updateInventoryQuantity(
    String sheetId,
    String category,
    String quantity,
  ) async {
    final rows = _inventoryChecks[sheetId];
    if (rows == null) return;
    for (final row in rows) {
      if (row['category'] == category) {
        row['stock_quantity'] = quantity;
        row['updated_at'] = DateTime.now().toString();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryCheck(String sheetId) async {
    return _inventoryChecks[sheetId] ?? [];
  }

  Future<List<Map<String, dynamic>>> getAllInventoryChecks() async {
    final List<Map<String, dynamic>> result = [];
    for (final entry in _inventoryChecks.entries) {
      final sheetId = entry.key;
      final rows = entry.value;
      final filled =
          rows.where((r) => (r['stock_quantity'] ?? '').toString().isNotEmpty).length;
      if (rows.isNotEmpty) {
        result.add({
          'sheet_id': sheetId,
          'start_date': rows.first['start_date'],
          'end_date': rows.first['end_date'],
          'created_at': rows.first['created_at'],
          'item_count': rows.length,
          'filled_count': filled,
        });
      }
    }
    result.sort((a, b) =>
        (b['created_at'] as String).compareTo(a['created_at'] as String));
    return result;
  }

  Future<void> deleteInventoryCheck(String sheetId) async {
    _inventoryChecks.remove(sheetId);
  }

  // 获取指定日期和品类的采购信息
  Future<Map<String, dynamic>?> getCategoryInfoByDate(
    String category,
    String date,
  ) async {
    final records = _procurementRecords
        .where(
          (record) =>
              record.category == category && record.createTime.startsWith(date),
        )
        .toList();
    if (records.isEmpty) return null;
    // 取该日期该品类的第一条记录
    final record = records.first;
    return {
      'category': record.category,
      'grade': record.grade,
      'supplierLocation': record.supplierLocation,
      'unit': record.unit,
      'price': record.price,
    };
  }

  // 搜索采购记录（智能模糊搜索，支持多关键字）
  Future<List<ProcurementRecord>> searchProcurementRecords(
    String keyword,
  ) async {
    // 分割多关键字（支持空格分隔）
    final keywords = keyword
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return [];

    return _procurementRecords.where((record) {
      return keywords.every((kw) => _matchRecord(record, kw));
    }).toList();
  }

  // 检查记录是否匹配关键字（智能模糊匹配）
  bool _matchRecord(ProcurementRecord record, String keyword) {
    final kw = keyword.toLowerCase().trim();
    if (kw.isEmpty) return false;

    final category = record.category.toLowerCase().trim();
    final grade = (record.grade ?? '').toLowerCase().trim();
    final location = (record.supplierLocation ?? '').toLowerCase().trim();
    final remark = (record.remark ?? '').toLowerCase().trim();

    // 1. 字段包含关键字（如："李明星西瓜"包含"西瓜"）
    final fieldContainsKeyword =
        category.contains(kw) ||
        grade.contains(kw) ||
        location.contains(kw) ||
        remark.contains(kw);

    // 2. 关键字包含非空字段（如："西瓜"包含在"李明星西瓜"中）
    // 只有当字段长度>=2时才进行反向匹配，避免空字符串或单字符误匹配
    final keywordContainsField =
        category.length >= 2 && kw.contains(category) ||
        grade.length >= 2 && kw.contains(grade) ||
        location.length >= 2 && kw.contains(location) ||
        remark.length >= 2 && kw.contains(remark);

    return fieldContainsKeyword || keywordContainsField;
  }

  // 搜索退货记录（智能模糊搜索，支持多关键字）
  Future<List<ReturnRecord>> searchReturnRecords(String keyword) async {
    // 分割多关键字
    final keywords = keyword
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return [];

    return _returnRecords.where((record) {
      return keywords.every((kw) => _matchReturnRecord(record, kw));
    }).toList();
  }

  // 检查退货记录是否匹配关键字
  bool _matchReturnRecord(ReturnRecord record, String keyword) {
    final kw = keyword.toLowerCase().trim();
    if (kw.isEmpty) return false;

    final category = record.category.toLowerCase().trim();
    final grade = (record.grade ?? '').toLowerCase().trim();
    final remark = (record.remark ?? '').toLowerCase().trim();

    // 1. 字段包含关键字
    final fieldContainsKeyword =
        category.contains(kw) || grade.contains(kw) || remark.contains(kw);

    // 2. 关键字包含非空字段（字段长度>=2才进行反向匹配）
    final keywordContainsField =
        category.length >= 2 && kw.contains(category) ||
        grade.length >= 2 && kw.contains(grade) ||
        remark.length >= 2 && kw.contains(remark);

    return fieldContainsKeyword || keywordContainsField;
  }
}

// 初始化数据库工厂
void _initDatabaseFactory() {
  // 移动平台使用默认的databaseFactory
  // Web平台使用内存存储
  // 桌面平台需要添加 sqflite_common_ffi 依赖
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor() {
    // 调用初始化函数
    _initDatabaseFactory();
  }

  Future<Database> get database async {
    if (kIsWeb) {
      // Web平台使用内存存储，这里返回null，后续操作会使用MemoryDatabase
      throw Exception('Web platform uses memory storage');
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fruit_procurement.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS return_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          price REAL NOT NULL,
          total_amount REAL NOT NULL,
          grade TEXT,
          supplier_location TEXT,
          image_path TEXT,
          return_time TEXT NOT NULL,
          original_record_time TEXT,
          remark TEXT,
          return_reason INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      // 版本3：添加数据库索引优化
      await _createIndexes(db);
    }
    if (oldVersion < 4) {
      // 版本4：添加退货状态字段
      await db.execute('''
        ALTER TABLE return_records ADD COLUMN status INTEGER DEFAULT 0
      ''');
    }
    if (oldVersion < 5) {
      // 版本5：添加清理日志表
      await _createCleanupLogsTable(db);
    }
    if (oldVersion < 6) {
      // 版本6：添加补单相关字段
      await _addSupplementFields(db);
    }
    if (oldVersion < 7) {
      // 版本7：添加库存盘点记录表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_checks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sheet_id TEXT NOT NULL,
          category TEXT NOT NULL,
          stock_quantity TEXT,
          start_date TEXT,
          end_date TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      // 版本8：添加外地回货标记字段
      await db.execute('''
        ALTER TABLE procurement ADD COLUMN is_return_goods INTEGER DEFAULT 0
      ''');
    }
    if (oldVersion < 9) {
      // 版本9：新增采购类型字段（0本地采购/1外地回货/2本地赊账）
      await db.execute('''
        ALTER TABLE procurement ADD COLUMN purchase_type INTEGER DEFAULT 0
      ''');
      // 迁移旧数据：原「外地回货」记录保持为类型 1
      await db.execute('''
        UPDATE procurement SET purchase_type = 1 WHERE is_return_goods = 1
      ''');
    }
  }

  /// 添加补单相关字段
  Future<void> _addSupplementFields(Database db) async {
    try {
      await db.execute('''
        ALTER TABLE procurement ADD COLUMN is_supplement INTEGER DEFAULT 0
      ''');
    } catch (e) {
      // 字段可能已存在
    }
    try {
      await db.execute('''
        ALTER TABLE procurement ADD COLUMN order_time TEXT
      ''');
    } catch (e) {
      // 字段可能已存在
    }
  }

  /// 创建清理日志表
  Future<void> _createCleanupLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cleanup_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cleanupTime TEXT NOT NULL,
        totalDeleted INTEGER NOT NULL,
        procurementDeleted INTEGER NOT NULL,
        returnDeleted INTEGER NOT NULL,
        deletedRecords TEXT NOT NULL,
        isRolledBack INTEGER DEFAULT 0,
        rollbackTime TEXT
      )
    ''');
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS procurement (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        total_amount REAL NOT NULL,
        service_fee REAL DEFAULT 0,
        grade TEXT,
        supplier_location TEXT,
        image_path TEXT,
        create_time TEXT NOT NULL,
        settle_status INTEGER DEFAULT 0,
        settle_time TEXT,
        remark TEXT,
        is_supplement INTEGER DEFAULT 0,
        order_time TEXT,
        is_return_goods INTEGER DEFAULT 0,
        purchase_type INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_finance (
        date TEXT PRIMARY KEY,
        income REAL DEFAULT 0,
        expense REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        remark TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS return_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        total_amount REAL NOT NULL,
        grade TEXT,
        supplier_location TEXT,
        image_path TEXT,
        return_time TEXT NOT NULL,
        original_record_time TEXT,
        remark TEXT,
        return_reason INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0
      )
    ''');

    // 创建数据清理日志表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cleanup_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cleanupTime TEXT NOT NULL,
        totalDeleted INTEGER NOT NULL,
        procurementDeleted INTEGER NOT NULL,
        returnDeleted INTEGER NOT NULL,
        deletedRecords TEXT NOT NULL,
        isRolledBack INTEGER DEFAULT 0,
        rollbackTime TEXT
      )
    ''');

    // 创建库存盘点记录表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sheet_id TEXT NOT NULL,
        category TEXT NOT NULL,
        stock_quantity TEXT,
        start_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // 创建索引优化查询性能
    await _createIndexes(db);
  }

  // 创建数据库索引
  Future<void> _createIndexes(Database db) async {
    // procurement 表索引
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_procurement_category ON procurement(category)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_procurement_create_time ON procurement(create_time)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_procurement_settle_status ON procurement(settle_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_procurement_category_time ON procurement(category, create_time)',
    );

    // return_records 表索引
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_return_category ON return_records(category)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_return_return_time ON return_records(return_time)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_return_category_time ON return_records(category, return_time)',
    );

    // daily_finance 表索引（date 已是主键，无需额外索引）
  }

  // 插入采购记录
  Future<int> insertRecord(ProcurementRecord record) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.insertRecord(record);
    }
    Database db = await instance.database;
    return await db.insert('procurement', record.toMap());
  }

  // 获取今日采购记录
  Future<List<ProcurementRecord>> getTodayRecords(String date) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getTodayRecords(date);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'create_time LIKE ?',
      whereArgs: ['$date%'],
    );
    return List.generate(
      maps.length,
      (i) => ProcurementRecord.fromMap(maps[i]),
    );
  }

  // 获取所有采购记录
  Future<List<ProcurementRecord>> getAllRecords() async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getAllRecords();
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('procurement');
    return List.generate(
      maps.length,
      (i) => ProcurementRecord.fromMap(maps[i]),
    );
  }

  // 获取所有补单记录
  Future<List<ProcurementRecord>> getSupplementRecords() async {
    if (kIsWeb) {
      final allRecords = await MemoryDatabase.instance.getAllRecords();
      return allRecords.where((r) => r.isSupplement == 1).toList();
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'is_supplement = ?',
      whereArgs: [1],
      orderBy: 'create_time DESC',
    );
    return List.generate(
      maps.length,
      (i) => ProcurementRecord.fromMap(maps[i]),
    );
  }

  // 更新采购记录
  Future<int> updateRecord(ProcurementRecord record) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateRecord(record);
    }
    Database db = await instance.database;
    return await db.update(
      'procurement',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // 删除采购记录
  Future<int> deleteRecord(int id) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.deleteRecord(id);
    }
    Database db = await instance.database;
    return await db.delete('procurement', where: 'id = ?', whereArgs: [id]);
  }

  // 批量更新清账状态
  Future<int> updateSettleStatus(
    List<int> ids,
    int status,
    String settleTime,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateSettleStatus(
        ids,
        status,
        settleTime,
      );
    }
    Database db = await instance.database;
    return await db.rawUpdate(
      'UPDATE procurement SET settle_status = ?, settle_time = ? WHERE id IN (${ids.map((id) => '?').join(', ')})',
      [status, settleTime, ...ids],
    );
  }

  // 更新单个记录的清账状态
  Future<int> updateSingleSettleStatus(
    int id,
    int status,
    String? settleTime,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateSingleSettleStatus(
        id,
        status,
        settleTime,
      );
    }
    Database db = await instance.database;
    return await db.update(
      'procurement',
      {'settle_status': status, 'settle_time': settleTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取指定日期范围的采购记录
  Future<List<ProcurementRecord>> getRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getRecordsByDateRange(
        startDate,
        endDate,
      );
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'create_time >= ? AND create_time <= ?',
      whereArgs: [startDate, endDate],
    );
    return List.generate(
      maps.length,
      (i) => ProcurementRecord.fromMap(maps[i]),
    );
  }

  // 获取所有唯一的水果品类
  Future<List<String>> getCategories() async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getCategories();
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM procurement ORDER BY category ASC',
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  // 获取品类最新信息（用于退货时自动填充）
  Future<Map<String, dynamic>?> getCategoryLatestInfo(String category) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getCategoryLatestInfo(category);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'create_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final record = ProcurementRecord.fromMap(maps.first);
    return {
      'category': record.category,
      'grade': record.grade,
      'supplierLocation': record.supplierLocation,
      'unit': record.unit,
      'price': record.price,
    };
  }

  // 根据品类获取最近一条采购记录（用于智能回填）
  Future<ProcurementRecord?> getLastRecordByCategory(String category) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getLastRecordByCategory(category);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'create_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProcurementRecord.fromMap(maps.first);
  }

  // 获取指定日期的水果品类
  Future<List<String>> getCategoriesByDate(String date) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getCategoriesByDate(date);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM procurement WHERE create_time LIKE ? ORDER BY category ASC',
      ['$date%'],
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  // 获取指定日期范围内的水果品类（用于库存盘点）
  Future<List<String>> getCategoriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getCategoriesByDateRange(
        startDate,
        endDate,
      );
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM procurement WHERE create_time >= ? AND create_time <= ? ORDER BY category ASC',
      [startDate, endDate],
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  /// 获取欠款类记录（purchaseType 为 null 表示所有欠款类型：回货+赊账）
  Future<List<ProcurementRecord>> getDebtRecords({
    int? purchaseType,
    int? settleStatus,
  }) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getDebtRecords(
        purchaseType: purchaseType,
        settleStatus: settleStatus,
      );
    }
    Database db = await instance.database;
    String where;
    final args = <Object?>[];
    if (purchaseType == null) {
      where = 'purchase_type IN (1, 2)';
    } else {
      where = 'purchase_type = ?';
      args.add(purchaseType);
    }
    if (settleStatus != null) {
      where += ' AND settle_status = ?';
      args.add(settleStatus);
    }
    final maps = await db.query(
      'procurement',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'create_time DESC',
    );
    return List.generate(maps.length, (i) => ProcurementRecord.fromMap(maps[i]));
  }

  /// 获取指定日期范围内结账的欠款记录
  Future<List<ProcurementRecord>> getSettledDebtRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getSettledDebtRecordsByDateRange(
        startDate,
        endDate,
      );
    }
    Database db = await instance.database;
    final maps = await db.query(
      'procurement',
      where:
          'settle_status = ? AND purchase_type IN (1, 2) AND settle_time >= ? AND settle_time <= ?',
      whereArgs: [1, startDate, endDate],
      orderBy: 'settle_time DESC',
    );
    return List.generate(maps.length, (i) => ProcurementRecord.fromMap(maps[i]));
  }

  // ===== 库存盘点记录 CRUD =====

  /// 保存一份盘点（批量插入品类行）。若 sheetId 已存在则先删除旧数据。
  ///
  /// 重要：这里是「先删后插」的覆盖保存，所以删除前会先读出该 sheetId 原有的
  /// created_at 并沿用，避免每次编辑都把创建时间刷新成当前时间
  ///（否则历史列表按 created_at DESC 排序时，编辑过的记录会跳到最前面）。
  /// updated_at 则记录本次保存时间。
  Future<void> saveInventoryCheck(
    String sheetId,
    List<String> categories,
    String startDate,
    String endDate,
    String createdAt, {
    Map<String, String>? quantities,
  }) async {
    if (kIsWeb) {
      await MemoryDatabase.instance.saveInventoryCheck(
        sheetId,
        categories,
        startDate,
        endDate,
        createdAt,
        quantities: quantities,
      );
      return;
    }
    Database db = await instance.database;
    // 沿用首次创建时间，保证编辑不会改变记录的历史位置
    final existing = await db.query(
      'inventory_checks',
      columns: ['created_at'],
      where: 'sheet_id = ?',
      whereArgs: [sheetId],
      limit: 1,
    );
    final effectiveCreatedAt = existing.isNotEmpty
        ? (existing.first['created_at'] as String? ?? createdAt)
        : createdAt;

    await db.delete(
      'inventory_checks',
      where: 'sheet_id = ?',
      whereArgs: [sheetId],
    );
    final batch = db.batch();
    for (final category in categories) {
      batch.insert('inventory_checks', {
        'sheet_id': sheetId,
        'category': category,
        'stock_quantity': quantities?[category] ?? '',
        'start_date': startDate,
        'end_date': endDate,
        'created_at': effectiveCreatedAt,
        'updated_at': createdAt,
      });
    }
    await batch.commit(noResult: true);
  }

  /// 更新某一行的库存数量
  Future<void> updateInventoryQuantity(
    String sheetId,
    String category,
    String quantity,
  ) async {
    if (kIsWeb) {
      await MemoryDatabase.instance.updateInventoryQuantity(
        sheetId,
        category,
        quantity,
      );
      return;
    }
    Database db = await instance.database;
    await db.update(
      'inventory_checks',
      {'stock_quantity': quantity, 'updated_at': DateTime.now().toString()},
      where: 'sheet_id = ? AND category = ?',
      whereArgs: [sheetId, category],
    );
  }

  /// 获取某份盘点的所有品类与库存数量。
  /// 按 id 升序（即保存时的原始顺序）返回，保证编辑页、导出表与首次导出的空表行序一致。
  Future<List<Map<String, dynamic>>> getInventoryCheck(String sheetId) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getInventoryCheck(sheetId);
    }
    Database db = await instance.database;
    final maps = await db.query(
      'inventory_checks',
      where: 'sheet_id = ?',
      whereArgs: [sheetId],
      orderBy: 'id ASC',
    );
    return maps;
  }

  /// 获取所有盘点记录（按 sheetId 分组，返回每条记录的关键信息）
  Future<List<Map<String, dynamic>>> getAllInventoryChecks() async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getAllInventoryChecks();
    }
    Database db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT sheet_id, start_date, end_date, created_at,
             COUNT(*) AS item_count,
             SUM(CASE WHEN stock_quantity IS NOT NULL AND stock_quantity != '' THEN 1 ELSE 0 END) AS filled_count
      FROM inventory_checks
      GROUP BY sheet_id
      ORDER BY created_at DESC
    ''');
    return maps;
  }

  /// 删除一份盘点
  Future<void> deleteInventoryCheck(String sheetId) async {
    if (kIsWeb) {
      await MemoryDatabase.instance.deleteInventoryCheck(sheetId);
      return;
    }
    Database db = await instance.database;
    await db.delete(
      'inventory_checks',
      where: 'sheet_id = ?',
      whereArgs: [sheetId],
    );
  }

  // 获取指定日期和品类的采购信息
  Future<Map<String, dynamic>?> getCategoryInfoByDate(
    String category,
    String date,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getCategoryInfoByDate(
        category,
        date,
      );
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'procurement',
      where: 'category = ? AND create_time LIKE ?',
      whereArgs: [category, '$date%'],
      orderBy: 'create_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final record = ProcurementRecord.fromMap(maps.first);
    return {
      'category': record.category,
      'grade': record.grade,
      'supplierLocation': record.supplierLocation,
      'unit': record.unit,
      'price': record.price,
    };
  }

  // 插入退货记录
  Future<int> insertReturnRecord(ReturnRecord record) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.insertReturnRecord(record);
    }
    Database db = await instance.database;
    return await db.insert('return_records', record.toMap());
  }

  // 获取所有退货记录
  Future<List<ReturnRecord>> getAllReturnRecords() async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getAllReturnRecords();
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'return_records',
      orderBy: 'return_time DESC',
    );
    return List.generate(maps.length, (i) => ReturnRecord.fromMap(maps[i]));
  }

  // 获取今日退货记录
  Future<List<ReturnRecord>> getTodayReturnRecords(String date) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getTodayReturnRecords(date);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'return_records',
      where: 'return_time LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'return_time DESC',
    );
    return List.generate(maps.length, (i) => ReturnRecord.fromMap(maps[i]));
  }

  // 获取指定日期范围的退货记录
  Future<List<ReturnRecord>> getReturnRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getReturnRecordsByDateRange(
        startDate,
        endDate,
      );
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'return_records',
      where: 'return_time >= ? AND return_time <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'return_time DESC',
    );
    return List.generate(maps.length, (i) => ReturnRecord.fromMap(maps[i]));
  }

  // 更新退货记录
  Future<int> updateReturnRecord(ReturnRecord record) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateReturnRecord(record);
    }
    Database db = await instance.database;
    return await db.update(
      'return_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // 删除退货记录
  Future<int> deleteReturnRecord(int id) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.deleteReturnRecord(id);
    }
    Database db = await instance.database;
    return await db.delete('return_records', where: 'id = ?', whereArgs: [id]);
  }

  // 获取每日财务统计
  Future<Map<String, dynamic>> getDailyFinance(String date) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getDailyFinance(date);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'daily_finance',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) {
      // 如果没有数据，返回默认入账10000
      return {
        'date': date,
        'income': 10000.0,
        'expense': 0.0,
        'balance': 10000.0,
        'remark': '',
      };
    }
    return maps[0];
  }

  /// 检查某日是否有财务记录
  Future<bool> hasDailyFinance(String date) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.hasDailyFinance(date);
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'daily_finance',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // 更新每日财务统计
  Future<int> updateDailyFinance(
    String date,
    double income,
    double expense,
    double balance,
    String remark,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateDailyFinance(
        date,
        income,
        expense,
        balance,
        remark,
      );
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'daily_finance',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) {
      return await db.insert('daily_finance', {
        'date': date,
        'income': income,
        'expense': expense,
        'balance': balance,
        'remark': remark,
      });
    } else {
      return await db.update(
        'daily_finance',
        {
          'income': income,
          'expense': expense,
          'balance': balance,
          'remark': remark,
        },
        where: 'date = ?',
        whereArgs: [date],
      );
    }
  }

  // 搜索采购记录（智能模糊搜索，支持多关键字）
  Future<List<ProcurementRecord>> searchProcurementRecords(
    String keyword,
  ) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.searchProcurementRecords(keyword);
    }
    Database db = await instance.database;

    // 分割多关键字（支持空格分隔）
    final keywords = keyword
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return [];

    // 获取所有记录，然后在内存中进行智能匹配
    List<Map<String, dynamic>> allMaps = await db.query(
      'procurement',
      orderBy: 'create_time DESC',
    );

    final allRecords = List.generate(
      allMaps.length,
      (i) => ProcurementRecord.fromMap(allMaps[i]),
    );

    // 智能匹配：支持双向模糊匹配
    return allRecords.where((record) {
      return keywords.every((kw) => _matchRecord(record, kw));
    }).toList();
  }

  // 检查记录是否匹配关键字（智能模糊匹配）
  bool _matchRecord(ProcurementRecord record, String keyword) {
    final kw = keyword.toLowerCase().trim();
    if (kw.isEmpty) return false;

    final category = record.category.toLowerCase().trim();
    final grade = (record.grade ?? '').toLowerCase().trim();
    final location = (record.supplierLocation ?? '').toLowerCase().trim();
    final remark = (record.remark ?? '').toLowerCase().trim();

    // 1. 字段包含关键字（如："李明星西瓜"包含"西瓜"）
    final fieldContainsKeyword =
        category.contains(kw) ||
        grade.contains(kw) ||
        location.contains(kw) ||
        remark.contains(kw);

    // 2. 关键字包含非空字段（如："西瓜"包含在"李明星西瓜"中）
    // 只有当字段长度>=2时才进行反向匹配，避免空字符串或单字符误匹配
    final keywordContainsField =
        category.length >= 2 && kw.contains(category) ||
        grade.length >= 2 && kw.contains(grade) ||
        location.length >= 2 && kw.contains(location) ||
        remark.length >= 2 && kw.contains(remark);

    return fieldContainsKeyword || keywordContainsField;
  }

  // 搜索退货记录（智能模糊搜索，支持多关键字）
  Future<List<ReturnRecord>> searchReturnRecords(String keyword) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.searchReturnRecords(keyword);
    }
    Database db = await instance.database;

    // 分割多关键字
    final keywords = keyword
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return [];

    // 获取所有记录
    List<Map<String, dynamic>> allMaps = await db.query(
      'return_records',
      orderBy: 'return_time DESC',
    );

    final allRecords = List.generate(
      allMaps.length,
      (i) => ReturnRecord.fromMap(allMaps[i]),
    );

    // 智能匹配
    return allRecords.where((record) {
      return keywords.every((kw) => _matchReturnRecord(record, kw));
    }).toList();
  }

  // 检查退货记录是否匹配关键字
  bool _matchReturnRecord(ReturnRecord record, String keyword) {
    final kw = keyword.toLowerCase().trim();
    if (kw.isEmpty) return false;

    final category = record.category.toLowerCase().trim();
    final grade = (record.grade ?? '').toLowerCase().trim();
    final remark = (record.remark ?? '').toLowerCase().trim();

    // 1. 字段包含关键字
    final fieldContainsKeyword =
        category.contains(kw) || grade.contains(kw) || remark.contains(kw);

    // 2. 关键字包含非空字段（字段长度>=2才进行反向匹配）
    final keywordContainsField =
        category.length >= 2 && kw.contains(category) ||
        grade.length >= 2 && kw.contains(grade) ||
        remark.length >= 2 && kw.contains(remark);

    return fieldContainsKeyword || keywordContainsField;
  }

  // ==================== 清理日志相关方法 ====================

  // 插入清理日志
  Future<int> insertCleanupLog(CleanupLog log) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.insertCleanupLog(log);
    }
    Database db = await instance.database;
    return await db.insert('cleanup_logs', log.toMap());
  }

  // 获取所有清理日志
  Future<List<CleanupLog>> getAllCleanupLogs() async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.getAllCleanupLogs();
    }
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'cleanup_logs',
      orderBy: 'cleanupTime DESC',
    );
    return List.generate(maps.length, (i) => CleanupLog.fromMap(maps[i]));
  }

  // 更新清理日志（用于回滚标记）
  Future<int> updateCleanupLog(CleanupLog log) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.updateCleanupLog(log);
    }
    Database db = await instance.database;
    return await db.update(
      'cleanup_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // 删除清理日志
  Future<int> deleteCleanupLog(int id) async {
    if (kIsWeb) {
      return await MemoryDatabase.instance.deleteCleanupLog(id);
    }
    Database db = await instance.database;
    return await db.delete('cleanup_logs', where: 'id = ?', whereArgs: [id]);
  }
}
