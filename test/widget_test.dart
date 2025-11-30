// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/src/screens/expense_home.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/storage_service.dart';

void main() {
  testWidgets('Shows add button and empty message', (WidgetTester tester) async {
    final fake = _FakeStorage();
    await tester.pumpWidget(MaterialApp(home: ExpenseHome(storage: fake)));

    expect(find.text('No expenses yet. Tap + to add.'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

}

class _FakeStorage implements StorageService {
  _FakeStorage();
  @override
  List<Expense> loadExpenses() => [];

  @override
  Future<bool> saveExpenses(List<Expense> expenses) async => true;

  @override
  Map<String, List<String>> loadCategories() => {};

  @override
  Future<bool> saveCategories(Map<String, List<String>> cats) async => true;

  @override
  Map<String, double> loadBudgetsForMonth(int year, int month) => {};

  @override
  Future<bool> saveBudgetsForMonth(int year, int month, Map<String, double> budgets) async => true;
}

