import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/expense.dart';
import '../../services/storage_service.dart';
import 'categories_page.dart';
import '../widgets/add_expense_dialog.dart';
import 'summary_page.dart';
import 'expense_history_page.dart';
import '../widgets/expense_history.dart';
import '../widgets/month_progress.dart';
import '../widgets/category_breakdown.dart';

final _uuid = Uuid();

class ExpenseHome extends StatefulWidget {
  final StorageService storage;
  const ExpenseHome({Key? key, required this.storage}) : super(key: key);

  @override
  State<ExpenseHome> createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  late List<Expense> _expenses;
  // Categories are loaded from storage; fallback defaults provided.
  late Map<String, List<String>> _categories;
  late Map<String, double> _budgets;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _expenses = widget.storage.loadExpenses();
    _categories = widget.storage.loadCategories();
    final now = DateTime.now();
    _budgets = widget.storage.loadBudgetsForMonth(now.year, now.month);
    // do not inject any default categories or subcategories; keep storage as-is (empty if nothing saved)
  }

  Future<void> _addExpense({required String category, required String subCategory, required String title, required double amount, required String details, required DateTime date}) async {
    final exp = Expense(id: _uuid.v4(), category: category, subCategory: subCategory, title: title, amount: amount, details: details, date: date);
    setState(() => _expenses.insert(0, exp));
    await widget.storage.saveExpenses(_expenses);
  }

  Future<void> _removeExpense(String id) async {
    setState(() => _expenses.removeWhere((e) => e.id == id));
    await widget.storage.saveExpenses(_expenses);
  }

  void _showAddDialog() {
    showDialog(context: context, builder: (c) => AddExpenseDialog(categories: _categories, onAdd: (category, sub, title, amount, details, date) async { await _addExpense(category: category, subCategory: sub, title: title, amount: amount, details: details, date: date); }));
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final monthExpenses = _expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final totalSpent = monthExpenses.fold<double>(0.0, (p, n) => p + n.amount);
    final totalBudget = _budgets.values.fold<double>(0.0, (p, n) => p + n);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 5,
          shadowColor: Colors.black54,
          centerTitle: false,
          title: const Text('Family Expense Tracker', style: TextStyle(fontFamily: 'LeckerliOne', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          ],
        ),
        endDrawer: Drawer(
          width: width * 0.7,
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories & Budgets'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoriesPage(categories: _categories, onChanged: (m) async {
                        setState(() => _categories = Map.from(m));
                        await widget.storage.saveCategories(_categories);
                      }, budgets: _budgets, onBudgetsChanged: (b) async {
                        setState(() => _budgets = Map.from(b));
                        final now = DateTime.now();
                        await widget.storage.saveBudgetsForMonth(now.year, now.month, _budgets);
                      })));
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Summary'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => SummaryPage(expenses: _expenses, budgets: _budgets)));
                },
              )
              ,
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Expense History'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseHistoryPage(expenses: _expenses)));
                },
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonthProgress(totalBudget: totalBudget, totalSpent: totalSpent),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 0,
                      thickness: 1,
                      color: Colors.black54,
                    ),
                    const SizedBox(height: 4),
                    const Center(child: Text('Category Wise Expenses', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 4),
                    const Divider(
                      height: 0,
                      thickness: 1,
                      color: Colors.black54,
                    ),
                    CategoryBreakdown(monthExpenses: monthExpenses, budgets: _budgets),
                  ],
                ),
              ),

              // Full-bleed History ribbon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                ),
                child: const Center(
                  child: Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ExpenseHistory(expenses: _expenses, onRemove: (id) async { await _removeExpense(id); }),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          foregroundColor: Colors.white,
          onPressed: _showAddDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // category breakdown moved to `CategoryBreakdown` widget
}
