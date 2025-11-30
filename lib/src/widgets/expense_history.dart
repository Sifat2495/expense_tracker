import 'package:flutter/material.dart';

import '../../models/expense.dart';

const _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class ExpenseHistory extends StatelessWidget {
  final List<Expense> expenses;
  final ValueChanged<String> onRemove;

  const ExpenseHistory({
    Key? key,
    required this.expenses,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No history yet.'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(height: 4, color: Colors.grey),
      itemBuilder: (context, i) {
        final e = expenses[i];
        return ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 0,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FittedBox(
                child: Text(
                  '${e.amount.toStringAsFixed(0)}\nTk',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onRemove(e.id),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.delete, size: 20, color: Colors.red),
                ),
              ),
            ],
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 0, color: Colors.grey.shade400),
              Text('${e.category} › ${e.subCategory}'),
              if (e.details.isNotEmpty) Text(e.details),
              Builder(
                builder: (_) {
                  final dt = e.date.toLocal();
                  final ds =
                      '${dt.day.toString().padLeft(2, '0')} ${_monthAbbr[dt.month - 1]}, ${dt.year}';
                  return Text(ds);
                },
              ),
            ],
          ),
          // trailing: IconButton(onPressed: () => onRemove(e.id), icon: const Icon(Icons.delete)),
        );
      },
    );
  }
}
