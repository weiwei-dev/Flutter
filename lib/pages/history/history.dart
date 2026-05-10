import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../components/tab_bar.dart';
import 'controller/history_controller.dart';
import 'widgets/history_widgets.dart';

/// 历史记录导出页 - UI骨架
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryController(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView>
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDatePicker(HistoryController controller, bool isStartDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _DatePickerSheet(
          isStartDate: isStartDate,
          currentDate: isStartDate ? controller.startDate : controller.endDate,
          minDate: isStartDate
              ? DateTime(2024).millisecondsSinceEpoch
              : DateTime.parse(controller.startDate).millisecondsSinceEpoch,
          maxDate: isStartDate
              ? DateTime.parse(controller.endDate).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
          onDateSelected: (date) {
            controller.selectDate(
              isStartDate,
              DateFormat('yyyy-MM-dd').format(date),
            );
          },
        );
      },
    );
  }

  Future<void> _exportExcel(HistoryController controller) async {
    final result = await controller.exportExcel();
    if (result.success && mounted) {
      TDToast.showSuccess('报表导出成功', context: context);
    } else if (!result.success && mounted) {
      TDToast.showText('导出失败: ${result.error}', context: context);
    }
  }

  Future<void> _exportAllExcel(HistoryController controller) async {
    final result = await controller.exportAllExcel();
    if (result.success && mounted) {
      TDToast.showSuccess('全部数据导出成功', context: context);
    } else if (!result.success && mounted) {
      TDToast.showText('导出失败: ${result.error}', context: context);
    }
  }

  Future<void> _importExcel(HistoryController controller) async {
    final result = await controller.importExcel();
    _showImportResult(result);
  }

  void _showImportResult(ImportResult result) {
    if (!mounted) return;

    if (result.success) {
      String message = '成功导入 ${result.successCount} 条记录';
      if (result.failCount > 0) {
        message += '，失败 ${result.failCount} 条';
      }
      TDToast.showSuccess(message, context: context);

      if (result.errors.isNotEmpty) {
        _showImportErrorDialog(result);
      }
    } else {
      TDToast.showText(result.message, context: context);
    }
  }

  void _showImportErrorDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入完成'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('成功: ${result.successCount} 条'),
              Text('失败: ${result.failCount} 条'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('错误详情:'),
                ...result.errors
                    .take(5)
                    .map(
                      (e) => Text('• $e', style: const TextStyle(fontSize: 12)),
                    ),
                if (result.errors.length > 5)
                  Text('... 还有 ${result.errors.length - 5} 条错误'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<HistoryController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildHeader(context, controller),
              _buildContent(context, controller),
            ],
          );
        },
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context, HistoryController controller) {
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
                _buildHeaderTitle(context),
                const SizedBox(height: 8),
                ExportRangeCard(dateRange: controller.dateRange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              TDIcons.chevron_left,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '历史记录导出',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, HistoryController controller) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期范围选择
              DateRangeCard(
                startDate: controller.startDate,
                endDate: controller.endDate,
                onStartDateTap: () => _showDatePicker(controller, true),
                onEndDateTap: () => _showDatePicker(controller, false),
              ),
              const SizedBox(height: 16),
              // 导出按钮（日期范围）
              _buildExportButton(controller),
              const SizedBox(height: 10),
              // 全部导出按钮
              _buildExportAllButton(controller),
              const SizedBox(height: 10),
              // 导入按钮
              _buildImportButton(controller),
              const SizedBox(height: 16),
              // 功能说明
              const InfoCard(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(HistoryController controller) {
    return TDButton(
      text: controller.isExporting ? '导出中...' : '导出 Excel 报表',
      size: TDButtonSize.large,
      style: TDButtonStyle(
        backgroundColor: controller.isExporting
            ? TDTheme.of(context).brandNormalColor.withValues(alpha: 0.6)
            : TDTheme.of(context).brandNormalColor,
        textColor: Colors.white,
      ),
      icon: controller.isExporting ? TDIcons.loading : TDIcons.download,
      isBlock: true,
      disabled: controller.isExporting,
      onTap: controller.isExporting ? null : () => _exportExcel(controller),
    );
  }

  Widget _buildExportAllButton(HistoryController controller) {
    return TDButton(
      text: controller.isExporting ? '导出中...' : '导出全部数据',
      size: TDButtonSize.large,
      type: TDButtonType.outline,
      theme: TDButtonTheme.primary,
      style: TDButtonStyle(
        backgroundColor: controller.isExporting
            ? TDTheme.of(context).brandNormalColor.withValues(alpha: 0.05)
            : Colors.transparent,
        textColor: TDTheme.of(context).brandNormalColor,
      ),
      icon: controller.isExporting ? TDIcons.loading : TDIcons.file_export,
      isBlock: true,
      disabled: controller.isExporting,
      onTap: controller.isExporting ? null : () => _exportAllExcel(controller),
    );
  }

  Widget _buildImportButton(HistoryController controller) {
    return TDButton(
      text: controller.isImporting ? '导入中...' : '导入 Excel 文件',
      size: TDButtonSize.large,
      type: TDButtonType.outline,
      theme: TDButtonTheme.primary,
      style: TDButtonStyle(
        backgroundColor: controller.isImporting
            ? TDTheme.of(context).brandNormalColor.withValues(alpha: 0.05)
            : Colors.transparent,
        textColor: TDTheme.of(context).brandNormalColor,
      ),
      icon: controller.isImporting ? TDIcons.loading : TDIcons.upload,
      isBlock: true,
      disabled: controller.isImporting,
      onTap: controller.isImporting ? null : () => _importExcel(controller),
    );
  }
}

/// 日期选择弹窗
class _DatePickerSheet extends StatelessWidget {
  final bool isStartDate;
  final String currentDate;
  final int minDate;
  final int maxDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerSheet({
    required this.isStartDate,
    required this.currentDate,
    required this.minDate,
    required this.maxDate,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              isStartDate ? '选择开始日期' : '选择结束日期',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TDCalendar(
              onChange: (value) {
                if (value.isNotEmpty) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value[0]);
                  onDateSelected(date);
                  Navigator.of(context).pop();
                }
              },
              value: [DateTime.parse(currentDate).millisecondsSinceEpoch],
              minDate: minDate,
              maxDate: maxDate,
            ),
          ),
        ],
      ),
    );
  }
}
