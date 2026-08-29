import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/db_service.dart';
import '../../services/export_service.dart';
import '../../core/widgets/date_picker.dart';
import '../../utils/category_classifier.dart';
import 'inventory_fill_page.dart';

/// 库存盘点 - 独立页面
/// 顶部日期范围（默认近10天）+ 数据源切换（近10天 / 全部历史）+ 搜索 + 按大类分组勾选 + 底部导出
/// 用户取消勾选的品类会被持久化，下次默认不再勾选
class InventorySelectPage extends StatefulWidget {
  const InventorySelectPage({super.key});

  @override
  State<InventorySelectPage> createState() => _InventorySelectPageState();
}

class _InventorySelectPageState extends State<InventorySelectPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  /// 数据源：true=近N天范围品类；false=全部历史品类
  bool _useDateRange = true;

  List<String> _allCategories = [];
  final Set<String> _selected = {};
  // 持久化：用户曾经取消勾选过的品类（下架/不需要）
  final Set<String> _excluded = {};
  // 持久化：用户跨数据源/日期明确选中的品类，切换时用于恢复选择
  final Set<String> _persistedSelection = {};
  // 用户手动新增的品类（可跨会话保留）
  final Set<String> _customCategories = {};

  bool _loading = false;
  String _keyword = '';

  static const String _excludedKey = 'inventory_excluded_categories';
  static const String _selectionKey = 'inventory_persisted_selection';
  static const String _customKey = 'inventory_custom_categories';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 默认近10天：今天及前9天
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 9));
    _loadExcluded();
    _loadPersistedSelection();
    _loadCustomCategories();
    _loadCategories();
  }

  String get _startStr => DateFormat('yyyy-MM-dd').format(_startDate);
  String get _endStr => DateFormat('yyyy-MM-dd').format(_endDate);

  Future<void> _loadExcluded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_excludedKey) ?? [];
      _excluded.addAll(saved);
    } catch (_) {
      // 读取失败不影响主流程
    }
  }

  Future<void> _persistExcluded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_excludedKey, _excluded.toList());
    } catch (_) {}
  }

  Future<void> _loadPersistedSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_selectionKey) ?? [];
      _persistedSelection.addAll(saved);
    } catch (_) {}
  }

  Future<void> _persistSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_selectionKey, _persistedSelection.toList());
    } catch (_) {}
  }

  Future<void> _loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_customKey) ?? [];
      _customCategories.addAll(saved);
    } catch (_) {}
  }

  Future<void> _persistCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customKey, _customCategories.toList());
    } catch (_) {}
  }

  Future<void> _pickRange() async {
    final range = await showAppDateRangePicker(
      context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadCategories();
    }
  }

  /// 切换数据源（近10天 / 全部历史）
  void _switchSource(bool useDateRange) {
    if (_useDateRange == useDateRange) return;
    setState(() => _useDateRange = useDateRange);
    _loadCategories();
  }

  /// 加载品类列表。
  /// 选中规则：
  /// - 如果用户已有持久化选择（_persistedSelection 非空），按持久化选择恢复，
  ///   只勾选同时满足「在当前列表中」且「未被排除」的品类。
  /// - 如果用户从未做过选择，默认勾选所有未被排除的品类。
  /// 这样「近10天」与「全部历史」来回切换，以及改日期范围时，
  /// 之前在另一数据源选中的品类不会丢失。
  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final categories = _useDateRange
          ? await DbService.instance.getCategoriesByDateRange(
              '$_startStr 00:00:00',
              '$_endStr 23:59:59',
            )
          : await DbService.instance.getAllCategories();
      // 合并历史品类与用户自定义品类，去重
      final merged = <String>{...categories, ..._customCategories}.toList();
      setState(() {
        _allCategories = merged;
        if (_persistedSelection.isEmpty) {
          // 首次使用：默认勾选所有未被排除的品类
          _selected
            ..clear()
            ..addAll(merged.where((c) => !_excluded.contains(c)));
        } else {
          // 已有持久化选择：按持久化集合恢复，同时排除下架项
          _selected
            ..clear()
            ..addAll(
              merged.where(
                (c) => _persistedSelection.contains(c) && !_excluded.contains(c),
              ),
            );
        }
      });
    } catch (e) {
      if (mounted) TDToast.showText('加载品类失败: $e', context: context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(String category, bool? checked) {
    setState(() {
      if (checked == true) {
        _selected.add(category);
        _persistedSelection.add(category);
        _excluded.remove(category);
      } else {
        _selected.remove(category);
        _persistedSelection.remove(category);
        _excluded.add(category);
      }
    });
    _persistExcluded();
    _persistSelection();
  }

  void _selectAll() {
    setState(() {
      for (final c in _allCategories) {
        if (!_excluded.contains(c)) {
          _selected.add(c);
          _persistedSelection.add(c);
        }
      }
    });
    _persistSelection();
  }

  void _invert() {
    setState(() {
      for (final c in _allCategories) {
        if (_selected.contains(c)) {
          _selected.remove(c);
          _persistedSelection.remove(c);
          _excluded.add(c);
        } else {
          _selected.add(c);
          _persistedSelection.add(c);
          _excluded.remove(c);
        }
      }
    });
    _persistExcluded();
    _persistSelection();
  }

  void _clear() {
    setState(() {
      for (final c in _allCategories) {
        _selected.remove(c);
        _persistedSelection.remove(c);
        _excluded.add(c);
      }
    });
    _persistExcluded();
    _persistSelection();
  }

  List<String> get _selectedList {
    return _allCategories.where((c) => _selected.contains(c)).toList();
  }

  Future<void> _exportInventoryCheck() async {
    if (_selected.isEmpty) {
      TDToast.showText('请至少选择一个品类', context: context);
      return;
    }
    try {
      await ExportService.instance.exportInventoryCheck(
        _selectedList,
        _startStr,
        _endStr,
      );
      if (mounted) {
        TDToast.showSuccess('库存盘点表已导出', context: context);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) TDToast.showText('导出失败: $e', context: context);
    }
  }

  /// 新增自定义品类
  Future<void> _addCustomCategory() async {
    final result = await showDialog<_AddCategoryResult?>(
      context: context,
      builder: (context) => const _AddCategoryDialog(),
    );
    if (result == null) return;

    final name = result.name;
    if (_allCategories.contains(name)) {
      TDToast.showText('该品类已存在', context: context);
      return;
    }

    setState(() {
      _customCategories.add(name);
      _allCategories.add(name);
      _selected.add(name);
      _persistedSelection.add(name);
      _excluded.remove(name);
    });
    await _persistCustomCategories();
    await _persistSelection();
    await _persistExcluded();
    TDToast.showSuccess('已新增并选中：$name', context: context);
  }

  Future<void> _fillInventory() async {
    if (_selected.isEmpty) {
      TDToast.showText('请至少选择一个品类', context: context);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryFillPage(
          categories: _selectedList,
          startDate: _startStr,
          endDate: _endStr,
        ),
      ),
    );
    if (result == true && mounted) {
      TDToast.showSuccess('已保存，可在「盘点历史」继续编辑', context: context);
    }
  }

  /// 按大类分组，过滤搜索关键字
  Map<String, List<String>> _groupedCategories() {
    final kw = _keyword.trim();
    final filtered = kw.isEmpty
        ? _allCategories
        : _allCategories
            .where((c) => c.toLowerCase().contains(kw.toLowerCase()))
            .toList();

    final map = <String, List<String>>{};
    for (final c in filtered) {
      final group = CategoryClassifier.getGroup(c);
      map.putIfAbsent(group, () => []).add(c);
    }
    // 按已配置的大类顺序排序，其余（含"其他"）排在后面
    final ordered = <String, List<String>>{};
    for (final g in CategoryClassifier.allGroups) {
      if (map.containsKey(g)) {
        map[g]!.sort();
        ordered[g] = map[g]!;
      }
    }
    for (final g in map.keys) {
      if (!ordered.containsKey(g)) {
        map[g]!.sort();
        ordered[g] = map[g]!;
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedCategories();
    final totalVisible = grouped.values.fold(0, (a, b) => a + b.length);
    final brandColor = TDTheme.of(context).brandNormalColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('库存盘点'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(TDIcons.add, size: 22),
            tooltip: '新增品类',
            onPressed: _loading ? null : _addCustomCategory,
          ),
          PopupMenuButton<String>(
            icon: const Icon(TDIcons.more, color: Colors.white),
            tooltip: '批量操作',
            onSelected: (value) {
              switch (value) {
                case 'selectAll':
                  _selectAll();
                  break;
                case 'invert':
                  _invert();
                  break;
                case 'clear':
                  _clear();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'selectAll', child: Text('全选')),
              const PopupMenuItem(value: 'invert', child: Text('反选')),
              const PopupMenuItem(value: 'clear', child: Text('清空')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 数据源切换：近10天 / 全部历史
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SourceChip(
                    label: '近10天品类',
                    active: _useDateRange,
                    onTap: () => _switchSource(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceChip(
                    label: '全部历史品类',
                    active: !_useDateRange,
                    onTap: () => _switchSource(false),
                  ),
                ),
              ],
            ),
          ),
          // 日期范围选择条（仅近10天模式显示）
          if (_useDateRange)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(TDIcons.calendar, size: 16, color: brandColor),
                            const SizedBox(width: 6),
                            TDText(
                              '$_startStr ~ $_endStr',
                              font: Font(size: 13, lineHeight: 18),
                              textColor: brandColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _pickRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: brandColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '更改',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 搜索框 + 新增品类
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(12, _useDateRange ? 0 : 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TDInput(
                    hintText: _useDateRange ? '搜索近10天品类' : '搜索全部历史品类',
                    leftIcon: const Icon(TDIcons.search, size: 18),
                    onChanged: (v) => setState(() => _keyword = v ?? ''),
                    needClear: true,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addCustomCategory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TDIcons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '新增品类',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 品类列表（按大类分组）
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : totalVisible == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _keyword.isNotEmpty
                                  ? '未找到"$_keyword"'
                                  : (_useDateRange
                                      ? '该日期范围内暂无采购品类'
                                      : '暂无品类数据'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_keyword.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TDButton(
                                text: '添加"$_keyword"',
                                size: TDButtonSize.small,
                                theme: TDButtonTheme.primary,
                                onTap: () async {
                                  final name = _keyword.trim();
                                  if (name.isEmpty) return;
                                  if (_allCategories.contains(name)) {
                                    TDToast.showText(
                                      '该品类已存在',
                                      context: context,
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _customCategories.add(name);
                                    _allCategories.add(name);
                                    _selected.add(name);
                                    _persistedSelection.add(name);
                                    _excluded.remove(name);
                                    _keyword = '';
                                  });
                                  await _persistCustomCategories();
                                  await _persistSelection();
                                  await _persistExcluded();
                                  TDToast.showSuccess(
                                    '已新增并选中：$name',
                                    context: context,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: grouped.length,
                        itemBuilder: (context, gi) {
                          final group = grouped.keys.elementAt(gi);
                          final items = grouped[group]!;
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
                                final checked = _selected.contains(category);
                                return Container(
                                  color: Colors.white,
                                  child: CheckboxListTile(
                                    value: checked,
                                    onChanged: (v) => _toggle(category, v),
                                    title: Text(category),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '已选 ${_selected.length} / ${_allCategories.length} 个品类',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TDButton(
                      text: '导出空表',
                      size: TDButtonSize.large,
                      theme: TDButtonTheme.light,
                      disabled: _selected.isEmpty,
                      onTap: _exportInventoryCheck,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TDButton(
                      text: '填写库存',
                      size: TDButtonSize.large,
                      theme: TDButtonTheme.primary,
                      disabled: _selected.isEmpty,
                      onTap: _fillInventory,
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
}

/// 数据源切换小卡片
class _SourceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = TDTheme.of(context).brandNormalColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? brandColor : brandColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : brandColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 新增品类弹窗结果
class _AddCategoryResult {
  final String name;
  final String group;

  const _AddCategoryResult({required this.name, required this.group});
}

/// 新增品类弹窗（独立 StatefulWidget，避免 StatefulBuilder + controller 的 build scope 问题）
class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedGroup = '其他';

  @override
  void initState() {
    super.initState();
    _selectedGroup = CategoryClassifier.getGroup('');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = TDTheme.of(context).brandNormalColor;
    return AlertDialog(
      title: const Text('新增盘点品类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TDInput(
              controller: _nameController,
              hintText: '输入品类名称，如：D101榴莲',
              autofocus: true,
              onChanged: (v) {
                final name = (v ?? '').trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _selectedGroup = CategoryClassifier.getGroup(name);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            const Text(
              '选择大类（可手动修正）',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryClassifier.allGroups.map((group) {
                final selected = _selectedGroup == group;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGroup = group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? brandColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      group,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TDButton(
          text: '确定',
          theme: TDButtonTheme.primary,
          size: TDButtonSize.small,
          onTap: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _AddCategoryResult(name: name, group: _selectedGroup),
            );
          },
        ),
      ],
    );
  }
}
