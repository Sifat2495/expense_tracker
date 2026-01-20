import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../core/theme.dart';

enum SortOrder { amountAsc, amountDesc, dateAsc, dateDesc }

class ExpenseHistoryPage extends StatefulWidget {
  final List<Expense> expenses;
  const ExpenseHistoryPage({Key? key, required this.expenses}) : super(key: key);

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  late List<Expense> _all;
  late List<Expense> _filtered;

  DateTime? _from;
  DateTime? _to;
  String? _category;
  String? _subCategory;
  SortOrder _sort = SortOrder.dateDesc;
  String _query = '';
  bool _showFilters = false;

  static const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _all = List.from(widget.expenses);
    _applyFilters();
  }

  void _applyFilters() {
    var list = _all.where((e) {
      if (_from != null && e.date.isBefore(_from!)) return false;
      if (_to != null && e.date.isAfter(_to!)) return false;
      if (_category != null && _category!.isNotEmpty && e.category != _category) return false;
      if (_subCategory != null && _subCategory!.isNotEmpty && e.subCategory != _subCategory) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!e.title.toLowerCase().contains(q) && !e.details.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case SortOrder.amountAsc:
          return a.amount.compareTo(b.amount);
        case SortOrder.amountDesc:
          return b.amount.compareTo(a.amount);
        case SortOrder.dateAsc:
          return a.date.compareTo(b.date);
        case SortOrder.dateDesc:
          return b.date.compareTo(a.date);
      }
    });

    setState(() => _filtered = list);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      setState(() => _from = DateTime(d.year, d.month, d.day));
      _applyFilters();
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      setState(() => _to = DateTime(d.year, d.month, d.day, 23, 59, 59));
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
      _category = null;
      _subCategory = null;
      _query = '';
      _sort = SortOrder.dateDesc;
      _showFilters = false;
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _from != null || _to != null || _category != null || _subCategory != null;

  @override
  Widget build(BuildContext context) {
    final cats = <String>{};
    final subs = <String>{};
    for (final e in _all) {
      cats.add(e.category);
      if (e.subCategory.isNotEmpty) subs.add(e.subCategory);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Expense History',
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Badge(
                isLabelVisible: _hasActiveFilters,
                backgroundColor: AppColors.warning,
                child: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                ),
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'Toggle Filters',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and sort bar
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.radiusXL),
                  topRight: Radius.circular(AppDimens.radiusXL),
                ),
              ),
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      boxShadow: AppShadows.small,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                              hintText: 'Search expenses...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (v) {
                              _query = v;
                              _applyFilters();
                            },
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.divider,
                        ),
                        PopupMenuButton<SortOrder>(
                          tooltip: 'Sort',
                          icon: const Icon(Icons.sort, color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          ),
                          onSelected: (s) {
                            setState(() => _sort = s);
                            _applyFilters();
                          },
                          itemBuilder: (_) => [
                            _buildSortItem(SortOrder.dateDesc, 'Date: Newest first', Icons.arrow_downward),
                            _buildSortItem(SortOrder.dateAsc, 'Date: Oldest first', Icons.arrow_upward),
                            _buildSortItem(SortOrder.amountDesc, 'Amount: High → Low', Icons.trending_down),
                            _buildSortItem(SortOrder.amountAsc, 'Amount: Low → High', Icons.trending_up),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter panel
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _showFilters ? null : 0,
                    child: AnimatedOpacity(
                      opacity: _showFilters ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _showFilters
                          ? Padding(
                              padding: const EdgeInsets.only(top: AppDimens.paddingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Text('Filters', style: AppTextStyles.subtitle),
                                      const Spacer(),
                                      if (_hasActiveFilters)
                                        TextButton.icon(
                                          onPressed: _clearFilters,
                                          icon: const Icon(Icons.clear, size: 16),
                                          label: const Text('Clear'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimens.paddingM),
                                  
                                  // Date filters
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFilterButton(
                                          icon: Icons.calendar_today,
                                          label: _from == null
                                              ? 'From date'
                                              : '${_from!.day} ${_monthAbbr[_from!.month - 1]}',
                                          onTap: _pickFrom,
                                          isActive: _from != null,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.paddingS),
                                      Expanded(
                                        child: _buildFilterButton(
                                          icon: Icons.calendar_today,
                                          label: _to == null
                                              ? 'To date'
                                              : '${_to!.day} ${_monthAbbr[_to!.month - 1]}',
                                          onTap: _pickTo,
                                          isActive: _to != null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: AppDimens.paddingS),
                                  
                                  // Category filters
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                            border: Border.all(
                                              color: _category != null ? AppColors.primary : AppColors.divider,
                                            ),
                                          ),
                                          child: DropdownButton<String?>(
                                            value: _category,
                                            hint: const Text('Category'),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items: [
                                              const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                                              ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))).toList()
                                            ],
                                            onChanged: (v) {
                                              setState(() => _category = v);
                                              _applyFilters();
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.paddingS),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                            border: Border.all(
                                              color: _subCategory != null ? AppColors.primary : AppColors.divider,
                                            ),
                                          ),
                                          child: DropdownButton<String?>(
                                            value: _subCategory,
                                            hint: const Text('Subcategory'),
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items: [
                                              const DropdownMenuItem<String?>(value: null, child: Text('All subcategories')),
                                              ...subs.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))).toList()
                                            ],
                                            onChanged: (v) {
                                              setState(() => _subCategory = v);
                                              _applyFilters();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Results info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL, vertical: AppDimens.paddingS),
            color: AppColors.background,
            child: Text(
              '${_filtered.length} expense${_filtered.length == 1 ? '' : 's'} found',
              style: AppTextStyles.caption,
            ),
          ),

          // Expense list
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.paddingL),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final e = _filtered[i];
                      return _buildExpenseCard(e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<SortOrder> _buildSortItem(SortOrder order, String label, IconData icon) {
    final isSelected = _sort == order;
    return PopupMenuItem(
      value: order,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense e) {
    final dt = e.date.toLocal();
    final dateStr = '${dt.day} ${_monthAbbr[dt.month - 1]}, ${dt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Row(
          children: [
            // Amount circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    e.amount.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.category} › ${e.subCategory}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
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
            
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXXL),
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
                Icons.search_off,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              _hasActiveFilters || _query.isNotEmpty
                  ? 'No matching expenses'
                  : 'No expenses yet',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              _hasActiveFilters || _query.isNotEmpty
                  ? 'Try adjusting your filters'
                  : 'Start tracking your expenses',
              style: AppTextStyles.bodySecondary,
            ),
            if (_hasActiveFilters || _query.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingL),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
