/// 采购类型
class PurchaseType {
  /// 本地采购（现场采购，可在每日清账页批量清账）
  static const int local = 0;
  /// 外地回货（外地发回，到货未结账，需单独结账）
  static const int returnGoods = 1;
  /// 本地赊账（本地拿货但货款未结，需单独结账）
  static const int credit = 2;

  static String label(int type) {
    switch (type) {
      case returnGoods:
        return '外地回货';
      case credit:
        return '本地赊账';
      default:
        return '本地采购';
    }
  }

  /// 是否为欠款类型（回货/赊账都需要单独结账）
  static bool isDebt(int type) => type == returnGoods || type == credit;
}

class ProcurementRecord {
  final int? id;
  final String category;
  final double quantity;
  final String unit;
  final double price;
  final double totalAmount;
  final double serviceFee;
  final String? grade;
  final String? supplierLocation;
  final String? imagePath;
  final String createTime;
  final int settleStatus;
  final String? settleTime;
  final String? remark;
  // 补单相关字段
  final int isSupplement; // 是否为补单 0=否 1=是
  final String? orderTime; // 下单时间（实际创建时间）
  /// 采购类型：0=本地采购 1=外地回货 2=本地赊账（见 PurchaseType）
  final int purchaseType;

  ProcurementRecord({
    this.id,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.totalAmount,
    this.serviceFee = 0.0,
    this.grade,
    this.supplierLocation,
    this.imagePath,
    required this.createTime,
    this.settleStatus = 0,
    this.settleTime,
    this.remark,
    this.isSupplement = 0,
    this.orderTime,
    this.purchaseType = PurchaseType.local,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'total_amount': totalAmount,
      'service_fee': serviceFee,
      'grade': grade,
      'supplier_location': supplierLocation,
      'image_path': imagePath,
      'create_time': createTime,
      'settle_status': settleStatus,
      'settle_time': settleTime,
      'remark': remark,
      'is_supplement': isSupplement,
      'order_time': orderTime,
      'is_return_goods': isReturnGoods,
      'purchase_type': purchaseType,
    };
  }

  factory ProcurementRecord.fromMap(Map<String, dynamic> map) {
    return ProcurementRecord(
      id: map['id'] as int?,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      serviceFee: (map['service_fee'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] as String?,
      supplierLocation: map['supplier_location'] as String?,
      imagePath: map['image_path'] as String?,
      createTime: map['create_time'] as String,
      settleStatus: map['settle_status'] as int? ?? 0,
      settleTime: map['settle_time'] as String?,
      remark: map['remark'] as String?,
      isSupplement: map['is_supplement'] as int? ?? 0,
      orderTime: map['order_time'] as String?,
      // 优先用新的 purchase_type，旧数据回退到 is_return_goods
      purchaseType:
          (map['purchase_type'] as int?) ??
          (map['is_return_goods'] as int? ?? 0),
    );
  }

  /// 是否为补单
  bool get isSupplementRecord => isSupplement == 1;

  /// 是否为外地回货（到货未结账）
  bool get isReturnGoodsRecord => purchaseType == PurchaseType.returnGoods;

  /// 是否为本地赊账（货款未结）
  bool get isCreditRecord => purchaseType == PurchaseType.credit;

  /// 是否为欠款类型（回货/赊账，需单独结账）
  bool get isDebtRecord => PurchaseType.isDebt(purchaseType);

  /// 是否为外地回货（兼容旧字段读取）
  int get isReturnGoods => purchaseType;

  /// 复制并修改部分字段
  ProcurementRecord copyWith({
    int? id,
    String? category,
    double? quantity,
    String? unit,
    double? price,
    double? totalAmount,
    double? serviceFee,
    String? grade,
    String? supplierLocation,
    String? imagePath,
    String? createTime,
    int? settleStatus,
    String? settleTime,
    String? remark,
    int? isSupplement,
    String? orderTime,
    int? purchaseType,
  }) {
    return ProcurementRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      grade: grade ?? this.grade,
      supplierLocation: supplierLocation ?? this.supplierLocation,
      imagePath: imagePath ?? this.imagePath,
      createTime: createTime ?? this.createTime,
      settleStatus: settleStatus ?? this.settleStatus,
      settleTime: settleTime ?? this.settleTime,
      remark: remark ?? this.remark,
      isSupplement: isSupplement ?? this.isSupplement,
      orderTime: orderTime ?? this.orderTime,
      purchaseType: purchaseType ?? this.purchaseType,
    );
  }
}
