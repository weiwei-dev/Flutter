import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../controller/return_entry_controller.dart';

/// 表单输入组件
class ReturnFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData leftIcon;
  final TextInputType? inputType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? rightWidget;
  final int maxLines;
  final String? errorText;

  const ReturnFormInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.leftIcon,
    this.inputType,
    this.readOnly = false,
    this.onTap,
    this.rightWidget,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: maxLines == 1 ? 38 : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? TDTheme.of(context).errorNormalColor
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TDInput(
              controller: controller,
              backgroundColor: Colors.transparent,
              leftIcon: Icon(leftIcon, size: 16, color: Colors.grey.shade500),
              inputType: inputType,
              leftLabel: '',
              hintText: placeholder,
              readOnly: readOnly,
              maxLines: maxLines,
              textStyle: const TextStyle(fontSize: 13, height: 1.4),
              hintTextStyle: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade400,
              ),
              rightWidget: rightWidget,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 11,
                color: TDTheme.of(context).errorNormalColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// 节标题组件
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }
}

/// 日期选择器组件
class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReturnEntryController>();

    return Selector<ReturnEntryController, DateTime>(
      selector: (_, c) => c.returnTime,
      builder: (context, returnTime, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('退货日期 *'),
            const SizedBox(height: 3),
            ReturnFormInput(
              controller: controller.dateController,
              placeholder: '请选择退货日期',
              leftIcon: TDIcons.calendar,
              readOnly: true,
              onTap: () => _showDatePicker(context, controller),
              rightWidget: Icon(
                TDIcons.chevron_down,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDatePicker(
    BuildContext context,
    ReturnEntryController controller,
  ) async {
    final DateTime minDateTime = DateTime(2020);
    final DateTime maxDateTime = DateTime.now();
    int selectedTimestamp = controller.returnTime.millisecondsSinceEpoch;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '选择退货日期',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            TDIcons.close,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TDCalendar(
                      value: [selectedTimestamp],
                      minDate: minDateTime.millisecondsSinceEpoch,
                      maxDate: maxDateTime.millisecondsSinceEpoch,
                      type: CalendarType.single,
                      title: '选择日期',
                      onChange: (List<int> value) {
                        if (value.isNotEmpty) {
                          setModalState(() {
                            selectedTimestamp = value.first;
                          });
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: TDButton(
                      text: '确定',
                      size: TDButtonSize.large,
                      type: TDButtonType.fill,
                      theme: TDButtonTheme.primary,
                      isBlock: true,
                      onTap: () {
                        Navigator.pop(context);
                        final selectedDate =
                            DateTime.fromMillisecondsSinceEpoch(
                              selectedTimestamp,
                            );
                        controller.selectDate(selectedDate);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 品类输入组件（支持手动输入和历史建议）
class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
      ReturnEntryController,
      (bool isLoading, List<String> categories, String? selected, TextEditingController categoryController)
    >(
      selector: (_, c) =>
          (c.isLoadingCategories, c.fruitCategories, c.selectedCategory, c.categoryController),
      builder: (context, data, child) {
        final (isLoading, categories, selected, categoryController) = data;
        final controller = context.read<ReturnEntryController>();

        // 获取建议列表
        final suggestions = controller.getFilteredCategories(categoryController.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('水果品类 *'),
            const SizedBox(height: 3),
            if (isLoading)
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Column(
                children: [
                  // 输入框
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == null && categoryController.text.isEmpty
                            ? TDTheme.of(context).errorNormalColor
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          TDIcons.apple,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: categories.isEmpty 
                                  ? '请先选择退货日期' 
                                  : '输入水果品类（如：BJ山竹）',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (categoryController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              categoryController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  // 建议列表
                  if (_showSuggestions && suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final category = suggestions[index];
                          return ListTile(
                            dense: true,
                            minLeadingWidth: 0,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            leading: Icon(
                              TDIcons.apple,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            title: Text(
                              category,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              controller.selectCategory(category);
                              _focusNode.unfocus();
                              setState(() {
                                _showSuggestions = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            if (selected == null && categoryController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  '* 必填项',
                  style: TextStyle(
                    fontSize: 11,
                    color: TDTheme.of(context).errorNormalColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

}

/// 退货原因选择器组件
class ReasonSelector extends StatelessWidget {
  const ReasonSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ReturnEntryController, int>(
      selector: (_, c) => c.returnReason,
      builder: (context, returnReason, child) {
        final controller = context.read<ReturnEntryController>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('退货原因'),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 4;
                return Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  children: ReturnEntryController.returnReasons.map((reason) {
                    final isSelected = returnReason == reason['value'];
                    return SizedBox(
                      width: itemWidth,
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              reason['icon'] as IconData,
                              size: 10,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                reason['label'] as String,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEF5350),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontSize: 10,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 0,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectReason(reason['value'] as int);
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            if (returnReason == 5) ...[
              const SizedBox(height: 8),
              ReturnFormInput(
                controller: controller.otherReasonController,
                placeholder: '请输入其他原因',
                leftIcon: TDIcons.edit,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 图片选择器组件
class ImagePickerWidget extends StatelessWidget {
  const ImagePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ReturnEntryController, File?>(
      selector: (_, c) => c.imageFile,
      builder: (context, imageFile, child) {
        final controller = context.read<ReturnEntryController>();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '退货照片',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (imageFile == null)
                  InkWell(
                    onTap: () => controller.pickImage(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TDIcons.camera,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '添加照片',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFile,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => controller.clearImage(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 金额合计卡片组件
class TotalAmountCard extends StatelessWidget {
  const TotalAmountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ReturnEntryController, (double, String?, double, double)>(
      selector: (_, c) => (c.totalAmount, c.selectedUnit, c.quantity, c.price),
      builder: (context, data, child) {
        final (total, unit, quantity, price) = data;
        final controller = context.read<ReturnEntryController>();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEF5350).withValues(alpha: 0.1),
                const Color(0xFFEF5350).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF5350).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '退货金额合计',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    '¥ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                ],
              ),
              if (controller.quantityController.text.isNotEmpty &&
                  controller.priceController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${controller.quantityController.text} ${unit ?? '斤'} × ¥${controller.priceController.text}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 自动填充提示组件
class AutoFillIndicator extends StatelessWidget {
  const AutoFillIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ReturnEntryController, bool>(
      selector: (_, c) => c.isAutoFilled,
      builder: (context, isAutoFilled, child) {
        if (!isAutoFilled) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              Icon(
                TDIcons.check_circle_filled,
                size: 14,
                color: TDTheme.of(context).successNormalColor,
              ),
              const SizedBox(width: 4),
              Text(
                '已自动填充采购信息',
                style: TextStyle(
                  fontSize: 12,
                  color: TDTheme.of(context).successNormalColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
