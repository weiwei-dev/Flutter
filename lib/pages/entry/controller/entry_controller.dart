import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:io';
import '../../../models/procurement.dart';
import '../../../app/providers/procurement_provider.dart';
import '../../../services/db_service.dart';
import '../../../utils/image_utils.dart';

final logger = Logger();

/// 录入页控制器
class EntryController extends ChangeNotifier {
  // Controllers
  final categoryController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final serviceFeeController = TextEditingController();
  final supplierLocationController = TextEditingController();
  final gradeController = TextEditingController();
  final remarkController = TextEditingController();

  // State
  String _selectedUnit = '件';
  File? _imageFile;
  double _totalAmount = 0.0;

  // 历史图片（用于品类图片复用）
  String? _historicalImagePath;
  bool _useHistoricalImage = false;

  // 品类建议列表
  List<String> _categorySuggestions = [];
  bool _showCategorySuggestions = false;
  Timer? _suggestionDebounceTimer;

  // Validation errors
  String? _categoryError;
  String? _quantityError;
  String? _priceError;

  // 防抖 Timer，用于智能回填
  Timer? _autoFillDebounceTimer;

  // 补单相关
  final bool isSupplement;
  DateTime _procurementDate;

  // 采购类型：0=本地采购 1=外地回货 2=本地赊账
  int _purchaseType = PurchaseType.local;

  // Getters
  String get selectedUnit => _selectedUnit;
  File? get imageFile => _imageFile;
  double get totalAmount => _totalAmount;
  String? get historicalImagePath => _historicalImagePath;
  bool get useHistoricalImage => _useHistoricalImage;
  bool get hasHistoricalImage =>
      _historicalImagePath != null && _historicalImagePath!.isNotEmpty;
  List<String> get categorySuggestions => _categorySuggestions;
  bool get showCategorySuggestions => _showCategorySuggestions;
  String? get categoryError => _categoryError;
  String? get quantityError => _quantityError;
  String? get priceError => _priceError;
  bool get isSupplementMode => isSupplement;
  DateTime get procurementDate => _procurementDate;
  int get purchaseType => _purchaseType;

  final List<String> units = const ['件', 'kg', 'g', '个', '箱', '袋', '斤', '盒'];

  EntryController({this.isSupplement = false, DateTime? procurementDate})
    : _procurementDate = procurementDate ?? DateTime.now() {
    logger.d('EntryController initialized, isSupplement: $isSupplement');
    _setupListeners();
  }

  /// 设置采购日期（用于补单）
  void setProcurementDate(DateTime date) {
    _procurementDate = date;
    notifyListeners();
  }

  /// 切换采购类型（0=本地采购 1=外地回货 2=本地赊账）
  void setPurchaseType(int value) {
    _purchaseType = value;
    notifyListeners();
  }

  void _setupListeners() {
    quantityController.addListener(_calculateTotal);
    priceController.addListener(_calculateTotal);
    serviceFeeController.addListener(_calculateTotal);
    // 品类输入监听，用于智能回填（带防抖）
    categoryController.addListener(_onCategoryChanged);
  }

  /// 品类输入变化回调（带防抖）
  void _onCategoryChanged() {
    // 取消之前的定时器
    _autoFillDebounceTimer?.cancel();
    _suggestionDebounceTimer?.cancel();

    final category = categoryController.text.trim();

    // 如果输入为空，隐藏建议列表
    if (category.isEmpty) {
      _showCategorySuggestions = false;
      _categorySuggestions = [];
      notifyListeners();
      return;
    }

    // 延迟 200ms 后查询建议列表
    _suggestionDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      _loadCategorySuggestions(category);
    });

    // 延迟 500ms 后执行智能回填
    _autoFillDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      autoFillByCategory(category);
    });
  }

  /// 加载品类建议列表
  Future<void> _loadCategorySuggestions(String input) async {
    try {
      final allCategories = await DbService.instance.getAllCategories();
      // 过滤包含输入内容的品类（不区分大小写）
      _categorySuggestions = allCategories
          .where((c) => c.toLowerCase().contains(input.toLowerCase()))
          .take(5) // 最多显示5个建议
          .toList();
      _showCategorySuggestions = _categorySuggestions.isNotEmpty;
      notifyListeners();
      logger.d('Loaded ${_categorySuggestions.length} category suggestions for: $input');
    } catch (e) {
      logger.e('Error loading category suggestions: $e');
    }
  }

  /// 选择建议的品类
  void selectCategorySuggestion(String category) {
    categoryController.text = category;
    _showCategorySuggestions = false;
    _categorySuggestions = [];
    notifyListeners();
    // 立即执行自动回填
    autoFillByCategory(category);
  }

  /// 隐藏建议列表
  void hideCategorySuggestions() {
    _showCategorySuggestions = false;
    notifyListeners();
  }

  /// 获取所有品类（用于建议列表）
  Future<List<String>> getAllCategories() async {
    return await DbService.instance.getAllCategories();
  }

  void _calculateTotal() {
    double quantity = double.tryParse(quantityController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0;
    double serviceFee = double.tryParse(serviceFeeController.text) ?? 0;
    _totalAmount = (quantity * price) + serviceFee;
    logger.d(
      'Calculated total: $_totalAmount (quantity: $quantity, price: $price, serviceFee: $serviceFee)',
    );
    // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void setImageFile(File? file) {
    _imageFile = file;
    _useHistoricalImage = false;
    notifyListeners();
  }

  void clearImage() {
    _imageFile = null;
    _useHistoricalImage = false;
    notifyListeners();
  }

  /// 设置历史图片路径
  void setHistoricalImagePath(String? path) {
    _historicalImagePath = path;
    notifyListeners();
  }

  /// 应用历史图片
  void applyHistoricalImage() {
    if (_historicalImagePath != null && _historicalImagePath!.isNotEmpty) {
      _useHistoricalImage = true;
      _imageFile = File(_historicalImagePath!);
      notifyListeners();
      logger.d('Using historical image: $_historicalImagePath');
    }
  }

  /// 取消使用历史图片
  void cancelHistoricalImage() {
    _useHistoricalImage = false;
    _imageFile = null;
    notifyListeners();
  }

  /// 验证表单
  bool validate() {
    bool isValid = true;

    // 验证水果品类
    if (categoryController.text.trim().isEmpty) {
      _categoryError = '此项为必填项';
      isValid = false;
    } else {
      _categoryError = null;
    }

    // 验证采购数量
    if (quantityController.text.trim().isEmpty) {
      _quantityError = '此项为必填项';
      isValid = false;
    } else {
      _quantityError = null;
    }

    // 验证采购单价
    if (priceController.text.trim().isEmpty) {
      _priceError = '此项为必填项';
      isValid = false;
    } else {
      _priceError = null;
    }

    notifyListeners();
    return isValid;
  }

  /// 保存记录
  Future<bool> saveRecord(ProcurementProvider provider) async {
    if (!validate()) {
      logger.d('Form validation failed');
      return false;
    }

    try {
      final now = DateTime.now();
      final String orderTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // 补单模式：createTime为选择的采购日期，orderTime为当前时间
      // 正常模式：两者都是当前时间
      final String createTime = isSupplement
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_procurementDate)
          : orderTime;

      final record = ProcurementRecord(
        category: categoryController.text,
        quantity: double.tryParse(quantityController.text) ?? 0,
        unit: _selectedUnit,
        price: double.tryParse(priceController.text) ?? 0,
        totalAmount: _totalAmount,
        serviceFee: double.tryParse(serviceFeeController.text) ?? 0,
        grade: gradeController.text,
        supplierLocation: supplierLocationController.text,
        imagePath: _imageFile?.path,
        createTime: createTime,
        settleStatus: 0,
        remark: remarkController.text,
        isSupplement: isSupplement ? 1 : 0,
        orderTime: isSupplement ? orderTime : null,
        purchaseType: _purchaseType,
      );

      logger.d('Adding record: ${record.category}');
      await provider.addRecord(record);
      logger.d('Record added successfully');

      // 清空表单
      clearForm();
      return true;
    } catch (e) {
      logger.e('Error saving record: $e');
      return false;
    }
  }

  /// 清空表单
  void clearForm() {
    categoryController.clear();
    quantityController.clear();
    priceController.clear();
    serviceFeeController.clear();
    gradeController.clear();
    supplierLocationController.clear();
    remarkController.clear();
    _selectedUnit = '件';
    _imageFile = null;
    _historicalImagePath = null;
    _useHistoricalImage = false;
    _purchaseType = PurchaseType.local;
    _totalAmount = 0.0;
    _categoryError = null;
    _quantityError = null;
    _priceError = null;
    notifyListeners();
  }

  /// 选择图片，压缩后保存到应用持久化目录
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        logger.d('Image picked: ${pickedFile.path}');
        final savedFile = await ImageUtils.compressAndSaveImage(
          File(pickedFile.path),
        );
        if (savedFile != null) {
          _imageFile = savedFile;
          _useHistoricalImage = false;
          logger.d('Image saved to persistent path: ${savedFile.path}');
        }
        notifyListeners();
      } else {
        logger.d('Image picker cancelled');
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      rethrow;
    }
  }

  /// 根据品类智能回填（当品类在库存中存在时，回填规格等级、供应商、备注）
  /// 会覆盖现有内容，确保信息始终与当前品类匹配
  Future<void> autoFillByCategory(String category) async {
    if (category.trim().isEmpty) return;

    logger.d('Auto-filling by category: $category');

    try {
      final lastRecord = await DbService.instance.getLastRecordByCategory(
        category.trim(),
      );

      if (lastRecord != null) {
        // 回填规格等级（如果有值则覆盖）
        if (lastRecord.grade != null && lastRecord.grade!.isNotEmpty) {
          gradeController.text = lastRecord.grade!;
          logger.d('Auto-filled grade: ${lastRecord.grade}');
        }

        // 回填供应商/档口（如果有值则覆盖）
        if (lastRecord.supplierLocation != null &&
            lastRecord.supplierLocation!.isNotEmpty) {
          supplierLocationController.text = lastRecord.supplierLocation!;
          logger.d('Auto-filled supplier: ${lastRecord.supplierLocation}');
        }

        // 回填备注（如果有值则覆盖）
        if (lastRecord.remark != null && lastRecord.remark!.isNotEmpty) {
          remarkController.text = lastRecord.remark!;
          logger.d('Auto-filled remark: ${lastRecord.remark}');
        }

        // 回填单位（如果有值则覆盖）
        if (lastRecord.unit.isNotEmpty) {
          _selectedUnit = lastRecord.unit;
          logger.d('Auto-filled unit: ${lastRecord.unit}');
        }

        // 回填历史图片路径（仅保存路径，不自动使用）
        logger.d('Last record imagePath: ${lastRecord.imagePath}');
        if (lastRecord.imagePath != null && lastRecord.imagePath!.isNotEmpty) {
          _historicalImagePath = lastRecord.imagePath;
          logger.d(
            'Auto-filled historical image path: ${lastRecord.imagePath}',
          );
        } else {
          _historicalImagePath = null;
          logger.d('No historical image found for category: $category');
        }

        // 使用 SchedulerBinding 延迟通知，避免在构建期间调用 setState
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        // 没有找到记录，清空历史图片
        _historicalImagePath = null;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      logger.e('Error auto-filling by category: $e');
    }
  }

  @override
  void dispose() {
    // 取消防抖定时器
    _autoFillDebounceTimer?.cancel();
    // 移除品类输入监听器
    categoryController.removeListener(_onCategoryChanged);
    categoryController.dispose();
    quantityController.dispose();
    priceController.dispose();
    serviceFeeController.dispose();
    supplierLocationController.dispose();
    gradeController.dispose();
    remarkController.dispose();
    super.dispose();
  }
}
