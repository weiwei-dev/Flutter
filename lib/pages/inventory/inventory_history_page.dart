import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../services/db_service.dart';
import '../../services/export_service.dart';
import '../../models/inventory_check.dart';
import '../../utils/category_group_override.dart';

/// 库存盘点 - 历史列表
/// 展示所有已保存的盘点记录，可进入继续编辑（重填）或删除
class InventoryHistoryPage extends StatefulWidget {
  const InventoryHistoryPage({super.key});

  @override
  State<InventoryHistoryPage> createState() => _InventoryHistoryPageState();
}

class _InventoryHistoryPageState extends State<InventoryHistoryPage> {
  List<Map<String, dynamic>> _sheets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sheets = await DbService.instance.getAllInventoryChecks();
      setState(() => _sheets = sheets);
    } catch (e) {
      if (mounted) TDToast.showText('加载失败: $e', context: context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSheet(Map<String, dynamic> sheet) async {
    final sheetId = sheet['sheet_id'] as String;
    final rows = await DbService.instance.getInventoryCheck(sheetId);
    if (!mounted) return;
    final categories = rows.map((r) => r['category'] as String).toList();
    final quantities = <String, String>{};
    for (final r in rows) {
      quantities[r['category'] as String] =
          (r['stock_quantity'] as String?) ?? '';
    }
    // 跳转到填写页，并预填已有的库存数
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PrefilledFillPage(
          categories: categories,
          quantities: quantities,
          startDate: (sheet['start_date'] as String?) ?? '',
          endDate: (sheet['end_date'] as String?) ?? '',
          sheetId: sheetId,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  /// 盘点范围描述。空日期范围表示「全部历史」模式下建的盘点。
  static String _rangeLabelOf(Map<String, dynamic> sheet) {
    final start = (sheet['start_date'] as String?) ?? '';
    final end = (sheet['end_date'] as String?) ?? '';
    if (start.isEmpty || end.isEmpty) return '全部历史';
    return '$start 至 $end';
  }

  Future<void> _exportSheet(Map<String, dynamic> sheet) async {
    final sheetId = sheet['sheet_id'] as String;
    try {
      final rows = await DbService.instance.getInventoryCheck(sheetId);
      // 按品类行读取即可，顺序与保存时一致（读取按 id 升序）
      final categories = rows.map((r) => r['category'] as String).toList();
      final quantities = <String, String>{};
      for (final r in rows) {
        quantities[r['category'] as String] =
            (r['stock_quantity'] as String?) ?? '';
      }
      await ExportService.instance.exportInventoryCheckFilled(
        categories,
        quantities,
        (sheet['start_date'] as String?) ?? '',
        (sheet['end_date'] as String?) ?? '',
        rangeLabel: _rangeLabelOf(sheet),
      );
    } catch (e) {
      if (mounted) TDToast.showText('导出失败: $e', context: context);
    }
  }

  Future<void> _delete(Map<String, dynamic> sheet) async {
    final sheetId = sheet['sheet_id'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除盘点记录'),
        content: const Text('确定删除这份盘点记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DbService.instance.deleteInventoryCheck(sheetId);
    if (!mounted) return;
    TDToast.showSuccess('已删除', context: context);
    _load();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('盘点历史'),
        backgroundColor: TDTheme.of(context).brandNormalColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sheets.isEmpty
              ? const Center(child: Text('暂无盘点记录'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sheets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sheet = _sheets[index];
                    final summary = InventoryCheckSummary.fromMap(sheet);
                    final allFilled = summary.itemCount > 0 &&
                        summary.filledCount >= summary.itemCount;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          _rangeLabelOf(sheet),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: allFilled
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  allFilled ? '已完成' : '未完成',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: allFilled
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_formatTime(summary.createdAt)} · '
                                  '${summary.filledCount}/${summary.itemCount} 项已填',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(TDIcons.file_1, size: 20),
                              tooltip: '导出 Excel',
                              onPressed: () => _exportSheet(sheet),
                            ),
                            IconButton(
                              icon: const Icon(TDIcons.edit, size: 20),
                              tooltip: '编辑',
                              onPressed: () => _openSheet(sheet),
                            ),
                            IconButton(
                              icon: const Icon(TDIcons.delete, size: 20),
                              tooltip: '删除',
                              onPressed: () => _delete(sheet),
                            ),
                          ],
                        ),
                        onTap: () => _openSheet(sheet),
                      ),
                    );
                  },
                ),
    );
  }
}

/// 预填已有库存数的填写页包装（复用 InventoryFillPage 的 UI 通过组合重构较复杂，
/// 这里单独实现一个带预填的编辑页）
class _PrefilledFillPage extends StatefulWidget {
  final List<String> categories;
  final Map<String, String> quantities;
  final String startDate;
  final String endDate;
  final String sheetId;

  const _PrefilledFillPage({
    required this.categories,
    required this.quantities,
    required this.startDate,
    required this.endDate,
    required this.sheetId,
  });

  @override
  State<_PrefilledFillPage> createState() => _PrefilledFillPageState();
}

class _PrefilledFillPageState extends State<_PrefilledFillPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<String>> _grouped = {};
  late final List<String> _orderedCategories;
  late final Map<String, String> _savedSnapshot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _orderedCategories = CategoryGroupOverride.sortByGroup(widget.categories);
    _savedSnapshot = {
      for (final c in _orderedCategories)
        c: (widget.quantities[c] ?? '').trim(),
    };
    for (final c in _orderedCategories) {
      _controllers[c] = TextEditingController(text: _savedSnapshot[c]);
    }
    _buildGroups();
  }

  void _buildGroups() {
    for (final c in _orderedCategories) {
      final g = CategoryGroupOverride.getGroup(c);
      _grouped.putIfAbsent(g, () => []).add(c);
    }
  }

  int get _filledCount =>
      _controllers.values.where((c) => c.text.trim().isNotEmpty).length;

  /// 与上次保存的内容相比是否有改动
  bool get _isDirty {
    for (final entry in _controllers.entries) {
      if (entry.value.text.trim() != (_savedSnapshot[entry.key] ?? '')) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃修改？'),
        content: const Text('本次修改尚未保存，直接返回将不会生效。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _save() async {
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      if (double.tryParse(text) == null || double.parse(text) < 0) {
        TDToast.showText('「${entry.key}」的库存数不是有效数字', context: context);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final quantities = <String, String>{};
      for (final entry in _controllers.entries) {
        quantities[entry.key] = entry.value.text.trim();
      }
      // 复用同一 sheetId 覆盖保存。
      // 保存层会沿用该 sheetId 首次的 created_at，
      // 因此编辑不会把这条记录顶到历史列表最前面。
      await DbService.instance.saveInventoryCheck(
        widget.sheetId,
        _orderedCategories,
        widget.startDate,
        widget.endDate,
        DateTime.now().toString(),
        quantities: quantities,
      );
      if (mounted) {
        TDToast.showSuccess('盘点记录已更新', context: context);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) TDToast.showText('保存失败: $e', context: context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = TDTheme.of(context).brandNormalColor;
    final rangeText = widget.startDate.isEmpty
        ? '数据范围：全部历史'
        : '数据范围：${widget.startDate} ~ ${widget.endDate}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final ok = await _onWillPop();
        if (ok && mounted) navigator.pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('编辑盘点'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(TDIcons.calendar, size: 16, color: brandColor),
                const SizedBox(width: 6),
                Text(
                  rangeText,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Spacer(),
                Text(
                  '已填 $_filledCount / ${_orderedCategories.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _grouped.length,
              itemBuilder: (context, gi) {
                final group = _grouped.keys.elementAt(gi);
                final items = _grouped[group]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: brandColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$group (${items.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...items.map((category) {
                      return Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TDInput(
                                controller: _controllers[category],
                                hintText: '库存数',
                                inputType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                textAlign: TextAlign.center,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: TDButton(
              text: _saving ? '保存中...' : '更新保存',
              size: TDButtonSize.large,
              theme: TDButtonTheme.primary,
              isBlock: true,
              disabled: _saving,
              onTap: _saving ? null : _save,
            ),
          ),
        ),
      ),
    );
  }
}
