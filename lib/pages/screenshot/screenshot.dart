import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../components/tab_bar.dart';
import '../../services/screenshot_service.dart';
import '../../utils/db.dart';
import '../../models/procurement.dart';
import '../../models/return_record.dart';

class ScreenshotPage extends StatefulWidget {
  final String? initialDate;

  const ScreenshotPage({super.key, this.initialDate});

  @override
  State<ScreenshotPage> createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isCapturing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 选中的日期，默认为今天
  DateTime _selectedDate = DateTime.now();

  // 数据
  List<ProcurementRecord> _procurementRecords = [];
  List<ReturnRecord> _returnRecords = [];
  int _recordCount = 0;
  double _totalAmount = 0;
  double _procurementTotal = 0;
  double _returnTotal = 0;
  double _todayIncome = 0;
  double _todayBalance = 0;
  bool _isLoading = false;

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

    // 如果有初始日期，则设置
    final initialDate = widget.initialDate;
    if (initialDate != null) {
      _selectedDate = DateTime.parse(initialDate);
    }

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载选中日期的数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startDate = '$dateStr 00:00:00';
      final endDate = '$dateStr 23:59:59';

      // 获取当天的采购记录
      final records = await DatabaseHelper.instance.getRecordsByDateRange(
        startDate,
        endDate,
      );

      // 获取当天的退货记录
      final returnRecords = await DatabaseHelper.instance
          .getReturnRecordsByDateRange(startDate, endDate);

      // 计算总数
      final totalCount = records.length + returnRecords.length;

      // 计算总金额（采购金额 - 退货金额）
      double procurementTotal = 0;
      double settledTotal = 0; // 已清账金额
      for (var record in records) {
        procurementTotal += record.totalAmount;
        if (record.settleStatus == 1) {
          settledTotal += record.totalAmount;
        }
      }

      double returnTotal = 0;
      for (var record in returnRecords) {
        returnTotal += record.totalAmount;
      }

      final netAmount = procurementTotal - returnTotal;

      // 获取当日财务数据（入账和结余）
      final financeData = await DatabaseHelper.instance.getDailyFinance(
        dateStr,
      );
      final todayIncome = (financeData['income'] as num?)?.toDouble() ?? 0;
      // 结余 = 入账 - 出账 + 退货（反映实际现金结余，只算已清账的）
      final todayBalance = todayIncome - settledTotal + returnTotal;

      setState(() {
        _procurementRecords = records;
        _returnRecords = returnRecords;
        _recordCount = totalCount;
        _totalAmount = netAmount;
        _procurementTotal = procurementTotal;
        _returnTotal = returnTotal;
        _todayIncome = todayIncome;
        _todayBalance = todayBalance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TDToast.showText('加载数据失败: $e', context: context);
      }
    }
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    var selectedDate = _selectedDate;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 480,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Expanded(
                child: TDCalendar(
                  title: '选择日期',
                  type: CalendarType.single,
                  minDate: firstDate.millisecondsSinceEpoch,
                  maxDate: lastDate.millisecondsSinceEpoch,
                  value: [selectedDate.millisecondsSinceEpoch],
                  onChange: (value) {
                    if (value.isNotEmpty) {
                      selectedDate = DateTime.fromMillisecondsSinceEpoch(
                        value[0],
                      );
                    }
                  },
                  cellHeight: 44,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TDButton(
                        text: '取消',
                        size: TDButtonSize.large,
                        type: TDButtonType.outline,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TDButton(
                        text: '确定',
                        size: TDButtonSize.large,
                        type: TDButtonType.fill,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // 更新选中的日期并重新加载数据
    if (selectedDate != _selectedDate) {
      setState(() => _selectedDate = selectedDate);
      await _loadData();
    }
  }

  Future<void> _captureScreenshot() async {
    setState(() => _isCapturing = true);

    try {
      final imageBytes = await ScreenshotService.instance.captureWidget(
        _screenshotKey,
      );
      if (imageBytes != null) {
        final filename =
            'screenshot_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

        // 保存到应用目录
        final path = await ScreenshotService.instance.saveScreenshot(
          imageBytes,
          filename,
        );

        // 保存到相册
        final savedToGallery = await ScreenshotService.instance.saveToGallery(
          imageBytes,
          fileName: filename,
        );

        if (mounted) {
          if (savedToGallery && path != null) {
            TDToast.showSuccess('截图已保存到相册', context: context);
          } else if (path != null) {
            TDToast.showSuccess('截图保存成功（未保存到相册）', context: context);
          } else {
            TDToast.showText('截图保存失败', context: context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('截图失败: $e', context: context);
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          TDText(
                            '截图功能',
                            font: TDTheme.of(context).fontTitleMedium,
                            textColor: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TDText(
                        '截取当前页面保存为图片',
                        font: Font(size: 12, lineHeight: 16),
                        textColor: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 日期选择器
                    GestureDetector(
                      onTap: _isLoading ? null : _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              TDIcons.calendar,
                              size: 18,
                              color: TDTheme.of(context).brandNormalColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '选择日期',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TDTheme.of(context).brandNormalColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              TDIcons.chevron_right,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 截图预览区域（包含详细记录）
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: RepaintBoundary(
                          key: _screenshotKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TDTheme.of(
                                  context,
                                ).brandNormalColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // 头部信息
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: TDTheme.of(context)
                                              .brandNormalColor
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          TDIcons.image,
                                          size: 32,
                                          color: TDTheme.of(
                                            context,
                                          ).brandNormalColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TDText(
                                        '${DateFormat('yyyy年MM月dd日').format(_selectedDate)} 财货详情',
                                        font: Font(size: 13, lineHeight: 16),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const SizedBox(height: 3),
                                      TDText(
                                        '采购与退货记录汇总',
                                        font: Font(size: 11, lineHeight: 14),
                                        textColor: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildPreviewItem(
                                              TDIcons.calendar,
                                              '日期',
                                              DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(_selectedDate),
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.file_1,
                                              '记录数',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '$_recordCount 条',
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.cart,
                                              '采购金额',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '¥${_procurementTotal.toStringAsFixed(2)}',
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.rollback,
                                              '退货金额',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '-¥${_returnTotal.toStringAsFixed(2)}',
                                              valueColor: Colors.red,
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.money,
                                              '总金额',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '¥${_totalAmount.toStringAsFixed(2)}',
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.wallet,
                                              '今日入账',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '¥${_todayIncome.toStringAsFixed(2)}',
                                              valueColor: Colors.green,
                                            ),
                                            const Divider(height: 8),
                                            _buildPreviewItem(
                                              TDIcons.chart_pie,
                                              '今日结余',
                                              _isLoading
                                                  ? '加载中...'
                                                  : '¥${_todayBalance.toStringAsFixed(2)}',
                                              valueColor: _todayBalance >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 详细记录列表
                                if (_isLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_procurementRecords.isEmpty &&
                                    _returnRecords.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(
                                          TDIcons.file_1,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '暂无记录',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  // 采购记录列表
                                  if (_procurementRecords.isNotEmpty) ...[
                                    _buildSectionHeader('采购记录', TDIcons.cart),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      itemCount: _procurementRecords.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        return _ProcurementRecordItem(
                                          record: _procurementRecords[index],
                                          index: index + 1,
                                        );
                                      },
                                    ),
                                  ],
                                  // 退货记录列表
                                  if (_returnRecords.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      '退货记录',
                                      TDIcons.rollback,
                                    ),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      itemCount: _returnRecords.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        return _ReturnRecordItem(
                                          record: _returnRecords[index],
                                          index: index + 1,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 截图按钮
                    TDButton(
                      text: _isCapturing ? '截图中...' : '截取当前页面',
                      size: TDButtonSize.large,
                      style: TDButtonStyle(
                        backgroundColor: _isCapturing
                            ? TDTheme.of(
                                context,
                              ).brandNormalColor.withValues(alpha: 0.6)
                            : TDTheme.of(context).brandNormalColor,
                        textColor: Colors.white,
                      ),
                      icon: _isCapturing ? TDIcons.loading : TDIcons.camera,
                      isBlock: true,
                      disabled: _isCapturing,
                      onTap: _isCapturing ? null : _captureScreenshot,
                    ),
                    const SizedBox(height: 12),
                    // 查看历史按钮
                    TDButton(
                      text: '查看历史截图',
                      size: TDButtonSize.large,
                      type: TDButtonType.outline,
                      theme: TDButtonTheme.primary,
                      style: TDButtonStyle(
                        backgroundColor: Colors.transparent,
                        textColor: TDTheme.of(context).brandNormalColor,
                      ),
                      icon: TDIcons.history,
                      isBlock: true,
                      onTap: () =>
                          Navigator.pushNamed(context, '/image_history'),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 3),
    );
  }

  Widget _buildPreviewItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            icon,
            size: 11,
            color: TDTheme.of(context).brandNormalColor,
          ),
        ),
        const SizedBox(width: 6),
        TDText(
          label,
          font: Font(size: 10, lineHeight: 12),
          textColor: Colors.grey.shade600,
        ),
        const Spacer(),
        TDText(
          value,
          font: Font(size: 10, lineHeight: 12),
          fontWeight: FontWeight.w600,
          textColor: valueColor,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.1),
          ),
          bottom: BorderSide(
            color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: TDTheme.of(context).brandNormalColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TDTheme.of(context).brandNormalColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: TDTheme.of(
                context,
              ).brandNormalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title == '采购记录'
                  ? '${_procurementRecords.length} 条'
                  : '${_returnRecords.length} 条',
              style: TextStyle(
                fontSize: 10,
                color: TDTheme.of(context).brandNormalColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 采购记录列表项
class _ProcurementRecordItem extends StatelessWidget {
  final ProcurementRecord record;
  final int index;

  const _ProcurementRecordItem({required this.record, required this.index});

  /// 显示图片预览弹窗
  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = record.settleStatus == 1;
    final hasImage = record.imagePath != null && record.imagePath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSettled
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSettled ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 图片区域（大尺寸）
          if (hasImage) ...[
            GestureDetector(
              onTap: () => _showImagePreview(context, record.imagePath!),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(record.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          TDIcons.image_error,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // 内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '¥${record.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TDTag(
                      isSettled ? '已清账' : '未清账',
                      theme: isSettled
                          ? TDTagTheme.success
                          : TDTagTheme.warning,
                      size: TDTagSize.small,
                    ),
                    // 补单标记
                    if (record.isSupplement == 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAB47BC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFFAB47BC,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          '补入',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFAB47BC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      TDIcons.calculation,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${record.quantity}${record.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(TDIcons.money, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      '¥${record.price}/${record.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // 服务费显示
                    if (record.serviceFee > 0) ...[
                      const SizedBox(width: 8),
                      Icon(
                        TDIcons.service,
                        size: 11,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '服务费: ¥${record.serviceFee}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (record.grade != null && record.grade!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(TDIcons.star, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '规格: ${record.grade}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (record.supplierLocation != null &&
                    record.supplierLocation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        TDIcons.location,
                        size: 11,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          record.supplierLocation!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 退货记录列表项
class _ReturnRecordItem extends StatelessWidget {
  final ReturnRecord record;
  final int index;

  const _ReturnRecordItem({required this.record, required this.index});

  static const List<String> _reasons = ['质量问题', '包装破损', '数量不符', '其他原因'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '-¥${record.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TDTag(
                      '退货',
                      theme: TDTagTheme.danger,
                      size: TDTagSize.small,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      TDIcons.calculation,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${record.quantity}${record.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(TDIcons.money, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      '¥${record.price}/${record.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (record.grade != null && record.grade!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(TDIcons.star, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '规格: ${record.grade}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      TDIcons.info_circle,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '原因: ${_reasons[record.returnReason]}${record.remark != null && record.remark!.isNotEmpty ? ' - ${record.remark}' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
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
}
