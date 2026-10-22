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

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.currentUser!.canManageBooks;

    final filtered = books.items
        .where((b) => _query.isEmpty ||
            b.book.title.toLowerCase().contains(_query.toLowerCase()) ||
            b.book.isbn.toLowerCase().contains(_query.toLowerCase()) ||
            b.book.author.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Manage Books',
        subtitle: '${books.items.length} title(s) in catalog',
        showMenu: true,
        actions: [
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
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Quick search title, ISBN, or author',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6CFBE)),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: books.isLoading && books.items.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.library_books_outlined,
                        title: 'No books found',
                        message: 'Add a new title to populate the catalog.',
                        actionLabel: canManage ? 'Add Book' : null,
                        onAction: canManage
                            ? () => Navigator.pushNamed(context, AppRoutes.bookForm,
                                arguments: null)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BookCard(
                            item: filtered[i],
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.bookDetail,
                              arguments: filtered[i].book.id,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
    );
  }
}
