import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Polished branded app bar used by most screens.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final bool showMenu;
  final Widget? leading;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
    this.showMenu = false,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.maybePop(context),
                )
              : showMenu
                  ? IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    )
                  : null),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontFamily: 'PT Serif',
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryLight],
          ),
        ),
      ),
    );
  }
}

/// Brand mark for splash + drawers.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppTheme.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.menu_book_rounded, color: AppTheme.accent, size: size * 0.5),
          Positioned(
            bottom: size * 0.16,
            child: Container(
              width: size * 0.6,
              height: 1.5,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
