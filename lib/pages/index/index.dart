import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../components/tab_bar.dart';
import '../../app/providers/procurement_provider.dart';
import '../../models/procurement.dart';
import '../entry/entry.dart';
import 'controller/home_controller.dart';
import 'widgets/home_widgets.dart';

/// 首页 - UI骨架
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ProcurementProvider>();
    await context.read<HomeController>().loadData(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          const _Header(),
          _Content(fadeAnimation: _fadeAnimation),
        ],
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 0),
    );
  }
}

/// 头部区域
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<HomeController>();

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TDTheme.of(context).brandNormalColor,
              TDTheme.of(context).brandNormalColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context, controller),
                const SizedBox(height: 10),
                const _StatCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '水果采购管理',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Selector<HomeController, String>(
          selector: (_, c) => c.selectedDate,
          builder: (context, date, child) {
            return TDButton(
              text: date,
              size: TDButtonSize.small,
              style: TDButtonStyle(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
              ),
              icon: TDIcons.calendar,
              onTap: () => _showDatePicker(context, controller),
            );
          },
        ),
      ],
    );
  }

  void _showDatePicker(BuildContext context, HomeController controller) {
    final provider = context.read<ProcurementProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DatePickerSheet(
        selectedDate: controller.selectedDate,
        onDateSelected: (date) {
          controller.selectDate(date);
          controller.loadData(provider);
        },
      ),
    );
  }
}

/// 日期选择弹窗
class _DatePickerSheet extends StatelessWidget {
  final String selectedDate;
  final ValueChanged<String> onDateSelected;

  const _DatePickerSheet({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '选择日期',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TDCalendar(
              onChange: (value) {
                if (value.isNotEmpty) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value[0]);
                  onDateSelected(DateFormat('yyyy-MM-dd').format(date));
                  Navigator.of(context).pop();
                }
              },
              value: [DateTime.parse(selectedDate).millisecondsSinceEpoch],
              minDate: DateTime(2024).millisecondsSinceEpoch,
              maxDate: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        ],
      ),
    );
  }
}

/// 统计卡片区域
class _StatCards extends StatelessWidget {
  const _StatCards();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeController, (double, double, int)>(
      selector: (_, c) => (c.totalAmount, c.totalServiceFee, c.recordCount),
      builder: (context, data, child) {
        final (totalAmount, totalServiceFee, count) = data;
        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: '采购总额',
                value: '¥${totalAmount.toStringAsFixed(2)}',
                icon: TDIcons.cart,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatCard(
                title: '服务费',
                value: '¥${totalServiceFee.toStringAsFixed(2)}',
                icon: TDIcons.bill,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: StatCard(
                title: '采购笔数',
                value: '$count',
                icon: TDIcons.file_1,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 内容区域
class _Content extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const _Content({required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: fadeAnimation,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickActions(),
              SizedBox(height: 16),
              _RecordsSection(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// 快捷操作
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: '新增采购',
                icon: TDIcons.add_circle,
                color: TDTheme.of(context).brandNormalColor,
                onTap: () => Navigator.pushNamed(context, '/entry'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                label: '补录采购',
                icon: TDIcons.edit_1,
                color: const Color(0xFFAB47BC),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EntryPage(isSupplement: true),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: '每日清账',
                icon: TDIcons.wallet,
                color: const Color(0xFFFFA726),
                onTap: () => Navigator.pushNamed(context, '/settle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                label: '历史记录',
                icon: TDIcons.history,
                color: const Color(0xFF42A5F5),
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 记录列表区域
class _RecordsSection extends StatelessWidget {
  const _RecordsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        const SizedBox(height: 10),
        Selector<HomeController, (bool, bool)>(
          selector: (_, c) => (c.isEmpty, c.isListMode),
          builder: (context, data, child) {
            final (isEmpty, isListMode) = data;

            if (isEmpty) return const EmptyState();

            return isListMode ? const _ListView() : const _CardView();
          },
        ),
      ],
    );
  }
}

/// 区域头部
class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<HomeController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '今日采购记录',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _ViewModeToggle(onToggle: controller.toggleViewMode),
            const SizedBox(width: 8),
            TDButton(
              text: '选择日期',
              size: TDButtonSize.extraSmall,
              style: TDButtonStyle(
                backgroundColor: Colors.transparent,
                textColor: TDTheme.of(context).brandNormalColor,
              ),
              icon: TDIcons.calendar,
              onTap: () => _showDatePicker(context, controller),
            ),
          ],
        ),
      ],
    );
  }

  void _showDatePicker(BuildContext context, HomeController controller) {
    final provider = context.read<ProcurementProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DatePickerSheet(
        selectedDate: controller.selectedDate,
        onDateSelected: (date) {
          controller.selectDate(date);
          controller.loadData(provider);
        },
      ),
    );
  }
}

/// 视图模式切换
class _ViewModeToggle extends StatelessWidget {
  final VoidCallback onToggle;

  const _ViewModeToggle({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeController, bool>(
      selector: (_, c) => c.isListMode,
      builder: (context, isListMode, child) {
        return GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isListMode ? TDIcons.view_list : TDIcons.view_module,
                  size: 14,
                  color: TDTheme.of(context).brandNormalColor,
                ),
                const SizedBox(width: 2),
                Text(
                  isListMode ? '列表' : '卡片',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: TDTheme.of(context).brandNormalColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 列表视图
class _ListView extends StatelessWidget {
  const _ListView();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeController, List<ProcurementRecord>>(
      selector: (_, c) => c.sortedRecords,
      builder: (context, records, child) {
        return Column(
          children: [
            const ListHeader(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, idx) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return RecordListItem(record: records[index], index: index + 1);
              },
            ),
          ],
        );
      },
    );
  }
}

/// 卡片视图
class _CardView extends StatelessWidget {
  const _CardView();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeController, List<ProcurementRecord>>(
      selector: (_, c) => c.records,
      builder: (context, records, child) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (_, idx) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return RecordCard(record: records[index]);
          },
        );
      },
    );
  }
}
