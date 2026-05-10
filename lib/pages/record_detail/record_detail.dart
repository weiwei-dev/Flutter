import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../models/procurement.dart';
import '../../services/db_service.dart';
import '../settle/settle.dart';

/// 采购记录详情/编辑页
class RecordDetailPage extends StatefulWidget {
  final int recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late RecordDetailController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = RecordDetailController(recordId: widget.recordId);
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleEdit() async {
    if (_isEditing) {
      // 保存修改
      final success = await _controller.saveChanges();
      if (success && mounted) {
        TDToast.showSuccess('保存成功', context: context);
        // 返回清账页面，传递记录日期用于刷新
        final recordDate = _controller.record?.createTime.substring(0, 10);
        if (Navigator.canPop(context)) {
          Navigator.pop(context, {'refreshDate': recordDate, 'refresh': true});
        }
      } else if (!success && mounted) {
        TDToast.showText('保存失败', context: context);
        return;
      }
    } else {
      // 进入编辑模式前检查清账状态
      final record = _controller.record;
      if (record != null && record.settleStatus == 1) {
        // 已清账，显示提示
        await _showSettledWarningDialog();
        return;
      }
      setState(() {
        _isEditing = !_isEditing;
      });
    }
  }

  /// 显示已清账警告对话框
  Future<void> _showSettledWarningDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(TDIcons.error_circle, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text('无法编辑'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('该单据已清账，无法直接编辑。', style: TextStyle(fontSize: 15)),
              SizedBox(height: 12),
              Text(
                '如需修改，请先将单据回退到"未清账/未结算"状态，系统才允许编辑修改。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                '修改完成后，需重新执行清账/结算操作，确保账务一致。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            TDButton(
              text: '去清账页面',
              theme: TDButtonTheme.primary,
              size: TDButtonSize.small,
              onTap: () {
                Navigator.of(context).pop();
                // 获取当前记录的日期 (格式: yyyy-MM-dd HH:mm:ss -> yyyy-MM-dd)
                final recordDate =
                    _controller.record?.createTime.substring(0, 10) ??
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettlePage(initialDate: recordDate),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(TDIcons.camera),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(TDIcons.image),
                title: const Text('从相册选择'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _controller.pickImage(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: TDTheme.of(context).brandNormalColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isEditing ? '编辑采购记录' : '采购详情',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_controller.record != null)
                TextButton(
                  onPressed: _toggleEdit,
                  child: Text(
                    _isEditing ? '保存' : '编辑',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.record == null
              ? const Center(child: Text('记录不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 16),
                      _buildPriceSection(),
                      const SizedBox(height: 16),
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      _buildRemarkSection(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final record = _controller.record!;
    final isSettled = record.settleStatus == 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSettled
              ? [Colors.green, Colors.green.withValues(alpha: 0.8)]
              : [Colors.orange, Colors.orange.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isSettled ? '已清账' : '待清账',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'ID: ${record.id}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '采购时间: ${record.createTime}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (isSettled && record.settleTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '清账时间: ${record.settleTime}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: '基本信息',
      icon: TDIcons.info_circle,
      children: [
        _buildInfoRow(
          label: '水果品类',
          value: _controller.categoryController.text,
          isEditing: _isEditing,
          controller: _controller.categoryController,
          icon: TDIcons.apple,
        ),
        _buildInfoRow(
          label: '规格等级',
          value: _controller.gradeController.text,
          isEditing: _isEditing,
          controller: _controller.gradeController,
          icon: TDIcons.chart_bar,
          hintText: '如：一级/大果',
        ),
        _buildInfoRow(
          label: '供应商/档口',
          value: _controller.supplierController.text,
          isEditing: _isEditing,
          controller: _controller.supplierController,
          icon: TDIcons.location,
          hintText: '如：A区102号',
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return _buildSection(
      title: '价格信息',
      icon: TDIcons.money,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                label: '采购数量',
                value: _controller.quantityController.text,
                isEditing: _isEditing,
                controller: _controller.quantityController,
                icon: TDIcons.calculation,
                keyboardType: TextInputType.number,
                onChanged: (_) => _controller.calculateTotal(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: _isEditing
                  ? _buildUnitSelector()
                  : _buildInfoRow(
                      label: '单位',
                      value: _controller.selectedUnit,
                      isEditing: false,
                      controller: null,
                      icon: TDIcons.measurement,
                    ),
            ),
          ],
        ),
        _buildInfoRow(
          label: '采购单价',
          value: _controller.priceController.text,
          isEditing: _isEditing,
          controller: _controller.priceController,
          icon: TDIcons.money,
          keyboardType: TextInputType.number,
          onChanged: (_) => _controller.calculateTotal(),
        ),
        _buildInfoRow(
          label: '服务费',
          value: _controller.serviceFeeController.text,
          isEditing: _isEditing,
          controller: _controller.serviceFeeController,
          icon: TDIcons.service,
          keyboardType: TextInputType.number,
          onChanged: (_) => _controller.calculateTotal(),
        ),
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TDTheme.of(context).brandNormalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '总金额',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '¥${_controller.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TDTheme.of(context).brandNormalColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector() {
    final units = ['件', 'kg', 'g', '个', '箱', '袋', '斤', '盒'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '单位',
          style: TextStyle(
            fontSize: AppConstants.fontSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: AppConstants.inputHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.smallRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _controller.selectedUnit,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _controller.setUnit(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final hasImage =
        _controller.imageFile != null ||
        (_controller.record?.imagePath != null &&
            _controller.record!.imagePath!.isNotEmpty);

    return _buildSection(
      title: '采购凭证',
      icon: TDIcons.image,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.smallRadius),
            child: _controller.imageFile != null
                ? Image.file(
                    _controller.imageFile!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_controller.record!.imagePath!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppConstants.smallRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TDIcons.image, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  '暂无图片',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        if (_isEditing) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TDButton(
                  text: hasImage ? '更换图片' : '添加图片',
                  icon: TDIcons.camera,
                  theme: TDButtonTheme.light,
                  onTap: _pickImage,
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TDButton(
                    text: '删除图片',
                    icon: TDIcons.delete,
                    theme: TDButtonTheme.danger,
                    onTap: () => _controller.clearImage(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRemarkSection() {
    return _buildSection(
      title: '备注',
      icon: TDIcons.edit,
      children: [
        _isEditing
            ? TextField(
                controller: _controller.remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '请输入备注信息...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.smallRadius,
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.smallRadius,
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.smallRadius,
                    ),
                    borderSide: BorderSide(
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _controller.remarkController.text.isEmpty
                      ? '暂无备注'
                      : _controller.remarkController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: _controller.remarkController.text.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TDTheme.of(context).brandNormalColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController? controller,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppConstants.fontSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          isEditing && controller != null
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: Icon(
                      icon,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.smallRadius,
                      ),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.smallRadius,
                      ),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.smallRadius,
                      ),
                      borderSide: BorderSide(
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(
                      AppConstants.smallRadius,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value.isEmpty ? '未填写' : value,
                          style: TextStyle(
                            fontSize: 14,
                            color: value.isEmpty
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

/// 采购记录详情控制器
class RecordDetailController extends ChangeNotifier {
  final int recordId;

  ProcurementRecord? _record;
  bool _isLoading = true;
  File? _imageFile;
  double _totalAmount = 0.0;

  // 编辑控制器
  final categoryController = TextEditingController();
  final gradeController = TextEditingController();
  final supplierController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final serviceFeeController = TextEditingController();
  final remarkController = TextEditingController();

  String _selectedUnit = '件';

  ProcurementRecord? get record => _record;
  bool get isLoading => _isLoading;
  File? get imageFile => _imageFile;
  double get totalAmount => _totalAmount;
  String get selectedUnit => _selectedUnit;

  RecordDetailController({required this.recordId});

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 获取所有记录并查找指定ID的记录
      final allRecords = await DbService.instance.getAllProcurementRecords();
      _record = allRecords.firstWhere((r) => r.id == recordId);

      if (_record != null) {
        // 初始化控制器
        categoryController.text = _record!.category;
        gradeController.text = _record!.grade ?? '';
        supplierController.text = _record!.supplierLocation ?? '';
        quantityController.text = _record!.quantity.toString();
        priceController.text = _record!.price.toString();
        serviceFeeController.text = _record!.serviceFee.toString();
        remarkController.text = _record!.remark ?? '';
        _selectedUnit = _record!.unit;
        _totalAmount = _record!.totalAmount;

        // 加载图片
        if (_record!.imagePath != null && _record!.imagePath!.isNotEmpty) {
          _imageFile = File(_record!.imagePath!);
        }
      }
    } catch (e) {
      debugPrint('Error loading record detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void calculateTotal() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    final serviceFee = double.tryParse(serviceFeeController.text) ?? 0;
    _totalAmount = (quantity * price) + serviceFee;
    notifyListeners();
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void clearImage() {
    _imageFile = null;
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    if (_record == null) return false;

    try {
      // 保存前重新计算总金额，确保金额是最新的
      calculateTotal();

      final updatedRecord = ProcurementRecord(
        id: _record!.id,
        category: categoryController.text,
        quantity: double.tryParse(quantityController.text) ?? 0,
        unit: _selectedUnit,
        price: double.tryParse(priceController.text) ?? 0,
        totalAmount: _totalAmount,
        serviceFee: double.tryParse(serviceFeeController.text) ?? 0,
        grade: gradeController.text.isEmpty ? null : gradeController.text,
        supplierLocation: supplierController.text.isEmpty
            ? null
            : supplierController.text,
        imagePath: _imageFile?.path ?? _record!.imagePath,
        createTime: _record!.createTime,
        settleStatus: _record!.settleStatus,
        settleTime: _record!.settleTime,
        remark: remarkController.text.isEmpty ? null : remarkController.text,
      );

      await DbService.instance.updateProcurementRecord(updatedRecord);
      _record = updatedRecord;
      return true;
    } catch (e) {
      debugPrint('Error saving record: $e');
      return false;
    }
  }

  @override
  void dispose() {
    categoryController.dispose();
    gradeController.dispose();
    supplierController.dispose();
    quantityController.dispose();
    priceController.dispose();
    serviceFeeController.dispose();
    remarkController.dispose();
    super.dispose();
  }
}
