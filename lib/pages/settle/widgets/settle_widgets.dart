import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/procurement.dart';

/// 清账统计卡片
class SettleSummaryCard extends StatelessWidget {
  final double selectedAmount;
  final String selectedDate;
  final VoidCallback onDateTap;

  const SettleSummaryCard({
    super.key,
    required this.selectedAmount,
    required this.selectedDate,
    required this.onDateTap,
  });

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
                '选中待清账',
                style: TextStyle(
                  fontSize: AppConstants.fontSmall,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '¥${selectedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TDButton(
            text: selectedDate,
            size: TDButtonSize.small,
            style: TDButtonStyle(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              textColor: Colors.white,
            ),
            icon: TDIcons.calendar,
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}

/// 记录卡片
class RecordCard extends StatelessWidget {
  final ProcurementRecord record;
  final bool isSettled;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxTap;
  final VoidCallback? onCancelSettle;
  final VoidCallback? onDelete;

  const RecordCard({
    super.key,
    required this.record,
    required this.isSettled,
    required this.isSelected,
    this.onTap,
    this.onCheckboxTap,
    this.onCancelSettle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
          side: isSelected
              ? BorderSide(
                  color: TDTheme.of(context).brandNormalColor,
                  width: 2,
                )
              : isSettled
              ? BorderSide(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (!isSettled)
                GestureDetector(
                  onTap: onCheckboxTap ?? onTap,
                  child: _buildCheckbox(context),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: TDTag(
                    record.isDebtRecord ? '已结账' : '已清账',
                    theme: TDTagTheme.success,
                    size: TDTagSize.small,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.category,
                            style: const TextStyle(
                              fontSize: AppConstants.fontNormal,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (record.isDebtRecord) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: record.purchaseType == PurchaseType.credit
                                  ? const Color(0xFFFFC107)
                                  : const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.purchaseType == PurchaseType.credit
                                  ? '赊账'
                                  : '回货',
                              style: TextStyle(
                                fontSize: 10,
                                color: record.purchaseType == PurchaseType.credit
                                    ? Colors.black87
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.quantity} ${record.unit} × ¥${record.price}',
                      style: TextStyle(
                        fontSize: AppConstants.fontSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isSettled && record.settleTime != null)
                      Text(
                        '清账时间: ${record.settleTime!.substring(0, 16)}',
                        style: const TextStyle(
                          fontSize: AppConstants.fontSmall,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    // 取消清账按钮
                    if (isSettled && onCancelSettle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: onCancelSettle,
                          child: Row(
                            children: [
                              Icon(
                                TDIcons.close_circle,
                                size: 12,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '取消清账',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSmall,
                                  color: Colors.orange.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                    '¥${record.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppConstants.fontNormal,
                      color: TDTheme.of(context).brandNormalColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 删除按钮
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              TDIcons.delete,
                              size: 12,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '删除',
                              style: TextStyle(
                                fontSize: AppConstants.fontSmall,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected
            ? TDTheme.of(context).brandNormalColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected
              ? TDTheme.of(context).brandNormalColor
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(TDIcons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

/// 清账底部栏
class SettleBottomBar extends StatelessWidget {
  final int selectedCount;
  final double selectedAmount;
  final VoidCallback onSettleTap;

  const SettleBottomBar({
    super.key,
    required this.selectedCount,
    required this.selectedAmount,
    required this.onSettleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已选 $selectedCount 笔',
                    style: TextStyle(
                      fontSize: AppConstants.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '¥${selectedAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: TDTheme.of(context).brandNormalColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TDButton(
              text: '确认清账',
              size: TDButtonSize.medium,
              style: TDButtonStyle(
                backgroundColor: TDTheme.of(context).brandNormalColor,
                textColor: Colors.white,
              ),
              icon: TDIcons.check_circle,
              onTap: onSettleTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态
class EmptySettleState extends StatelessWidget {
  const EmptySettleState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(TDIcons.file_1, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                '暂无采购记录',
                style: TextStyle(
                  fontSize: AppConstants.fontNormal,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 清账确认弹窗
class SettleConfirmDialog extends StatelessWidget {
  final int count;
  final double amount;

  const SettleConfirmDialog({
    super.key,
    required this.count,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认清账'),
      content: Text(
        '确定要清账选中的 $count 条记录吗？\n清账金额：¥${amount.toStringAsFixed(2)}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            '确认',
            style: TextStyle(color: TDTheme.of(context).brandNormalColor),
          ),
        ),
      ],
    );
  }
}

/// 今日财务卡片
class TodayFinanceCard extends StatelessWidget {
  final double income; // 今日入账
  final double expense; // 今日出账（清账金额）
  final double balance; // 今日结余
  final VoidCallback? onIncomeTap;

  const TodayFinanceCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    this.onIncomeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 今日入账
          Expanded(
            child: _buildFinanceItem(
              context,
              title: '今日入账',
              amount: income,
              icon: TDIcons.add_circle,
              color: const Color(0xFF4CAF50),
              onTap: onIncomeTap,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          // 今日出账（清账金额，不可输入）
          Expanded(
            child: _buildFinanceItem(
              context,
              title: '今日出账',
              amount: expense,
              icon: TDIcons.minus_circle,
              color: const Color(0xFFFF9800),
              onTap: null,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          // 今日结余
          Expanded(
            child: _buildFinanceItem(
              context,
              title: '今日结余',
              amount: balance,
              icon: TDIcons.wallet,
              color: balance >= 0
                  ? const Color(0xFF2196F3)
                  : const Color(0xFFE53935),
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final item = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                TDIcons.edit,
                size: 9,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: item,
      );
    }
    return item;
  }
}

/// 金额输入弹窗
class AmountInputDialog extends StatefulWidget {
  final String title;
  final double initialAmount;
  final String hintText;

  const AmountInputDialog({
    super.key,
    required this.title,
    this.initialAmount = 0,
    this.hintText = '请输入金额',
  });

  @override
  State<AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<AmountInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TDInput(
        controller: _controller,
        backgroundColor: Colors.transparent,
        inputType: TextInputType.number,
        leftLabel: '金额',
        hintText: widget.hintText,
        rightBtn: Icon(
          TDIcons.money,
          size: 20,
          color: TDTheme.of(context).brandNormalColor,
        ),
        onChanged: (value) {},
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0;
            Navigator.pop(context, amount);
          },
          child: Text(
            '确认',
            style: TextStyle(color: TDTheme.of(context).brandNormalColor),
          ),
        ),
      ],
    );
  }
}
