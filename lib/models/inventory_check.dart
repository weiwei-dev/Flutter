/// 库存盘点 - 一份盘点记录的概要信息
class InventoryCheckSummary {
  final String sheetId;
  final String startDate;
  final String endDate;
  final String createdAt;
  final int itemCount;
  final int filledCount;

  InventoryCheckSummary({
    required this.sheetId,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.itemCount,
    required this.filledCount,
  });

  factory InventoryCheckSummary.fromMap(Map<String, dynamic> map) {
    return InventoryCheckSummary(
      sheetId: map['sheet_id'] as String,
      startDate: (map['start_date'] as String?) ?? '',
      endDate: (map['end_date'] as String?) ?? '',
      createdAt: (map['created_at'] as String?) ?? '',
      itemCount: (map['item_count'] as int?) ?? 0,
      filledCount: (map['filled_count'] as int?) ?? 0,
    );
  }
}

/// 库存盘点 - 单个品类行
class InventoryCheckItem {
  final String category;
  final String stockQuantity;

  InventoryCheckItem({
    required this.category,
    required this.stockQuantity,
  });

  factory InventoryCheckItem.fromMap(Map<String, dynamic> map) {
    return InventoryCheckItem(
      category: map['category'] as String,
      stockQuantity: (map['stock_quantity'] as String?) ?? '',
    );
  }
}
