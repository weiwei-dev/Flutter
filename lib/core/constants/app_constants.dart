import 'package:flutter/material.dart';

/// 应用常量
class AppConstants {
  AppConstants._();

  // 单位列表
  static const List<String> units = ['件', 'kg', 'g', '个', '箱', '袋', '斤', '盒'];
  
  // 默认单位
  static const String defaultUnit = '斤';
  
  // 动画持续时间
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // 页面边距
  static const double pagePadding = 12.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 12.0;
  static const double itemSpacing = 6.0;
  
  // 圆角
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double xlargeRadius = 20.0;
  
  // 图标大小
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  
  // 字体大小
  static const double fontSmall = 10.0;
  static const double fontMedium = 12.0;
  static const double fontNormal = 13.0;
  static const double fontLarge = 14.0;
  static const double fontXLarge = 16.0;
  static const double fontXXLarge = 18.0;
  static const double fontTitle = 20.0;
  
  // 输入框高度
  static const double inputHeight = 38.0;
  
  // 按钮高度
  static const double buttonSmall = 32.0;
  static const double buttonMedium = 40.0;
  static const double buttonLarge = 48.0;
}

/// 颜色常量
class AppColors {
  AppColors._();
  
  // 主色调
  static const Color primary = Color(0xFF0052D9);
  static const Color primaryLight = Color(0xFFE8F4FF);
  static const Color danger = Color(0xFFEF5350);
  static const Color dangerLight = Color(0xFFFEF0F0);
  static const Color success = Color(0xFF00A870);
  static const Color warning = Color(0xFFFFB800);
  
  // 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  
  // 文字色
  static const Color textPrimary = Color(0xFF1F2329);
  static const Color textSecondary = Color(0xFF8F959E);
  static const Color textTertiary = Color(0xFFC4C4C4);
  
  // 边框色
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderLight = Color(0xFFF0F0F0);
  
  // 阴影色
  static Color shadow = Colors.black.withValues(alpha: 0.02);
}

/// 文本样式常量
class AppTextStyles {
  AppTextStyles._();
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const TextStyle moneyLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.danger,
  );
  
  static const TextStyle moneyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

/// 装饰样式常量
class AppDecorations {
  AppDecorations._();
  
  static BoxDecoration card = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration input = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration gradientHeader = const BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, Color(0xFF0066FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(AppConstants.xlargeRadius),
    ),
  );
  
  static BoxDecoration dangerGradientHeader = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: const BorderRadius.vertical(
      bottom: Radius.circular(AppConstants.xlargeRadius),
    ),
  );
}
