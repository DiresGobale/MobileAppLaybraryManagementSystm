import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/book_card.dart';
import '../../widgets/empty_state.dart';

class BookCatalogScreen extends StatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  State<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends State<BookCatalogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.currentUser!.canManageBooks;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Book Catalog',
        subtitle: 'Browse ${books.items.length} title(s) in the collection',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => books.refresh(),
          ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.bookForm, arguments: null),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search by title, author, ISBN, or category',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              books.setQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD6CFBE)),
                    ),
                  ),
                  onChanged: (v) => books.setQuery(v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(
                        context: context,
                        label: 'All',
                        selected: books.categoryId == null,
                        onTap: () => books.setCategory(null),
                      ),
                      for (final c in books.categories)
                        _filterChip(
                          context: context,
                          label: c.name,
                          selected: books.categoryId == c.id,
                          onTap: () => books.setCategory(c.id),
                        ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Available only',
                            style: TextStyle(fontFamily: 'PT Serif', fontSize: 11.5)),
                        selected: books.availableOnly,
                        onSelected: (v) => books.setAvailableOnly(v),
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: books.availableOnly ? Colors.white : AppTheme.ink,
                          fontFamily: 'PT Serif',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD6CFBE)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: books.isLoading && books.items.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : books.items.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No books match your search',
                        message: 'Try adjusting your query or clearing filters.',
                        actionLabel: canManage ? 'Add Book' : null,
                        onAction: canManage
                            ? () => Navigator.pushNamed(context, AppRoutes.bookForm,
                                arguments: null)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                        itemCount: books.items.length,
                        itemBuilder: (context, i) {
                          final item = books.items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BookCard(
                              item: item,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.bookDetail,
                                arguments: item.book.id,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _filterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppTheme.ink,
            fontFamily: 'PT Serif',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD6CFBE)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}
