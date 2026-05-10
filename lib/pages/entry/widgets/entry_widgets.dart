import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/constants/app_constants.dart';

/// 区块标题
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppConstants.fontSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// 自定义输入框
class EntryInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData leftIcon;
  final TextInputType? inputType;
  final bool required;
  final String? prefixText;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const EntryInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.leftIcon,
    this.inputType,
    this.required = false,
    this.prefixText,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: maxLines == 1 ? AppConstants.inputHeight : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(
              color: errorText != null
                  ? TDTheme.of(context).errorNormalColor
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TDInput(
            controller: controller,
            backgroundColor: Colors.transparent,
            leftIcon: Icon(leftIcon, size: 16, color: AppColors.textSecondary),
            inputType: inputType,
            leftLabel: '',
            hintText: placeholder,
            maxLines: maxLines,
            additionInfo: '',
            required: required,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            hintTextStyle: TextStyle(
              fontSize: AppConstants.fontMedium,
              color: Colors.grey.shade400,
            ),
            textStyle: const TextStyle(fontSize: AppConstants.fontMedium),
            onChanged: onChanged ?? (value) {},
            onEditingComplete: onEditingComplete,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: AppConstants.fontSmall,
                color: TDTheme.of(context).errorNormalColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// 单位选择器
class UnitSelector extends StatelessWidget {
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const UnitSelector({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.inputHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedUnit,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
            size: 16,
          ),
          style: const TextStyle(
            fontSize: AppConstants.fontMedium,
            color: AppColors.textPrimary,
          ),
          items: units.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

/// 图片选择器
class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const ImagePickerWidget({
    super.key,
    this.imageFile,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
          border: Border.all(
            color: imageFile != null
                ? TDTheme.of(context).brandNormalColor.withValues(alpha: 0.3)
                : AppColors.border,
            width: imageFile != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile!, fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            TDIcons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TDTheme.of(
                        context,
                      ).brandNormalColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.smallRadius,
                      ),
                    ),
                    child: Icon(
                      TDIcons.camera,
                      size: 20,
                      color: TDTheme.of(context).brandNormalColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '点击拍照或选择图片',
                    style: TextStyle(
                      fontSize: AppConstants.fontMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 图片源选择弹窗
class ImageSourcePicker extends StatelessWidget {
  const ImageSourcePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '选择图片来源',
                style: TextStyle(
                  fontSize: AppConstants.fontLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TDTheme.of(
                      context,
                    ).brandNormalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    TDIcons.camera,
                    color: TDTheme.of(context).brandNormalColor,
                  ),
                ),
                title: const Text('拍照'),
                subtitle: const Text('使用相机拍摄照片'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TDTheme.of(
                      context,
                    ).brandNormalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    TDIcons.image,
                    color: TDTheme.of(context).brandNormalColor,
                  ),
                ),
                title: const Text('从相册选择'),
                subtitle: const Text('选择手机相册中的照片'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TDButton(
                  text: '取消',
                  size: TDButtonSize.large,
                  type: TDButtonType.outline,
                  theme: TDButtonTheme.primary,
                  isBlock: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 总计显示卡片
class TotalAmountCard extends StatelessWidget {
  final double amount;

  const TotalAmountCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '实付总计',
                style: TextStyle(
                  fontSize: AppConstants.fontSmall,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '¥${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(TDIcons.cart_add, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
