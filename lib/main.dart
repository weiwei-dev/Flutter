import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/db_service.dart';
import 'utils/category_group_override.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log('Application starting...');

  // 初始化数据库
  log('Initializing database...');
  await DbService.instance.initDatabase();
  log('Database initialized successfully');

  // 加载用户手动指定的品类大类（盘点分组用）
  await CategoryGroupOverride.load();

  log('Running app...');
  runApp(const MyApp());
  log('App started');
}
