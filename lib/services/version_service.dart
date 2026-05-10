import 'package:package_info_plus/package_info_plus.dart';

/// 应用版本信息服务
class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  static VersionService get instance => _instance;

  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _initialized = false;

  /// 获取应用版本号 (如: 1.0.9)
  String get version => _version;

  /// 获取应用构建号 (如: 10)
  String get buildNumber => _buildNumber;

  /// 获取完整版本信息 (如: 1.0.9+10)
  String get fullVersion => '$_version+$_buildNumber';

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 初始化版本信息
  Future<void> init() async {
    if (_initialized) return;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _initialized = true;
    } catch (e) {
      // 如果获取失败，使用默认版本号
      _version = '1.0.0';
      _buildNumber = '1';
    }
  }

  /// 获取格式化的版本字符串
  String getFormattedVersion({bool showBuildNumber = false}) {
    if (showBuildNumber && _buildNumber.isNotEmpty) {
      return '$_version ($_buildNumber)';
    }
    return _version;
  }
}
