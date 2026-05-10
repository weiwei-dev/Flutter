import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 通用页面头部组件
/// 统一所有页面的头部样式
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final Widget? bottom;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.height = 56,
    this.gradient,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.bottom,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);

    return Container(
      height: bottom != null ? null : height,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ?? theme.brandNormalColor)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: height,
              padding: padding,
              child: Row(
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: onBackPressed ?? () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    )
                  else
                    ...?(leading != null ? [leading!] : null),
                  if (showBackButton || leading != null)
                    const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TDText(
                          title,
                          font: TDTheme.of(context).fontTitleLarge,
                          textColor: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        if (subtitle case final subtitleText?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: TDText(
                              subtitleText,
                              font: Font(size: 12, lineHeight: 16),
                              textColor: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

/// 带渐变背景的页面头部
class GradientPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Color> gradientColors;
  final Widget? bottom;

  const GradientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.gradientColors = const [Color(0xFF4CAF50), Color(0xFF81C784)],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      bottom: bottom,
    );
  }
}
