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
    );
  }

  /// 是否为补单
  bool get isSupplementRecord => isSupplement == 1;
}
