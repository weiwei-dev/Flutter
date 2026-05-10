import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/screenshot_service.dart';

/// 截图文件信息
class ScreenshotInfo {
  final File file;
  final DateTime dateTime;

  ScreenshotInfo({required this.file, required this.dateTime});
}

class ImageHistoryPage extends StatefulWidget {
  const ImageHistoryPage({super.key});

  @override
  State<ImageHistoryPage> createState() => _ImageHistoryPageState();
}

class _ImageHistoryPageState extends State<ImageHistoryPage>
    with SingleTickerProviderStateMixin {
  List<ScreenshotInfo> _allScreenshots = [];
  List<ScreenshotInfo> _filteredScreenshots = [];
  bool _isLoading = true;

  // 日期筛选
  DateTime? _selectedDate;

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
    _loadScreenshots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 从文件名解析日期
  DateTime? _parseDateFromFilename(String filename) {
    try {
      // 格式: screenshot_20240420_143022.png
      final regex = RegExp(r'screenshot_(\d{8})_(\d{6})');
      final match = regex.firstMatch(filename);
      if (match != null) {
        final dateStr = match.group(1)!;
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(4, 6));
        final day = int.parse(dateStr.substring(6, 8));
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('解析日期失败: $e');
    }
    return null;
  }

  Future<void> _loadScreenshots() async {
    setState(() => _isLoading = true);
    try {
      final files = await ScreenshotService.instance.getScreenshots();
      final screenshots = <ScreenshotInfo>[];

      for (var file in files) {
        final dateTime =
            _parseDateFromFilename(file.path.split('/').last) ??
            file.lastModifiedSync();
        screenshots.add(ScreenshotInfo(file: file, dateTime: dateTime));
      }

      // 按日期倒序排列
      screenshots.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        _allScreenshots = screenshots;
        _filteredScreenshots = screenshots;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('加载截图失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 选择日期筛选
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    var selectedDate = _selectedDate ?? now;
    // 标记是否是重置操作
    var isReset = false;

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
                        text: '重置',
                        size: TDButtonSize.large,
                        type: TDButtonType.outline,
                        onTap: () {
                          isReset = true;
                          Navigator.pop(context);
                        },
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

    // 处理结果
    if (isReset) {
      // 重置操作
      setState(() {
        _selectedDate = null;
        _filteredScreenshots = _allScreenshots;
      });
    } else if (selectedDate != _selectedDate ||
        (_selectedDate == null && selectedDate != now)) {
      // 确定操作 - 应用日期筛选
      setState(() {
        _selectedDate = selectedDate;
        _filterByDate(selectedDate);
      });
    }
  }

  /// 按日期筛选
  void _filterByDate(DateTime date) {
    final filtered = _allScreenshots.where((screenshot) {
      return screenshot.dateTime.year == date.year &&
          screenshot.dateTime.month == date.month &&
          screenshot.dateTime.day == date.day;
    }).toList();

    setState(() {
      _filteredScreenshots = filtered;
    });
  }

  /// 按日期分组
  Map<String, List<ScreenshotInfo>> _groupByDate() {
    final groups = <String, List<ScreenshotInfo>>{};

    for (var screenshot in _filteredScreenshots) {
      final dateKey = DateFormat('yyyy-MM-dd').format(screenshot.dateTime);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(screenshot);
    }

    return groups;
  }

  void _viewImage(ScreenshotInfo screenshot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailPage(screenshot: screenshot),
      ),
    );
  }

  Future<void> _deleteImage(ScreenshotInfo screenshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: TDTheme.of(context).errorNormalColor,
            ),
            const SizedBox(width: 8),
            const Text('删除截图'),
          ],
        ),
        content: const Text('确定要删除这张截图吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TDButton(
            text: '删除',
            size: TDButtonSize.small,
            type: TDButtonType.fill,
            theme: TDButtonTheme.danger,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await screenshot.file.delete();
        await _loadScreenshots();
        if (mounted) {
          TDToast.showSuccess('截图已删除', context: context);
        }
      } catch (e) {
        if (mounted) {
          TDToast.showText('删除失败: $e', context: context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedScreenshots = _groupByDate();
    final sortedDates = groupedScreenshots.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // 头部
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
                            '图片历史',
                            font: TDTheme.of(context).fontTitleMedium,
                            textColor: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 日期筛选按钮
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                TDIcons.calendar,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? '全部日期'
                                    : DateFormat(
                                        'yyyy年MM月dd日',
                                      ).format(_selectedDate!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                TDIcons.chevron_down,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '共 ${_filteredScreenshots.length} 张截图',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 内容区域
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredScreenshots.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TDIcons.image,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDate == null ? '暂无截图' : '该日期暂无截图',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(height: 12),
                          TDButton(
                            text: '查看全部',
                            size: TDButtonSize.small,
                            type: TDButtonType.outline,
                            onTap: () {
                              setState(() {
                                _selectedDate = null;
                                _filteredScreenshots = _allScreenshots;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverFadeTransition(
                    opacity: _fadeAnimation,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final date = sortedDates[index];
                        final screenshots = groupedScreenshots[date]!;
                        return _buildDateSection(date, screenshots);
                      }, childCount: sortedDates.length),
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// 构建日期分组区域
  Widget _buildDateSection(String date, List<ScreenshotInfo> screenshots) {
    final dateTime = DateTime.parse(date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;
    final dateText = isToday ? '今天' : DateFormat('MM月dd日').format(dateTime);
    final weekdayText = [
      '周日',
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
    ][dateTime.weekday % 7];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TDTheme.of(context).brandNormalColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                weekdayText,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${screenshots.length} 张',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        // 截图网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: screenshots.length,
          itemBuilder: (context, index) {
            return _buildImageCard(screenshots[index], index + 1);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建图片卡片
  Widget _buildImageCard(ScreenshotInfo screenshot, int index) {
    return GestureDetector(
      onTap: () => _viewImage(screenshot),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(screenshot.file, fit: BoxFit.cover),
              // 序号标签
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TDTheme.of(context).brandNormalColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // 删除按钮
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteImage(screenshot),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      TDIcons.delete,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
              // 底部提示
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TDIcons.zoom_in, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        '点击查看',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
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

/// 图片详情页面 - 支持查看原图和分享
class ImageDetailPage extends StatefulWidget {
  final ScreenshotInfo screenshot;

  const ImageDetailPage({super.key, required this.screenshot});

  @override
  State<ImageDetailPage> createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSharing = false;

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

  /// 分享图片到其它应用（原图）
  Future<void> _shareImage() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final file = widget.screenshot.file;
      if (await file.exists()) {
        // 使用 XFile 分享原图文件
        final xFile = XFile(file.path);

        await Share.shareXFiles(
          [xFile],
          text:
              '财货详情截图 - ${DateFormat('yyyy年MM月dd日').format(widget.screenshot.dateTime)}',
          subject: '水果采购系统截图',
        );
      } else {
        if (mounted) {
          TDToast.showText('图片文件不存在', context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('分享失败: $e', context: context);
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'yyyy年MM月dd日 HH:mm',
    ).format(widget.screenshot.dateTime);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          dateStr,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // 分享按钮
          IconButton(
            onPressed: _isSharing ? null : _shareImage,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.share, color: Colors.white),
            tooltip: '分享原图',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            child: Image.file(
              widget.screenshot.file,
              fit: BoxFit.contain,
              // 显示原图，不进行压缩
              cacheWidth: null,
              cacheHeight: null,
            ),
          ),
        ),
      ),
      // 底部操作栏
      bottomNavigationBar: Container(
        color: Colors.black.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 分享按钮（大）
              Expanded(
                child: TDButton(
                  text: '分享原图',
                  size: TDButtonSize.large,
                  icon: Icons.share,
                  type: TDButtonType.fill,
                  style: TDButtonStyle(
                    backgroundColor: TDTheme.of(context).brandNormalColor,
                    textColor: Colors.white,
                  ),
                  disabled: _isSharing,
                  onTap: _shareImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
