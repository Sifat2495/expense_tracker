import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../core/theme.dart';

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
    
    if (totals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'No expenses this month',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Add an expense to see category breakdown',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((e) {
        final budget = budgets[e.key] ?? 0.0;
        final spent = e.value;
        final progress = (budget > 0) ? (spent / budget).clamp(0.0, 1.0) : 0.0;
        final over = budget > 0 && spent > budget;
        final percentage = budget > 0 ? (spent / budget * 100) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            boxShadow: AppShadows.small,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (over ? AppColors.errorLight : AppColors.primaryLight).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: over ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    
                    // Category name and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (budget > 0) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    color: over ? AppColors.error : AppColors.success,
                                    backgroundColor: AppColors.divider,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: AppDimens.paddingM),
                    
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${spent.toStringAsFixed(0)} Tk',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: over ? AppColors.error : AppColors.textPrimary,
                          ),
                        ),
                        if (budget > 0)
                          Text(
                            '${percentage.toStringAsFixed(0)}% of ${budget.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: over ? AppColors.error : AppColors.textSecondary,
                            ),
                          )
                        else
                          Text(
                            'No budget set',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
