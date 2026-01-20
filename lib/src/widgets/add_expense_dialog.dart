import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/snackbar_service.dart';

class AddExpenseDialog extends StatefulWidget {
  final Map<String, List<String>> categories;
  final Future<void> Function(String category, String sub, String title, double amount, String details, DateTime date) onAdd;

  const AddExpenseDialog({Key? key, required this.categories, required this.onAdd}) : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  String? _selectedSub;
  final _titleCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  final _detailsCtl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final hasCats = widget.categories.isNotEmpty && widget.categories.values.any((l) => l.isNotEmpty);
    if (hasCats) {
      _selectedCategory = widget.categories.keys.first;
      _selectedSub = widget.categories[_selectedCategory!]!.first;
    } else {
      _selectedCategory = null;
      _selectedSub = null;
    }

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleCtl.dispose();
    _amountCtl.dispose();
    _detailsCtl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final title = _titleCtl.text.trim();
    final amount = double.tryParse(_amountCtl.text.trim()) ?? 0.0;
    final details = _detailsCtl.text.trim();
    
    if (_selectedCategory == null || _selectedSub == null) return;

    setState(() => _isLoading = true);
    
    try {
      await widget.onAdd(_selectedCategory!, _selectedSub!, title, amount, details, _selectedDate);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Failed to add expense');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCats = widget.categories.isNotEmpty && widget.categories.values.any((l) => l.isNotEmpty);
    final screenWidth = MediaQuery.of(context).size.width;
    // Allow the dialog to expand on larger screens but keep padding on small screens
    final dialogMaxWidth = screenWidth > 900 ? 900.0 : (screenWidth - 48.0);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxWidth: dialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimens.radiusXL),
                    topRight: Radius.circular(AppDimens.radiusXL),
                  ),
                ),
                child: Column(
                  children: [
                    // Container(
                    //   width: 56,
                    //   height: 56,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white.withOpacity(0.2),
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: const Icon(
                    //     Icons.add_shopping_cart,
                    //     color: Colors.white,
                    //     size: 28,
                    //   ),
                    // ),
                    // const SizedBox(height: AppDimens.paddingM),
                    const Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your spending',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content (made flexible + scrollable to avoid overflow)
              Flexible(
                child: hasCats
                    ? Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(left:20, right:20, top:16, bottom:28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category dropdown
                              _buildLabel('Category'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL, vertical: AppDimens.paddingM),
                                ),
                                items: widget.categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedCategory = v;
                                    _selectedSub = widget.categories[_selectedCategory!]!.first;
                                  });
                                },
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              // Sub-category dropdown
                              _buildLabel('Sub-category'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              DropdownButtonFormField<String>(
                                value: _selectedSub,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.subdirectory_arrow_right, color: AppColors.primary),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL, vertical: AppDimens.paddingM),
                                ),
                                items: widget.categories[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (v) => setState(() => _selectedSub = v ?? _selectedSub),
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              // Title field
                              _buildLabel('Title'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              TextFormField(
                                controller: _titleCtl,
                                decoration: const InputDecoration(
                                  hintText: 'What did you spend on?',
                                  prefixIcon: Icon(Icons.title, color: AppColors.primary),
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              // Amount field
                              _buildLabel('Amount'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              TextFormField(
                                controller: _amountCtl,
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                                  suffixText: 'Tk',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final amount = double.tryParse(value.trim());
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              // Details field (optional)
                              _buildLabel('Details (optional)'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              TextFormField(
                                controller: _detailsCtl,
                                decoration: const InputDecoration(
                                  hintText: 'Add any notes...',
                                  prefixIcon: Icon(Icons.notes, color: AppColors.primary),
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                maxLines: 2,
                              ),

                              const SizedBox(height: AppDimens.paddingS),

                              // Date picker
                              _buildLabel('Date'),
                              // const SizedBox(height: AppDimens.paddingXS),
                              InkWell(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (d != null) setState(() => _selectedDate = d);
                                },
                                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                child: Container(
                                  padding: const EdgeInsets.all(AppDimens.paddingL),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.divider),
                                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: AppColors.primary),
                                      const SizedBox(width: AppDimens.paddingM),
                                      Text(
                                        _formatDate(_selectedDate),
                                        style: AppTextStyles.body,
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppDimens.paddingXL),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.paddingM),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Add Expense'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimens.paddingXL),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.category_outlined,
                                color: AppColors.warning,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: AppDimens.paddingL),
                            const Text(
                              'No Categories Found',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: AppDimens.paddingS),
                            Text(
                              'Please add a category and sub-category before adding expenses.',
                              style: AppTextStyles.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.paddingXL),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
