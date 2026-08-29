import 'package:flutter/material.dart';
import '../pages/index/index.dart';
import '../pages/entry/entry.dart';
import '../pages/settle/settle.dart';
import '../pages/history/history.dart';
import '../pages/screenshot/screenshot.dart';
import '../pages/image_history/image_history.dart';
import '../pages/returns/returns.dart';
import '../pages/analysis/analysis.dart';
import '../pages/about/about.dart';
import '../pages/search/search.dart';
import '../pages/cleanup/cleanup.dart';
import '../pages/supplement/supplement_list.dart';
import '../pages/inventory/inventory_select_page.dart';
import '../pages/inventory/inventory_fill_page.dart';
import '../pages/inventory/inventory_history_page.dart';
import '../pages/return_goods/return_goods_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String entry = '/entry';
  static const String settle = '/settle';
  static const String history = '/history';
  static const String screenshot = '/screenshot';
  static const String imageHistory = '/image_history';
  static const String returns = '/returns';
  static const String analysis = '/analysis';
  static const String about = '/about';
  static const String search = '/search';
  static const String cleanup = '/cleanup';
  static const String supplement = '/supplement';
  static const String inventorySelect = '/inventory_select';
  static const String inventoryFill = '/inventory_fill';
  static const String inventoryHistory = '/inventory_history';
  static const String returnGoods = '/return_goods';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    entry: (context) => const EntryPage(),
    settle: (context) => const SettlePage(),
    history: (context) => const HistoryPage(),
    screenshot: (context) => const ScreenshotPage(),
    imageHistory: (context) => const ImageHistoryPage(),
    returns: (context) => const ReturnsPage(),
    analysis: (context) => const AnalysisPage(),
    about: (context) => const AboutPage(),
    search: (context) => const SearchPage(),
    cleanup: (context) => const DataCleanupPage(),
    supplement: (context) => const SupplementListPage(),
    inventorySelect: (context) => const InventorySelectPage(),
    inventoryFill: (context) => const InventoryFillPage(
          categories: [],
          startDate: '',
          endDate: '',
        ),
    inventoryHistory: (context) => const InventoryHistoryPage(),
    returnGoods: (context) => const ReturnGoodsPage(),
  };
}
