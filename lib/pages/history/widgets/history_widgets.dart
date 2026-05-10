import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/constants/app_constants.dart';

/// 日期选择卡片
class DateCard extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const DateCard({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSmall,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: AppConstants.fontNormal,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  TDIcons.calendar,
                  size: 12,
                  color: TDTheme.of(context).brandNormalColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 信息项
class InfoItem extends StatelessWidget {
  final String number;
  final String text;

  const InfoItem({
    super.key,
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: AppConstants.fontSmall,
                  fontWeight: FontWeight.bold,
                  color: TDTheme.of(context).brandNormalColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppConstants.fontMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期范围卡片
class DateRangeCard extends StatelessWidget {
  final String startDate;
  final String endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const DateRangeCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TDTheme.of(
                      context,
                    ).brandNormalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    TDIcons.calendar,
                    color: TDTheme.of(context).brandNormalColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '日期范围',
                  style: TextStyle(
                    fontSize: AppConstants.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DateCard(
                    label: '开始日期',
                    date: startDate,
                    onTap: onStartDateTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DateCard(
                    label: '结束日期',
                    date: endDate,
                    onTap: onEndDateTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 使用说明卡片
class InfoCard extends StatelessWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(
          color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                TDIcons.info_circle,
                color: TDTheme.of(context).brandNormalColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '使用说明',
                style: TextStyle(
                  fontSize: AppConstants.fontNormal,
                  fontWeight: FontWeight.w600,
                  color: TDTheme.of(context).brandNormalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const InfoItem(number: '1', text: '导出：选择日期范围，生成 Excel 报表'),
          const InfoItem(number: '2', text: '导入：选择 Excel 文件，批量导入采购记录'),
          const InfoItem(number: '3', text: '支持 采购日期、水果品类、数量、单价等字段'),
          const InfoItem(number: '4', text: '清账状态为"已清账"的记录会被标记'),
        ],
      ),
    );
  }
}

/// 导出范围显示卡片
class ExportRangeCard extends StatelessWidget {
  final String dateRange;

  const ExportRangeCard({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '导出范围',
                style: TextStyle(
                  fontSize: AppConstants.fontSmall,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                dateRange,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              TDIcons.file_export,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
