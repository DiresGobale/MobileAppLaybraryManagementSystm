import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/book_provider.dart';
import '../../services/book_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _items = [];
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bp = context.read<BookProvider>();
    final svc = context.read<BookService>();
    setState(() => _loading = true);
    _items = await svc.categories();
    _counts = {for (final c in _items) c.id!: await bp._bookServiceCategoriesCount(c.id!)};
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Categories',
        subtitle: '${_items.length} catalog categories',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openCreateForm,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  message: 'Add a category to organize your catalog.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    final count = _counts[c.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.category_rounded, color: AppTheme.accent, size: 18),
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                          c.description?.isNotEmpty == true ? c.description! : 'No description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count book(s)',
                                style: const TextStyle(
                                  color: AppTheme.accentDark,
                                  fontFamily: 'PT Serif',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
                              onPressed: () => _openEditForm(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger, size: 18),
                              onPressed: () => _delete(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openCreateForm() async {
    await showDialog(
      context: context,
      builder: (_) => const _CategoryDialog(category: null),
    );
    _load();
  }

  Future<void> _openEditForm(Category c) async {
    await showDialog(
      context: context,
      builder: (_) => _CategoryDialog(category: c),
    );
    _load();
  }

  Future<void> _delete(Category c) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete category',
      message: 'Delete "${c.name}"? Categories with books cannot be deleted. '
          'Reassign books first.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    final svc = context.read<BookService>();
    try {
      await svc.deleteCategory(c.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    }
    _load();
  }
}

extension on BookProvider {
  Future<int> _bookServiceCategoriesCount(int id) async {
    final res = await this.search(categoryId: id);
    return res.length;
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(text: widget.category?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _working = true);
    final svc = context.read<BookService>();
    try {
      final c = Category(
        id: widget.category?.id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      );
      if (widget.category == null) {
        await svc.createCategory(c);
      } else {
        await svc.updateCategory(c);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.category == null ? 'New Category' : 'Edit Category',
        style: const TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Computer Science'),
                validator: (v) => Validators.required(v, label: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _working ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
