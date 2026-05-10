import 'package:flutter/material.dart';

/// 页面动画混入
/// 为 StatefulWidget 提供统一的淡入动画效果
/// 使用示例：
/// ```dart
/// class _MyPageState extends State<MyPage>
///     with SingleTickerProviderStateMixin, PageAnimationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return FadeTransition(
///       opacity: fadeAnimation,
///       child: MyPageContent(),
///     );
///   }
/// }
/// ```
mixin PageAnimationMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  /// 动画持续时间，子类可覆盖
  Duration get animationDuration => const Duration(milliseconds: 300);

  /// 是否启用位移动画
  bool get enableSlideAnimation => false;

  /// 滑动起始位置
  Offset get slideBeginOffset => const Offset(0, 0.1);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    animationController.forward();
  }

  void _initAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
    );

    if (enableSlideAnimation) {
      slideAnimation = Tween<Offset>(
        begin: slideBeginOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  /// 重新播放动画
  void replayAnimation() {
    animationController.reset();
    animationController.forward();
  }
}

/// 带位移动画的混入
/// 适用于需要上滑进入效果的页面
mixin PageSlideAnimationMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  Duration get animationDuration => const Duration(milliseconds: 400);
  Offset get slideBeginOffset => const Offset(0, 0.2);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
    );

    slideAnimation = Tween<Offset>(
      begin: slideBeginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
