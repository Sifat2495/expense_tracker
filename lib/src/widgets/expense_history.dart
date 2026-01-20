import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../core/theme.dart';

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingXXL),
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
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'No transactions yet',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add your first expense',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    // Show only recent 10 expenses on home
    final displayExpenses = expenses.take(10).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: displayExpenses.length,
          itemBuilder: (context, i) {
            final e = displayExpenses[i];
            return _buildExpenseItem(context, e);
          },
        ),
        if (expenses.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.paddingM),
            child: Text(
              '+ ${expenses.length - 10} more transactions',
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense e) {
    final dt = e.date.toLocal();
    final dateStr = '${dt.day} ${_monthAbbr[dt.month - 1]}';

    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // Let the parent handle confirmation
        onRemove(e.id);
        return false; // We handle removal externally
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.paddingXL),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          boxShadow: AppShadows.small,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Row(
            children: [
              // Amount badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.amount.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Tk',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppDimens.paddingM),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${e.category} › ${e.subCategory}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (e.details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        e.details,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: AppDimens.paddingS),
              
              // Date and delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => onRemove(e.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
