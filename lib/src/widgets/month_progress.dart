import 'package:flutter/material.dart';

class MonthProgress extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  const MonthProgress({Key? key, required this.totalBudget, required this.totalSpent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasBudget = totalBudget > 0;
    final progress = hasBudget ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final over = hasBudget && totalSpent > totalBudget;
    final remainingPct = hasBudget ? (((totalBudget - totalSpent) / totalBudget) * 100).clamp(-999.0, 999.0) : 0.0;

    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final header = 'Overview - ${monthNames[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Text(header, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 182,
              height: 182,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // outer border
                  Container(
                    width: 182,
                    height: 182,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade100, width: 1),
                    ),
                  ),
                  // progress ring (slightly smaller than outer border)
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      color: over ? Colors.red : Colors.pinkAccent,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  // inner border around the center content
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade100, width: 1),
                      color: Colors.white,
                    ),
                  ),
                  // central labels
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Budget', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('${totalBudget.toStringAsFixed(0)} Tk', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(
                        height: 8,
                        thickness: 1,
                        indent: 40,
                        endIndent: 40,
                        color: Colors.grey,
                      ),
                      Text('Spent', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('${totalSpent.toStringAsFixed(0)} Tk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: over ? Colors.red : Colors.black87)),
                      const Divider(
                        height: 8,
                        thickness: 1,
                        indent: 40,
                        endIndent: 40,
                        color: Colors.grey,
                      ),
                      if (hasBudget)
                        Text('${remainingPct.toStringAsFixed(0)}% remaining', style: const TextStyle(fontSize: 12, color: Colors.black54))
                      else
                        const Text('No budget set', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
