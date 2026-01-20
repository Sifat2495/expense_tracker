import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../core/theme.dart';

class SummaryPage extends StatefulWidget {
  final List<Expense> expenses;
  final Map<String, double> budgets;
  const SummaryPage({Key? key, required this.expenses, required this.budgets}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late DateTime _selected;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
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
    final totalSpent = filtered.fold(0.0, (p, n) => p + n.amount);
    final totalBudget = widget.budgets.values.fold(0.0, (p, n) => p + n);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Summary',
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Month selector header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.radiusXL),
                  topRight: Radius.circular(AppDimens.radiusXL),
                ),
              ),
              child: Column(
                children: [
                  // Month navigation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      boxShadow: AppShadows.small,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left, color: AppColors.primary),
                          ),
                          onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month - 1)),
                        ),
                        Column(
                          children: [
                            Text(
                              _monthNames[month - 1],
                              style: AppTextStyles.heading3,
                            ),
                            Text(
                              '$year',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right, color: AppColors.primary),
                          ),
                          onPressed: () => setState(() => _selected = DateTime(_selected.year, _selected.month + 1)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppDimens.paddingL),
                  
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Spent',
                          '${totalSpent.toStringAsFixed(0)} Tk',
                          Icons.shopping_cart_outlined,
                          AppColors.error,
                          AppColors.errorLight,
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: _buildSummaryCard(
                          'Budget',
                          '${totalBudget.toStringAsFixed(0)} Tk',
                          Icons.savings_outlined,
                          AppColors.success,
                          AppColors.successLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Category breakdown
          Expanded(
            child: cat.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(AppDimens.paddingL),
                    children: [
                      Text(
                        'Category Breakdown',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      ...cat.entries.map((e) {
                        final budget = widget.budgets[e.key] ?? 0.0;
                        final spent = e.value;
                        final progress = (budget > 0) ? (spent / budget).clamp(0.0, 1.0) : 0.0;
                        final over = budget > 0 && spent > budget;
                        final subs = subTotals[e.key] ?? {};
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            boxShadow: AppShadows.small,
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL, vertical: AppDimens.paddingS),
                              childrenPadding: const EdgeInsets.fromLTRB(AppDimens.paddingL, 0, AppDimens.paddingL, AppDimens.paddingL),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (over ? AppColors.errorLight : AppColors.primaryLight).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.folder_outlined,
                                  color: over ? AppColors.error : AppColors.primary,
                                ),
                              ),
                              title: Text(
                                e.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: budget > 0
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 6,
                                          color: over ? AppColors.error : AppColors.success,
                                          backgroundColor: AppColors.divider,
                                        ),
                                      ),
                                    )
                                  : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${spent.toStringAsFixed(0)} Tk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: over ? AppColors.error : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (budget > 0)
                                    Text(
                                      'of ${budget.toStringAsFixed(0)} Tk',
                                      style: AppTextStyles.caption,
                                    ),
                                ],
                              ),
                              children: [
                                if (subs.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(AppDimens.paddingM),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 18, color: AppColors.textHint),
                                        const SizedBox(width: 8),
                                        Text('No subcategory expenses', style: AppTextStyles.bodySecondary),
                                      ],
                                    ),
                                  )
                                else
                                  ...subs.entries.map((s) => Container(
                                    margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
                                    padding: const EdgeInsets.all(AppDimens.paddingM),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(s.key)),
                                        Text(
                                          '${s.value.toStringAsFixed(0)} Tk',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'No expenses this month',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Start tracking to see your summary',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
