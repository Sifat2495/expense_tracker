import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_dialogs.dart';
import '../core/snackbar_service.dart';

class CategoriesPage extends StatefulWidget {
  final Map<String, List<String>> categories;
  final ValueChanged<Map<String, List<String>>> onChanged;
  final Map<String, double> budgets;
  final ValueChanged<Map<String, double>> onBudgetsChanged;
  const CategoriesPage({
    Key? key,
    required this.categories,
    required this.onChanged,
    required this.budgets,
    required this.onBudgetsChanged,
  }) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Map<String, List<String>> _cats;
  late Map<String, double> _budgets;

  @override
  void initState() {
    super.initState();
    _cats = Map.from(widget.categories);
    _budgets = Map.from(widget.budgets);
  }

  void _addCategory() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppDimens.paddingL),
              const Text(
                'New Category',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingL),
              TextField(
                controller: ctl,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
                  hintText: 'e.g., Food, Transport, Bills',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = ctl.text.trim();
                        if (name.isNotEmpty && !_cats.containsKey(name)) {
                          setState(() {
                            _cats[name] = [];
                            _budgets[name] = 0.0;
                          });
                          widget.onChanged(_cats);
                          widget.onBudgetsChanged(_budgets);
                          Navigator.of(context).pop();
                          SnackbarService.showSuccess(context, 'Category "$name" added');
                        } else if (_cats.containsKey(name)) {
                          SnackbarService.showError(context, 'Category already exists');
                        }
                      },
                      child: const Text('Add'),
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

  void _editSubcategories(String category) {
    final list = List<String>.from(_cats[category] ?? []);
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setSt) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.paddingXL),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.radiusL),
                        topRight: Radius.circular(AppDimens.radiusL),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, color: Colors.white, size: 32),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          'Subcategories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'for $category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingL),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add new subcategory
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ctl,
                                  decoration: const InputDecoration(
                                    hintText: 'New subcategory',
                                    prefixIcon: Icon(Icons.add, color: AppColors.primary),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty && !list.contains(value.trim())) {
                                      setSt(() => list.add(value.trim()));
                                      ctl.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppDimens.paddingS),
                              IconButton.filled(
                                onPressed: () {
                                  if (ctl.text.trim().isNotEmpty && !list.contains(ctl.text.trim())) {
                                    setSt(() => list.add(ctl.text.trim()));
                                    ctl.clear();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppDimens.paddingM),
                          
                          // List of subcategories
                          Flexible(
                            child: list.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
                                        const SizedBox(height: AppDimens.paddingS),
                                        Text(
                                          'No subcategories yet',
                                          style: AppTextStyles.bodySecondary,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: list.length,
                                    itemBuilder: (ctx, i) {
                                      final s = list[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${i + 1}',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Text(s),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                            onPressed: () => setSt(() => list.removeAt(i)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingL),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _cats[category] = list);
                              widget.onChanged(_cats);
                              Navigator.of(context).pop();
                              SnackbarService.showSuccess(context, 'Subcategories updated');
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _setBudget(String category) {
    final ctl = TextEditingController(
      text: (_budgets[category] ?? 0.0).toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppDimens.paddingL),
              Text(
                'Set Budget',
                style: AppTextStyles.heading3,
              ),
              Text(
                'for $category',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              TextField(
                controller: ctl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly budget',
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                  suffixText: 'Tk',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(ctl.text.trim()) ?? 0.0;
                        setState(() => _budgets[category] = v);
                        widget.onBudgetsChanged(_budgets);
                        Navigator.of(context).pop();
                        SnackbarService.showSuccess(context, 'Budget updated');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Save'),
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

  Future<void> _deleteCategory(String category) async {
    final confirm = await AppDialogs.showConfirmation(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete "$category"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirm) {
      setState(() {
        _cats.remove(category);
        _budgets.remove(category);
      });
      widget.onChanged(_cats);
      widget.onBudgetsChanged(_budgets);
      if (mounted) {
        SnackbarService.showSuccess(context, 'Category deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Categories & Budgets',
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: false,
      ),
      body: _cats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              itemCount: _cats.keys.length,
              itemBuilder: (context, index) {
                final category = _cats.keys.elementAt(index);
                return _buildCategoryCard(category);
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          onPressed: _addCategory,
          child: const Icon(Icons.add, size: 28),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
            const Text(
              'No Categories Yet',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Create your first category to start tracking expenses',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            ElevatedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    final budget = _budgets[category] ?? 0.0;
    final subcategories = _cats[category] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusM),
                topRight: Radius.circular(AppDimens.radiusM),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_outlined, color: Colors.white),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        '${subcategories.length} subcategories',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  onSelected: (val) {
                    if (val == 'budget') {
                      _setBudget(category);
                    } else if (val == 'edit') {
                      _editSubcategories(category);
                    } else if (val == 'delete') {
                      _deleteCategory(category);
                    }
                  },
                  itemBuilder: (ctx) => [
                    _buildPopupItem(Icons.attach_money, 'Set budget', 'budget', AppColors.success),
                    _buildPopupItem(Icons.edit_outlined, 'Edit subcategories', 'edit', AppColors.info),
                    _buildPopupItem(Icons.delete_outline, 'Delete category', 'delete', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget row
                Row(
                  children: [
                    Icon(Icons.savings_outlined, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Budget:',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const Spacer(),
                    Text(
                      '${budget.toStringAsFixed(0)} Tk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: budget > 0 ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                if (subcategories.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.paddingM),
                  const Divider(),
                  const SizedBox(height: AppDimens.paddingS),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subcategories.map((sub) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        sub,
                        style: const TextStyle(fontSize: 13),
                      ),
                    )).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: AppDimens.paddingM),
                  InkWell(
                    onTap: () => _editSubcategories(category),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Add subcategories',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(IconData icon, String text, String value, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
