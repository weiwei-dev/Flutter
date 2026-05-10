import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/procurement.dart';
import '../../utils/db.dart';

class ProcurementProvider extends ChangeNotifier {
  List<ProcurementRecord> _records = [];
  bool _isLoading = false;

  List<ProcurementRecord> get records => _records;
  bool get isLoading => _isLoading;

  Future<void> loadRecords(String date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await DatabaseHelper.instance.getTodayRecords(date);
    } catch (e) {
      debugPrint('Error loading records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(ProcurementRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.insertRecord(record);
      await loadRecords(record.createTime.substring(0, 10));
    } catch (e) {
      debugPrint('Error adding record: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecord(ProcurementRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.updateRecord(record);
      await loadRecords(record.createTime.substring(0, 10));
    } catch (e) {
      debugPrint('Error updating record: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(int id, String date) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.deleteRecord(id);
      await loadRecords(date);
    } catch (e) {
      debugPrint('Error deleting record: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> settleRecords(List<int> ids, String settleTime) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.updateSettleStatus(ids, 1, settleTime);
      await loadRecords(settleTime.substring(0, 10));
    } catch (e) {
      debugPrint('Error settling records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
