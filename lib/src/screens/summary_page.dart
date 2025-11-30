import 'package:flutter/material.dart';

import '../../models/expense.dart';

class SummaryPage extends StatefulWidget {
  final List<Expense> expenses;
  final Map<String, double> budgets;
  const SummaryPage({Key? key, required this.expenses, required this.budgets}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
  }

  // helper methods removed; summary computes totals for selected month inline

  @override
  Widget build(BuildContext context) {
    // filter expenses for selected month
    final year = _selected.year;
    final month = _selected.month;
    final filtered = widget.expenses.where((e) => e.date.year == year && e.date.month == month).toList();
    final cat = <String, double>{};
    final Map<String, Map<String, double>> subTotals = {};
    for (final e in filtered) {
      cat[e.category] = (cat[e.category] ?? 0) + e.amount;
      final sm = subTotals.putIfAbsent(e.category, () => {});
      sm[e.subCategory] = (sm[e.subCategory] ?? 0) + e.amount;
    }
    final mon = { '${year}-${month.toString().padLeft(2,'0')}': filtered.fold(0.0, (p, n) => p + n.amount) };
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            'Summary',
            style: TextStyle(
              fontFamily: 'LeckerliOne',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Category Totals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month - 1))),
                  Text('${_selected.year}-${_selected.month.toString().padLeft(2,'0')}'),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month + 1))),
                ])
              ]),
              const SizedBox(height: 8),
              ...cat.entries.map((e) {
                final budget = widget.budgets[e.key] ?? 0.0;
                final spent = e.value;
                final progress = (budget > 0) ? (spent / budget).clamp(0.0, 2.0) : 0.0;
                final over = budget > 0 && spent > budget;
                final subs = subTotals[e.key] ?? {};
                return ExpansionTile(
                  title: Text(e.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: budget > 0
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: LinearProgressIndicator(value: progress, color: over ? Colors.red : Colors.pinkAccent, backgroundColor: Colors.grey[200]),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${spent.toStringAsFixed(1)} Tk', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (budget > 0) Text('of ${budget.toStringAsFixed(1)} Tk', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  children: [
                    if (subs.isEmpty)
                      const ListTile(title: Text('No subcategory expenses'))
                    else
                      ...subs.entries.map((s) => ListTile(
                        contentPadding: EdgeInsets.only(left:30, right:20, top: 0, bottom: 0),
                            title: Text(s.key),
                            trailing: Text('\$${s.value.toStringAsFixed(1)}'),
                          ))
                  ],
                );
              }),
              const Divider(),
              const Text('Month Totals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...mon.entries.map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value.toStringAsFixed(1)} Tk'))),
            ],
          ),
        ),
      ),
    );
  }
}
