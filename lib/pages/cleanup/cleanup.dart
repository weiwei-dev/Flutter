import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/cleanup_log.dart';
import '../../models/procurement.dart';
import '../../models/return_record.dart';
import '../../services/data_cleanup_service.dart';

/// 数据清理页面
class DataCleanupPage extends StatefulWidget {
  const DataCleanupPage({super.key});

  @override
  State<DataCleanupPage> createState() => _DataCleanupPageState();
}

class _DataCleanupPageState extends State<DataCleanupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isChecking = false;
  bool _isCheckingDirty = false;

  // 重复数据检查结果
  List<List<ProcurementRecord>> _procurementDuplicateGroups = [];
  List<List<ReturnRecord>> _returnDuplicateGroups = [];

  // 脏数据检查结果
  List<ProcurementRecord> _dirtyProcurementRecords = [];
  List<ReturnRecord> _dirtyReturnRecords = [];

  // 清理日志
  List<CleanupLog> _cleanupLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCleanupLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载清理日志
  Future<void> _loadCleanupLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await DataCleanupService.instance.getCleanupLogs();
      if (mounted) {
        setState(() {
          _cleanupLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('加载日志失败: $e', context: context);
      }
    }
  }

  /// 检查重复数据
  Future<void> _checkDuplicates() async {
    setState(() => _isChecking = true);
    try {
      final procurementGroups = await DataCleanupService.instance
          .checkDuplicateProcurementRecords();
      final returnGroups = await DataCleanupService.instance
          .checkDuplicateReturnRecords();

      if (mounted) {
        setState(() {
          _procurementDuplicateGroups = procurementGroups;
          _returnDuplicateGroups = returnGroups;
          _isChecking = false;
        });

        final totalDuplicates =
            procurementGroups.fold<int>(
              0,
              (sum, group) => sum + group.length - 1,
            ) +
            returnGroups.fold<int>(0, (sum, group) => sum + group.length - 1);

        if (totalDuplicates == 0) {
          TDToast.showSuccess('未发现重复数据', context: context);
        } else {
          TDToast.showText('发现 $totalDuplicates 条重复数据', context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        TDToast.showText('检查失败: $e', context: context);
      }
    }
  }

  /// 执行清理
  Future<void> _performCleanup() async {
    final totalDuplicates =
        _procurementDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.length - 1,
        ) +
        _returnDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.length - 1,
        );

    if (totalDuplicates == 0) {
      TDToast.showText('没有需要清理的重复数据', context: context);
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发现 $totalDuplicates 条重复数据'),
            const SizedBox(height: 8),
            Text(
              '清理后将保留每组的第一条数据，删除其余重复项。清理的记录会被保存，可随时回滚恢复。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清理'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await DataCleanupService.instance.performCleanup();
      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          TDToast.showSuccess(result.message, context: context);
          // 清空检查结果并刷新日志
          setState(() {
            _procurementDuplicateGroups = [];
            _returnDuplicateGroups = [];
          });
          _loadCleanupLogs();
        } else {
          TDToast.showText(result.message, context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('清理失败: $e', context: context);
      }
    }
  }

  /// 回滚清理
  Future<void> _rollbackCleanup(CleanupLog log) async {
    if (log.isRolledBack) {
      TDToast.showText('该清理记录已回滚', context: context);
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认回滚'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('清理时间: ${_formatDateTime(log.cleanupTime)}'),
            const SizedBox(height: 8),
            Text('删除记录数: ${log.totalDeleted} 条'),
            const SizedBox(height: 8),
            Text(
              '回滚将恢复被删除的所有数据，确定要继续吗？',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认回滚'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await DataCleanupService.instance.rollbackCleanup(log.id!);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          TDToast.showSuccess(result.message, context: context);
          _loadCleanupLogs();
        } else {
          TDToast.showText(result.message, context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('回滚失败: $e', context: context);
      }
    }
  }

  /// 删除日志
  Future<void> _deleteLog(CleanupLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日志'),
        content: const Text(
          '确定要删除这条清理日志吗？\n注意：删除日志后无法回滚该次清理操作。',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await DataCleanupService.instance.deleteCleanupLog(
        log.id!,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          TDToast.showSuccess('日志已删除', context: context);
          _loadCleanupLogs();
        } else {
          TDToast.showText('删除失败', context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('删除失败: $e', context: context);
      }
    }
  }

  /// 格式化日期时间
  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 头部
          Container(
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
              child: Column(
                children: [
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            TDIcons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '数据清理',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab栏
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: '重复检测'),
                      Tab(text: '脏数据清理'),
                      Tab(text: '清理历史'),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDuplicateCheckTab(),
                _buildDirtyDataTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 重复检测 Tab
  Widget _buildDuplicateCheckTab() {
    final totalDuplicates =
        _procurementDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.length - 1,
        ) +
        _returnDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.length - 1,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 操作卡片
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 统计信息
                  if (totalDuplicates > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            TDIcons.error_circle,
                            color: const Color(0xFFEF5350),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TDText(
                                  '发现 $totalDuplicates 条重复数据',
                                  font: TDTheme.of(context).fontBodyMedium,
                                  fontWeight: FontWeight.bold,
                                  textColor: const Color(0xFFEF5350),
                                ),
                                const SizedBox(height: 4),
                                TDText(
                                  '采购重复: ${_procurementDuplicateGroups.fold<int>(0, (sum, g) => sum + g.length - 1)} 条，退货重复: ${_returnDuplicateGroups.fold<int>(0, (sum, g) => sum + g.length - 1)} 条',
                                  font: Font(size: 12, lineHeight: 16),
                                  textColor: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (!_isChecking &&
                      _procurementDuplicateGroups.isEmpty &&
                      _returnDuplicateGroups.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            TDIcons.check_circle,
                            color: const Color(0xFF26A69A),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TDText(
                                  '暂无重复数据',
                                  font: TDTheme.of(context).fontBodyMedium,
                                  fontWeight: FontWeight.bold,
                                  textColor: const Color(0xFF26A69A),
                                ),
                                const SizedBox(height: 4),
                                TDText(
                                  '系统未检测到重复导入的数据',
                                  font: Font(size: 12, lineHeight: 16),
                                  textColor: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 操作按钮
                  TDButton(
                    text: _isChecking ? '检测中...' : '检测重复数据',
                    size: TDButtonSize.large,
                    type: TDButtonType.outline,
                    theme: TDButtonTheme.primary,
                    icon: _isChecking ? null : TDIcons.search,
                    disabled: _isChecking,
                    isBlock: true,
                    onTap: _isChecking ? null : _checkDuplicates,
                  ),
                  if (totalDuplicates > 0) ...[
                    const SizedBox(height: 12),
                    TDButton(
                      text: '执行清理',
                      size: TDButtonSize.large,
                      theme: TDButtonTheme.primary,
                      icon: TDIcons.delete,
                      isBlock: true,
                      onTap: _performCleanup,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 重复数据详情
          if (_procurementDuplicateGroups.isNotEmpty) ...[
            _buildDuplicateGroupSection(
              '采购记录重复',
              _procurementDuplicateGroups,
              TDIcons.cart,
              const Color(0xFF5C6BC0),
            ),
            const SizedBox(height: 16),
          ],
          if (_returnDuplicateGroups.isNotEmpty) ...[
            _buildDuplicateGroupSection(
              '退货记录重复',
              _returnDuplicateGroups,
              TDIcons.rotation,
              const Color(0xFFFF8A65),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建重复数据分组区域
  Widget _buildDuplicateGroupSection(
    String title,
    List<List<dynamic>> groups,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TDText(
                    title,
                    font: TDTheme.of(context).fontBodyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${groups.fold<int>(0, (sum, g) => sum + g.length - 1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...groups.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              return _buildDuplicateGroupItem(index + 1, group, color);
            }),
          ],
        ),
      ),
    );
  }

  /// 检查脏数据
  Future<void> _checkDirtyData() async {
    setState(() => _isCheckingDirty = true);
    try {
      final dirtyProcurement = await DataCleanupService.instance
          .checkDirtyProcurementRecords();
      final dirtyReturns = await DataCleanupService.instance
          .checkDirtyReturnRecords();

      if (mounted) {
        setState(() {
          _dirtyProcurementRecords = dirtyProcurement;
          _dirtyReturnRecords = dirtyReturns;
          _isCheckingDirty = false;
        });

        final totalDirty = dirtyProcurement.length + dirtyReturns.length;

        if (totalDirty == 0) {
          TDToast.showSuccess('未发现脏数据', context: context);
        } else {
          TDToast.showText('发现 $totalDirty 条脏数据（异常时间）', context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingDirty = false);
        TDToast.showText('检查失败: $e', context: context);
      }
    }
  }

  /// 执行脏数据清理
  Future<void> _performDirtyCleanup() async {
    final totalDirty =
        _dirtyProcurementRecords.length + _dirtyReturnRecords.length;

    if (totalDirty == 0) {
      TDToast.showText('没有需要清理的脏数据', context: context);
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理脏数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发现 $totalDirty 条脏数据（异常时间）'),
            const SizedBox(height: 8),
            Text(
              '这些记录的创建时间异常（如1900年），通常是由于导入数据时列顺序错误导致的。清理的记录会被保存，可随时回滚恢复。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
            ),
            child: const Text('确认清理'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await DataCleanupService.instance
          .performDirtyDataCleanup();
      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          TDToast.showSuccess(result.message, context: context);
          // 清空检查结果并刷新日志
          setState(() {
            _dirtyProcurementRecords = [];
            _dirtyReturnRecords = [];
          });
          _loadCleanupLogs();
        } else {
          TDToast.showText(result.message, context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TDToast.showText('清理失败: $e', context: context);
      }
    }
  }

  /// 脏数据清理 Tab
  Widget _buildDirtyDataTab() {
    final totalDirty =
        _dirtyProcurementRecords.length + _dirtyReturnRecords.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 说明卡片
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        TDIcons.info_circle,
                        color: TDTheme.of(context).brandNormalColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      TDText(
                        '什么是脏数据？',
                        font: TDTheme.of(context).fontBodyMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TDText(
                    '脏数据是指创建时间异常（如1900年）的记录，通常是由于导入Excel时列顺序错误导致的。这些数据会影响统计和查询功能。',
                    font: Font(size: 12, lineHeight: 18),
                    textColor: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 检查结果
          if (totalDirty > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    TDIcons.error_circle,
                    color: const Color(0xFFEF5350),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TDText(
                          '发现 $totalDirty 条脏数据',
                          font: TDTheme.of(context).fontBodyMedium,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xFFEF5350),
                        ),
                        const SizedBox(height: 4),
                        TDText(
                          '采购记录: ${_dirtyProcurementRecords.length} 条，退货记录: ${_dirtyReturnRecords.length} 条',
                          font: Font(size: 12, lineHeight: 16),
                          textColor: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 脏数据列表
            if (_dirtyProcurementRecords.isNotEmpty) ...[
              _buildDirtyDataSection(
                '采购记录',
                _dirtyProcurementRecords,
                TDIcons.cart,
                const Color(0xFF5C6BC0),
              ),
              const SizedBox(height: 16),
            ],
            if (_dirtyReturnRecords.isNotEmpty) ...[
              _buildDirtyDataSection(
                '退货记录',
                _dirtyReturnRecords,
                TDIcons.rotation,
                const Color(0xFFFF8A65),
              ),
              const SizedBox(height: 16),
            ],

            // 清理按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _performDirtyCleanup,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(TDIcons.delete),
              label: Text('清理 $totalDirty 条脏数据'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (!_isCheckingDirty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    TDIcons.check_circle,
                    color: const Color(0xFF26A69A),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TDText(
                          '未发现脏数据',
                          font: TDTheme.of(context).fontBodyMedium,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xFF26A69A),
                        ),
                        const SizedBox(height: 4),
                        TDText(
                          '所有记录的时间都在正常范围内',
                          font: Font(size: 12, lineHeight: 16),
                          textColor: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 检测按钮
          ElevatedButton.icon(
            onPressed: _isCheckingDirty ? null : _checkDirtyData,
            icon: _isCheckingDirty
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(TDIcons.search),
            label: Text(_isCheckingDirty ? '检测中...' : '检测脏数据'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建脏数据分组
  Widget _buildDirtyDataSection(
    String title,
    List<dynamic> records,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TDText(
                    title,
                    font: TDTheme.of(context).fontBodyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${records.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 只显示前5条
            ...records.take(5).map((record) => _buildDirtyRecordItem(record)),
            if (records.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TDText(
                  '还有 ${records.length - 5} 条...',
                  font: Font(size: 11, lineHeight: 14),
                  textColor: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建脏数据项
  Widget _buildDirtyRecordItem(dynamic record) {
    String title;
    String timeStr;
    String subtitle;

    if (record is ProcurementRecord) {
      title = '${record.category} - ${record.quantity}${record.unit}';
      timeStr = record.createTime;
      subtitle =
          '¥${record.price.toStringAsFixed(2)} × ${record.quantity} = ¥${record.totalAmount.toStringAsFixed(2)}';
    } else if (record is ReturnRecord) {
      title = '${record.category} - ${record.quantity}${record.unit}';
      timeStr = record.returnTime;
      subtitle =
          '¥${record.price.toStringAsFixed(2)} × ${record.quantity} = ¥${record.totalAmount.toStringAsFixed(2)}';
    } else {
      title = '未知记录';
      timeStr = '';
      subtitle = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TDText(
            title,
            font: Font(size: 13, lineHeight: 18),
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 4),
          TDText(
            subtitle,
            font: Font(size: 11, lineHeight: 14),
            textColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(TDIcons.time, size: 14, color: const Color(0xFFEF5350)),
              const SizedBox(width: 4),
              TDText(
                '异常时间: $timeStr',
                font: Font(size: 11, lineHeight: 14),
                textColor: const Color(0xFFEF5350),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建重复组项
  Widget _buildDuplicateGroupItem(int index, List<dynamic> group, Color color) {
    final firstRecord = group.first;
    String title;
    String subtitle;

    if (firstRecord is ProcurementRecord) {
      title =
          '${firstRecord.category} - ${firstRecord.quantity}${firstRecord.unit}';
      subtitle =
          '¥${firstRecord.price.toStringAsFixed(2)} × ${firstRecord.quantity} = ¥${firstRecord.totalAmount.toStringAsFixed(2)}';
    } else if (firstRecord is ReturnRecord) {
      title =
          '${firstRecord.category} - ${firstRecord.quantity}${firstRecord.unit}';
      subtitle =
          '¥${firstRecord.price.toStringAsFixed(2)} × ${firstRecord.quantity} = ¥${firstRecord.totalAmount.toStringAsFixed(2)}';
    } else {
      title = '未知记录';
      subtitle = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TDText(
                  '组 $index',
                  font: Font(size: 10, lineHeight: 14),
                  textColor: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TDText(
                  title,
                  font: Font(size: 13, lineHeight: 18),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TDText(
            subtitle,
            font: Font(size: 11, lineHeight: 14),
            textColor: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(TDIcons.copy, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              TDText(
                '重复 ${group.length - 1} 条（保留第1条，删除其余）',
                font: Font(size: 11, lineHeight: 14),
                textColor: Colors.grey.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 清理历史 Tab
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: TDCircleIndicator());
    }

    if (_cleanupLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TDIcons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            TDText(
              '暂无清理记录',
              font: TDTheme.of(context).fontBodyLarge,
              textColor: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            TDText(
              '执行数据清理后，这里会显示历史记录',
              font: Font(size: 12, lineHeight: 16),
              textColor: Colors.grey.shade400,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCleanupLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cleanupLogs.length,
        itemBuilder: (context, index) {
          final log = _cleanupLogs[index];
          return _buildCleanupLogCard(log);
        },
      ),
    );
  }

  /// 构建清理日志卡片
  Widget _buildCleanupLogCard(CleanupLog log) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: log.isRolledBack
                        ? Colors.grey.shade200
                        : const Color(0xFFEF5350).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    log.isRolledBack ? TDIcons.rollback : TDIcons.delete,
                    color: log.isRolledBack
                        ? Colors.grey.shade600
                        : const Color(0xFFEF5350),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        log.isRolledBack ? '已回滚' : '数据清理',
                        font: TDTheme.of(context).fontBodyMedium,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 2),
                      TDText(
                        _formatDateTime(log.cleanupTime),
                        font: Font(size: 11, lineHeight: 14),
                        textColor: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                if (log.isRolledBack)
                  const TDTag('已回滚', size: TDTagSize.small)
                else
                  TDTag(
                    '${log.totalDeleted} 条',
                    theme: TDTagTheme.danger,
                    size: TDTagSize.small,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 统计信息
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '采购记录',
                    '${log.procurementDeleted} 条',
                    TDIcons.cart,
                    const Color(0xFF5C6BC0),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '退货记录',
                    '${log.returnDeleted} 条',
                    TDIcons.rotation,
                    const Color(0xFFFF8A65),
                  ),
                ),
              ],
            ),
            // 回滚信息
            if (log.isRolledBack && log.rollbackTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(TDIcons.time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TDText(
                        '回滚时间: ${_formatDateTime(log.rollbackTime!)}',
                        font: Font(size: 11, lineHeight: 14),
                        textColor: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 操作按钮
            if (!log.isRolledBack) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TDButton(
                      text: '回滚恢复',
                      size: TDButtonSize.small,
                      type: TDButtonType.outline,
                      theme: TDButtonTheme.primary,
                      icon: TDIcons.rollback,
                      onTap: () => _rollbackCleanup(log),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TDButton(
                    text: '',
                    size: TDButtonSize.small,
                    type: TDButtonType.text,
                    theme: TDButtonTheme.danger,
                    icon: TDIcons.delete,
                    onTap: () => _deleteLog(log),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TDText(
              label,
              font: Font(size: 11, lineHeight: 14),
              textColor: Colors.grey.shade600,
            ),
            TDText(
              value,
              font: Font(size: 13, lineHeight: 18),
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ],
    );
  }
}
