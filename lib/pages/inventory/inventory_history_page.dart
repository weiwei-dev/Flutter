import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../services/db_service.dart';
import '../../models/inventory_check.dart';
import '../../utils/category_classifier.dart';

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
    if (result == true) _load();
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
    if (ok == true) {
      await DbService.instance.deleteInventoryCheck(sheetId);
      TDToast.showSuccess('已删除', context: context);
      _load();
    }
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
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          '${summary.startDate} ~ ${summary.endDate}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_formatTime(summary.createdAt)} · '
                            '${summary.filledCount}/${summary.itemCount} 项已填',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(TDIcons.edit, size: 20),
                              onPressed: () => _openSheet(sheet),
                            ),
                            IconButton(
                              icon: const Icon(TDIcons.delete, size: 20),
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.categories) {
      _controllers[c] = TextEditingController(text: widget.quantities[c] ?? '');
    }
    _buildGroups();
  }

  void _buildGroups() {
    final map = <String, List<String>>{};
    for (final c in widget.categories) {
      final g = CategoryClassifier.getGroup(c);
      map.putIfAbsent(g, () => []).add(c);
    }
    for (final g in CategoryClassifier.allGroups) {
      if (map.containsKey(g)) {
        map[g]!.sort();
        _grouped[g] = map[g]!;
      }
    }
    for (final g in map.keys) {
      if (!_grouped.containsKey(g)) {
        map[g]!.sort();
        _grouped[g] = map[g]!;
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final quantities = <String, String>{};
      for (final entry in _controllers.entries) {
        quantities[entry.key] = entry.value.text.trim();
      }
      // 复用同一 sheetId 覆盖保存
      await DbService.instance.saveInventoryCheck(
        widget.sheetId,
        widget.categories,
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
    return Scaffold(
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
                  '数据范围：${widget.startDate} ~ ${widget.endDate}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Spacer(),
                Text(
                  '共 ${widget.categories.length} 项',
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
                                inputType: TextInputType.number,
                                textAlign: TextAlign.center,
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
    );
  }
}
