import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../routes/app_routes.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final notif = context.read<NotificationProvider>();
    if (auth.currentUser != null) {
      await notif.loadForUser(auth.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.currentUser!.isStudent;
    final items = notif.items;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Notifications',
        subtitle: notif.unreadCount > 0
            ? '${notif.unreadCount} unread'
            : 'All caught up',
        showMenu: true,
        actions: [
          if (notif.unreadCount > 0)
            TextButton(
              onPressed: () => notif.markAllRead(auth.currentUser!.id!),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notif.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  message: 'You will be notified here about issued books, '
                      'due dates, and overdue reminders.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final color = _colorFor(n.title);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: n.isRead ? Colors.white : color.withOpacity(0.05),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withOpacity(0.35), width: 1),
                          ),
                          child: Icon(_iconFor(n.title), color: color, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 14,
                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.message,
                                style: const TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 12.5,
                                  color: AppTheme.slate,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateUtilsX.relative(n.createdAt),
                                style: const TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 11,
                                  color: AppTheme.slate,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!n.isRead) {
                            notif.markRead(n.id!, auth.currentUser!.id!);
                          }
                          // Optional deep-link could go here.
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18,
                              color: AppTheme.danger),
                          onPressed: () => notif.delete(n.id!, auth.currentUser!.id!),
                          tooltip: 'Delete',
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: AppBottomNav(currentIndex: isStudent ? 3 : 3),
    );
  }

  Color _colorFor(String title) {
    if (title.toLowerCase().contains('overdue')) return AppTheme.danger;
    if (title.toLowerCase().contains('returned')) return AppTheme.success;
    if (title.toLowerCase().contains('due soon')) return AppTheme.warning;
    return AppTheme.primary;
  }

  IconData _iconFor(String title) {
    if (title.toLowerCase().contains('overdue')) return Icons.error_outline_rounded;
    if (title.toLowerCase().contains('returned')) return Icons.assignment_returned_rounded;
    if (title.toLowerCase().contains('due soon')) return Icons.access_time_rounded;
    return Icons.local_library_rounded;
  }
}
