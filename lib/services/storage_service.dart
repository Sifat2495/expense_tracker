import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class StorageService {
  static const _key = 'expenses_v1';
  static const _catKey = 'categories_v1';
  static const _budgetKey = 'budgets_v1';

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  List<Expense> loadExpenses() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list.map((e) => Expense.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveExpenses(List<Expense> expenses) async {
    final jsonStr = json.encode(expenses.map((e) => e.toMap()).toList());
    return _prefs.setString(_key, jsonStr);
  }

  /// Categories are stored as a map from category -> list of subcategories
  Map<String, List<String>> loadCategories() {
    final raw = _prefs.getString(_catKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> m = json.decode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e as String).toList()));
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveCategories(Map<String, List<String>> cats) async {
    final jsonStr = json.encode(cats.map((k, v) => MapEntry(k, v)));
    return _prefs.setString(_catKey, jsonStr);
  }

  /// Budgets are stored flattened with keys like 'Category|YYYY-MM' -> amount
  /// Use `loadBudgetsForMonth(year, month)` to get a category->amount map for a specific month.
  Map<String, double> loadBudgetsForMonth(int year, int month) {
    final raw = _prefs.getString(_budgetKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> m = json.decode(raw) as Map<String, dynamic>;
      final Map<String, double> result = {};
      final suffix = '-${month.toString().padLeft(2, '0')}';
      m.forEach((k, v) {
        // expect format 'Category|YYYY-MM'
        final parts = k.split('|');
        if (parts.length == 2 && parts[1].endsWith(suffix) && parts[1].startsWith(year.toString())) {
          result[parts[0]] = (v as num).toDouble();
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Save budgets for a specific month. The map should be category -> amount.
  Future<bool> saveBudgetsForMonth(int year, int month, Map<String, double> budgets) async {
    final raw = _prefs.getString(_budgetKey);
    Map<String, dynamic> m = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        m = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        m = {};
      }
    }
    // remove existing entries for this month
    final prefix = '|${year.toString()}-${month.toString().padLeft(2, '0')}';
    final keysToRemove = m.keys.where((k) => k.contains(prefix)).toList();
    for (final k in keysToRemove) m.remove(k);
    // add new entries
    budgets.forEach((cat, amt) {
      m['$cat|${year.toString()}-${month.toString().padLeft(2, '0')}'] = amt;
    });
    final jsonStr = json.encode(m);
    return _prefs.setString(_budgetKey, jsonStr);
  }
}
