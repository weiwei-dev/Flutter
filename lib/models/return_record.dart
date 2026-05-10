import 'package:flutter/material.dart';

class ReturnRecord {
  final int? id;
  final String category;
  final double quantity;
  final String unit;
  final double price;
  final double totalAmount;
  final String? grade;
  final String? supplierLocation;
  final String? imagePath;
  final String returnTime;
  final String? originalRecordTime;
  final String? remark;
  final int returnReason;
  final int status;

  ReturnRecord({
    this.id,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.totalAmount,
    this.grade,
    this.supplierLocation,
    this.imagePath,
    required this.returnTime,
    this.originalRecordTime,
    this.remark,
    this.returnReason = 0,
    this.status = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'total_amount': totalAmount,
      'grade': grade,
      'supplier_location': supplierLocation,
      'image_path': imagePath,
      'return_time': returnTime,
      'original_record_time': originalRecordTime,
      'remark': remark,
      'return_reason': returnReason,
      'status': status,
    };
  }

  factory ReturnRecord.fromMap(Map<String, dynamic> map) {
    return ReturnRecord(
      id: map['id'] as int?,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      grade: map['grade'] as String?,
      supplierLocation: map['supplier_location'] as String?,
      imagePath: map['image_path'] as String?,
      returnTime: map['return_time'] as String,
      originalRecordTime: map['original_record_time'] as String?,
      remark: map['remark'] as String?,
      returnReason: map['return_reason'] as int? ?? 0,
      status: map['status'] as int? ?? 0,
    );
  }

  /// 复制并修改某些字段
  ReturnRecord copyWith({
    int? id,
    String? category,
    double? quantity,
    String? unit,
    double? price,
    double? totalAmount,
    String? grade,
    String? supplierLocation,
    String? imagePath,
    String? returnTime,
    String? originalRecordTime,
    String? remark,
    int? returnReason,
    int? status,
  }) {
    return ReturnRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      grade: grade ?? this.grade,
      supplierLocation: supplierLocation ?? this.supplierLocation,
      imagePath: imagePath ?? this.imagePath,
      returnTime: returnTime ?? this.returnTime,
      originalRecordTime: originalRecordTime ?? this.originalRecordTime,
      remark: remark ?? this.remark,
      returnReason: returnReason ?? this.returnReason,
      status: status ?? this.status,
    );
  }
}

/// 退货原因枚举
enum ReturnReason {
  qualityIssue(0, '质量问题'),
  wrongProduct(1, '货物不符'),
  damaged(2, '包装破损'),
  expired(3, '过期变质'),
  customerCancel(4, '客户取消'),
  other(5, '其他原因');

  final int value;
  final String label;

  const ReturnReason(this.value, this.label);

  static ReturnReason fromValue(int value) {
    return ReturnReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnReason.other,
    );
  }
}

/// 退货状态枚举
enum ReturnStatus {
  pending(0, '未退货', Color(0xFFFFA726)),
  processing(1, '处理中', Color(0xFF42A5F5)),
  returned(2, '已退货', Color(0xFF66BB6A)),
  completed(3, '已结束', Color(0xFF9E9E9E));

  final int value;
  final String label;
  final Color color;

  const ReturnStatus(this.value, this.label, this.color);

  static ReturnStatus fromValue(int value) {
    return ReturnStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnStatus.pending,
    );
  }
}
