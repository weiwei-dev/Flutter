import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../components/tab_bar.dart';
import '../../app/providers/procurement_provider.dart';
import 'controller/entry_controller.dart';
import 'widgets/entry_widgets.dart';

/// 采购录入页 - UI骨架
///
/// [isSupplement] 是否为补单模式，true表示补单，需要选择历史日期
class EntryPage extends StatelessWidget {
  final bool isSupplement;

  const EntryPage({super.key, this.isSupplement = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EntryController(isSupplement: isSupplement),
      child: _EntryView(isSupplement: isSupplement),
    );
  }
}

class _EntryView extends StatefulWidget {
  final bool isSupplement;

  const _EntryView({required this.isSupplement});

  @override
  State<_EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<_EntryView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourcePicker(EntryController controller) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImageSourcePicker(),
    );

    if (source == null) return;

    try {
      final imageSource = source == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;
      await controller.pickImage(imageSource);
    } catch (e) {
      if (mounted) {
        final message = source == 'camera' ? '无法使用相机，请从相册选择' : '无法访问相册';
        TDToast.showText(message, context: context);
      }
    }
  }

  Future<void> _saveRecord(EntryController controller) async {
    final provider = Provider.of<ProcurementProvider>(context, listen: false);
    final success = await controller.saveRecord(provider);

    if (success && mounted) {
      TDToast.showSuccess('采购记录保存成功', context: context);
    } else if (!success && mounted) {
      TDToast.showText('请填写必填项', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<EntryController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildHeader(context, controller),
              _buildForm(context, controller),
            ],
          );
        },
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context, EntryController controller) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TDTheme.of(context).brandNormalColor,
              TDTheme.of(context).brandNormalColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTitle(context, controller),
                const SizedBox(height: 8),
                TotalAmountCard(amount: controller.totalAmount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context, EntryController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              TDIcons.chevron_left,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isSupplement ? '补录采购数据' : '录入采购数据',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.isSupplement)
                GestureDetector(
                  onTap: () => _showDatePicker(context, controller),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TDIcons.calendar,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '采购日期: ${DateFormat('yyyy-MM-dd').format(controller.procurementDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示日期选择器
  void _showDatePicker(BuildContext context, EntryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '选择采购日期',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: TDCalendar(
                onChange: (value) {
                  if (value.isNotEmpty) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value[0]);
                    controller.setProcurementDate(date);
                    Navigator.of(context).pop();
                  }
                },
                value: [controller.procurementDate.millisecondsSinceEpoch],
                minDate: DateTime(2024).millisecondsSinceEpoch,
                maxDate: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, EntryController controller) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(controller),
                _buildQuantitySection(controller),
                _buildPriceSection(controller),
                _buildAdditionalSection(controller),
                _buildImageSection(controller),
                _buildSubmitButton(controller),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(EntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 水果品类
        const SectionTitle(title: '水果品类 *'),
        const SizedBox(height: 3),
        // 品类输入框（带建议列表）
        _buildCategoryInputWithSuggestions(controller),
        const SizedBox(height: 6),

        // 规格等级
        const SectionTitle(title: '规格等级'),
        const SizedBox(height: 3),
        EntryInput(
          controller: controller.gradeController,
          placeholder: '如：一级/大果/80#',
          leftIcon: TDIcons.chart_bar,
        ),
        const SizedBox(height: 6),

        // 供应商/档口
        const SectionTitle(title: '供应商/档口'),
        const SizedBox(height: 3),
        EntryInput(
          controller: controller.supplierLocationController,
          placeholder: '如：A区102号',
          leftIcon: TDIcons.location,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildQuantitySection(EntryController controller) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '采购数量 *'),
              const SizedBox(height: 3),
              EntryInput(
                controller: controller.quantityController,
                placeholder: '0.00',
                leftIcon: TDIcons.calculation,
                inputType: TextInputType.number,
                errorText: controller.quantityError,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '单位'),
              const SizedBox(height: 3),
              UnitSelector(
                selectedUnit: controller.selectedUnit,
                units: controller.units,
                onChanged: controller.setUnit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(EntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 采购单价
        const SectionTitle(title: '采购单价 *'),
        const SizedBox(height: 3),
        EntryInput(
          controller: controller.priceController,
          placeholder: '0.00',
          leftIcon: TDIcons.money,
          inputType: TextInputType.number,
          prefixText: '¥',
          errorText: controller.priceError,
        ),
        const SizedBox(height: 6),

        // 服务费用
        const SectionTitle(title: '服务费/手续费'),
        const SizedBox(height: 3),
        EntryInput(
          controller: controller.serviceFeeController,
          placeholder: '0.00',
          leftIcon: TDIcons.bill,
          inputType: TextInputType.number,
          prefixText: '¥',
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildAdditionalSection(EntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 备注
        const SectionTitle(title: '备注'),
        const SizedBox(height: 3),
        EntryInput(
          controller: controller.remarkController,
          placeholder: '添加备注信息...',
          leftIcon: TDIcons.edit_1,
          maxLines: 2,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildImageSection(EntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '付款截图'),
        const SizedBox(height: 3),
        // 历史图片提示
        if (controller.hasHistoricalImage &&
            !controller.useHistoricalImage &&
            controller.imageFile == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(TDIcons.image, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '发现历史图片',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 历史图片预览
                GestureDetector(
                  onTap: () => _showHistoricalImagePreview(controller),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(controller.historicalImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              TDIcons.image_error,
                              size: 24,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TDButton(
                        text: '使用此图片',
                        size: TDButtonSize.small,
                        type: TDButtonType.fill,
                        theme: TDButtonTheme.primary,
                        onTap: () => controller.applyHistoricalImage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TDButton(
                        text: '重新拍照',
                        size: TDButtonSize.small,
                        type: TDButtonType.outline,
                        theme: TDButtonTheme.primary,
                        onTap: () => _showImageSourcePicker(controller),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          // 调试信息：显示历史图片状态
          if (controller.categoryController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    TDIcons.info_circle,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '该品类暂无历史图片',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 普通图片选择器
          ImagePickerWidget(
            imageFile: controller.imageFile,
            onTap: () => _showImageSourcePicker(controller),
            onClear: controller.clearImage,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建品类输入框（带建议列表）
  Widget _buildCategoryInputWithSuggestions(EntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入框
        EntryInput(
          controller: controller.categoryController,
          placeholder: '如：红富士苹果',
          leftIcon: TDIcons.apple,
          errorText: controller.categoryError,
          onEditingComplete: () {
            controller.hideCategorySuggestions();
            controller.autoFillByCategory(controller.categoryController.text);
          },
        ),
        // 建议列表
        if (controller.showCategorySuggestions) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: controller.categorySuggestions.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final category = entry.value;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        controller.selectCategorySuggestion(category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border:
                              index < controller.categorySuggestions.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              TDIcons.search,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Icon(
                              TDIcons.chevron_right,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 显示历史图片预览
  void _showHistoricalImagePreview(EntryController controller) {
    if (controller.historicalImagePath == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(controller.historicalImagePath!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(EntryController controller) {
    return TDButton(
      text: '保存采购记录',
      size: TDButtonSize.large,
      style: TDButtonStyle(
        backgroundColor: TDTheme.of(context).brandNormalColor,
        textColor: Colors.white,
      ),
      icon: TDIcons.check_circle,
      isBlock: true,
      onTap: () => _saveRecord(controller),
    );
  }
}
