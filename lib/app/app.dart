import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'dart:developer';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    log('Building MyApp...');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            log('Creating AppProvider...');
            return AppProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            log('Creating ProcurementProvider...');
            return Provider.of<AppProvider>(
              context,
              listen: false,
            ).procurementProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: '水果采购管理系统',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
