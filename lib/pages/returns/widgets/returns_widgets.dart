import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/return_record.dart';

/// 退货统计卡片
class ReturnStatisticsCard extends StatelessWidget {
  final double totalAmount;
  final int recordCount;
  final int? filteredCount;

  const ReturnStatisticsCard({
    super.key,
    required this.totalAmount,
    required this.recordCount,
    this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEF5350),
              const Color(0xFFEF5350).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.assignment_return,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '退货总金额',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              filteredCount != null && filteredCount != recordCount
                  ? '显示 $recordCount / $filteredCount 笔退货记录'
                  : '共 $recordCount 笔退货记录',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 过滤器栏
class FilterBar extends StatelessWidget {
  final String dateRangeText;
  final VoidCallback onDateTap;
  final VoidCallback onRefreshTap;

  const FilterBar({
    super.key,
    required this.dateRangeText,
    required this.onDateTap,
    required this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: TDTheme.of(context).brandNormalColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateRangeText,
                    style: TextStyle(
                      fontSize: AppConstants.fontMedium,
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TDButton(
          text: '刷新',
          size: TDButtonSize.small,
          type: TDButtonType.outline,
          icon: TDIcons.refresh,
          onTap: onRefreshTap,
        ),
      ],
    );
  }
}

/// 状态筛选器
class StatusFilterBar extends StatelessWidget {
  final List<int> selectedStatuses;
  final Function(List<int>) onStatusChanged;
  final VoidCallback onReset;

  const StatusFilterBar({
    super.key,
    required this.selectedStatuses,
    required this.onStatusChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected =
        selectedStatuses.isEmpty ||
        selectedStatuses.length == ReturnStatus.values.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 全部状态按钮
          _buildFilterChip(
            label: '全部',
            isSelected: isAllSelected,
            onTap: () => onStatusChanged([]),
          ),
          const SizedBox(width: 6),
          // 各状态按钮
          ...ReturnStatus.values.map((status) {
            final isSelected = selectedStatuses.contains(status.value);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildFilterChip(
                label: status.label,
                isSelected: isSelected,
                color: status.color,
                onTap: () {
                  final newStatuses = List<int>.from(selectedStatuses);
                  if (isSelected) {
                    newStatuses.remove(status.value);
                  } else {
                    newStatuses.add(status.value);
                  }
                  onStatusChanged(newStatuses);
                },
              ),
            );
          }),
          // 重置按钮
          if (!isAllSelected) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Text(
                      '重置',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    // 基础颜色
    final baseColor = color ?? const Color(0xFF42A5F5);

    // 选中状态：深色背景 + 白色文字
    // 未选中状态：浅色背景 + 灰色文字
    final bgColor = isSelected ? baseColor : Colors.grey.shade100;
    final textColor = isSelected
        ? Colors.white
        : (color ?? Colors.grey.shade600);
    final borderColor = isSelected ? baseColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 12, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 退货记录卡片
class ReturnRecordCard extends StatelessWidget {
  final ReturnRecord record;
  final VoidCallback onTap;
  final VoidCallback? onStatusChange;

  const ReturnRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final reason = ReturnReason.fromValue(record.returnReason);
    final status = ReturnStatus.fromValue(record.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 退货原因标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reason.label,
                      style: const TextStyle(
                        fontSize: AppConstants.fontSmall,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 状态标签（可点击）
                  GestureDetector(
                    onTap: onStatusChange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: AppConstants.fontSmall,
                              color: status.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (onStatusChange != null) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: status.color,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    record.returnTime.length >= 16
                        ? record.returnTime.substring(0, 16)
                        : record.returnTime,
                    style: TextStyle(
                      fontSize: AppConstants.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.category,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (record.grade != null && record.grade!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '规格: ${record.grade}',
                              style: TextStyle(
                                fontSize: AppConstants.fontSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-¥${record.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                      Text(
                        '${record.quantity}${record.unit} × ¥${record.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppConstants.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (record.supplierLocation != null &&
                  record.supplierLocation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.supplierLocation!,
                        style: TextStyle(
                          fontSize: AppConstants.fontSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (record.remark != null && record.remark!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '备注: ${record.remark}',
                    style: TextStyle(
                      fontSize: AppConstants.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态
class EmptyReturnsState extends StatelessWidget {
  const EmptyReturnsState({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '暂无退货记录',
              style: TextStyle(
                fontSize: AppConstants.fontLarge,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加退货记录',
              style: TextStyle(
                fontSize: AppConstants.fontMedium,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 详情弹窗
class ReturnDetailSheet extends StatelessWidget {
  final ReturnRecord record;
  final VoidCallback onDelete;

  const ReturnDetailSheet({
    super.key,
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final reason = ReturnReason.fromValue(record.returnReason);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reason.label,
                        style: const TextStyle(
                          fontSize: AppConstants.fontNormal,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      record.returnTime,
                      style: TextStyle(
                        fontSize: AppConstants.fontNormal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('水果品类', record.category),
                _buildDetailRow('规格等级', record.grade ?? '未填写'),
                _buildDetailRow('退货数量', '${record.quantity} ${record.unit}'),
                _buildDetailRow('单价', '¥${record.price.toStringAsFixed(2)}'),
                _buildDetailRow(
                  '退货金额',
                  '¥${record.totalAmount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFEF5350),
                ),
                _buildDetailRow('供应商位置', record.supplierLocation ?? '未填写'),
                _buildDetailRow('备注', record.remark ?? '无'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TDButton(
                        text: '删除',
                        size: TDButtonSize.large,
                        type: TDButtonType.outline,
                        theme: TDButtonTheme.danger,
                        isBlock: true,
                        onTap: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TDButton(
                        text: '关闭',
                        size: TDButtonSize.large,
                        type: TDButtonType.fill,
                        isBlock: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppConstants.fontNormal,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppConstants.fontNormal,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 删除确认弹窗
class DeleteConfirmDialog extends StatelessWidget {
  final String category;

  const DeleteConfirmDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定要删除这条$category的退货记录吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
