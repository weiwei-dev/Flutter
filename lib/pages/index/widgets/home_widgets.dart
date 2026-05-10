import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/procurement.dart';
import '../controller/home_controller.dart';
import '../../record_detail/record_detail.dart';

/// 统计卡片
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              height: 1.2,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷操作按钮
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 列表头部
class ListHeader extends StatelessWidget {
  const ListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            child: Text(
              '序号',
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _SortableHeader(label: '品类', field: 'category'),
          ),
          Expanded(
            flex: 2,
            child: _SortableHeader(label: '规格', field: 'grade'),
          ),
          const SizedBox(
            width: 70,
            child: _SortableHeader(
              label: '金额',
              field: 'amount',
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// 可排序表头
class _SortableHeader extends StatelessWidget {
  final String label;
  final String field;
  final bool alignRight;

  const _SortableHeader({
    required this.label,
    required this.field,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<HomeController, (String, bool)>(
      selector: (_, c) => (c.sortField, c.sortAscending),
      builder: (context, data, child) {
        final (sortField, sortAscending) = data;
        final isActive = sortField == field;

        return GestureDetector(
          onTap: () => context.read<HomeController>().onSort(field),
          child: Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                isActive
                    ? (sortAscending
                          ? TDIcons.chevron_up
                          : TDIcons.chevron_down)
                    : TDIcons.chevron_down,
                size: 10,
                color: isActive
                    ? TDTheme.of(context).brandNormalColor
                    : Colors.grey.shade400,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 记录列表项
class RecordListItem extends StatelessWidget {
  final ProcurementRecord record;
  final int index;

  const RecordListItem({super.key, required this.record, required this.index});

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailPage(recordId: record.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = record.settleStatus == 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        splashColor: TDTheme.of(
          context,
        ).brandNormalColor.withValues(alpha: 0.1),
        highlightColor: TDTheme.of(
          context,
        ).brandNormalColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSettled ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  record.category,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  record.grade ?? '-',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '¥${record.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: TDTheme.of(context).brandNormalColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 记录卡片
class RecordCard extends StatelessWidget {
  final ProcurementRecord record;

  const RecordCard({super.key, required this.record});

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailPage(recordId: record.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = record.settleStatus == 1;

    return InkWell(
      onTap: () => _navigateToDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TDTag(
                        isSettled ? '已清账' : '未清账',
                        theme: isSettled
                            ? TDTagTheme.success
                            : TDTagTheme.warning,
                        size: TDTagSize.small,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.createTime.substring(11, 16),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '¥${record.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: TDTheme.of(context).brandNormalColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    TDIcons.calculation,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${record.quantity} ${record.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(TDIcons.money, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '¥${record.price}/${record.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (record.supplierLocation != null &&
                  record.supplierLocation!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      TDIcons.location,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.supplierLocation!,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(TDIcons.file_1, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                '暂无采购记录',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TDButton(
                text: '去添加第一条记录',
                size: TDButtonSize.small,
                onTap: () => Navigator.pushNamed(context, '/entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
