import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static final BackupService instance = BackupService._privateConstructor();

  BackupService._privateConstructor();

  // 备份数据库
  Future<void> backupDatabase() async {
    try {
      // 获取数据库路径
      String dbPath = await getDatabasesPath();
      String dbName = 'fruit_procurement.db';
      File dbFile = File('$dbPath/$dbName');

      // 获取备份目录
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backups';
      await Directory(backupPath).create(recursive: true);

      // 创建备份文件
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      String backupFileName = 'backup_$timestamp.db';
      File backupFile = File('$backupPath/$backupFileName');

      // 复制数据库文件
      await dbFile.copy(backupFile.path);

      // 分享备份文件
      await Share.shareXFiles([XFile(backupFile.path)], text: '水果采购管理系统备份文件');
    } catch (e) {
      debugPrint('Error backing up database: $e');
      rethrow;
    }
  }

  // 恢复数据库
  Future<void> restoreDatabase(String backupFilePath) async {
    try {
      // 获取数据库路径
      String dbPath = await getDatabasesPath();
      String dbName = 'fruit_procurement.db';
      File dbFile = File('$dbPath/$dbName');

      // 复制备份文件到数据库位置
      File backupFile = File(backupFilePath);
      await backupFile.copy(dbFile.path);
    } catch (e) {
      debugPrint('Error restoring database: $e');
      rethrow;
    }
  }

  // 获取所有备份文件
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backups';
      final dir = Directory(backupPath);
      if (!await dir.exists()) return [];
      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.db'))
          .toList();
      return files.map((file) => File(file.path)).toList();
    } catch (e) {
      debugPrint('Error getting backup files: $e');
      return [];
    }
  }
}
