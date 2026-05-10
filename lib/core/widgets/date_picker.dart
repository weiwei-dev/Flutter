import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';

/// 显示应用统一的日期选择器
///
/// 使用示例：
/// ```dart
/// final date = await showAppDatePicker(context);
/// if (date != null) {
///   // 处理选择的日期
/// }
/// ```
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  final now = DateTime.now();

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TDText(
                title ?? '选择日期',
                font: TDTheme.of(context).fontTitleMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: TDCalendar(
                value: [
                  initialDate?.millisecondsSinceEpoch ??
                      now.millisecondsSinceEpoch,
                ],
                minDate: (firstDate ?? DateTime(now.year - 5))
                    .millisecondsSinceEpoch,
                maxDate:
                    (lastDate ?? DateTime(now.year + 1)).millisecondsSinceEpoch,
                onChange: (value) {
                  if (value.isNotEmpty) {
                    Navigator.pop(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(value.first),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 显示日期范围选择器
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialDateRange,
  String? startTitle,
  String? endTitle,
}) async {
  DateTime? startDate;
  DateTime? endDate;
  int currentStep = 0;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final now = DateTime.now();

          return Container(
            height: 420,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TDText(
                              startTitle ?? '开始日期',
                              font: Font(size: 12, lineHeight: 16),
                              textColor: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 4),
                            TDText(
                              startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(startDate!)
                                  : '请选择',
                              font: Font(size: 14, lineHeight: 20),
                              textColor: currentStep == 0
                                  ? TDTheme.of(context).brandNormalColor
                                  : Colors.grey.shade700,
                              fontWeight: currentStep == 0
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            TDText(
                              endTitle ?? '结束日期',
                              font: Font(size: 12, lineHeight: 16),
                              textColor: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 4),
                            TDText(
                              endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(endDate!)
                                  : '请选择',
                              font: Font(size: 14, lineHeight: 20),
                              textColor: currentStep == 1
                                  ? TDTheme.of(context).brandNormalColor
                                  : Colors.grey.shade700,
                              fontWeight: currentStep == 1
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TDCalendar(
                    value: [
                      (currentStep == 0
                          ? (startDate?.millisecondsSinceEpoch ??
                                now.millisecondsSinceEpoch)
                          : (endDate?.millisecondsSinceEpoch ??
                                startDate?.millisecondsSinceEpoch ??
                                now.millisecondsSinceEpoch)),
                    ],
                    minDate: (currentStep == 1 && startDate != null
                        ? startDate!.millisecondsSinceEpoch
                        : DateTime(now.year - 5).millisecondsSinceEpoch),
                    maxDate: DateTime(now.year + 1).millisecondsSinceEpoch,
                    onChange: (value) {
                      if (value.isNotEmpty) {
                        final selectedDate =
                            DateTime.fromMillisecondsSinceEpoch(value.first);
                        if (currentStep == 0) {
                          setState(() {
                            startDate = selectedDate;
                            currentStep = 1;
                          });
                        } else {
                          setState(() {
                            endDate = selectedDate;
                          });
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (startDate != null && endDate != null) {
    return DateTimeRange(start: startDate!, end: endDate!);
  }
  return null;
}

/// 日期选择按钮
class DatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? label;
  final IconData icon;

  const DatePickerButton({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label,
    this.icon = TDIcons.calendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);

    return GestureDetector(
      onTap: () async {
        final date = await showAppDatePicker(
          context,
          initialDate: selectedDate,
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.brandNormalColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.brandNormalColor),
            const SizedBox(width: 6),
            TDText(
              selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                  : (label ?? '选择日期'),
              font: Font(size: 12, lineHeight: 16),
              textColor: theme.brandNormalColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
