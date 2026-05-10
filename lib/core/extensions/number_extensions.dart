import 'package:intl/intl.dart';

/// 数字扩展方法
extension NumberExtension on num {
  /// 格式化为货币（保留2位小数）
  String get formatCurrency {
    return NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    ).format(this);
  }
  
  /// 格式化为金额（不带符号）
  String get formatMoney {
    return NumberFormat('#,##0.00').format(this);
  }
  
  /// 格式化为整数金额
  String get formatMoneyInt {
    return NumberFormat('#,##0').format(this);
  }
  
  /// 格式化为百分比
  String toPercent([int decimalDigits = 2]) {
    return '${(this * 100).toStringAsFixed(decimalDigits)}%';
  }
  
  /// 千分位格式化
  String get formatWithComma {
    return NumberFormat('#,###').format(this);
  }
  
  /// 限制小数位
  String toFixed(int digits) {
    return toStringAsFixed(digits);
  }
}

/// 双精度浮点数扩展
extension DoubleExtension on double {
  /// 是否为0
  bool get isZero => this == 0.0;
  
  /// 是否大于0
  bool get isPositive => this > 0;
  
  /// 是否小于0
  bool get isNegative => this < 0;
  
  /// 四舍五入到整数
  int get roundInt => round();
  
  /// 向下取整
  int get floorInt => floor();
  
  /// 向上取整
  int get ceilInt => ceil();
}

/// 整数扩展
extension IntExtension on int {
  /// 格式化为带单位的数字
  String get formatCompact {
    if (this >= 100000000) {
      return '${(this / 100000000).toStringAsFixed(1)}亿';
    } else if (this >= 10000) {
      return '${(this / 10000).toStringAsFixed(1)}万';
    } else {
      return toString();
    }
  }
}
