import 'package:flutter/material.dart';

import '../models/loan.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';

class LoanCard extends StatelessWidget {
  final LoanDetail detail;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LoanCard({super.key, required this.detail, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l = detail.loan;
    final isOverdue = l.isReturned
        ? false
        : DateTime.now().isAfter(l.dueDate);
    final color = l.isReturned
        ? AppTheme.success
        : isOverdue
            ? AppTheme.danger
            : AppTheme.primary;

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
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.bookTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                        fontFamily: 'PT Serif',
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.bookAuthor,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate,
                        fontFamily: 'PT Serif',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _badge(color: color, text: l.isReturned
                            ? 'Returned'
                            : isOverdue
                                ? 'Overdue'
                                : 'Active'),
                        _mini(
                          'Issued ${DateUtilsX.formatDate(l.issueDate)}',
                        ),
                        _mini(
                          'Due ${DateUtilsX.formatDate(l.dueDate)}',
                        ),
                      ],
                    ),
                    if (!l.isReturned)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateUtilsX.daysLeft(l.dueDate),
                          style: TextStyle(
                            color: isOverdue ? AppTheme.danger : AppTheme.slate,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PT Serif',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({required Color color, required String text}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'PT Serif',
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _mini(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.slate,
          fontFamily: 'PT Serif',
        ),
      );
}
