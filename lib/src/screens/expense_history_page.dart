import 'package:flutter/material.dart';

import '../../models/expense.dart';

enum SortOrder { amountAsc, amountDesc }

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
  SortOrder _sort = SortOrder.amountDesc;
  String _query = '';

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
      if (_sort == SortOrder.amountAsc) return a.amount.compareTo(b.amount);
      return b.amount.compareTo(a.amount);
    });

    setState(() => _filtered = list);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(context: context, initialDate: _from ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) {
      setState(() => _from = DateTime(d.year, d.month, d.day));
      _applyFilters();
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(context: context, initialDate: _to ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
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
      _sort = SortOrder.amountDesc;
      _applyFilters();
    });
  }

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
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            'Expense History',
            style: TextStyle(
              fontFamily: 'LeckerliOne',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search title or details'),
                    onChanged: (v) {
                      _query = v;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortOrder>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort),
                  onSelected: (s) {
                    setState(() => _sort = s);
                    _applyFilters();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: SortOrder.amountDesc, child: Text('Amount: High → Low')),
                    const PopupMenuItem(value: SortOrder.amountAsc, child: Text('Amount: Low → High')),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(onPressed: _pickFrom, icon: const Icon(Icons.calendar_today), label: Text(_from == null ? 'From' : '${_from!.year}-${_from!.month.toString().padLeft(2,'0')}-${_from!.day.toString().padLeft(2,'0')}')),
                ElevatedButton.icon(onPressed: _pickTo, icon: const Icon(Icons.calendar_today), label: Text(_to == null ? 'To' : '${_to!.year}-${_to!.month.toString().padLeft(2,'0')}-${_to!.day.toString().padLeft(2,'0')}')),
                DropdownButton<String?>(
                  value: _category,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Any')),
                    ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))).toList()
                  ],
                  onChanged: (v) {
                    setState(() => _category = v);
                    _applyFilters();
                  },
                ),
                DropdownButton<String?>(
                  value: _subCategory,
                  hint: const Text('Subcategory'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Any')),
                    ...subs.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))).toList()
                  ],
                  onChanged: (v) {
                    setState(() => _subCategory = v);
                    _applyFilters();
                  },
                ),
                TextButton(onPressed: _clearFilters, child: const Text('Clear')),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No expenses match the filters'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final e = _filtered[i];
                      return ListTile(
                        title: Text(e.title),
                        subtitle: Text('${e.category} › ${e.subCategory} • ${e.date.toLocal().toString().split(' ').first}'),
                        trailing: Text('${e.amount.toStringAsFixed(1)} Tk'),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
