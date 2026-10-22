import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Compact activity / event tile for dashboard "recent activity" lists.
class ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? time;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.13),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withOpacity(0.35), width: 0.8),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'PT Serif',
          fontSize: 13.5,
          color: AppTheme.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 12,
                color: AppTheme.slate,
              ),
            ),
      trailing: time == null
          ? null
          : Text(
              time!,
              style: const TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 11,
                color: AppTheme.slate,
              ),
            ),
    );
  }
}
