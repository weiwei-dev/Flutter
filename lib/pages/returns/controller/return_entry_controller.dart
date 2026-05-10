import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/return_record.dart';
import '../../../utils/db.dart';

/// 退货录入页面控制器 - 使用 Provider 管理状态
class ReturnEntryController extends ChangeNotifier {
  // 状态字段
  DateTime _returnTime = DateTime.now();
  String? _selectedCategory;
  String? _selectedUnit = '斤';
  int _returnReason = 0;
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isLoadingCategories = false;
  bool _isAutoFilled = false;
  List<String> _fruitCategories = [];
  double _quantity = 0;
  double _price = 0;

  // Controllers
  late final TextEditingController dateController;
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController otherReasonController = TextEditingController();

  // Getters
  DateTime get returnTime => _returnTime;
  String? get selectedCategory => _selectedCategory;
  String? get selectedUnit => _selectedUnit;
  int get returnReason => _returnReason;
  File? get imageFile => _imageFile;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isAutoFilled => _isAutoFilled;
  List<String> get fruitCategories => _fruitCategories;
  double get quantity => _quantity;
  double get price => _price;

  // 计算总金额
  double get totalAmount => _quantity * _price;

  // 格式化日期
  String get formattedDate =>
      '${_returnTime.year}-${_returnTime.month.toString().padLeft(2, '0')}-${_returnTime.day.toString().padLeft(2, '0')}';

  // 退货原因列表
  static const List<Map<String, dynamic>> returnReasons = [
    {'value': 0, 'label': '质量问题', 'icon': Icons.warning},
    {'value': 1, 'label': '货物不符', 'icon': Icons.compare},
    {'value': 2, 'label': '包装破损', 'icon': Icons.broken_image},
    {'value': 3, 'label': '过期变质', 'icon': Icons.timer_off},
    {'value': 4, 'label': '客户取消', 'icon': Icons.cancel},
    {'value': 5, 'label': '其他原因', 'icon': Icons.help},
  ];

  // 单位列表
  static const List<String> units = ['斤', '公斤', '个', '箱', '篮', '件'];

  /// 初始化
  void init() {
    dateController = TextEditingController(text: formattedDate);
    _setupListeners();
    // 延迟加载，避免在构建期间调用 notifyListeners
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadCategoriesByDate();
    });
  }

  /// 设置监听器
  void _setupListeners() {
    categoryController.addListener(_onCategoryChanged);
    quantityController.addListener(_updateQuantity);
    priceController.addListener(_updatePrice);
  }

  /// 品类输入变更处理
  void _onCategoryChanged() {
    final category = categoryController.text.trim();
    if (category.isEmpty) {
      _selectedCategory = null;
      _isAutoFilled = false;
      notifyListeners();
      return;
    }

    _selectedCategory = category;
    // 如果输入的品类在历史品类中，触发自动填充
    if (_fruitCategories.contains(category)) {
      _autoFillByCategory(category);
    } else {
      // 新品类，清除自动填充标记
      _isAutoFilled = false;
      notifyListeners();
    }
  }

  /// 根据品类自动填充信息
  Future<void> _autoFillByCategory(String category) async {
    final info = await DatabaseHelper.instance.getCategoryInfoByDate(
      category,
      formattedDate,
    );

    if (info != null) {
      gradeController.text = info['grade'] as String? ?? '';
      locationController.text = info['supplierLocation'] as String? ?? '';
      _selectedUnit = info['unit'] as String? ?? '斤';
      _price = (info['price'] as num?)?.toDouble() ?? 0;
      _isAutoFilled = true;

      priceController.text = (info['price'] as num?)?.toString() ?? '';
      notifyListeners();
    } else {
      _isAutoFilled = false;
      notifyListeners();
    }
  }

  /// 获取过滤后的品类建议列表
  List<String> getFilteredCategories(String input) {
    if (input.isEmpty) return _fruitCategories;
    return _fruitCategories
        .where(
          (category) => category.toLowerCase().contains(input.toLowerCase()),
        )
        .toList();
  }

  /// 更新数量
  void _updateQuantity() {
    _quantity = double.tryParse(quantityController.text) ?? 0;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 更新单价
  void _updatePrice() {
    _price = double.tryParse(priceController.text) ?? 0;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 选择日期
  void selectDate(DateTime date) {
    _returnTime = date;
    _selectedCategory = null;
    _fruitCategories = [];
    _isAutoFilled = false;
    dateController.text = formattedDate;

    // 清空相关字段
    categoryController.clear();
    gradeController.clear();
    locationController.clear();
    priceController.clear();

    notifyListeners();
    loadCategoriesByDate();
  }

  /// 根据日期加载品类
  Future<void> loadCategoriesByDate() async {
    _isLoadingCategories = true;
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final categories = await DatabaseHelper.instance.getCategoriesByDate(
        formattedDate,
      );
      _fruitCategories = categories;
      _isLoadingCategories = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isLoadingCategories = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// 选择品类（从历史品类中选择）
  Future<void> selectCategory(String category) async {
    if (category == _selectedCategory) return;

    // 更新控制器文本（不触发监听器循环）
    categoryController.text = category;
    _selectedCategory = category;
    _isAutoFilled = false;
    notifyListeners();

    // 触发自动填充
    await _autoFillByCategory(category);
  }

  /// 选择单位
  void selectUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  /// 选择退货原因
  void selectReason(int reason) {
    _returnReason = reason;
    if (reason != 5) {
      otherReasonController.clear();
    }
    notifyListeners();
  }

  /// 选择图片
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  /// 清除图片
  void clearImage() {
    _imageFile = null;
    notifyListeners();
  }

  /// 提交表单
  Future<ReturnRecord?> submit() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // 组合备注信息
      String? finalRemark;
      if (_returnReason == 5) {
        finalRemark = '其他原因：${otherReasonController.text.trim()}';
        if (remarkController.text.isNotEmpty) {
          finalRemark = '$finalRemark\n${remarkController.text}';
        }
      } else {
        finalRemark = remarkController.text.isEmpty
            ? null
            : remarkController.text;
      }

      final record = ReturnRecord(
        category: _selectedCategory!,
        quantity: _quantity,
        unit: _selectedUnit!,
        price: _price,
        totalAmount: totalAmount,
        grade: gradeController.text.isEmpty ? null : gradeController.text,
        supplierLocation: locationController.text.isEmpty
            ? null
            : locationController.text,
        imagePath: _imageFile?.path,
        returnTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(_returnTime),
        remark: finalRemark,
        returnReason: _returnReason,
        status: 0, // 默认状态：未退货
      );

      await DatabaseHelper.instance.insertReturnRecord(record);
      _isSubmitting = false;
      notifyListeners();
      return record;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    quantityController.removeListener(_updateQuantity);
    priceController.removeListener(_updatePrice);

    dateController.dispose();
    quantityController.dispose();
    priceController.dispose();
    gradeController.dispose();
    locationController.dispose();
    remarkController.dispose();
    otherReasonController.dispose();

    super.dispose();
  }
}
