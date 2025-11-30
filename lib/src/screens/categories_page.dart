import 'package:flutter/material.dart';

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
      builder: (c) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctl.text.trim();
              if (name.isNotEmpty && !_cats.containsKey(name)) {
                setState(() {
                  _cats[name] = [];
                  _budgets[name] = 0.0;
                });
                widget.onChanged(_cats);
                widget.onBudgetsChanged(_budgets);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
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
          final maxHeight = MediaQuery.of(context).size.height * 0.5;
          return AlertDialog(
            title: Text('Subcategories for $category'),
            content: SizedBox(
              width: double.maxFinite,
              height: maxHeight,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final s = list[i];
                        return ListTile(
                          visualDensity: VisualDensity.compact,
                          dense: true,
                          title: Text(s),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setSt(() => list.removeAt(i));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  TextField(
                    controller: ctl,
                    decoration: const InputDecoration(labelText: 'New subcategory'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = ctl.text.trim();
                  if (v.isNotEmpty) {
                    setState(() => _cats[category] = [...list, v]);
                    widget.onChanged(_cats);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            'Manage Categories',
            style: TextStyle(
              fontFamily: 'LeckerliOne',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: ListView(
        children: _cats.keys
            .map(
              (k) => ListTile(
                title: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                      height: 0,
                      color: Colors.grey,
                    ),
                    Text('Budget:   ${(_budgets[k] ?? 0.0).toStringAsFixed(0)} Tk'),
                    const Divider(
                      height: 0,
                      color: Colors.grey,
                    ),
                    Text('Subcategories:\n${(_cats[k] ?? []).join(', ')}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'budget') {
                      final ctl = TextEditingController(
                        text: (_budgets[k] ?? 0.0).toString(),
                      );
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Set budget for $k'),
                          content: TextField(
                            controller: ctl,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final v = double.tryParse(ctl.text.trim()) ?? 0.0;
                                setState(() => _budgets[k] = v);
                                widget.onBudgetsChanged(_budgets);
                                Navigator.of(context).pop();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    } else if (val == 'edit') {
                      _editSubcategories(k);
                    } else if (val == 'delete') {
                      setState(() {
                        _cats.remove(k);
                        _budgets.remove(k);
                      });
                      widget.onChanged(_cats);
                      widget.onBudgetsChanged(_budgets);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'budget', child: Row(children: const [Icon(Icons.attach_money, color: Colors.orange), SizedBox(width: 8), Text('Set budget')])),
                    PopupMenuItem(value: 'edit', child: Row(children: const [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit subcategories')])),
                    PopupMenuItem(value: 'delete', child: Row(children: const [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete category')])),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
