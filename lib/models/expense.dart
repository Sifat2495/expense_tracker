import 'dart:convert';

class Expense {
  final String id;
  final String category;
  final String subCategory;
  final String title;
  final double amount;
  final String details;
  final DateTime date;

  Expense({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.title,
    required this.amount,
    required this.details,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'subCategory': subCategory,
        'title': title,
        'amount': amount,
        'details': details,
        'date': date.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        category: (m['category'] ?? '') as String,
        subCategory: (m['subCategory'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        amount: (m['amount'] as num).toDouble(),
        details: (m['details'] ?? '') as String,
        date: DateTime.parse(m['date'] as String),
      );

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String s) => Expense.fromMap(json.decode(s) as Map<String, dynamic>);
}
