import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/db_service.dart';
import '../../utils/category_group_override.dart';

/// 库存盘点 - 填写页
/// 进入时传入已选品类与日期范围，用户在手机上逐行填写库存数，保存到本地数据库
class InventoryFillPage extends StatefulWidget {
  final List<String> categories;
  final String startDate;
  final String endDate;

  const InventoryFillPage({
    super.key,
    required this.categories,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<InventoryFillPage> createState() => _InventoryFillPageState();
}

class _InventoryFillPageState extends State<InventoryFillPage> {
  // 品类 -> 库存数
  final Map<String, TextEditingController> _controllers = {};
  // 按大类分组
  final Map<String, List<String>> _grouped = {};
  // 统一排序后的品类顺序：显示、保存、后续导出都用它，保证行序始终一致
  late final List<String> _orderedCategories;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _orderedCategories = CategoryGroupOverride.sortByGroup(widget.categories);
    for (final c in _orderedCategories) {
      _controllers[c] = TextEditingController();
    }
    _buildGroups();
  }

  void _buildGroups() {
    // _orderedCategories 已按大类排好序，同大类天然连续，顺序遍历即可成组
    for (final c in _orderedCategories) {
      final g = CategoryGroupOverride.getGroup(c);
      _grouped.putIfAbsent(g, () => []).add(c);
    }
  }

  String _generateSheetId() {
    final now = DateTime.now();
    final rnd = Random().nextInt(900) + 100; // 避免同一秒内多次保存相互覆盖
    return 'inv_${DateFormat('yyyyMMdd_HHmmssSSS').format(now)}_$rnd';
  }

  /// 已填写的项数（非空即算已填）
  int get _filledCount => _controllers.values
      .where((c) => c.text.trim().isNotEmpty)
      .length;

  /// 是否有任何输入（用于离开时提醒）
  bool get _hasInput => _filledCount > 0;

  Future<bool> _onWillPop() async {
    if (!_hasInput || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃本次盘点？'),
        content: Text('已填写 $_filledCount 项库存数，直接返回将不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续填写'),
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
    // 校验：只允许非负整数或小数
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
      final sheetId = _generateSheetId();
      await DbService.instance.saveInventoryCheck(
        sheetId,
        _orderedCategories,
        widget.startDate,
        widget.endDate,
        DateTime.now().toString(),
        quantities: quantities,
      );
      if (mounted) {
        TDToast.showSuccess('盘点记录已保存到手机', context: context);
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
        title: const Text('填写库存数量'),
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
              text: _saving ? '保存中...' : '保存到手机',
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
