import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/providers/procurement_provider.dart';

/// Provider 扩展
/// 简化 Provider 的获取和使用
extension BuildContextProviderExtensions on BuildContext {
  /// 获取 ProcurementProvider（不监听）
  ProcurementProvider get procurementProvider =>
      Provider.of<ProcurementProvider>(this, listen: false);

  /// 获取 ProcurementProvider（监听）
  ProcurementProvider get watchProcurementProvider =>
      Provider.of<ProcurementProvider>(this, listen: true);

  /// 安全地获取 Provider
  T? tryGet<T>() {
    try {
      return Provider.of<T>(this, listen: false);
    } catch (_) {
      return null;
    }
  }
}

/// 异步操作混入
/// 简化页面中的异步操作和加载状态管理
mixin AsyncOperationMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// 执行异步操作，自动管理加载状态和错误
  /// 
  /// 使用示例：
  /// ```dart
  /// Future<void> loadData() async {
  ///   await runAsync(() async {
  ///     final data = await api.fetchData();
  ///     setState(() => _data = data);
  ///   }, errorMessage: '加载失败');
  /// }
  /// ```
  Future<void> runAsync(
    Future<void> Function() operation, {
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await operation();
      onSuccess?.call();
    } catch (e) {
      setState(() {
        _errorMessage = errorMessage ?? e.toString();
      });
      onError?.call();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清除错误状态
  void clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
}
