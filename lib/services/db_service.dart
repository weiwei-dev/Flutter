import 'package:flutter/foundation.dart';
import '../utils/db.dart';
import '../models/procurement.dart';
import '../models/return_record.dart';
import 'dart:developer';

class DbService {
  static final DbService instance = DbService._privateConstructor();

  DbService._privateConstructor();

  Future<void> initDatabase() async {
    log('Initializing database...');
    try {
      await DatabaseHelper.instance.database;
      log('Database initialized successfully');
    } catch (e) {
      log('Database initialization error (expected on web): $e');
      // Web平台使用内存存储，这里捕获异常以允许应用继续运行
    }
  }

  Future<ProcurementRecord> addProcurementRecord(
    ProcurementRecord record,
  ) async {
    int id = await DatabaseHelper.instance.insertRecord(record);
    return ProcurementRecord(
      id: id,
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
    );
  }

  Future<List<ProcurementRecord>> getProcurementRecords(String date) async {
    return await DatabaseHelper.instance.getTodayRecords(date);
  }

  Future<List<ProcurementRecord>> getAllProcurementRecords() async {
    return await DatabaseHelper.instance.getAllRecords();
  }

  Future<List<ProcurementRecord>> getRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await DatabaseHelper.instance.getRecordsByDateRange(
      startDate,
      endDate,
    );
  }

  Future<void> updateProcurementRecord(ProcurementRecord record) async {
    await DatabaseHelper.instance.updateRecord(record);
  }

  Future<void> deleteProcurementRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
  }

  Future<void> settleProcurementRecords(
    List<int> ids,
    String settleTime,
  ) async {
    await DatabaseHelper.instance.updateSettleStatus(ids, 1, settleTime);
  }

  /// 更新单个记录的清账状态
  Future<void> updateRecordSettleStatus(
    int id,
    int settleStatus,
    String? settleTime,
  ) async {
    await DatabaseHelper.instance.updateSingleSettleStatus(
      id,
      settleStatus,
      settleTime,
    );
  }

  Future<Map<String, dynamic>> getDailyFinance(String date) async {
    return await DatabaseHelper.instance.getDailyFinance(date);
  }

  /// 检查某日是否有财务记录
  Future<bool> hasDailyFinance(String date) async {
    return await DatabaseHelper.instance.hasDailyFinance(date);
  }

  Future<void> updateDailyFinance(
    String date,
    double income,
    double expense,
    double balance,
    String remark,
  ) async {
    await DatabaseHelper.instance.updateDailyFinance(
      date,
      income,
      expense,
      balance,
      remark,
    );
  }

  /// 根据品类获取最近一条采购记录（用于智能回填）
  Future<ProcurementRecord?> getLastRecordByCategory(String category) async {
    return await DatabaseHelper.instance.getLastRecordByCategory(category);
  }

  /// 获取欠款类记录（purchaseType 为 null 表示回货+赊账，settleStatus 为 null 表示全部）
  Future<List<ProcurementRecord>> getDebtRecords({
    int? purchaseType,
    int? settleStatus,
  }) async {
    return await DatabaseHelper.instance.getDebtRecords(
      purchaseType: purchaseType,
      settleStatus: settleStatus,
    );
  }

  /// 外地回货欠款总额（未结账回货金额合计）
  Future<double> getReturnGoodsDebt() async {
    final records = await DatabaseHelper.instance.getDebtRecords(
      purchaseType: PurchaseType.returnGoods,
      settleStatus: 0,
    );
    return records.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
  }

  /// 本地赊账欠款总额（未结账赊账金额合计）
  Future<double> getCreditDebt() async {
    final records = await DatabaseHelper.instance.getDebtRecords(
      purchaseType: PurchaseType.credit,
      settleStatus: 0,
    );
    return records.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
  }

  /// 获取指定日期范围内的退货记录
  Future<List<ReturnRecord>> getReturnRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await DatabaseHelper.instance.getReturnRecordsByDateRange(
      startDate,
      endDate,
    );
  }

  /// 搜索采购记录
  Future<List<ProcurementRecord>> searchProcurementRecords(String keyword) async {
    return await DatabaseHelper.instance.searchProcurementRecords(keyword);
  }

  /// 搜索退货记录
  Future<List<ReturnRecord>> searchReturnRecords(String keyword) async {
    return await DatabaseHelper.instance.searchReturnRecords(keyword);
  }

  /// 获取所有唯一的水果品类
  Future<List<String>> getAllCategories() async {
    return await DatabaseHelper.instance.getCategories();
  }

  /// 获取指定日期范围内的所有唯一水果品类（用于库存盘点）
  Future<List<String>> getCategoriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await DatabaseHelper.instance.getCategoriesByDateRange(
      startDate,
      endDate,
    );
  }

  /// 保存一份库存盘点记录（批量）
  Future<void> saveInventoryCheck(
    String sheetId,
    List<String> categories,
    String startDate,
    String endDate,
    String createdAt, {
    Map<String, String>? quantities,
  }) async {
    await DatabaseHelper.instance.saveInventoryCheck(
      sheetId,
      categories,
      startDate,
      endDate,
      createdAt,
      quantities: quantities,
    );
  }

  /// 更新某品类行的库存数量
  Future<void> updateInventoryQuantity(
    String sheetId,
    String category,
    String quantity,
  ) async {
    await DatabaseHelper.instance.updateInventoryQuantity(
      sheetId,
      category,
      quantity,
    );
  }

  /// 获取某份盘点的所有品类行
  Future<List<Map<String, dynamic>>> getInventoryCheck(String sheetId) async {
    return await DatabaseHelper.instance.getInventoryCheck(sheetId);
  }

  /// 获取所有盘点记录概要（按时间倒序）
  Future<List<Map<String, dynamic>>> getAllInventoryChecks() async {
    return await DatabaseHelper.instance.getAllInventoryChecks();
  }

  /// 删除一份盘点
  Future<void> deleteInventoryCheck(String sheetId) async {
    await DatabaseHelper.instance.deleteInventoryCheck(sheetId);
  }
}
