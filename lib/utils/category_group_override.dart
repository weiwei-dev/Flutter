import 'package:shared_preferences/shared_preferences.dart';
import 'category_classifier.dart';

/// 品类大类的「用户手动指定」覆盖表。
///
/// CategoryClassifier 只能用关键字推断大类，用户在新增盘点品类时手动挑选的大类
/// 需要跨会话保留，否则下次打开又会被推断回原来的大类。
/// 这里用 SharedPreferences 持久化一张 品类 -> 大类 的映射，
/// 取大类时优先查这张表，查不到再回退到自动推断。
class CategoryGroupOverride {
  static final Map<String, String> _map = {};
  static bool _loaded = false;

  static const String _key = 'inventory_custom_groups';

  /// 在应用启动时调用一次加载，之后所有页面都能同步读取
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith('$_key::')) {
          final category = k.substring('$_key::'.length);
          final group = prefs.getString(k);
          if (group != null && group.isNotEmpty) {
            _map[category] = group;
          }
        }
      }
    } catch (_) {
      // 读取失败不影响主流程，退化为自动推断
    }
    _loaded = true;
  }

  /// 取品类所属大类：手动指定优先，否则自动推断
  static String getGroup(String category) {
    final custom = _map[category];
    if (custom != null && custom.isNotEmpty) return custom;
    return CategoryClassifier.getGroup(category);
  }

  /// 记录用户手动指定的大类
  static Future<void> set(String category, String group) async {
    _map[category] = group;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_key::$category', group);
    } catch (_) {}
  }

  /// 移除手动指定，恢复自动推断
  static Future<void> remove(String category) async {
    _map.remove(category);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_key::$category');
    } catch (_) {}
  }

  /// 按「大类顺序 + 组内字典序」排序。
  ///
  /// 选择页导出空表、填写页保存、编辑页回读、历史页导出，四处必须用同一个顺序，
  /// 否则用户打印出来的空表和事后导出的已填表行序对不上，逐行核对会很痛苦。
  static List<String> sortByGroup(List<String> categories) {
    final map = <String, List<String>>{};
    for (final c in categories) {
      map.putIfAbsent(getGroup(c), () => []).add(c);
    }
    final result = <String>[];
    for (final g in CategoryClassifier.allGroups) {
      final list = map.remove(g);
      if (list != null) {
        list.sort();
        result.addAll(list);
      }
    }
    // 未收录的大类排在最后
    for (final list in map.values) {
      list.sort();
      result.addAll(list);
    }
    return result;
  }
}
