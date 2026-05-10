import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'procurement_provider.dart';

class AppProvider extends ChangeNotifier {
  final ProcurementProvider procurementProvider = ProcurementProvider();

  static AppProvider of(BuildContext context) {
    return Provider.of<AppProvider>(context, listen: false);
  }
}
