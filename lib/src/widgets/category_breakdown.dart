import 'package:flutter/material.dart';
import '../../models/expense.dart';

class CategoryBreakdown extends StatelessWidget {
  final List<Expense> monthExpenses;
  final Map<String, double> budgets;

  const CategoryBreakdown({Key? key, required this.monthExpenses, required this.budgets}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (final e in monthExpenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    if (totals.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No category expenses this month.'));
      final cards = totals.entries.map((e) {
        final budget = budgets[e.key] ?? 0.0;
        final spent = e.value;
        final progress = (budget > 0) ? (spent / budget).clamp(0.0, 2.0) : 0.0;
        final over = budget > 0 && spent > budget;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${spent.toStringAsFixed(1)} Tk'),
                        // if (budget > 0)
                        //   Text('of ${budget.toStringAsFixed(1)} Tk', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                if (budget > 0) ...[
                  // const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            color: over ? Colors.red : Colors.pinkAccent,
                            backgroundColor: Colors.green[200],
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('of ${budget.toStringAsFixed(1)} Tk', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList();

      return Column(children: cards);
  }
}
