import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'controller/return_entry_controller.dart';
import 'widgets/return_form_widgets.dart';

/// 退货录入页面 - UI骨架
/// 业务逻辑已抽取到 ReturnEntryController
class ReturnEntryPage extends StatelessWidget {
  const ReturnEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReturnEntryController()..init(),
      child: const _ReturnEntryView(),
    );
  }
}

class _ReturnEntryView extends StatelessWidget {
  const _ReturnEntryView();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReturnEntryController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          const _Header(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('退货信息'),
                    const SizedBox(height: 6),
                    const DateSelector(),
                    const SizedBox(height: 6),
                    const CategorySelector(),
                    const AutoFillIndicator(),
                    const SizedBox(height: 6),
                    _GradeInput(controller: controller),
                    const SizedBox(height: 6),
                    _LocationInput(controller: controller),
                    const SizedBox(height: 6),
                    const ReasonSelector(),
                    const SizedBox(height: 12),
                    const SectionTitle('数量与价格'),
                    const SizedBox(height: 6),
                    _QuantityAndUnit(controller: controller),
                    const SizedBox(height: 6),
                    _PriceInput(controller: controller),
                    const SizedBox(height: 12),
                    const SectionTitle('其他信息'),
                    const SizedBox(height: 6),
                    _RemarkInput(controller: controller),
                    const SizedBox(height: 6),
                    const ImagePickerWidget(),
                    const SizedBox(height: 24),
                    const TotalAmountCard(),
                    const SizedBox(height: 24),
                    _SubmitButton(controller: controller),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 页面头部
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEF5350),
              const Color(0xFFEF5350).withValues(alpha: 0.8),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
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
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '新增退货',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '记录退货信息',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 规格等级输入
class _GradeInput extends StatelessWidget {
  final ReturnEntryController controller;
  const _GradeInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('规格等级'),
        const SizedBox(height: 3),
        ReturnFormInput(
          controller: controller.gradeController,
          placeholder: '如：一级/大果/80#',
          leftIcon: TDIcons.chart_bar,
        ),
      ],
    );
  }
}

/// 供应商位置输入
class _LocationInput extends StatelessWidget {
  final ReturnEntryController controller;
  const _LocationInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('供应商/档口'),
        const SizedBox(height: 3),
        ReturnFormInput(
          controller: controller.locationController,
          placeholder: '如：A区102号',
          leftIcon: TDIcons.location,
        ),
      ],
    );
  }
}

/// 数量与单位
class _QuantityAndUnit extends StatelessWidget {
  final ReturnEntryController controller;
  const _QuantityAndUnit({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('退货数量 *'),
              const SizedBox(height: 3),
              ReturnFormInput(
                controller: controller.quantityController,
                placeholder: '0.00',
                leftIcon: TDIcons.calculation,
                inputType: TextInputType.number,
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
              const SectionTitle('单位'),
              const SizedBox(height: 3),
              const _UnitSelector(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单位选择器
class _UnitSelector extends StatelessWidget {
  const _UnitSelector();

  @override
  Widget build(BuildContext context) {
    return Selector<ReturnEntryController, String?>(
      selector: (_, c) => c.selectedUnit,
      builder: (context, selectedUnit, child) {
        final controller = context.read<ReturnEntryController>();

        return ReturnFormInput(
          controller: TextEditingController(text: selectedUnit),
          placeholder: '选择单位',
          leftIcon: TDIcons.layers,
          readOnly: true,
          onTap: () => _showUnitPicker(context, controller),
          rightWidget: Icon(
            TDIcons.chevron_down,
            size: 16,
            color: Colors.grey.shade400,
          ),
        );
      },
    );
  }

  void _showUnitPicker(BuildContext context, ReturnEntryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择单位',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ReturnEntryController.units.length,
                  itemBuilder: (context, index) {
                    final unit = ReturnEntryController.units[index];
                    final isSelected = unit == controller.selectedUnit;
                    return ListTile(
                      title: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? TDTheme.of(context).brandNormalColor
                              : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              TDIcons.check,
                              color: TDTheme.of(context).brandNormalColor,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        controller.selectUnit(unit);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 单价输入
class _PriceInput extends StatelessWidget {
  final ReturnEntryController controller;
  const _PriceInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('退货单价 *'),
        const SizedBox(height: 3),
        ReturnFormInput(
          controller: controller.priceController,
          placeholder: '0.00',
          leftIcon: TDIcons.money,
          inputType: TextInputType.number,
        ),
      ],
    );
  }
}

/// 备注输入
class _RemarkInput extends StatelessWidget {
  final ReturnEntryController controller;
  const _RemarkInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('备注'),
        const SizedBox(height: 3),
        ReturnFormInput(
          controller: controller.remarkController,
          placeholder: '添加备注信息...',
          leftIcon: TDIcons.edit,
          maxLines: 3,
        ),
      ],
    );
  }
}

/// 提交按钮
class _SubmitButton extends StatelessWidget {
  final ReturnEntryController controller;
  const _SubmitButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Selector<
      ReturnEntryController,
      (bool isSubmitting, String? selectedCategory)
    >(
      selector: (_, c) => (c.isSubmitting, c.selectedCategory),
      builder: (context, data, child) {
        final (isSubmitting, selectedCategory) = data;

        return TDButton(
          text: isSubmitting ? '保存中...' : '保存退货记录',
          size: TDButtonSize.large,
          type: TDButtonType.fill,
          theme: TDButtonTheme.danger,
          isBlock: true,
          disabled: isSubmitting || selectedCategory == null,
          onTap: isSubmitting ? null : () => _submit(context, controller),
        );
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    ReturnEntryController controller,
  ) async {
    // 验证必填项
    if (controller.selectedCategory == null) {
      TDToast.showText('请选择水果品类', context: context);
      return;
    }

    if (controller.quantity <= 0) {
      TDToast.showText('请输入退货数量', context: context);
      return;
    }

    if (controller.price <= 0) {
      TDToast.showText('请输入退货单价', context: context);
      return;
    }

    // 检查其他原因是否填写
    if (controller.returnReason == 5 &&
        controller.otherReasonController.text.trim().isEmpty) {
      TDToast.showText('请输入其他原因', context: context);
      return;
    }

    try {
      final record = await controller.submit();
      if (record != null && context.mounted) {
        TDToast.showSuccess('保存成功', context: context);
        Navigator.pop(context, record);
      }
    } catch (e) {
      if (context.mounted) {
        TDToast.showText('保存失败: $e', context: context);
      }
    }
  }
}
