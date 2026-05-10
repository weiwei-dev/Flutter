import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../services/backup_service.dart';
import '../../services/version_service.dart';
import '../../components/tab_bar.dart';
import 'package:file_selector/file_selector.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _version = '1.0.0';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _initVersion();
  }

  /// 初始化版本信息
  Future<void> _initVersion() async {
    await VersionService.instance.init();
    if (mounted) {
      setState(() {
        _version = VersionService.instance.version;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _backupDatabase() async {
    setState(() => _isBackingUp = true);

    try {
      await BackupService.instance.backupDatabase();
      if (mounted) {
        TDToast.showSuccess('备份成功', context: context);
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('备份失败: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() => _isRestoring = true);

    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'Database Backup', extensions: ['db']),
        ],
      );

      if (file != null) {
        await BackupService.instance.restoreDatabase(file.path);
        if (mounted) {
          TDToast.showSuccess('恢复成功，请重启应用', context: context);
        }
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('恢复失败: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // 渐变头部
          SliverToBoxAdapter(
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
                      TDText(
                        '更多功能',
                        font: TDTheme.of(context).fontTitleMedium,
                        textColor: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      // 系统信息卡片
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
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
                                TDText(
                                  '水果采购管理系统',
                                  font: Font(size: 10, lineHeight: 12),
                                  textColor: Colors.white.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                TDText(
                                  '版本 $_version',
                                  font: Font(size: 14, lineHeight: 20),
                                  textColor: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                TDIcons.cart,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 快捷功能
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TDText(
                                '快捷功能',
                                font: TDTheme.of(context).fontTitleSmall,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionItem(
                                icon: TDIcons.search,
                                title: '全局搜索',
                                subtitle: '搜索所有采购和退货记录',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/search'),
                                color: const Color(0xFF26A69A),
                              ),
                              const Divider(height: 16),
                              _buildQuickActionItem(
                                icon: TDIcons.history,
                                title: '历史记录',
                                subtitle: '查看和导出采购历史',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/history'),
                                color: const Color(0xFF42A5F5),
                              ),
                              const Divider(height: 16),
                              _buildQuickActionItem(
                                icon: TDIcons.camera,
                                title: '截图功能',
                                subtitle: '快速截图保存重要信息',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/screenshot'),
                                color: TDTheme.of(context).brandNormalColor,
                              ),
                              const Divider(height: 16),
                              _buildQuickActionItem(
                                icon: TDIcons.rollback,
                                title: '退货管理',
                                subtitle: '管理退货记录与退款',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/returns'),
                                color: const Color(0xFFFFA726),
                              ),
                              const Divider(height: 16),
                              _buildQuickActionItem(
                                icon: TDIcons.edit_1,
                                title: '补入采购',
                                subtitle: '查看所有补录的采购记录',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/supplement'),
                                color: const Color(0xFFAB47BC),
                              ),
                              const Divider(height: 16),
                              _buildQuickActionItem(
                                icon: TDIcons.chart,
                                title: '数据分析',
                                subtitle: '采购数据统计与分析',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/analysis'),
                                color: const Color(0xFF9C27B0),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 数据备份卡片
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF42A5F5,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      TDIcons.cloud_upload,
                                      color: const Color(0xFF42A5F5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TDText(
                                          '数据备份',
                                          font: TDTheme.of(
                                            context,
                                          ).fontBodyMedium,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const SizedBox(height: 2),
                                        TDText(
                                          '保护您的数据安全',
                                          font: Font(size: 11, lineHeight: 14),
                                          textColor: Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildActionButton(
                                icon: TDIcons.cloud_upload,
                                label: '备份数据',
                                isLoading: _isBackingUp,
                                onTap: _backupDatabase,
                                color: const Color(0xFF42A5F5),
                              ),
                              const SizedBox(height: 8),
                              _buildActionButton(
                                icon: TDIcons.cloud_download,
                                label: '恢复数据',
                                isLoading: _isRestoring,
                                onTap: _restoreDatabase,
                                color: const Color(0xFFFFA726),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      TDIcons.tips,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TDText(
                                        '建议定期备份数据，以防数据丢失。恢复数据会覆盖当前所有数据。',
                                        font: Font(size: 11, lineHeight: 14),
                                        textColor: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 数据清理卡片
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pushNamed(context, '/cleanup'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF5350,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        TDIcons.delete,
                                        color: const Color(0xFFEF5350),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TDText(
                                            '数据清理',
                                            font: TDTheme.of(
                                              context,
                                            ).fontBodyMedium,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          const SizedBox(height: 2),
                                          TDText(
                                            '检测并清理重复数据，支持回滚',
                                            font: Font(
                                              size: 11,
                                              lineHeight: 14,
                                            ),
                                            textColor: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      TDIcons.chevron_right,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      TDIcons.tips,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TDText(
                                        '支持检测重复数据、清理重复项、查看清理历史，误删数据可随时回滚恢复',
                                        font: Font(size: 11, lineHeight: 14),
                                        textColor: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 应用描述
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                TDIcons.info_circle,
                                size: 24,
                                color: TDTheme.of(context).brandNormalColor,
                              ),
                              const SizedBox(height: 10),
                              TDText(
                                '一个简洁高效的水果采购管理应用，帮助您轻松记录采购信息、管理账目、追踪结算状态。',
                                font: Font(size: 12, lineHeight: 18),
                                textColor: Colors.grey.shade700,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 版权信息
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TDTheme.of(
                            context,
                          ).brandNormalColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: TDTheme.of(
                              context,
                            ).brandNormalColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              TDIcons.heart,
                              color: TDTheme.of(context).brandNormalColor,
                              size: 16,
                            ),
                            const SizedBox(height: 8),
                            TDText(
                              '© 2024 水果采购管理系统',
                              font: Font(size: 12, lineHeight: 16),
                              textColor: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            const SizedBox(height: 2),
                            TDText(
                              '用心打造，为您而来',
                              font: Font(size: 10, lineHeight: 12),
                              textColor: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TabBarWidgetWrapper(activeIndex: 3),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    required Color color,
  }) {
    return TDButton(
      text: label,
      size: TDButtonSize.medium,
      type: TDButtonType.outline,
      theme: TDButtonTheme.primary,
      style: TDButtonStyle(
        backgroundColor: isLoading
            ? Colors.grey.shade100
            : color.withValues(alpha: 0.05),
        textColor: color,
      ),
      icon: icon,
      disabled: isLoading,
      isBlock: true,
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDText(
                    title,
                    font: TDTheme.of(context).fontBodySmall,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  TDText(
                    subtitle,
                    font: Font(size: 11, lineHeight: 14),
                    textColor: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            Icon(TDIcons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
