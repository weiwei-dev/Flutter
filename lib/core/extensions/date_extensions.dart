import 'package:intl/intl.dart';

/// DateTime 扩展方法
extension DateTimeExtension on DateTime {
  /// 格式化为 yyyy-MM-dd
  String get formatDate => DateFormat('yyyy-MM-dd').format(this);
  
  /// 格式化为 yyyy-MM-dd HH:mm:ss
  String get formatDateTime => DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  
  /// 格式化为 HH:mm
  String get formatTime => DateFormat('HH:mm').format(this);
  
  /// 格式化为 yyyy年MM月dd日
  String get formatChineseDate => DateFormat('yyyy年MM月dd日').format(this);
  
  /// 获取毫秒时间戳
  int get timestamp => millisecondsSinceEpoch;
  
  /// 是否为今天
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// 是否为昨天
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  /// 获取星期几（中文）
  String get weekdayChinese {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
  
  /// 获取月初
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// 获取月末
  DateTime get endOfMonth => DateTime(year, month + 1, 0);
  
  /// 添加天数
  DateTime addDays(int days) => add(Duration(days: days));
  
  /// 添加月份
  DateTime addMonths(int months) {
    return DateTime(year, month + months, day);
  }
}

/// String 日期扩展
extension DateStringExtension on String {
  /// 解析为 DateTime
  DateTime? get parseDateTime {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }
  
  /// 解析为日期（仅 yyyy-MM-dd 部分）
  DateTime? get parseDate {
    try {
      return DateFormat('yyyy-MM-dd').parse(this);
    } catch (e) {
      return null;
    }
  }
}
