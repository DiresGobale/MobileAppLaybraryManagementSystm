import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final BookWithCategory item;
  final VoidCallback onTap;

  const BookCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = item.book;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverThumb(book: b),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                        fontFamily: 'PT Serif',
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.slate,
                        fontFamily: 'PT Serif',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.categoryName != null)
                          _Chip(text: item.categoryName!, color: AppTheme.accent),
                        _Chip(
                          text: 'ISBN ${b.isbn}',
                          color: AppTheme.slate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          b.isAvailable ? Icons.check_circle : Icons.do_not_disturb,
                          size: 14,
                          color: b.isAvailable ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            b.isAvailable
                                ? '${b.availableQuantity} of ${b.totalQuantity} available'
                                : 'Out of stock',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: b.isAvailable ? AppTheme.success : AppTheme.danger,
                              fontFamily: 'PT Serif',
                            ),
                          ),
                        ),
                        if (b.shelfLocation != null && b.shelfLocation!.isNotEmpty)
                          Text(
                            'Shelf ${b.shelfLocation}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate,
                              fontFamily: 'PT Serif',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final Book book;
  const _CoverThumb({required this.book});

  @override
  Widget build(BuildContext context) {
    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          book.coverPath!,
          width: 56,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 76,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.6), width: 1.2),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: AppTheme.accent,
          size: 26,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'PT Serif',
        ),
      ),
    );
  }
}
