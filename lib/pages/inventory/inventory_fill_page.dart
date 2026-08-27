import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/db_service.dart';
import '../../utils/category_classifier.dart';

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.categories) {
      _controllers[c] = TextEditingController();
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

  String _generateSheetId() {
    final now = DateTime.now();
    return 'inv_${DateFormat('yyyyMMdd_HHmmss').format(now)}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final quantities = <String, String>{};
      for (final entry in _controllers.entries) {
        quantities[entry.key] = entry.value.text.trim();
      }
      final sheetId = _generateSheetId();
      await DbService.instance.saveInventoryCheck(
        sheetId,
        widget.categories,
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
    return Scaffold(
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
            text: _saving ? '保存中...' : '保存到手机',
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
