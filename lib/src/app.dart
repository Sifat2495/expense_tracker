import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'screens/expense_home.dart';

class ExpenseApp extends StatelessWidget {
  final StorageService storage;

  const ExpenseApp({Key? key, required this.storage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seed = Colors.pink.shade400;
    return MaterialApp(
      title: 'Family Expense Tracker',
      theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: seed)).copyWith(
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: seed),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: seed),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: seed)),
      ),
      home: ExpenseHome(storage: storage),
    );
  }
}
