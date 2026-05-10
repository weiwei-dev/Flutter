import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../controller/analysis_controller.dart';

/// 趋势组合图表 - 柱状图展示金额，折线图展示数量
class TrendComboChart extends StatelessWidget {
  final List<DailyStat> dailyStats;

  const TrendComboChart({super.key, required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 最多显示30天数据
    final displayStats = dailyStats.length > 30
        ? dailyStats.sublist(dailyStats.length - 30)
        : dailyStats;

    final maxAmount = displayStats
        .map((e) => e.totalAmount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('金额(¥)', const Color(0xFF42A5F5)),
            const SizedBox(width: 24),
            _buildLegendItem('笔数', const Color(0xFF66BB6A)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = displayStats[groupIndex];
                    return BarTooltipItem(
                      '${stat.date}\n金额: ¥${stat.totalAmount.toStringAsFixed(0)}\n笔数: ${stat.count}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= displayStats.length) {
                        return const SizedBox.shrink();
                      }
                      // 只显示部分日期避免拥挤
                      if (displayStats.length > 10 && index % 3 != 0) {
                        return const SizedBox.shrink();
                      }
                      final date = displayStats[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          date.substring(5), // MM-DD
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '¥${(value / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: displayStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: stat.totalAmount,
                      color: const Color(0xFF42A5F5),
                      width: displayStats.length > 15 ? 4 : 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// 饼图 - 成本结构
class CostPieChart extends StatelessWidget {
  final List<CategoryStat> categoryStats;

  const CostPieChart({super.key, required this.categoryStats});

  @override
  Widget build(BuildContext context) {
    if (categoryStats.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 只显示前6个，其他归为其他
    final displayStats = categoryStats.length > 6
        ? categoryStats.sublist(0, 6)
        : categoryStats;

    double otherAmount = 0;
    if (categoryStats.length > 6) {
      otherAmount = categoryStats
          .sublist(6)
          .fold(0.0, (sum, s) => sum + s.totalAmount);
    }

    final colors = [
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF26C6DA),
      Colors.grey.shade400,
    ];

    final totalAmount = categoryStats.fold(
      0.0,
      (sum, s) => sum + s.totalAmount,
    );

    return Row(
      children: [
        // 饼图
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  ...displayStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final percentage = totalAmount > 0
                        ? stat.totalAmount / totalAmount
                        : 0;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: stat.totalAmount,
                      title: percentage > 0.1
                          ? '${(percentage * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  if (otherAmount > 0)
                    PieChartSectionData(
                      color: colors[6],
                      value: otherAmount,
                      title: '',
                      radius: 60,
                    ),
                ],
              ),
            ),
          ),
        ),
        // 图例
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...displayStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return _buildPieLegendItem(
                  stat.category,
                  colors[index % colors.length],
                  stat.totalAmount,
                  totalAmount,
                );
              }),
              if (otherAmount > 0)
                _buildPieLegendItem('其他', colors[6], otherAmount, totalAmount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegendItem(
    String label,
    Color color,
    double amount,
    double total,
  ) {
    final percentage = total > 0 ? amount / total : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% · ¥${amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 水平条形图 - Top榜
class TopBarChart extends StatelessWidget {
  final List<CategoryStat> categoryStats;
  final bool showAmount; // true显示金额，false显示数量

  const TopBarChart({
    super.key,
    required this.categoryStats,
    this.showAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryStats.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 只显示前8个
    final displayStats = categoryStats.length > 8
        ? categoryStats.sublist(0, 8)
        : categoryStats;

    final maxValue = showAmount
        ? displayStats.map((e) => e.totalAmount).reduce((a, b) => a > b ? a : b)
        : displayStats
              .map((e) => e.count.toDouble())
              .reduce((a, b) => a > b ? a : b);

    final colors = [
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF26C6DA),
      const Color(0xFFD4E157),
      const Color(0xFFFF7043),
    ];

    return Column(
      children: displayStats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        final value = showAmount ? stat.totalAmount : stat.count.toDouble();
        final percentage = maxValue > 0 ? value / maxValue : 0;
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // 排名
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: index < 3 ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 品类名称
              SizedBox(
                width: 70,
                child: Text(
                  stat.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 进度条
              Expanded(
                child: Stack(
                  children: [
                    // 背景
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // 进度
                    Container(
                      height: 16,
                      width:
                          percentage * MediaQuery.of(context).size.width * 0.35,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 数值
              Text(
                showAmount
                    ? '¥${value.toStringAsFixed(0)}'
                    : '${value.toInt()}笔',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 折线图 - 单价趋势
class PriceTrendLineChart extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> priceData;

  const PriceTrendLineChart({super.key, required this.priceData});

  @override
  Widget build(BuildContext context) {
    if (priceData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final colors = [
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
    ];

    // 获取所有日期
    final allDates = <String>{};
    for (final data in priceData.values) {
      for (final item in data) {
        allDates.add(item['date'] as String);
      }
    }
    final sortedDates = allDates.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 计算Y轴范围
    double minPrice = double.infinity;
    double maxPrice = 0;
    for (final data in priceData.values) {
      for (final item in data) {
        final price = item['avgPrice'] as double;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
    }
    final priceRange = maxPrice - minPrice;
    final yMin = minPrice - priceRange * 0.1;
    final yMax = maxPrice + priceRange * 0.1;

    return Column(
      children: [
        // 图例
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: priceData.keys.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return _buildLegendItem(category, colors[index % colors.length]);
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (yMax - yMin) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedDates.length) {
                        return const SizedBox.shrink();
                      }
                      // 只显示部分日期
                      if (sortedDates.length > 8 && index % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      final date = sortedDates[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          date.substring(5), // MM-DD
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '¥${value.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: priceData.entries.toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final data = entry.value.value;

                // 构建日期到价格的映射
                final priceMap = {
                  for (var item in data)
                    item['date'] as String: item['avgPrice'] as double,
                };

                return LineChartBarData(
                  spots: sortedDates
                      .asMap()
                      .entries
                      .map((e) {
                        final dateIndex = e.key;
                        final date = e.value;
                        final price = priceMap[date] ?? 0;
                        return FlSpot(dateIndex.toDouble(), price);
                      })
                      .where((spot) => spot.y > 0)
                      .toList(),
                  isCurved: true,
                  color: colors[index % colors.length],
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: sortedDates.length <= 15,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: colors[index % colors.length],
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colors[index % colors.length].withValues(alpha: 0.1),
                  ),
                );
              }).toList(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = sortedDates[spot.x.toInt()];
                      return LineTooltipItem(
                        '$date\n¥${spot.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// 图表卡片容器
class ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final double? height;

  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TDTheme.of(context).brandNormalColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (height != null) SizedBox(height: height, child: child) else child,
        ],
      ),
    );
  }
}
