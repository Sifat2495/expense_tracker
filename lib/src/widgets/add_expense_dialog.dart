import 'package:flutter/material.dart';

class AddExpenseDialog extends StatefulWidget {
  final Map<String, List<String>> categories;
  final Future<void> Function(String category, String sub, String title, double amount, String details, DateTime date) onAdd;

  const AddExpenseDialog({Key? key, required this.categories, required this.onAdd}) : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  String? _selectedCategory;
  String? _selectedSub;
  final _titleCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  final _detailsCtl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Builder(
          builder: (ctx) {
            final hasCats = widget.categories.isNotEmpty && widget.categories.values.any((l) => l.isNotEmpty);
            if (!hasCats) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Please add category and sub-category before adding expense.'),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedCategory = v;
                      _selectedSub = widget.categories[_selectedCategory!]!.first;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedSub,
                  decoration: const InputDecoration(labelText: 'Sub-category'),
                  items: widget.categories[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSub = v ?? _selectedSub),
                ),
                TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: _amountCtl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: _detailsCtl, decoration: const InputDecoration(labelText: 'Details (optional)')),
                Row(children: [TextButton.icon(onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (d != null) setState(() => _selectedDate = d);
                }, icon: const Icon(Icons.calendar_today), label: Text('${_selectedDate.toLocal()}'.split(' ')[0]))]),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        if (widget.categories.isNotEmpty && widget.categories.values.any((l) => l.isNotEmpty))
          ElevatedButton(onPressed: () async {
            final title = _titleCtl.text.trim();
            final amount = double.tryParse(_amountCtl.text.trim()) ?? 0.0;
            final details = _detailsCtl.text.trim();
            if (title.isNotEmpty && amount > 0 && _selectedCategory != null && _selectedSub != null) {
              await widget.onAdd(_selectedCategory!, _selectedSub!, title, amount, details, _selectedDate);
              Navigator.of(context).pop();
            }
          }, child: const Text('Add')),
      ],
    );
   }
 }
